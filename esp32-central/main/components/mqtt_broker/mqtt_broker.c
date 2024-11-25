#include "mqtt_broker.h"
#include <stddef.h>
#include "esp_event.h"
#include "esp_log.h"
#include "mqtt_client.h"

#define TAG "MQTT_CLIENT"

static esp_mqtt_client_handle_t client;
static bool mqtt_connected = false;

void mqtt_publish(const char *topic, const char *message) {
    if (mqtt_connected) {
        ESP_LOGI(TAG, "Publishing message to topic: %s", topic);
        esp_mqtt_client_publish(client, topic, message, 0, 1, 0);
    } else {
        ESP_LOGW(TAG, "Cannot publish, MQTT not connected");
    }
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t) event_data;
    esp_mqtt_client_handle_t client = event->client;

    ESP_LOGI(TAG, "MQTT event received: %d", event->event_id);

    switch ((esp_mqtt_event_id_t) event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT connected");
            mqtt_connected = true;
            esp_mqtt_client_subscribe(client, "user123/esp32_1/led/control", 0);
            break;
        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT disconnected");
            mqtt_connected = false;
            break;
        case MQTT_EVENT_ERROR:
            ESP_LOGE(TAG, "MQTT event error");
            if (event->error_handle->error_type == MQTT_ERROR_TYPE_ESP_TLS) {
                ESP_LOGE(TAG, "TLS Error Code: 0x%x", event->error_handle->esp_tls_last_esp_err);
            } else if (event->error_handle->error_type == MQTT_ERROR_TYPE_CONNECTION_REFUSED) {
                ESP_LOGE(TAG, "Connection refused error: 0x%x", event->error_handle->connect_return_code);
            } else {
                ESP_LOGE(TAG, "Unknown error type: 0x%x", event->error_handle->error_type);
            }
            break;
        default:
            ESP_LOGI(TAG, "Other MQTT event id: %d", event->event_id);
            break;
    }
}


void mqtt_app_start(void) {
    const esp_mqtt_client_config_t mqtt_cfg = {
            .broker.address.uri = "mqtt://192.168.0.148",
            .broker.address.port = 1883,
            .credentials = {
                    .username = "user123",
                    .authentication.password = "user123",
            },
            .session = {
                    .keepalive = 60,
            },
    };

    client = esp_mqtt_client_init(&mqtt_cfg);
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(client);
}
