// components/ble_central/ble_central.c

#include "ble_central.h"
#include <string.h>
#include <stdio.h>
#include <inttypes.h>
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "esp_bt_defs.h"
#include "esp_bt_device.h"
#include "nvs_flash.h"

#define TAG "BLE_CLIENT"

#define REMOTE_DEVICE_NAME "ESP32-C3-BLE"
#define PROFILE_NUM 1
#define PROFILE_APP_ID 0

// The UUIDs of the remote service and characteristic
#define REMOTE_SERVICE_UUID        0x00FF
#define REMOTE_CHAR_UUID           0xFF01

static bool connect = false;
static bool get_server = false;
static uint16_t remote_notify_char_handle = 0;
// Remove or comment out if unused
// static uint16_t descr_handle = 0;

static esp_ble_scan_params_t ble_scan_params = {
    .scan_type              = BLE_SCAN_TYPE_ACTIVE,
    .own_addr_type          = BLE_ADDR_TYPE_PUBLIC,
    .scan_filter_policy     = BLE_SCAN_FILTER_ALLOW_ALL,
    .scan_interval          = 0x50,
    .scan_window            = 0x30,
    .scan_duplicate         = BLE_SCAN_DUPLICATE_DISABLE
};

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);
static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param);

struct gattc_profile_inst {
    esp_gattc_cb_t gattc_cb;
    esp_gatt_if_t gattc_if;
    uint16_t app_id;
    uint16_t conn_id;
    uint16_t service_start_handle;
    uint16_t service_end_handle;
    esp_bd_addr_t remote_bda;
};

static struct gattc_profile_inst gl_profile_tab[PROFILE_NUM] = {
    [PROFILE_APP_ID] = {
        .gattc_cb = gattc_event_handler,
        .gattc_if = ESP_GATT_IF_NONE,
    },
};

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
        if (gl_profile_tab[PROFILE_APP_ID].service_start_handle != 0 && gl_profile_tab[PROFILE_APP_ID].service_end_handle != 0) {
            ESP_LOGI(TAG, "Searching for characteristic...");
            uint16_t count = 0;
            esp_gatt_status_t status = esp_ble_gattc_get_attr_count(gattc_if,
                                                                    gl_profile_tab[PROFILE_APP_ID].conn_id,
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
                                                            gl_profile_tab[PROFILE_APP_ID].conn_id,
                                                            gl_profile_tab[PROFILE_APP_ID].service_start_handle,
                                                            gl_profile_tab[PROFILE_APP_ID].service_end_handle,
                                                            char_uuid,
                                                            char_elem_result,
                                                            &count);
                    if (status != ESP_GATT_OK) {
                        ESP_LOGE(TAG, "esp_ble_gattc_get_char_by_uuid error");
                    }
                    if (count > 0 && char_elem_result != NULL) {
                        remote_notify_char_handle = char_elem_result[0].char_handle;
                        ESP_LOGI(TAG, "Characteristic found, handle: %d", remote_notify_char_handle);

                        // Proceed to read the characteristic
                        esp_ble_gattc_read_char(gattc_if,
                                                gl_profile_tab[PROFILE_APP_ID].conn_id,
                                                remote_notify_char_handle,
                                                ESP_GATT_AUTH_REQ_NONE);
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

        // Write to the characteristic
        uint8_t write_value = 0x55; // Example value
        esp_ble_gattc_write_char(gattc_if,
                                 gl_profile_tab[PROFILE_APP_ID].conn_id,
                                 remote_notify_char_handle,
                                 sizeof(write_value),
                                 &write_value,
                                 ESP_GATT_WRITE_TYPE_RSP,
                                 ESP_GATT_AUTH_REQ_NONE);
        break;
    case ESP_GATTC_WRITE_CHAR_EVT:
        if (param->write.status != ESP_GATT_OK) {
            ESP_LOGE(TAG, "Failed to write characteristic, error status = %d", param->write.status);
            break;
        }
        ESP_LOGI(TAG, "Characteristic written successfully");
        break;
    case ESP_GATTC_DISCONNECT_EVT:
        ESP_LOGI(TAG, "ESP_GATTC_DISCONNECT_EVT, reason = %d", param->disconnect.reason);
        connect = false;
        get_server = false;
        break;
    default:
        break;
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
    esp_err_t err;
    switch (event) {
    case ESP_GAP_BLE_SCAN_PARAM_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "Scan parameters set, starting scan");
        esp_ble_gap_start_scanning(30); // Scan for 30 seconds
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
                strncmp((char *)adv_name, REMOTE_DEVICE_NAME, adv_name_len) == 0) {
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
        break;
    }
}

esp_err_t ble_client_init(void) {
    esp_err_t ret;

    // Initialize NVS
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        // NVS partition was truncated and needs to be erased
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize the ESP BT controller
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "initialize controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Enable the controller
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "enable controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Initialize Bluedroid stack
    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "init bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Enable Bluedroid
    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "enable bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register GAP callback function FIRST
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "gap register error: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register the GATTC callback function
    ret = esp_ble_gattc_register_callback(gattc_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "gattc register error: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register the application profile
    ret = esp_ble_gattc_app_register(PROFILE_APP_ID);
    if (ret) {
        ESP_LOGE(TAG, "gattc app register error: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "BLE GATT client initialized.");
    return ESP_OK;
}
