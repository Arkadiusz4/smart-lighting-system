#include "ble_init.h"
#include "gatt_server.h"
#include "temperature.h"
#include "esp_log.h"
#include "esp_gatts_api.h"
#include "esp_gap_ble_api.h"
#include "esp_bt_defs.h"
#include <string.h>

#define TAG "GATT_SERVER"
#define DEVICE_NAME "ESP32-C3-BLE"
#define GATTS_APP_ID 0

#define GATTS_SERVICE_UUID_TEST   0x00FF
#define GATTS_CHAR_UUID_TEST_A    0xFF01
#define GATTS_NUM_HANDLE_TEST     4

extern esp_ble_adv_params_t adv_params;

static uint16_t service_handle = 0;
static esp_gatt_srvc_id_t service_id = {
        .is_primary = true,
        .id.inst_id = 0x00,
        .id.uuid.len = ESP_UUID_LEN_16,
        .id.uuid.uuid.uuid16 = GATTS_SERVICE_UUID_TEST,
};

static uint16_t char_handle = 0;
static esp_bt_uuid_t char_uuid = {
        .len = ESP_UUID_LEN_16,
        .uuid = {.uuid16 = GATTS_CHAR_UUID_TEST_A},
};

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if,
                                esp_ble_gatts_cb_param_t *param);

esp_err_t gatt_server_init(void) {
    esp_err_t ret;

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

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if,
                                esp_ble_gatts_cb_param_t *param) {
    esp_err_t ret;
    switch (event) {
        case ESP_GATTS_REG_EVT:
            ESP_LOGI(TAG, "Zarejestrowano GATT Server, app_id %d", param->reg.app_id);

            esp_ble_gap_set_device_name(DEVICE_NAME);

            esp_ble_adv_data_t adv_data = {
                    .set_scan_rsp = false,
                    .include_name = true,
                    .include_txpower = false,
                    .min_interval = 0x0006,
                    .max_interval = 0x0010,
                    .appearance = 0x00,
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

            ret = esp_ble_gatts_create_service(gatts_if, &service_id, GATTS_NUM_HANDLE_TEST);
            if (ret) {
                ESP_LOGE(TAG, "Utworzenie serwisu nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;

        case ESP_GATTS_CREATE_EVT:
            ESP_LOGI(TAG, "Serwis utworzony, status %d, service_handle %d", param->create.status,
                     param->create.service_handle);
            service_handle = param->create.service_handle;

            ret = esp_ble_gatts_add_char(service_handle, &char_uuid,
                                         ESP_GATT_PERM_READ,
                                         ESP_GATT_CHAR_PROP_BIT_READ,
                                         NULL, NULL);
            if (ret) {
                ESP_LOGE(TAG, "Dodanie charakterystyki nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;

        case ESP_GATTS_ADD_CHAR_EVT:
            ESP_LOGI(TAG, "Charakterystyka dodana, uuid %04x, handle %d", param->add_char.char_uuid.uuid.uuid16,
                     param->add_char.attr_handle);
            char_handle = param->add_char.attr_handle;

            ret = esp_ble_gatts_start_service(service_handle);
            if (ret) {
                ESP_LOGE(TAG, "Uruchomienie serwisu nie powiodło się: %s", esp_err_to_name(ret));
            }
            break;

        case ESP_GATTS_READ_EVT:
            ESP_LOGI(TAG, "ESP_GATTS_READ_EVT, conn_id %d, trans_id %"
            PRIu32
            ", handle %d",
                    param->read.conn_id, param->read.trans_id, param->read.handle);

            float temperature = temperature_get_value();
            ESP_LOGI(TAG, "Odczytana temperatura: %.2f ℃", temperature);

            int16_t temp_value = (int16_t)(temperature * 100);

            uint8_t temp_buffer[2];
            temp_buffer[0] = temp_value & 0xFF;
            temp_buffer[1] = (temp_value >> 8) & 0xFF;

            esp_gatt_rsp_t rsp;
            memset(&rsp, 0, sizeof(esp_gatt_rsp_t));
            rsp.attr_value.handle = param->read.handle;
            rsp.attr_value.len = sizeof(temp_buffer);
            memcpy(rsp.attr_value.value, temp_buffer, sizeof(temp_buffer));

            esp_ble_gatts_send_response(gatts_if, param->read.conn_id, param->read.trans_id,
                                        ESP_GATT_OK, &rsp);
            break;

        case ESP_GATTS_CONNECT_EVT:
            ESP_LOGI(TAG, "Device connected, conn_id: %d", param->connect.conn_id);
            break;

        case ESP_GATTS_DISCONNECT_EVT:
            ESP_LOGI(TAG, "Device disconnected, restarting advertising");

            ret = esp_ble_gap_start_advertising(&adv_params);
            if (ret) {
                ESP_LOGE(TAG, "Failed to start advertising: %s", esp_err_to_name(ret));
            }
            break;

        default:
            ESP_LOGI(TAG, "GATT zdarzenie: %d", event);
            break;
    }
}
