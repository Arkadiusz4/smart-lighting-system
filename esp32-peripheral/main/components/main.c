#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_log.h"

#define DEVICE_NAME "ESP32-C3-BLE"

static const char *TAG = "BLE_PERIPHERAL";

static uint8_t adv_service_uuid128[32] = {
    /* LSB <--------------------------------------------------------------------------------> MSB */
    // First UUID, 128-bit
    0xfb, 0x34, 0x9b, 0x5f, 0x80, 0x00, 0x00, 0x80,
    0x00, 0x10, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x12,
};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min        = 0x20,
    .adv_int_max        = 0x40,
    .adv_type           = ADV_TYPE_IND,
    .own_addr_type      = BLE_ADDR_TYPE_PUBLIC,
    .channel_map        = ADV_CHNL_ALL,
    .adv_filter_policy  = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event) {
    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        // Advertising start complete event
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising started successfully");
        } else {
            ESP_LOGE(TAG, "Failed to start advertising, error code: %d", param->adv_start_cmpl.status);
        }
        break;
    case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
        // Advertising stop complete event
        if (param->adv_stop_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising stopped successfully");
        } else {
            ESP_LOGE(TAG, "Failed to stop advertising, error code: %d", param->adv_stop_cmpl.status);
        }
        break;
    default:
        break;
    }
}

void app_main(void)
{
    esp_err_t ret;

    // Initialize the ESP BT controller
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "Bluetooth controller initialization failed: %s", esp_err_to_name(ret));
        return;
    }

    // Enable the BT controller in BLE mode
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "Bluetooth controller enable failed: %s", esp_err_to_name(ret));
        return;
    }

    // Initialize Bluedroid stack
    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "Bluedroid stack initialization failed: %s", esp_err_to_name(ret));
        return;
    }

    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "Bluedroid stack enable failed: %s", esp_err_to_name(ret));
        return;
    }

    // Register GAP callback function
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret){
        ESP_LOGE(TAG, "GAP callback registration failed: %s", esp_err_to_name(ret));
        return;
    }

    // Set device name
    esp_ble_gap_set_device_name(DEVICE_NAME);

    // Configure advertising data
    esp_ble_adv_data_t adv_data = {
        .set_scan_rsp        = false,
        .include_name        = true,
        .include_txpower     = true,
        .min_interval        = 0x0006,  // 7.5ms
        .max_interval        = 0x0010,  // 20ms
        .appearance          = 0x00,
        .manufacturer_len    = 0,       // No manufacturer data
        .p_manufacturer_data = NULL,
        .service_data_len    = 0,
        .p_service_data      = NULL,
        .service_uuid_len    = sizeof(adv_service_uuid128),
        .p_service_uuid      = adv_service_uuid128,
        .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
    };

    esp_ble_gap_config_adv_data(&adv_data);

    // Start advertising
    ret = esp_ble_gap_start_advertising(&adv_params);
    if (ret){
        ESP_LOGE(TAG, "Failed to start advertising: %s", esp_err_to_name(ret));
        return;
    }
}
