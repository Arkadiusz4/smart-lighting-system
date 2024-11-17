#include "wifi_manager.h"
#include "http_client.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_tls.h"
#include "mqtt_broker.h"

void http_request_task(void *pvParameters) {
    esp_tls_init_global_ca_store();
    http_client_get("https://example.com");
    esp_tls_free_global_ca_store();
    vTaskDelete(NULL);
}

void app_main(void) {
    wifi_manager_init();

    while (!wifi_manager_is_connected()) {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }

    xTaskCreate(&http_request_task, "http_request_task", 8192, NULL, 5, NULL);

    mqtt_app_start();

    mqtt_publish("user123/esp32_1/motion", "Motion detected");
}
