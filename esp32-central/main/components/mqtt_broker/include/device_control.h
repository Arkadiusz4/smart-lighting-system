#ifndef DEVICE_CONTROL_H
#define DEVICE_CONTROL_H

#include <stdbool.h>

void device_control_init(void);

void device_control_set_led(int gpio_num, bool on);

void device_control_remove_device(const char *deviceId);

void device_control_set_mqtt_client(void *client);

void device_control_update_device(
        const char *deviceId,
        const char *type,
        const char *port_str,
        const char *status_str,
        const char *cooldown_time_str,
        const char *led_on_duration_str
);

#endif // DEVICE_CONTROL_H
