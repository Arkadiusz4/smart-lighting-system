// components/ble/ble_init.c

#include "ble_init.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_log.h"
#include "led_control.h"

#define DEVICE_NAME "ESP32-C3-BLE"
#define GATTS_APP_ID 0

static const char *TAG = "BLE_INIT";

static uint8_t adv_service_uuid128[16] = {
    /* LSB <--------------------------------------------------------------------------------> MSB */
    // UUID, 128-bit
    0x12,
    0xEF,
    0xCD,
    0xAB,
    0x00,
    0x00,
    0x10,
    0x00,
    0x80,
    0x00,
    0x00,
    0x80,
    0x5F,
    0x9B,
    0x34,
    0xFB,
};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min = 0x20,
    .adv_int_max = 0x40,
    .adv_type = ADV_TYPE_IND,
    .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .channel_map = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

static TaskHandle_t led_blink_task_handle = NULL;

static void led_blink_task(void *arg)
{
    while (1)
    {
        led_set_state(true); // Turn LED on
        vTaskDelay(pdMS_TO_TICKS(500));
        led_set_state(false); // Turn LED off
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event)
    {
    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGI(TAG, "Advertising started successfully");
            // Start blinking LED if not connected
            if (led_blink_task_handle == NULL)
            {
                xTaskCreate(led_blink_task, "LED_Blink_Task", 2048, NULL, 5, &led_blink_task_handle);
            }
        }
        else
        {
            ESP_LOGE(TAG, "Failed to start advertising, error code: %d", param->adv_start_cmpl.status);
        }
        break;
    default:
        break;
    }
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    switch (event)
    {
    case ESP_GATTS_REG_EVT:
        ESP_LOGI(TAG, "GATT server registered, app_id %d", param->reg.app_id);
        break;
    case ESP_GATTS_CONNECT_EVT:
        ESP_LOGI(TAG, "Device connected");
        if (led_blink_task_handle != NULL)
        {
            ESP_LOGI(TAG, "inside if");
            vTaskDelete(led_blink_task_handle);
            led_blink_task_handle = NULL;
            ESP_LOGI(TAG, "after task");
        }
        ESP_LOGI(TAG, "after if");
        led_set_state(true);
        break;
    case ESP_GATTS_DISCONNECT_EVT:
        ESP_LOGI(TAG, "Device disconnected");
        // Turn off LED and restart blinking
        led_set_state(false);
        if (led_blink_task_handle == NULL)
        {
            xTaskCreate(led_blink_task, "LED_Blink_Task", 2048, NULL, 5, &led_blink_task_handle);
        }
        // Restart advertising
        esp_ble_gap_start_advertising(&adv_params);
        break;
    default:
        break;
    }
}

esp_err_t ble_init(void)
{
    esp_err_t ret;

    // Initialize the LED
    led_setup();

    // Initialize the ESP BT controller
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret)
    {
        ESP_LOGE(TAG, "Bluetooth controller initialization failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Enable the BT controller in BLE mode
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret)
    {
        ESP_LOGE(TAG, "Bluetooth controller enable failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Initialize Bluedroid stack
    ret = esp_bluedroid_init();
    if (ret)
    {
        ESP_LOGE(TAG, "Bluedroid stack initialization failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_enable();
    if (ret)
    {
        ESP_LOGE(TAG, "Bluedroid stack enable failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register GAP callback function
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret)
    {
        ESP_LOGE(TAG, "GAP callback registration failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register GATT server callback function
    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret)
    {
        ESP_LOGE(TAG, "GATT server callback registration failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register the application profile
    ret = esp_ble_gatts_app_register(GATTS_APP_ID);
    if (ret)
    {
        ESP_LOGE(TAG, "GATT app registration failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Set device name
    ret = esp_ble_gap_set_device_name(DEVICE_NAME);
    if (ret)
    {
        ESP_LOGE(TAG, "Failed to set device name: %s", esp_err_to_name(ret));
        return ret;
    }

    // Configure advertising data
    esp_ble_adv_data_t adv_data = {
        .set_scan_rsp = false,
        .include_name = true,
        .include_txpower = true,
        .min_interval = 0x0006,
        .max_interval = 0x0010,
        .appearance = 0x00,
        .manufacturer_len = 0,
        .p_manufacturer_data = NULL,
        .service_data_len = 0,
        .p_service_data = NULL,
        .service_uuid_len = sizeof(adv_service_uuid128),
        .p_service_uuid = adv_service_uuid128,
        .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
    };

    ret = esp_ble_gap_config_adv_data(&adv_data);
    if (ret)
    {
        ESP_LOGE(TAG, "Failed to configure advertising data: %s", esp_err_to_name(ret));
        return ret;
    }

    // Start advertising
    ret = esp_ble_gap_start_advertising(&adv_params);
    if (ret)
    {
        ESP_LOGE(TAG, "Failed to start advertising: %s", esp_err_to_name(ret));
        return ret;
    }

    // Start blinking LED
    if (led_blink_task_handle == NULL)
    {
        xTaskCreate(led_blink_task, "LED_Blink_Task", 2048, NULL, 5, &led_blink_task_handle);
    }

    return ESP_OK;
}
