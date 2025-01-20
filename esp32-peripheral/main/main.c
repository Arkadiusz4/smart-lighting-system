#include "ble_init.h"
#include "esp_log.h"

void app_main(void) {
    esp_err_t ret = ble_init();
    if (ret != ESP_OK) {
        ESP_LOGE("MAIN", "Inicjalizacja BLE nie powiodła się: %s", esp_err_to_name(ret));
        return;
    }
    ESP_LOGI("MAIN", "Peripheral GATT gotowy. Oczekuje na zapisy: 'on'/'off'");
}
