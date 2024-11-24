// components/ble/ble_init.c

#include "ble_init.h"
#include <string.h>
#include <inttypes.h>
#include "esp_system.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_log.h"
#include "led_control.h"
#include "nvs_flash.h"
#include "esp_gatt_common_api.h"
#include "driver/temperature_sensor.h"

#define DEVICE_NAME "ESP32-C3-BLE"
#define GATTS_APP_ID 0

static const char *TAG = "BLE_INIT";

// UUIDs
#define GATTS_SERVICE_UUID_TEST   0x00FF
#define GATTS_CHAR_UUID_TEST_A    0xFF01
#define GATTS_NUM_HANDLE_TEST     4

static esp_ble_adv_params_t adv_params = {
    .adv_int_min       = 0x20,
    .adv_int_max       = 0x40,
    .adv_type          = ADV_TYPE_IND,
    .own_addr_type     = BLE_ADDR_TYPE_PUBLIC,
    .channel_map       = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

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

static temperature_sensor_handle_t temp_sensor_handle = NULL;

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event)
    {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "Advertising data set complete");
        // Start advertising after the advertising data is set
        esp_ble_gap_start_advertising(&adv_params);
        break;

    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGI(TAG, "Advertising started successfully");
        }
        else
        {
            ESP_LOGE(TAG, "Failed to start advertising, error code: %d", param->adv_start_cmpl.status);
        }
        break;

    default:
        ESP_LOGI(TAG, "GAP event: %d", event);
        break;
    }
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if,
                                esp_ble_gatts_cb_param_t *param)
{
    esp_err_t ret;
    switch (event)
    {
    case ESP_GATTS_REG_EVT:
        ESP_LOGI(TAG, "GATT server registered, app_id %d", param->reg.app_id);
        // Set the device name
        esp_ble_gap_set_device_name(DEVICE_NAME);

        // Configure the advertising data
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
            ESP_LOGE(TAG, "Failed to configure advertising data: %s", esp_err_to_name(ret));
        }

        // Create the service
        esp_ble_gatts_create_service(gatts_if, &service_id, GATTS_NUM_HANDLE_TEST);
        break;

    case ESP_GATTS_CREATE_EVT:
        ESP_LOGI(TAG, "Service created, status %d, service_handle %d", param->create.status, param->create.service_handle);
        service_handle = param->create.service_handle;

        // Add the characteristic
        ret = esp_ble_gatts_add_char(service_handle, &char_uuid,
                                     ESP_GATT_PERM_READ,
                                     ESP_GATT_CHAR_PROP_BIT_READ,
                                     NULL, NULL);
        if (ret) {
            ESP_LOGE(TAG, "Add characteristic failed, error code =%x", ret);
        }
        break;

    case ESP_GATTS_ADD_CHAR_EVT:
        ESP_LOGI(TAG, "Characteristic added, uuid %04x, handle %d", param->add_char.char_uuid.uuid.uuid16, param->add_char.attr_handle);
        char_handle = param->add_char.attr_handle;

        // Start the service
        esp_ble_gatts_start_service(service_handle);
        break;

    case ESP_GATTS_READ_EVT:
        ESP_LOGI(TAG, "ESP_GATTS_READ_EVT, conn_id %d, trans_id %" PRIu32 ", handle %d",
                 param->read.conn_id, param->read.trans_id, param->read.handle);
        {
            float temperature;
            ret = temperature_sensor_get_celsius(temp_sensor_handle, &temperature);
            if (ret != ESP_OK) {
                ESP_LOGE(TAG, "Failed to read temperature: %s", esp_err_to_name(ret));
                temperature = 0.0; // Default value in case of error
            }
            ESP_LOGI(TAG, "Read Temperature: %.2f ℃", temperature);

            // Convert the float temperature to an integer representation (e.g., multiply by 100)
            int16_t temp_value = (int16_t)(temperature * 100);

            // Store the temperature in a buffer in little-endian format
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
        }
        break;

    default:
        ESP_LOGI(TAG, "GATT event: %d", event);
        break;
    }
}

static void temperature_logging_task(void *arg)
{
    while (1)
    {
        float temperature;
        esp_err_t ret = temperature_sensor_get_celsius(temp_sensor_handle, &temperature);
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "Failed to read temperature: %s", esp_err_to_name(ret));
        } else {
            ESP_LOGI(TAG, "Temperature value: %.2f ℃", temperature);
        }
        vTaskDelay(pdMS_TO_TICKS(1000)); // Delay for 1 second
    }
}

esp_err_t ble_init(void)
{
    esp_err_t ret;

    // Initialize NVS
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize the temperature sensor
    ESP_LOGI(TAG, "Install temperature sensor, expected temp range: 10~50 ℃");
    temperature_sensor_handle_t temp_sensor = NULL;
    temperature_sensor_config_t temp_sensor_config = {
        .clk_src = TEMPERATURE_SENSOR_CLK_SRC_DEFAULT,
        .range_min = 10,  // Set the minimum temperature range
        .range_max = 50,  // Set the maximum temperature range
    };
    ret = temperature_sensor_install(&temp_sensor_config, &temp_sensor);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to install temperature sensor: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "Enable temperature sensor");
    ret = temperature_sensor_enable(temp_sensor);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to enable temperature sensor: %s", esp_err_to_name(ret));
        return ret;
    }

    temp_sensor_handle = temp_sensor;

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

    // Register the GAP callback function
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret)
    {
        ESP_LOGE(TAG, "GAP callback registration failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register the GATT server callback function
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

    // Start the temperature logging task
    xTaskCreate(temperature_logging_task, "Temperature_Logging_Task", 2048, NULL, 5, NULL);

    return ESP_OK;
}
