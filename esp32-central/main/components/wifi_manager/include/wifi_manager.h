#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <stddef.h>
#include "esp_err.h"
#include <stdbool.h>

void wifi_manager_init(void);

void save_wifi_credentials(const char *ssid, const char *password);

esp_err_t load_wifi_credentials(char *ssid, size_t ssid_size, char *password, size_t password_size);

bool wifi_manager_is_connected(void);

#endif // WIFI_MANAGER_H
