#include <stdio.h>
#include <string.h>
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "esp_bt_defs.h"
#include "nvs_flash.h"
#include "ble_central.h"

#define TAG "BLE_CENTRAL"


void app_main(void)
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

    ret = ble_central_init();
    if (ret != ESP_OK)
    {
        ESP_LOGE("MAIN", "Failed to initialize BLE Central: %s", esp_err_to_name(ret));
        return;
    }

    ESP_LOGI("MAIN", "BLE Central initialized successfully.");
}
