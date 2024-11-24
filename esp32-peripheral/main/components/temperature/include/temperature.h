#ifndef TEMPERATURE_H
#define TEMPERATURE_H

#include "esp_err.h"

esp_err_t temperature_init(void);

float temperature_get_value(void);

#endif // TEMPERATURE_H
