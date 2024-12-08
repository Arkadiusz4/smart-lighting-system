#include <stdio.h>
#include <string.h>
#include "driver/i2c.h"
#include "esp_log.h"
#include "oled_display.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void)
{
    ESP_ERROR_CHECK(oled_i2c_init(GPIO_NUM_35, GPIO_NUM_41));
    oled_init();

    oled_demo();

    while (1)
    {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}