#include "http_client.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "certs.h"

static const char *TAG = "HTTP_CLIENT";

#define MAX_HTTP_OUTPUT_BUFFER 8192
static char output_buffer[MAX_HTTP_OUTPUT_BUFFER];
static int output_len = 0;

esp_err_t _http_event_handler(esp_http_client_event_t *evt) {
    switch (evt->event_id) {
        case HTTP_EVENT_ON_DATA:
            if (!esp_http_client_is_chunked_response(evt->client)) {
                printf("%.*s", evt->data_len, (char *) evt->data);
            }
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
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);

    output_len = 0;
    esp_err_t err = esp_http_client_perform(client);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "HTTP GET Status = %d, content_length = %lld",
                 esp_http_client_get_status_code(client),
                 esp_http_client_get_content_length(client));
        output_buffer[output_len] = '\0';
        printf("Received data:\n%s\n", output_buffer);
    } else {
        ESP_LOGE(TAG, "HTTP GET request failed: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
}
