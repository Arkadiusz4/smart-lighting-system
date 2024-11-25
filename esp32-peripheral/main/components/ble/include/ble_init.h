#ifndef BLE_INIT_H
#define BLE_INIT_H

#include "esp_gap_ble_api.h"
#include "esp_err.h"

extern esp_ble_adv_params_t adv_params;

esp_err_t ble_init(void);

#endif // BLE_INIT_H
