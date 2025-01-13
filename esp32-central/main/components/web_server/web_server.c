#include "web_server.h"
#include "cJSON.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "wifi_manager.h"
#include "oled_display.h"
#include <string.h>
#include <ctype.h>

static const char *TAG = "web_server";
static httpd_handle_t server = NULL;

static esp_err_t root_post_handler(httpd_req_t *req);

static void url_decode(char *dst, const char *src) {
    char a, b;
    while (*src) {
        if ((*src == '%') &&
            ((a = src[1]) && (b = src[2])) &&
            (isxdigit(a) && isxdigit(b))) {
            if (a >= 'a')
                a -= 'a' - 'A';
            if (a >= 'A')
                a -= ('A' - 10);
            else
                a -= '0';
            if (b >= 'a')
                b -= 'a' - 'A';
            if (b >= 'A')
                b -= ('A' - 10);
            else
                b -= '0';
            *dst++ = 16 * a + b;
            src += 3;
        } else if (*src == '+') {
            *dst++ = ' ';
            src++;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

static esp_err_t get_handler(httpd_req_t *req) {
    httpd_resp_set_type(req, "text/html; charset=utf-8");

    const char *resp_str = "<!DOCTYPE html>"
                           "<html lang=\"pl\">"
                           "<head>"
                           "<meta charset=\"UTF-8\">"
                           "<title>Konfiguracja Wi-Fi</title>"
                           "</head>"
                           "<body>"
                           "<h1>Konfiguracja Wi-Fi</h1>"
                           "<form action=\"/\" method=\"post\">"
                           "SSID:<br><input type=\"text\" name=\"ssid\"><br>"
                           "Hasło:<br><input type=\"password\" name=\"password\"><br><br>"
                           "<input type=\"submit\" value=\"Zapisz\">"
                           "</form>"
                           "</body>"
                           "</html>";
    httpd_resp_send(req, resp_str, strlen(resp_str));

    oled_clear_display();
    oled_draw_text(0, 0, "Wi-Fi Config Portal");
    oled_draw_text(0, 16, "Ready to connect");
    oled_update_display();

    return ESP_OK;
}

static esp_err_t post_handler(httpd_req_t *req) {
    char buf[200];
    int ret, remaining = req->content_len;

    char ssid[32] = {0};
    char password[64] = {0};

    if (remaining >= sizeof(buf)) {
        ESP_LOGE(TAG, "Dane są zbyt duże");
        httpd_resp_send_500(req);
        return ESP_FAIL;
    }

    if ((ret = httpd_req_recv(req, buf, remaining)) <= 0) {
        if (ret == HTTPD_SOCK_ERR_TIMEOUT) {
            ESP_LOGE(TAG, "Timeout przy odbieraniu danych");
            httpd_resp_send_408(req);
        }
        return ESP_FAIL;
    }
    buf[ret] = '\0';

    char *ssid_start = strstr(buf, "ssid=");
    char *password_start = strstr(buf, "password=");

    if (ssid_start) {
        ssid_start += 5;
        char *ssid_end = strchr(ssid_start, '&');
        if (ssid_end) {
            memcpy(ssid, ssid_start, ssid_end - ssid_start);
            ssid[ssid_end - ssid_start] = '\0';
        } else {
            strcpy(ssid, ssid_start);
        }
        url_decode(ssid, ssid);
    }

    if (password_start) {
        password_start += 9;
        strcpy(password, password_start);
        url_decode(password, password);
    }

    save_wifi_credentials(ssid, password);

    httpd_resp_set_type(req, "text/html; charset=utf-8");

    const char *resp_str = "<!DOCTYPE html>"
                           "<html lang=\"pl\">"
                           "<head>"
                           "<meta charset=\"UTF-8\">"
                           "<title>Konfiguracja Wi-Fi</title>"
                           "</head>"
                           "<body>"
                           "<h1>Dane zapisane. Urządzenie zostanie zrestartowane.</h1>"
                           "</body>"
                           "</html>";
    httpd_resp_send(req, resp_str, strlen(resp_str));

    oled_clear_display();
    oled_draw_text(0, 0, "Wi-Fi Credentials:");
    oled_draw_text(0, 16, ssid);
    oled_draw_text(0, 32, "Saved!");
    oled_update_display();

    vTaskDelay(2000 / portTICK_PERIOD_MS);

    oled_clear_display();
    oled_draw_text(0, 0, "Restarting...");
    oled_update_display();

    esp_restart();

    return ESP_OK;
}

void start_webserver(void) {
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();

    httpd_uri_t uri_get = {
            .uri = "/",
            .method = HTTP_GET,
            .handler = get_handler,
            .user_ctx = NULL
    };

    httpd_uri_t uri_post = {
            .uri = "/",
            .method = HTTP_POST,
            .handler = root_post_handler,
            .user_ctx = NULL
    };

    if (httpd_start(&server, &config) == ESP_OK) {
        httpd_register_uri_handler(server, &uri_get);
        httpd_register_uri_handler(server, &uri_post);
        ESP_LOGI(TAG, "Serwer HTTP uruchomiony");

        oled_clear_display();
        oled_draw_text(0, 8, "HTTP Server: Started");
        oled_update_display();
    } else {
        ESP_LOGE(TAG, "Nie udało się uruchomić serwera HTTP");

        oled_clear_display();
        oled_draw_text(0, 8, "HTTP Server: Error!");
        oled_update_display();
    }
}

static esp_err_t root_post_handler(httpd_req_t *req) {
    char content[128];
    int received = httpd_req_recv(req, content, sizeof(content) - 1);
    if (received <= 0) {
        ESP_LOGE(TAG, "Błąd odbioru danych");
        return ESP_FAIL;
    }
    content[received] = '\0'; // zakończ string
    ESP_LOGI(TAG, "Odebrano dane: %s", content);

    cJSON *json = cJSON_Parse(content);
    if (json == NULL) {
        ESP_LOGE(TAG, "Błąd parsowania JSON");
        return ESP_FAIL;
    }

    const cJSON *ssid_json = cJSON_GetObjectItemCaseSensitive(json, "ssid");
    const cJSON *password_json = cJSON_GetObjectItemCaseSensitive(json, "password");

    const char *ssid = cJSON_IsString(ssid_json) ? ssid_json->valuestring : "";
    const char *password = cJSON_IsString(password_json) ? password_json->valuestring : "";

    ESP_LOGI(TAG, "Parsowane dane - SSID: %s, PASSWORD: %s", ssid, password);

    save_wifi_credentials(ssid, password);

    cJSON_Delete(json);

    const char resp[] = "OK";
    httpd_resp_send(req, resp, HTTPD_RESP_USE_STRLEN);

    esp_restart();

    return ESP_OK;
}
