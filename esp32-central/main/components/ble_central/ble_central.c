#include "ble_central.h"
#include "gatt_client.h"
#include "temperature.h"
#include "esp_log.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "nvs_flash.h"
#include <string.h>

#define TAG "BLE_CENTRAL"
#define REMOTE_DEVICE_NAME "ESP32-C3-BLE"
#define PROFILE_APP_ID 0

#define REMOTE_SERVICE_UUID        0x00FF
#define REMOTE_CHAR_UUID           0xFF01

static bool connect = false;
static bool get_server = false;
uint16_t char_handle_global = 0;

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);

static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param);

static esp_ble_scan_params_t ble_scan_params = {
        .scan_type              = BLE_SCAN_TYPE_ACTIVE,
        .own_addr_type          = BLE_ADDR_TYPE_PUBLIC,
        .scan_filter_policy     = BLE_SCAN_FILTER_ALLOW_ALL,
        .scan_interval          = 0x50,
        .scan_window            = 0x30,
        .scan_duplicate         = BLE_SCAN_DUPLICATE_DISABLE
};

esp_err_t ble_central_init(void) {
    esp_err_t ret;

    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    ret = gatt_client_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "GATT Client initialization failed");
        return ret;
    }

    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "GAP register error: %s", esp_err_to_name(ret));
        return ret;
    }

    gl_profile_tab[PROFILE_APP_ID].gattc_cb = gattc_event_handler;

    gatt_client_register_callback();

    ESP_LOGI(TAG, "BLE Central initialized.");
    return ESP_OK;
}

static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param) {
    switch (event) {
        case ESP_GATTC_REG_EVT:
            ESP_LOGI(TAG, "ESP_GATTC_REG_EVT");
            gl_profile_tab[PROFILE_APP_ID].gattc_if = gattc_if;
            esp_ble_gap_set_scan_params(&ble_scan_params);
            break;
        case ESP_GATTC_CONNECT_EVT:
            ESP_LOGI(TAG, "ESP_GATTC_CONNECT_EVT conn_id %d, if %d", param->connect.conn_id, gattc_if);
            gl_profile_tab[PROFILE_APP_ID].conn_id = param->connect.conn_id;
            memcpy(gl_profile_tab[PROFILE_APP_ID].remote_bda, param->connect.remote_bda, sizeof(esp_bd_addr_t));

            gattc_if_global = gattc_if;
            conn_id_global = param->connect.conn_id;
            connected = true;

            esp_ble_gattc_search_service(gattc_if, param->connect.conn_id, NULL);
            break;
        case ESP_GATTC_OPEN_EVT:
            if (param->open.status == ESP_GATT_OK) {
                ESP_LOGI(TAG, "Connected to the device successfully");
                get_server = true;
            } else {
                ESP_LOGE(TAG, "Failed to connect, error status = %d", param->open.status);
                connect = false;
                get_server = false;
                connected = false;
            }
            break;
        case ESP_GATTC_SEARCH_RES_EVT:
            if (param->search_res.srvc_id.uuid.len == ESP_UUID_LEN_16 &&
                param->search_res.srvc_id.uuid.uuid.uuid16 == REMOTE_SERVICE_UUID) {
                ESP_LOGI(TAG, "Service found with UUID: 0x%04x", REMOTE_SERVICE_UUID);
                gl_profile_tab[PROFILE_APP_ID].service_start_handle = param->search_res.start_handle;
                gl_profile_tab[PROFILE_APP_ID].service_end_handle = param->search_res.end_handle;
            }
            break;
        case ESP_GATTC_SEARCH_CMPL_EVT:
            if (param->search_cmpl.status != ESP_GATT_OK) {
                ESP_LOGE(TAG, "Service discovery failed, error status = %d", param->search_cmpl.status);
                break;
            }
            if (gl_profile_tab[PROFILE_APP_ID].service_start_handle != 0 &&
                gl_profile_tab[PROFILE_APP_ID].service_end_handle != 0) {
                ESP_LOGI(TAG, "Searching for characteristic...");
                uint16_t count = 0;
                esp_gatt_status_t status = esp_ble_gattc_get_attr_count(gattc_if,
                                                                        conn_id_global,
                                                                        ESP_GATT_DB_CHARACTERISTIC,
                                                                        gl_profile_tab[PROFILE_APP_ID].service_start_handle,
                                                                        gl_profile_tab[PROFILE_APP_ID].service_end_handle,
                                                                        ESP_GATT_ILLEGAL_HANDLE,
                                                                        &count);
                if (status != ESP_GATT_OK) {
                    ESP_LOGE(TAG, "esp_ble_gattc_get_attr_count error");
                }
                if (count > 0) {
                    esp_gattc_char_elem_t *char_elem_result = malloc(sizeof(esp_gattc_char_elem_t) * count);
                    if (!char_elem_result) {
                        ESP_LOGE(TAG, "No memory to allocate char_elem_result");
                    } else {
                        esp_bt_uuid_t char_uuid;
                        char_uuid.len = ESP_UUID_LEN_16;
                        char_uuid.uuid.uuid16 = REMOTE_CHAR_UUID;
                        status = esp_ble_gattc_get_char_by_uuid(gattc_if,
                                                                conn_id_global,
                                                                gl_profile_tab[PROFILE_APP_ID].service_start_handle,
                                                                gl_profile_tab[PROFILE_APP_ID].service_end_handle,
                                                                char_uuid,
                                                                char_elem_result,
                                                                &count);
                        if (status != ESP_GATT_OK) {
                            ESP_LOGE(TAG, "esp_ble_gattc_get_char_by_uuid error");
                        }
                        if (count > 0 && char_elem_result != NULL) {
                            char_handle_global = char_elem_result[0].char_handle;
                            ESP_LOGI(TAG, "Characteristic found, handle: %d", char_handle_global);

                            temperature_init();
                        } else {
                            ESP_LOGE(TAG, "Characteristic not found");
                        }
                        free(char_elem_result);
                    }
                } else {
                    ESP_LOGE(TAG, "No characteristics found");
                }
            } else {
                ESP_LOGE(TAG, "Service not found");
            }
            break;
        case ESP_GATTC_READ_CHAR_EVT:
            if (param->read.status != ESP_GATT_OK) {
                ESP_LOGE(TAG, "Failed to read characteristic, error status = %d", param->read.status);
                break;
            }
            ESP_LOGI(TAG, "Characteristic value:");
            esp_log_buffer_hex(TAG, param->read.value, param->read.value_len);

            handle_temperature_data(param->read.value, param->read.value_len);
            break;
        case ESP_GATTC_DISCONNECT_EVT:
            ESP_LOGI(TAG, "ESP_GATTC_DISCONNECT_EVT, reason = %d", param->disconnect.reason);
            connect = false;
            get_server = false;
            connected = false;
            break;
        default:
            ESP_LOGI(TAG, "GATTC event: %d", event);
            break;
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
    esp_err_t err;
    switch (event) {
        case ESP_GAP_BLE_SCAN_PARAM_SET_COMPLETE_EVT:
            ESP_LOGI(TAG, "Scan parameters set, starting scan");
            esp_ble_gap_start_scanning(30);
            break;
        case ESP_GAP_BLE_SCAN_START_COMPLETE_EVT:
            if ((err = param->scan_start_cmpl.status) != ESP_BT_STATUS_SUCCESS) {
                ESP_LOGE(TAG, "Scan start failed, error status = %x", err);
            } else {
                ESP_LOGI(TAG, "Scan started successfully");
            }
            break;
        case ESP_GAP_BLE_SCAN_RESULT_EVT: {
            esp_ble_gap_cb_param_t *scan_result = param;
            switch (scan_result->scan_rst.search_evt) {
                case ESP_GAP_SEARCH_INQ_RES_EVT: {
                    uint8_t *adv_name = NULL;
                    uint8_t adv_name_len = 0;
                    adv_name = esp_ble_resolve_adv_data(scan_result->scan_rst.ble_adv,
                                                        ESP_BLE_AD_TYPE_NAME_CMPL, &adv_name_len);

                    if (adv_name != NULL && strlen(REMOTE_DEVICE_NAME) == adv_name_len &&
                        strncmp((char *) adv_name, REMOTE_DEVICE_NAME, adv_name_len) == 0) {
                        ESP_LOGI(TAG, "Found target device: %s", REMOTE_DEVICE_NAME);
                        if (!connect) {
                            connect = true;
                            ESP_LOGI(TAG, "Connecting to the device...");
                            esp_ble_gap_stop_scanning();
                            esp_ble_gattc_open(gl_profile_tab[PROFILE_APP_ID].gattc_if,
                                               scan_result->scan_rst.bda, scan_result->scan_rst.ble_addr_type, true);
                        }
                    }
                    break;
                }
                case ESP_GAP_SEARCH_INQ_CMPL_EVT:
                    ESP_LOGI(TAG, "Scan completed");
                    break;
                default:
                    break;
            }
            break;
        }
        case ESP_GAP_BLE_SCAN_STOP_COMPLETE_EVT:
            if ((err = param->scan_stop_cmpl.status) != ESP_BT_STATUS_SUCCESS) {
                ESP_LOGE(TAG, "Scan stop failed, error status = %x", err);
            } else {
                ESP_LOGI(TAG, "Scan stopped successfully");
            }
            break;
        default:
            ESP_LOGI(TAG, "GAP event: %d", event);
            break;
    }
}
