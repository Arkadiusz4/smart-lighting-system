#ifndef DEVICE_CONTROL_H
#define DEVICE_CONTROL_H

#include <stdbool.h>

void device_control_init(void);

void device_control_set_led(int gpio_num, bool on);

#endif // DEVICE_CONTROL_H
