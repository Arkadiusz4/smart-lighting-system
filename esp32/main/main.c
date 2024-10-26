#include "wifi_manager.h"
#include "http_client.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_tls.h"

void app_main(void) {
    wifi_manager_init();

    while (!wifi_manager_is_connected()) {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }

    esp_tls_init_global_ca_store();
    http_client_get("https://www.onet.pl");
    esp_tls_free_global_ca_store();
}
