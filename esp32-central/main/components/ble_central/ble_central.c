#include "ble_central.h"
#include "gatt_client.h"
#include "esp_log.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "nvs_flash.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_client.h"
#include "board_manager.h"

static esp_mqtt_client_handle_t mqtt_client = NULL;

#define TAG "BLE_CENTRAL"
#define PROFILE_APP_ID 0

#define REMOTE_SERVICE_UUID 0x00FF
#define REMOTE_CHAR_UUID 0xFF01
#define REMOTE_CHAR_UUID2 0xFF02

extern esp_gatt_if_t gattc_if_global;
extern uint16_t conn_id_global;
extern bool manual_disconnect;

static bool connect = false;
static bool get_server = false;
uint16_t char_handle_global = 0;
static uint16_t char_handle_sensor = 0;

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);

static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param);

static esp_ble_scan_params_t ble_scan_params = {
        .scan_type = BLE_SCAN_TYPE_ACTIVE,
        .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
        .scan_filter_policy = BLE_SCAN_FILTER_ALLOW_ALL,
        .scan_interval = 0x50,
        .scan_window = 0x30,
        .scan_duplicate = BLE_SCAN_DUPLICATE_DISABLE};

static char *bda2str(esp_bd_addr_t bda, char *str, size_t size) {
    if (size < 18) {
        return NULL;
    }
    snprintf(str, size, "%02X:%02X:%02X:%02X:%02X:%02X",
             bda[0], bda[1], bda[2], bda[3], bda[4], bda[5]);
    return str;
}

esp_err_t ble_central_write_led(const char *cmd) {
    if (!connected) {
        ESP_LOGW(TAG, "Not connected");
        return ESP_FAIL;
    }
    if (!char_handle_global) {
        ESP_LOGW(TAG, "No char_handle found");
        return ESP_FAIL;
    }
    size_t cmd_len = strlen(cmd);
    if (cmd_len > 20)
        cmd_len = 20;
    esp_err_t err = esp_ble_gattc_write_char(
            gattc_if_global,
            conn_id_global,
            char_handle_global,
            cmd_len,
            (uint8_t *) cmd,
            ESP_GATT_WRITE_TYPE_RSP,
            ESP_GATT_AUTH_REQ_NONE);
    ESP_LOGI(TAG, "Write LED: %s (err=%s)", cmd, esp_err_to_name(err));
    return err;
}

esp_err_t ble_central_write_darkness_sensor(const char *cmd) {
    if (!connected) {
        ESP_LOGW(TAG, "Not connected");
        return ESP_FAIL;
    }
    if (char_handle_sensor == 0) {
        ESP_LOGW(TAG, "No characteristic handle found for darkness sensor");
        return ESP_FAIL;
    }
    size_t cmd_len = strlen(cmd);
    if (cmd_len > 20)
        cmd_len = 20;
    esp_err_t err = esp_ble_gattc_write_char(
            gattc_if_global,
            conn_id_global,
            char_handle_sensor,
            cmd_len,
            (uint8_t *) cmd,
            ESP_GATT_WRITE_TYPE_RSP,
            ESP_GATT_AUTH_REQ_NONE);
    ESP_LOGI(TAG, "Write darkness sensor: %s (err=%s)", cmd, esp_err_to_name(err));
    return err;
}


static void led_toggle_task(void *pv) {
    while (1) {
        if (connected && char_handle_global) {
            ble_central_write_led("on");
            vTaskDelay(pdMS_TO_TICKS(5000));

            ble_central_write_led("off");
            vTaskDelay(pdMS_TO_TICKS(5000));
        } else {
            vTaskDelay(pdMS_TO_TICKS(2000));
        }
    }
}

void ble_central_start_toggle_task(void) {
    xTaskCreate(led_toggle_task, "led_toggle_task", 4096, NULL, 5, NULL);
}

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
                ESP_LOGI(TAG, "Searching for characteristics...");
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
                        esp_bt_uuid_t uuid_led, uuid_sensor;
                        uuid_led.len = ESP_UUID_LEN_16;
                        uuid_led.uuid.uuid16 = REMOTE_CHAR_UUID;

                        uuid_sensor.len = ESP_UUID_LEN_16;
                        uuid_sensor.uuid.uuid16 = REMOTE_CHAR_UUID2;

                        status = esp_ble_gattc_get_char_by_uuid(gattc_if,
                                                                conn_id_global,
                                                                gl_profile_tab[PROFILE_APP_ID].service_start_handle,
                                                                gl_profile_tab[PROFILE_APP_ID].service_end_handle,
                                                                uuid_led,
                                                                char_elem_result,
                                                                &count);
                        if (status == ESP_GATT_OK && count > 0 && char_elem_result != NULL) {
                            char_handle_global = char_elem_result[0].char_handle;
                            ESP_LOGI(TAG, "LED Characteristic found, handle: %d", char_handle_global);
                        } else {
                            ESP_LOGE(TAG, "LED Characteristic not found");
                        }

                        status = esp_ble_gattc_get_char_by_uuid(gattc_if,
                                                                conn_id_global,
                                                                gl_profile_tab[PROFILE_APP_ID].service_start_handle,
                                                                gl_profile_tab[PROFILE_APP_ID].service_end_handle,
                                                                uuid_sensor,
                                                                char_elem_result,
                                                                &count);
                        if (status == ESP_GATT_OK && count > 0 && char_elem_result != NULL) {
                            char_handle_sensor = char_elem_result[0].char_handle;
                            ESP_LOGI(TAG, "Darkness Sensor Characteristic found, handle: %d", char_handle_sensor);
                        } else {
                            ESP_LOGE(TAG, "Darkness Sensor Characteristic not found");
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

            break;
        case ESP_GATTC_DISCONNECT_EVT:
            ESP_LOGI(TAG, "ESP_GATTC_DISCONNECT_EVT, reason = %d", param->disconnect.reason);
            connect = false;
            get_server = false;
            connected = false;

            if (!manual_disconnect) {
                esp_err_t ret = esp_ble_gap_set_scan_params(&ble_scan_params);
                if (ret != ESP_OK) {
                    ESP_LOGE(TAG, "Failed to set scan parameters: %s", esp_err_to_name(ret));
                }
                ESP_LOGI(TAG, "Disconnected, restarting scan");
                ret = esp_ble_gap_start_scanning(60);
                if (ret != ESP_OK) {
                    ESP_LOGE(TAG, "Failed to start scanning: %s", esp_err_to_name(ret));
                }
            } else {
                ESP_LOGI(TAG, "Manual disconnect – not restarting scan.");
                manual_disconnect = false;
            }
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

                    char bda_str[18];
                    bda2str(scan_result->scan_rst.bda, bda_str, sizeof(bda_str));
                    if (adv_name != NULL) {
                        ESP_LOGI(TAG, "Device found: %.*s, Addr: %s, RSSI: %d", adv_name_len, adv_name, bda_str,
                                 scan_result->scan_rst.rssi);
                    } else {
                        ESP_LOGI(TAG, "Device found: <unknown>, Addr: %s, RSSI: %d", bda_str,
                                 scan_result->scan_rst.rssi);
                    }

                    if (adv_name != NULL && strlen(remote_device_name) == adv_name_len &&
                        strncmp((char *) adv_name, remote_device_name, adv_name_len) == 0) {
                        ESP_LOGI(TAG, "Found target device: %s", remote_device_name);
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
