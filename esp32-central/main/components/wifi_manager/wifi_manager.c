#include "wifi_manager.h"
#include "esp_http_server.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_mac.h"
#include "esp_netif.h"
#include <string.h>
#include "web_server.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "oled_display.h"
#include "cJSON.h"

#define LED_GPIO_PIN GPIO_NUM_4

static const char *TAG = "wifi_manager";
static bool wifi_connected = false;
static TaskHandle_t led_task_handle = NULL;

bool wifi_manager_is_connected(void) {
    return wifi_connected;
}

void led_task(void *param) {
    while (1) {
        if (!wifi_connected) {
            gpio_set_level(LED_GPIO_PIN, 1);
            vTaskDelay(500 / portTICK_PERIOD_MS);
            gpio_set_level(LED_GPIO_PIN, 0);
            vTaskDelay(500 / portTICK_PERIOD_MS);
        } else {
            for (int i = 0; i < 10; i++) {
                if (!wifi_connected) {
                    break;
                }
                gpio_set_level(LED_GPIO_PIN, 0);
                vTaskDelay(100 / portTICK_PERIOD_MS);
            }
        }
    }
}

static void wifi_event_handler(void *arg, esp_event_base_t event_base,
                               int32_t event_id, void *event_data) {
    if (event_base == WIFI_EVENT) {
        switch (event_id) {
            case WIFI_EVENT_STA_START:
                esp_wifi_connect();
                oled_clear_display();
                oled_draw_text(0, 0, "Wi-Fi Starting...");
                oled_update_display();
                break;
            case WIFI_EVENT_STA_CONNECTED:
                ESP_LOGI(TAG, "Połączono z siecią Wi-Fi.");
                wifi_connected = true;
                oled_clear_display();
                oled_draw_text(0, 0, "Wi-Fi Connected!");
                oled_update_display();
                break;
            case WIFI_EVENT_STA_DISCONNECTED:
                ESP_LOGI(TAG, "Odłączono od sieci Wi-Fi, ponawiam próbę połączenia...");
                wifi_connected = false;
                esp_wifi_connect();
                oled_clear_display();
                oled_draw_text(0, 0, "Wi-Fi Disconnected");
                oled_update_display();
                break;
            default:
                break;
        }
    }
}

void wifi_manager_init(void) {
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_t *netif_sta = esp_netif_create_default_wifi_sta();
    esp_netif_t *netif_ap = esp_netif_create_default_wifi_ap();
    assert(netif_sta && netif_ap);

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                        ESP_EVENT_ANY_ID,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                        IP_EVENT_STA_GOT_IP,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));

    gpio_reset_pin(LED_GPIO_PIN);
    gpio_set_direction(LED_GPIO_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO_PIN, 0);

    oled_i2c_init(GPIO_NUM_35, GPIO_NUM_41);
    oled_init();
    oled_clear_display();
    oled_draw_text(0, 0, "Starting Wi-Fi...");
    oled_update_display();

    xTaskCreate(led_task, "LED Task", 2048, NULL, 5, &led_task_handle);

    wifi_config_t wifi_ap_config = {
            .ap = {
                    .ssid = "ESP32-Config",
                    .ssid_len = strlen("ESP32-Config"),
                    .channel = 1,
                    .password = "config123",
                    .max_connection = 4,
                    .authmode = WIFI_AUTH_WPA_WPA2_PSK},
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &wifi_ap_config));

    char ssid[32] = {0};
    char password[64] = {0};
    if (load_wifi_credentials(ssid, sizeof(ssid), password, sizeof(password)) == ESP_OK) {
        ESP_LOGI(TAG, "Znaleziono zapisane dane Wi-Fi, łączenie z siecią: %s", ssid);

        wifi_config_t wifi_sta_config = {0};
        strcpy((char *) wifi_sta_config.sta.ssid, ssid);
        strcpy((char *) wifi_sta_config.sta.password, password);

        ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_sta_config));
        oled_clear_display();
        oled_draw_text(0, 0, "Connecting...");
        oled_draw_text(0, 16, ssid);
        oled_update_display();
    } else {
        ESP_LOGI(TAG, "Brak zapisanych danych Wi-Fi, uruchamianie tylko Access Point");
        oled_clear_display();
        oled_draw_text(0, 0, "AP Mode:");
        oled_draw_text(0, 16, "ESP32-Config");
        oled_update_display();
    }

    ESP_ERROR_CHECK(esp_wifi_start());
    start_webserver();
}

void save_wifi_credentials(const char *ssid, const char *password) {
    ESP_LOGI(TAG, "Zapisywanie danych Wi-Fi: SSID=%s, PASSWORD=%s", ssid, password);
    nvs_handle_t nvs_handle;
    ESP_ERROR_CHECK(nvs_open("storage", NVS_READWRITE, &nvs_handle));

    ESP_ERROR_CHECK(nvs_set_str(nvs_handle, "ssid", ssid));
    ESP_ERROR_CHECK(nvs_set_str(nvs_handle, "password", password));

    ESP_ERROR_CHECK(nvs_commit(nvs_handle));
    nvs_close(nvs_handle);

    ESP_LOGI(TAG, "Dane Wi-Fi zapisane w NVS");
    oled_clear_display();
    oled_draw_text(0, 0, "Wi-Fi Credentials:");
    oled_draw_text(0, 16, "Saved!");
    oled_update_display();
}

esp_err_t load_wifi_credentials(char *ssid, size_t ssid_size, char *password, size_t password_size) {
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &nvs_handle);
    if (err != ESP_OK) {
        return err;
    }

    err = nvs_get_str(nvs_handle, "ssid", ssid, &ssid_size);
    if (err != ESP_OK) {
        nvs_close(nvs_handle);
        return err;
    }

    err = nvs_get_str(nvs_handle, "password", password, &password_size);
    nvs_close(nvs_handle);

    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Wczytane dane Wi-Fi: SSID=%s, PASSWORD=%s", ssid, password);
        oled_clear_display();
        oled_draw_text(0, 0, "Wi-Fi Credentials:");
        oled_draw_text(0, 16, "Loaded!");
        oled_update_display();
    }

    return err;
}
