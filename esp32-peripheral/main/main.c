// main/main.c

#include <stdio.h>
#include "esp_log.h"
#include "ble_init.h"
#include "nvs_flash.h"

static const char *TAG = "MAIN";

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

    ret = ble_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "BLE initialization failed");
        return;
    }

    ESP_LOGI(TAG, "BLE initialized successfully");
}
