#include "http_client.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "certs.h"

#define MAX_HTTP_OUTPUT_BUFFER 8192

#define COLOR_RESET "\033[0m"
#define COLOR_BLUE "\033[34m"

static const char *TAG = "HTTP_CLIENT";

static char output_buffer[MAX_HTTP_OUTPUT_BUFFER];
static int output_len = 0;

esp_err_t _http_event_handler(esp_http_client_event_t *evt) {
    switch (evt->event_id) {
        case HTTP_EVENT_ON_DATA:
            if (!esp_http_client_is_chunked_response(evt->client)) {
                int copy_len = evt->data_len;

                if (output_len + copy_len < MAX_HTTP_OUTPUT_BUFFER) {
                    memcpy(output_buffer + output_len, evt->data, copy_len);
                    output_len += copy_len;
                } else {
                    ESP_LOGW(TAG, "Buffer overflow, response too large");
                }
            }
            break;
        case HTTP_EVENT_ON_FINISH:
            output_buffer[output_len] = '\0';
            ESP_LOGI(TAG, COLOR_BLUE "Received data:\n%s" COLOR_RESET, output_buffer);
            output_len = 0;
            break;
        default:
            break;
    }
    return ESP_OK;
}

void http_client_get(const char *url) {
    esp_http_client_config_t config = {
            .url = url,
            .event_handler = _http_event_handler,
            .cert_pem = root_cert_pem,
            .timeout_ms = 10000,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);

    esp_err_t err = esp_http_client_perform(client);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "HTTP GET Status = %d, content_length = %lld",
                 esp_http_client_get_status_code(client),
                 esp_http_client_get_content_length(client));
    } else {
        ESP_LOGE(TAG, "HTTP GET request failed: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
}
