#include "mqtt_broker.h"
#include <stddef.h>
#include "esp_event.h"
#include "gatt_client.h"
#include "mqtt_manager.h"
#include "device_control.h"
#include "esp_log.h"
#include "mqtt_client.h"
#include "cJSON.h"
#include "board_manager.h"
#include "ble_central.h"
#include "esp_gap_ble_api.h"
#include "nvs_flash.h"

#define TAG "MQTT_CLIENT"

static esp_mqtt_client_handle_t client;
static bool mqtt_connected = false;
extern bool manual_disconnect;

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t) event_data;
    esp_mqtt_client_handle_t client = event->client;

    switch ((esp_mqtt_event_id_t) event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT connected");
            mqtt_connected = true;
            {
                char network_topic[64];
                snprintf(network_topic, sizeof(network_topic), "boards/%s/network", s_board_id);
                mqtt_publish(network_topic, "connected");
            }
            {
                char subscribe_topic[64];
                snprintf(subscribe_topic, sizeof(subscribe_topic), "boards/%s/devices/+", s_board_id);
                esp_mqtt_client_subscribe(client, subscribe_topic, 1);
            }
            esp_mqtt_client_subscribe(client, "central/command/#", 1);

            break;

        case MQTT_EVENT_DATA: {
            ESP_LOGI(TAG, "MQTT_EVENT_DATA");

            char *incoming_topic = strndup(event->topic, event->topic_len);
            char *incoming_data = strndup(event->data, event->data_len);
            ESP_LOGI(TAG, "MQTT Data received on topic: %s, data: %s", incoming_topic, incoming_data);

            if (strncmp(incoming_topic, "central/command/scan", strlen("central/command/scan")) == 0) {
                strncpy(remote_device_name, incoming_data, sizeof(remote_device_name) - 1);
                remote_device_name[sizeof(remote_device_name) - 1] = '\0';
                ESP_LOGI(TAG, "Setting remote device name to: %s", remote_device_name);
                esp_ble_gap_start_scanning(30);
            } else if (strncmp(incoming_topic, "central/command/led_on", strlen("central/command/led_on")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'led_on' received");
                ble_central_write_led("on");
            } else if (strncmp(incoming_topic, "central/command/led_off", strlen("central/command/led_off")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'led_off' received");
                ble_central_write_led("off");
            } else if (strncmp(incoming_topic, "central/command/darkness_sensor_on",
                               strlen("central/command/darkness_sensor_on")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'darkness_sensor_on' received");
                ble_central_write_darkness_sensor("on");
            } else if (strncmp(incoming_topic, "central/command/darkness_sensor_off",
                               strlen("central/command/darkness_sensor_off")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'darkness_sensor_off' received");
                ble_central_write_darkness_sensor("off");
            } else if (strncmp(incoming_topic, "central/command/reset", strlen("central/command/reset")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'reset' received");
                esp_err_t err = nvs_flash_erase();
                if (err == ESP_OK) {
                    ESP_LOGI(TAG, "Flash erased, restarting...");
                    esp_restart();
                } else {
                    ESP_LOGE(TAG, "Failed to erase flash: %s", esp_err_to_name(err));
                }
            } else if (strncmp(incoming_topic, "central/command/peripheral_disconnect",
                               strlen("central/command/peripheral_disconnect")) == 0) {
                ESP_LOGI(TAG, "MQTT command 'peripheral_disconnect' received");
                manual_disconnect = true;

                if (connected) {
                    esp_ble_gattc_close(gattc_if_global, conn_id_global);
                    ESP_LOGI(TAG, "Disconnected from peripheral");
                }
            }

            free(incoming_topic);
            free(incoming_data);

            char *topic = strndup(event->topic, event->topic_len);
            char *payload_str = strndup(event->data, event->data_len);
            ESP_LOGI(TAG, "Odebrano na temat: %s, dane: %s", topic, payload_str);

            if (strncmp(topic, "central/command/scan", strlen("central/command/scan")) == 0) {
                free(topic);
                free(payload_str);
                break;
            }
            if (strncmp(topic, "central/command/led_on", strlen("central/command/led_on")) == 0) {
                free(topic);
                free(payload_str);
                break;
            }
            if (strncmp(topic, "central/command/led_off", strlen("central/command/led_off")) == 0) {
                free(topic);
                free(payload_str);
                break;
            }

            cJSON *json = cJSON_Parse(payload_str);
            if (json == NULL) {
                ESP_LOGW(TAG, "Nie można sparsować JSON");
            } else {
                cJSON *status_item = cJSON_GetObjectItem(json, "status");
                cJSON *device_id_item = cJSON_GetObjectItem(json, "deviceId");
                if (cJSON_IsString(status_item) && cJSON_IsString(device_id_item) &&
                    strcmp(status_item->valuestring, "removed") == 0) {
                    device_control_remove_device(device_id_item->valuestring);
                    cJSON_Delete(json);
                    free(topic);
                    free(payload_str);
                    break;
                }

                cJSON *port_item = cJSON_GetObjectItem(json, "port");
                cJSON *type_item = cJSON_GetObjectItem(json, "type");
                cJSON *cooldown_item = cJSON_GetObjectItem(json, "pir_cooldown_time");
                cJSON *ledOn_item = cJSON_GetObjectItem(json, "led_on_duration");

                if (cJSON_IsString(device_id_item) &&
                    cJSON_IsString(status_item) &&
                    cJSON_IsString(port_item) &&
                    cJSON_IsString(type_item)) {
                    const char *device_id_str = device_id_item->valuestring;
                    const char *status_str = status_item->valuestring;
                    const char *port_str = port_item->valuestring;
                    const char *type_str = type_item->valuestring;
                    const char *cooldown_str = cJSON_IsString(cooldown_item) ? cooldown_item->valuestring : "0";
                    const char *ledOn_str = cJSON_IsString(ledOn_item) ? ledOn_item->valuestring : "0";

                    device_control_update_device(device_id_str,
                                                 type_str,
                                                 port_str,
                                                 status_str,
                                                 cooldown_str,
                                                 ledOn_str);
                } else {
                    ESP_LOGW(TAG, "Brak wymaganych pól w otrzymanym JSON (deviceId/status/port/type).");
                }

                cJSON_Delete(json);
            }
            free(topic);
            free(payload_str);
            break;
        }

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

void mqtt_publish(const char *topic, const char *message) {
    if (mqtt_connected) {
        ESP_LOGI(TAG, "Publishing message to topic: %s", topic);
        int msg_id = esp_mqtt_client_publish(client, topic, message, 0, 1, 0);
        if (msg_id != -1) {
            ESP_LOGI(TAG, "Wiadomość wysłana, msg_id=%d", msg_id);
        } else {
            ESP_LOGW(TAG, "Błąd przy wysyłaniu wiadomości");
        }
    } else {
        ESP_LOGW(TAG, "Cannot publish, MQTT not connected");
    }
}

static void heartbeat_task(void *param) {
    char topic[128];
    snprintf(topic, sizeof(topic), "boards/%s/heartbeat", s_board_id);

    while (1) {
        if (mqtt_connected && client != NULL) {
            char payload[] = "{\"status\":\"alive\"}";
            esp_mqtt_client_publish(client, topic, payload, 0, 1, 0);
            ESP_LOGI(TAG, "Heartbeat sent: %s => %s", topic, payload);
        }
        vTaskDelay(pdMS_TO_TICKS(60000));
    }
}

void mqtt_app_start(void) {
    char clientId[64] = {0};
    char mqttPassword[64] = {0};

    if (load_mqtt_credentials(clientId, sizeof(clientId), mqttPassword, sizeof(mqttPassword)) != ESP_OK) {
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
    device_control_set_mqtt_client(client);

    ESP_LOGI(TAG, "MQTT client zainicjalizowany, rozpoczynam rejestrację zdarzeń");
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_err_t start_err = esp_mqtt_client_start(client);
    if (start_err == ESP_OK) {
        ESP_LOGI(TAG, "esp_mqtt_client_start() zwróciło ESP_OK");
    } else {
        ESP_LOGE(TAG, "esp_mqtt_client_start() zwróciło błąd: %d", start_err);
    }

    char board_id[32] = {0};
    load_board_id(board_id, sizeof(board_id));
    if (strlen(board_id) == 0) {
        ESP_LOGW(TAG, "Brak boardId w NVS, używam domyślnego.");
        strcpy(board_id, "defaultBoardId");
    }
    ESP_LOGI(TAG, "Używam boardId: %s", board_id);

    strncpy(s_board_id, board_id, sizeof(s_board_id) - 1);
    device_control_set_board_id(board_id);

    xTaskCreate(heartbeat_task, "heartbeat_task", 2048, (void *) board_id, 5, NULL);
}
