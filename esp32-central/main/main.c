#include <stdio.h>
#include "esp_log.h"
#include "ble_central.h"

void app_main(void) {
    esp_err_t ret;

    ret = ble_client_init();
    if (ret != ESP_OK) {
        ESP_LOGE("MAIN", "Failed to initialize BLE Client: %s", esp_err_to_name(ret));
        return;
    }

    ESP_LOGI("MAIN", "BLE Client initialized successfully.");
}