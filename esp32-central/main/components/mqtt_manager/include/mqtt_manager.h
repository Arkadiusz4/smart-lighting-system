#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include "esp_err.h"

void save_mqtt_credentials(const char *clientId, const char *mqttPassword);

esp_err_t load_mqtt_credentials(char *clientId, size_t clientId_size,
                                char *mqttPassword, size_t mqttPassword_size);

#endif // MQTT_MANAGER_H
