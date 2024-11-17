#include "mqtt_broker.h"
#include <stddef.h>
#include "esp_event.h"
#include "esp_log.h"
#include "mqtt_client.h"

#define TAG "MQTT_CLIENT"

static esp_mqtt_client_handle_t client;

void mqtt_publish(const char *topic, const char *message) {
    ESP_LOGI(TAG, "Publishing message to topic: %s", topic);
    esp_mqtt_client_publish(client, topic, message, 0, 1, 0);
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t) event_data;

    switch ((esp_mqtt_event_id_t) event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT connected");
            esp_mqtt_client_subscribe(client, "user123/esp32_1/led/control", 0);
            break;
        case MQTT_EVENT_DATA:
            ESP_LOGI(TAG, "Received data on topic: %.*s",
                     event->topic_len, event->topic);
            ESP_LOGI(TAG, "Data: %.*s", event->data_len, event->data);
            break;
        default:
            break;
    }
}

void mqtt_app_start(void) {
    const esp_mqtt_client_config_t mqtt_cfg = {
            .broker.address.uri = "mqtt://MacBook-Pro-Arkadiusz-2.local",
            .credentials = {
                    .username = "user123",
                    .authentication.password = "user123",
            },
    };

    client = esp_mqtt_client_init(&mqtt_cfg);
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(client);
}
