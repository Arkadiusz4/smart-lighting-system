#include "ble_init.h"
#include "gatt_server.h"
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "nvs_flash.h"

#define TAG "BLE_INIT"
#define DEVICE_NAME "ESP32-C3-BLE"

static esp_ble_adv_params_t adv_params = {
        .adv_int_min       = 0x20,
        .adv_int_max       = 0x40,
        .adv_type          = ADV_TYPE_IND,
        .own_addr_type     = BLE_ADDR_TYPE_PUBLIC,
        .channel_map       = ADV_CHNL_ALL,
        .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);

esp_err_t ble_init(void) {
    esp_err_t ret;

    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "Inicjalizacja kontrolera BT nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "Włączenie kontrolera BT nie powiodło się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "Inicjalizacja Bluedroid nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "Włączenie Bluedroid nie powiodło się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "Rejestracja callback GAP nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = gatt_server_init();
    if (ret) {
        ESP_LOGE(TAG, "Inicjalizacja GATT Servera nie powiodła się: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "BLE zainicjalizowane pomyślnie.");
    return ESP_OK;
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
    esp_err_t ret;
    switch (event) {
        case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
            ESP_LOGI(TAG, "Dane reklamowe ustawione.");

            ret = esp_ble_gap_start_advertising(&adv_params);
            if (ret) {
                ESP_LOGE(TAG, "Nie udało się rozpocząć reklamowania: %s", esp_err_to_name(ret));
            }
            break;

        case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
            if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS) {
                ESP_LOGI(TAG, "Reklamowanie rozpoczęte pomyślnie.");
            } else {
                ESP_LOGE(TAG, "Nie udało się rozpocząć reklamowania, kod błędu: %d", param->adv_start_cmpl.status);
            }
            break;

        default:
            ESP_LOGI(TAG, "GAP zdarzenie: %d", event);
            break;
    }
}
