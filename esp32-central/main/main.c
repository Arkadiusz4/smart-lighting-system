#include <stdio.h>
#include <string.h>
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "esp_bt_defs.h"
#include "nvs_flash.h"

#define TAG "BLE_CENTRAL"

static esp_ble_scan_params_t ble_scan_params = {
    .scan_type = BLE_SCAN_TYPE_ACTIVE,
    .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .scan_filter_policy = BLE_SCAN_FILTER_ALLOW_ALL,
    .scan_interval = 0x50,
    .scan_window = 0x30};

#define REMOTE_DEVICE_NAME "ESP32-C3-BLE"
#define PROFILE_NUM 1
#define PROFILE_APP_ID 0

static bool connect = false;
static bool get_server = false;
static esp_bd_addr_t server_bda;

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);
static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param);

struct gattc_profile_inst
{
    esp_gattc_cb_t gattc_cb;
    esp_gatt_if_t gattc_if;
    uint16_t app_id;
    uint16_t conn_id;
    esp_bd_addr_t remote_bda;
};

static struct gattc_profile_inst gl_profile_tab[PROFILE_NUM] = {
    [PROFILE_APP_ID] = {
        .gattc_cb = gattc_event_handler,
        .gattc_if = ESP_GATT_IF_NONE,
    },
};

static void notify_event_handler(esp_ble_gattc_cb_param_t *p_data)
{
    // Handle notifications from the server
}

static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param)
{
    switch (event)
    {
    case ESP_GATTC_REG_EVT:
        ESP_LOGI(TAG, "ESP_GATTC_REG_EVT");
        // Assign the gattc_if to your profile instance
        gl_profile_tab[PROFILE_APP_ID].gattc_if = gattc_if;

        esp_ble_gap_set_scan_params(&ble_scan_params);
        break;
    case ESP_GATTC_CONNECT_EVT:
        ESP_LOGI(TAG, "ESP_GATTC_CONNECT_EVT conn_id %d, if %d", param->connect.conn_id, gattc_if);
        gl_profile_tab[PROFILE_APP_ID].conn_id = param->connect.conn_id;
        memcpy(gl_profile_tab[PROFILE_APP_ID].remote_bda, param->connect.remote_bda, sizeof(esp_bd_addr_t));
        break;
    case ESP_GATTC_OPEN_EVT:
        if (param->open.status == ESP_GATT_OK)
        {
            ESP_LOGI(TAG, "Connected to the device successfully");
            get_server = true;
        }
        else
        {
            ESP_LOGE(TAG, "Failed to connect, error status = %d", param->open.status);
            connect = false;
            get_server = false;
        }
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

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    esp_err_t err;
    switch (event)
    {
    case ESP_GAP_BLE_SCAN_PARAM_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "Scan parameters set, starting scan");
        esp_ble_gap_start_scanning(30); // Scan for 30 seconds
        break;
    case ESP_GAP_BLE_SCAN_START_COMPLETE_EVT:
        if ((err = param->scan_start_cmpl.status) != ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGE(TAG, "Scan start failed, error status = %x", err);
        }
        else
        {
            ESP_LOGI(TAG, "Scan started successfully");
        }
        break;
    case ESP_GAP_BLE_SCAN_RESULT_EVT:
    {
        esp_ble_gap_cb_param_t *scan_result = param;
        switch (scan_result->scan_rst.search_evt)
        {
        case ESP_GAP_SEARCH_INQ_RES_EVT:
            // Parse the advertising data
            uint8_t *adv_name = NULL;
            uint8_t adv_name_len = 0;
            adv_name = esp_ble_resolve_adv_data(scan_result->scan_rst.ble_adv,
                                                ESP_BLE_AD_TYPE_NAME_CMPL, &adv_name_len);

            if (adv_name != NULL)
            {
                if (strlen(REMOTE_DEVICE_NAME) == adv_name_len &&
                    strncmp((char *)adv_name, REMOTE_DEVICE_NAME, adv_name_len) == 0)
                {
                    ESP_LOGI(TAG, "Found target device: %s", REMOTE_DEVICE_NAME);
                    if (connect == false)
                    {
                        connect = true;
                        ESP_LOGI(TAG, "Connecting to the device...");
                        esp_ble_gap_stop_scanning();
                        esp_ble_gattc_open(gl_profile_tab[PROFILE_APP_ID].gattc_if,
                                           scan_result->scan_rst.bda, scan_result->scan_rst.ble_addr_type, true);
                    }
                }
            }
            break;
        case ESP_GAP_SEARCH_INQ_CMPL_EVT:
            ESP_LOGI(TAG, "Scan completed");
            break;
        default:
            break;
        }
        break;
    }
    case ESP_GAP_BLE_SCAN_STOP_COMPLETE_EVT:
        if ((err = param->scan_stop_cmpl.status) != ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGE(TAG, "Scan stop failed, error status = %x", err);
        }
        else
        {
            ESP_LOGI(TAG, "Scan stopped successfully");
        }
        break;
    default:
        break;
    }
}

void app_main()
{
    esp_err_t ret;

    // Initialize NVS
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        // NVS partition was truncated and needs to be erased
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize the ESP BT controller
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret)
    {
        ESP_LOGE(TAG, "%s initialize controller failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Enable the controller
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret)
    {
        ESP_LOGE(TAG, "%s enable controller failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Initialize Bluedroid stack
    ret = esp_bluedroid_init();
    if (ret)
    {
        ESP_LOGE(TAG, "%s init bluetooth failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Enable Bluedroid
    ret = esp_bluedroid_enable();
    if (ret)
    {
        ESP_LOGE(TAG, "%s enable bluetooth failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Register GAP callback function FIRST
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret)
    {
        ESP_LOGE(TAG, "gap register error, error code = %x", ret);
        return;
    }

    // Register the GATTC callback function
    ret = esp_ble_gattc_register_callback(gattc_event_handler);
    if (ret)
    {
        ESP_LOGE(TAG, "gattc register error, error code = %x", ret);
        return;
    }

    // Register the application profile
    ret = esp_ble_gattc_app_register(PROFILE_APP_ID);
    if (ret)
    {
        ESP_LOGE(TAG, "gattc app register error, error code = %x", ret);
        return;
    }

    ESP_LOGI(TAG, "BLE GATT client initialized.");
}
