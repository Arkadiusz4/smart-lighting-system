#include "mqtt_broker.h"
#include <stddef.h>
#include "esp_event.h"
#include "mqtt_manager.h"
#include "device_control.h"
#include "esp_log.h"
#include "mqtt_client.h"
#include "cJSON.h"

#define TAG "MQTT_CLIENT"

static esp_mqtt_client_handle_t client;
static bool mqtt_connected = false;

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;
    esp_mqtt_client_handle_t client = event->client;

    // ESP_LOGI(TAG, "MQTT event received: %d", event->event_id);

    switch ((esp_mqtt_event_id_t)event_id)
    {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(TAG, "MQTT connected");
        mqtt_connected = true;
        mqtt_publish("boards/F0F5BD4AA62C/network/status", "Połączono z Wi-Fi i MQTT");
        esp_mqtt_client_subscribe(client, "boards/F0F5BD4AA62C/devices/+", 1);

        break;
    case MQTT_EVENT_DATA:
    {
        ESP_LOGI(TAG, "MQTT_EVENT_DATA");
        char topic[event->topic_len + 1];
        memcpy(topic, event->topic, event->topic_len);
        topic[event->topic_len] = '\0';

        char payload[event->data_len + 1];
        memcpy(payload, event->data, event->data_len);
        payload[event->data_len] = '\0';

        ESP_LOGI(TAG, "Odebrano na temat: %s, dane: %s", topic, payload);

        cJSON *json = cJSON_Parse(payload);
        if (json == NULL)
        {
            ESP_LOGW(TAG, "Nie można sparsować JSON");
        }
        else
        {
            cJSON *status_item = cJSON_GetObjectItem(json, "status");
            cJSON *port_item = cJSON_GetObjectItem(json, "port");
            cJSON *type_item = cJSON_GetObjectItem(json, "type");
            cJSON *cooldown_item = cJSON_GetObjectItem(json, "pir_cooldown_time");
            cJSON *ledOn_item = cJSON_GetObjectItem(json, "led_on_duration");
            cJSON *device_id_item = cJSON_GetObjectItem(json, "deviceId");
            // "1737288290192"

            if (cJSON_IsString(device_id_item) &&
                cJSON_IsString(status_item) &&
                cJSON_IsString(port_item) &&
                cJSON_IsString(type_item))
            {
                const char *device_id_str = device_id_item->valuestring;
                const char *status_str = status_item->valuestring;
                const char *port_str = port_item->valuestring;
                const char *type_str = type_item->valuestring;
                const char *cooldown_str = cJSON_IsString(cooldown_item) ? cooldown_item->valuestring : "0";
                const char *ledOn_str = cJSON_IsString(ledOn_item) ? ledOn_item->valuestring : "0";

                // Aktualizuj device (LED lub Sensor ruchu) w device_control
                device_control_update_device(device_id_str,
                                             type_str,
                                             port_str,
                                             status_str,
                                             cooldown_str,
                                             ledOn_str);
            }
            else
            {
                ESP_LOGW(TAG, "Brak wymaganych pól w otrzymanym JSON (deviceId/status/port/type).");
            }

            cJSON_Delete(json);
        }
        break;
    }

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGI(TAG, "MQTT disconnected");
        mqtt_connected = false;
        break;
    case MQTT_EVENT_ERROR:
        ESP_LOGE(TAG, "MQTT event error");
        if (event->error_handle->error_type == MQTT_ERROR_TYPE_ESP_TLS)
        {
            ESP_LOGE(TAG, "TLS Error Code: 0x%x", event->error_handle->esp_tls_last_esp_err);
        }
        else if (event->error_handle->error_type == MQTT_ERROR_TYPE_CONNECTION_REFUSED)
        {
            ESP_LOGE(TAG, "Connection refused error: 0x%x", event->error_handle->connect_return_code);
        }
        else
        {
            ESP_LOGE(TAG, "Unknown error type: 0x%x", event->error_handle->error_type);
        }
        break;
    default:
        ESP_LOGI(TAG, "Other MQTT event id: %d", event->event_id);
        break;
    }
}

void mqtt_publish(const char *topic, const char *message)
{
    if (mqtt_connected)
    {
        ESP_LOGI(TAG, "Publishing message to topic: %s", topic);
        int msg_id = esp_mqtt_client_publish(client, topic, message, 0, 1, 0);
        if (msg_id != -1)
        {
            ESP_LOGI(TAG, "Wiadomość wysłana, msg_id=%d", msg_id);
        }
        else
        {
            ESP_LOGW(TAG, "Błąd przy wysyłaniu wiadomości");
        }
    }
    else
    {
        ESP_LOGW(TAG, "Cannot publish, MQTT not connected");
    }
}

void mqtt_app_start(void)
{
    char clientId[64] = {0};
    char mqttPassword[64] = {0};

    if (load_mqtt_credentials(clientId, sizeof(clientId), mqttPassword, sizeof(mqttPassword)) != ESP_OK)
    {
        ESP_LOGW(TAG, "Brak zapisanych danych MQTT, używam domyślnych wartości");
        strcpy(clientId, "defaultClientId");
        strcpy(mqttPassword, "defaultPassword");
    }

    ESP_LOGI(TAG, "Inicjalizacja MQTT z clientId=%s", clientId);

    const esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = "mqtt://192.168.0.145",
        .broker.address.port = 2137,
        .credentials = {
            .username = clientId,
            .authentication.password = mqttPassword,
        },
        .session = {
            .keepalive = 60,
        },
    };

    device_control_init();
    client = esp_mqtt_client_init(&mqtt_cfg);
    ESP_LOGI(TAG, "MQTT client zainicjalizowany, rozpoczynam rejestrację zdarzeń");
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_err_t start_err = esp_mqtt_client_start(client);
    if (start_err == ESP_OK)
    {
        ESP_LOGI(TAG, "esp_mqtt_client_start() zwróciło ESP_OK");
    }
    else
    {
        ESP_LOGE(TAG, "esp_mqtt_client_start() zwróciło błąd: %d", start_err);
    }
}
