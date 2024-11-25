#include "ble_central.h"
#include "wifi_manager.h"
#include "http_client.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_tls.h"
#include "mqtt_broker.h"
#include "esp_log.h"

void http_request_task(void *pvParameters) {
    esp_tls_init_global_ca_store();
    http_client_get("https://example.com");
    esp_tls_free_global_ca_store();
    vTaskDelete(NULL);
}

void app_main(void) {
    esp_err_t ret;

    wifi_manager_init();

    while (!wifi_manager_is_connected()) {
        ESP_LOGI("MAIN", "Czekam na połączenie Wi-Fi...");
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }

    mqtt_app_start();

    ret = ble_central_init();
    if (ret != ESP_OK) {
        ESP_LOGE("MAIN", "Failed to initialize BLE Central: %s", esp_err_to_name(ret));
        return;
    }
    ESP_LOGI("MAIN", "BLE Central initialized successfully.");

    xTaskCreate(&http_request_task, "http_request_task", 8192, NULL, 5, NULL);
}
