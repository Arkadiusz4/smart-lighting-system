#ifndef TEMPERATURE_H
#define TEMPERATURE_H

#include <stdint.h>
#include "esp_gattc_api.h"

void temperature_init(void);

void handle_temperature_data(uint8_t *data, uint16_t length);

#endif // TEMPERATURE_H
