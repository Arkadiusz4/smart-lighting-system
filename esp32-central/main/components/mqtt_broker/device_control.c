#include "device_control.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include <string.h>
#include <stdlib.h>

static const char *TAG = "DEVICE_CONTROL";

static int parse_gpio_string(const char *gpio_str) {
    if (strncmp(gpio_str, "GPIO", 4) == 0) {
        return atoi(gpio_str + 4);
    }
    return -1;
}

void device_control_init(void) {
    ESP_LOGI(TAG, "Device control init complete");
}

void device_control_set_led(int gpio_num, bool on) {
    gpio_reset_pin(gpio_num);
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT);

    gpio_set_level(gpio_num, on ? 1 : 0);

    ESP_LOGI(TAG, "LED on GPIO=%d, set to: %s", gpio_num, on ? "ON" : "OFF");
}
