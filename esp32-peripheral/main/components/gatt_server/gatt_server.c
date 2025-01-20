#include "gatt_server.h"
#include "esp_log.h"
#include "esp_gatts_api.h"
#include "esp_gap_ble_api.h"
#include "esp_bt_defs.h"
#include <string.h>
#include "driver/gpio.h"

#define TAG "GATT_SERVER"
#define DEVICE_NAME "ESP32-C3-BLE"
#define GATTS_APP_ID 0

#define GATTS_SERVICE_UUID   0x00FF
#define GATTS_CHAR_UUID      0xFF01
#define GATTS_NUM_HANDLE     4

extern esp_ble_adv_params_t adv_params;

static uint16_t service_handle = 0;
static esp_gatt_srvc_id_t service_id = {
        .is_primary = true,
        .id.inst_id = 0x00,
        .id.uuid.len = ESP_UUID_LEN_16,
        .id.uuid.uuid.uuid16 = GATTS_SERVICE_UUID,
};

static uint16_t char_handle = 0;
static esp_bt_uuid_t char_uuid = {
        .len = ESP_UUID_LEN_16,
        .uuid = {.uuid16 = GATTS_CHAR_UUID},
};

#define LED_GPIO_PIN 6

static void gatts_event_handler(esp_gatts_cb_event_t event,
                                esp_gatt_if_t gatts_if,
                                esp_ble_gatts_cb_param_t *param);

static void init_led_gpio(void) {
    gpio_reset_pin(LED_GPIO_PIN);
    gpio_set_direction(LED_GPIO_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO_PIN, 0);
}

esp_err_t gatt_server_init(void) {
    esp_err_t ret;

    init_led_gpio();

    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "Rejestracja callback GATTS nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_ble_gatts_app_register(GATTS_APP_ID);
    if (ret) {
        ESP_LOGE(TAG, "Rejestracja aplikacji GATTS nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    return ESP_OK;
}

static void gatts_event_handler(esp_gatts_cb_event_t event,
                                esp_gatt_if_t gatts_if,
                                esp_ble_gatts_cb_param_t *param) {
    esp_err_t ret;

    switch (event) {

        case ESP_GATTS_REG_EVT: {
            ESP_LOGI(TAG, "Zarejestrowano GATT Server, app_id %d", param->reg.app_id);

            esp_ble_gap_set_device_name(DEVICE_NAME);

            esp_ble_adv_data_t adv_data = {
                    .set_scan_rsp = false,
                    .include_name = true,
                    .include_txpower = false,
                    .min_interval = 0x0006,
                    .max_interval = 0x0010,
                    .appearance   = 0x00,
                    .manufacturer_len = 0,
                    .p_manufacturer_data = NULL,
                    .service_data_len = 0,
                    .p_service_data = NULL,
                    .service_uuid_len = 0,
                    .p_service_uuid = NULL,
                    .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
            };
            ret = esp_ble_gap_config_adv_data(&adv_data);
            if (ret) {
                ESP_LOGE(TAG, "Konfiguracja danych reklamowych nie powiodła się: %s", esp_err_to_name(ret));
            }

            ret = esp_ble_gatts_create_service(gatts_if, &service_id, GATTS_NUM_HANDLE);
            if (ret) {
                ESP_LOGE(TAG, "Utworzenie serwisu nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;
        }
        case ESP_GATTS_CREATE_EVT: {
            ESP_LOGI(TAG, "Serwis utworzony, status %d, service_handle %d",
                     param->create.status, param->create.service_handle);
            service_handle = param->create.service_handle;

            ret = esp_ble_gatts_add_char(
                    service_handle,
                    &char_uuid,
                    ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
                    ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_WRITE,
                    NULL, NULL
            );
            if (ret) {
                ESP_LOGE(TAG, "Dodanie charakterystyki nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;
        }
        case ESP_GATTS_ADD_CHAR_EVT: {
            ESP_LOGI(TAG, "Charakterystyka dodana, uuid 0x%X, handle %d",
                     param->add_char.char_uuid.uuid.uuid16,
                     param->add_char.attr_handle);
            char_handle = param->add_char.attr_handle;

            ret = esp_ble_gatts_start_service(service_handle);
            if (ret) {
                ESP_LOGE(TAG, "Uruchomienie serwisu nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;
        }

        case ESP_GATTS_WRITE_EVT: {
            if (param->write.handle == char_handle && param->write.len > 0) {
                char data[32] = {0};
                int len = param->write.len;
                if (len >= (int) sizeof(data)) {
                    len = sizeof(data) - 1;
                }
                memcpy(data, param->write.value, len);
                data[len] = '\0';
                ESP_LOGI(TAG, "Wartosc zapisu: %s", data);

                if (strcasecmp(data, "on") == 0) {
                    gpio_set_level(LED_GPIO_PIN, 1);
                    ESP_LOGI(TAG, "LED ON na GPIO=%d", LED_GPIO_PIN);
                } else if (strcasecmp(data, "off") == 0) {
                    gpio_set_level(LED_GPIO_PIN, 0);
                    ESP_LOGI(TAG, "LED OFF na GPIO=%d", LED_GPIO_PIN);
                } else {
                    ESP_LOGW(TAG, "Nieznane polecenie: %s", data);
                }

                if (param->write.need_rsp) {
                    esp_gatt_rsp_t rsp;
                    memset(&rsp, 0, sizeof(rsp));
                    rsp.attr_value.handle = param->write.handle;
                    rsp.attr_value.len = 2;
                    rsp.attr_value.value[0] = 0x00;
                    rsp.attr_value.value[1] = 0x00;
                    esp_ble_gatts_send_response(gatts_if, param->write.conn_id,
                                                param->write.trans_id,
                                                ESP_GATT_OK, &rsp);
                }
            }
            break;
        }
        case ESP_GATTS_CONNECT_EVT:
            ESP_LOGI(TAG, "BLE polaczono, conn_id %d", param->connect.conn_id);
            break;
        case ESP_GATTS_DISCONNECT_EVT:
            ESP_LOGI(TAG, "BLE rozłączono, wznawiam reklamowanie");
            ret = esp_ble_gap_start_advertising(&adv_params);
            if (ret) {
                ESP_LOGE(TAG, "Nie udało się wznowić reklamowania: %s", esp_err_to_name(ret));
            }
            break;

        default:
            ESP_LOGI(TAG, "GATT event: %d", event);
            break;
    }
}
