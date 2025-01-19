#include "mqtt_manager.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "esp_log.h"

static const char *TAG = "MQTT_MANAGER";

void save_mqtt_credentials(const char *clientId, const char *mqttPassword) {
    ESP_LOGI(TAG, "Zapisywanie danych MQTT: clientId=%s, mqttPassword=%s", clientId, mqttPassword);
    nvs_handle_t nvs_handle;
    ESP_ERROR_CHECK(nvs_open("mqtt_storage", NVS_READWRITE, &nvs_handle));

    ESP_ERROR_CHECK(nvs_set_str(nvs_handle, "clientId", clientId));
    ESP_ERROR_CHECK(nvs_set_str(nvs_handle, "mqttPassword", mqttPassword));

    ESP_ERROR_CHECK(nvs_commit(nvs_handle));
    nvs_close(nvs_handle);

    ESP_LOGI(TAG, "Dane MQTT zapisane w NVS");
}

esp_err_t load_mqtt_credentials(char *clientId, size_t clientId_size,
                                char *mqttPassword, size_t mqttPassword_size) {
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("mqtt_storage", NVS_READONLY, &nvs_handle);
    if (err != ESP_OK) {
        return err;
    }

    err = nvs_get_str(nvs_handle, "clientId", clientId, &clientId_size);
    if (err != ESP_OK) {
        nvs_close(nvs_handle);
        return err;
    }

    err = nvs_get_str(nvs_handle, "mqttPassword", mqttPassword, &mqttPassword_size);
    nvs_close(nvs_handle);

    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Wczytane dane MQTT: clientId=%s, mqttPassword=%s", clientId, mqttPassword);
    }

    return err;
}
