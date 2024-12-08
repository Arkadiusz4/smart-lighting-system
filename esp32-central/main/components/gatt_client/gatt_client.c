#include "gatt_client.h"
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "esp_bt_defs.h"
#include "esp_bt_device.h"
#include <string.h>

#define TAG "GATT_CLIENT"
#define PROFILE_NUM 1
#define PROFILE_APP_ID 0

esp_gatt_if_t gattc_if_global = 0;
uint16_t conn_id_global = 0;
bool connected = false;

static void gattc_event_handler(esp_gattc_cb_event_t event,
                                esp_gatt_if_t gattc_if,
                                esp_ble_gattc_cb_param_t *param);

gattc_profile_inst_t gl_profile_tab[PROFILE_NUM] = {
        [PROFILE_APP_ID] = {
                .gattc_cb = NULL,
                .gattc_if = ESP_GATT_IF_NONE,
        },
};

esp_err_t gatt_client_init(void) {
    esp_err_t ret;

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "Initialize controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "Enable controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "Init Bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "Enable Bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "GATT Client initialized successfully.");
    return ESP_OK;
}

void gatt_client_register_callback(void) {
    esp_err_t ret = esp_ble_gattc_register_callback(gl_profile_tab[PROFILE_APP_ID].gattc_cb);
    if (ret) {
        ESP_LOGE(TAG, "GATTC register error: %s", esp_err_to_name(ret));
        return;
    }

    ret = esp_ble_gattc_app_register(PROFILE_APP_ID);
    if (ret) {
        ESP_LOGE(TAG, "GATTC app register error: %s", esp_err_to_name(ret));
        return;
    }
}
