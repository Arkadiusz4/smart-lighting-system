// main/main.c

#include <stdio.h>
#include "esp_log.h"
#include "ble_init.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "driver/temperature_sensor.h"
static const char *TAG = "MAIN";

void app_main(void)
{
    esp_err_t ret;

    ret = ble_init();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "BLE initialization failed");
        return;
    }

    ESP_LOGI(TAG, "BLE initialized successfully");
}