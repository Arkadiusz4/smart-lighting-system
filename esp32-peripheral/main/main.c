#include "ble_init.h"
#include "esp_log.h"
#include "driver/adc.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "gatt_server.h"

#define LED_GPIO_PIN GPIO_NUM_6
#define PHOTORESISTOR_ADC_CHANNEL ADC1_CHANNEL_0
#define LIGHT_THRESHOLD 2000

extern bool ble_led_active;

static void init_gpio_adc(void) {
    adc1_config_width(ADC_WIDTH_BIT_12);
    adc1_config_channel_atten(PHOTORESISTOR_ADC_CHANNEL, ADC_ATTEN_DB_11);

    gpio_reset_pin(LED_GPIO_PIN);
    gpio_set_direction(LED_GPIO_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO_PIN, 0);
}

void app_main(void) {
    esp_err_t ret = ble_init();
    if (ret != ESP_OK) {
        ESP_LOGE("MAIN", "Inicjalizacja BLE nie powiodła się: %s", esp_err_to_name(ret));
        return;
    }

    init_gpio_adc();

    while (1) {
        if (!ble_led_active && photoresistor_enabled) {
            int light_value = adc1_get_raw(PHOTORESISTOR_ADC_CHANNEL);

            ESP_LOGI("MAIN", "Odczyt jasności: %d", light_value);

            if (light_value < LIGHT_THRESHOLD) {
                gpio_set_level(LED_GPIO_PIN, 1);
                ESP_LOGI("MAIN", "LED ON (ciemno)");
            } else {
                gpio_set_level(LED_GPIO_PIN, 0);
                ESP_LOGI("MAIN", "LED OFF (jasno)");
            }
        }

        vTaskDelay(pdMS_TO_TICKS(500));
    }
}
