#include "temperature.h"
#include "esp_log.h"
#include "driver/temperature_sensor.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define TAG "TEMPERATURE"

static temperature_sensor_handle_t temp_sensor_handle = NULL;
static float current_temperature = 0.0;

static void temperature_task(void *arg) {
    while (1) {
        esp_err_t ret = temperature_sensor_get_celsius(temp_sensor_handle, &current_temperature);
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "Nie udało się odczytać temperatury: %s", esp_err_to_name(ret));
        } else {
            ESP_LOGI(TAG, "Aktualna temperatura: %.2f ℃", current_temperature);
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

esp_err_t temperature_init(void) {
    esp_err_t ret;

    ESP_LOGI(TAG, "Instalacja czujnika temperatury, zakres: 10~50 ℃");
    temperature_sensor_config_t temp_sensor_config = {
            .clk_src = TEMPERATURE_SENSOR_CLK_SRC_DEFAULT,
            .range_min = 10,
            .range_max = 50,
    };

    ret = temperature_sensor_install(&temp_sensor_config, &temp_sensor_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Instalacja czujnika temperatury nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "Włączenie czujnika temperatury");
    ret = temperature_sensor_enable(temp_sensor_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Włączenie czujnika temperatury nie powiodło się: %s", esp_err_to_name(ret));
        return ret;
    }

    xTaskCreate(temperature_task, "temperature_task", 2048, NULL, 5, NULL);

    return ESP_OK;
}

float temperature_get_value(void) {
    return current_temperature;
}
