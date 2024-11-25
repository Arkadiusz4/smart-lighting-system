#include "temperature.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "gatt_client.h"
#include "mqtt_broker.h"

#define TAG "TEMPERATURE"

extern uint16_t char_handle_global;
extern bool connected;
extern esp_gatt_if_t gattc_if_global;
extern uint16_t conn_id_global;

static void periodic_read_task(void *arg) {
    while (1) {
        if (connected && char_handle_global != 0) {
            esp_err_t ret = esp_ble_gattc_read_char(gattc_if_global,
                                                    conn_id_global,
                                                    char_handle_global,
                                                    ESP_GATT_AUTH_REQ_NONE);
            if (ret != ESP_OK) {
                ESP_LOGE(TAG, "Failed to read characteristic: %s", esp_err_to_name(ret));
            }
        } else {
            ESP_LOGW(TAG, "Not connected or characteristic handle invalid");
        }
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

void handle_temperature_data(uint8_t *data, uint16_t length) {
    if (length == 2) {
        uint16_t temp_raw = data[0] | (data[1] << 8);
        float temperature = temp_raw / 100.0;
        ESP_LOGI(TAG, "Received temperature: %.2f ℃", temperature);

        char temp_str[16];
        snprintf(temp_str, sizeof(temp_str), "%.2f", temperature);

        mqtt_publish("user123/esp32_1/temperature", temp_str);
    } else {
        ESP_LOGE(TAG, "Unexpected value length: %d", length);
    }
}


void temperature_init(void) {
    xTaskCreate(periodic_read_task, "periodic_read_task", 4096, NULL, 5, NULL);
}
