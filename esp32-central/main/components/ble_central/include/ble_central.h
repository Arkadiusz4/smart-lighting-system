#ifndef BLE_CENTRAL_H
#define BLE_CENTRAL_H

#include "esp_err.h"

esp_err_t ble_central_init(void);

esp_err_t ble_central_write_led(const char *cmd);

#endif // BLE_CENTRAL_H
