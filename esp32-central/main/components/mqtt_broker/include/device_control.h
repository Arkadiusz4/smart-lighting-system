#ifndef DEVICE_CONTROL_H
#define DEVICE_CONTROL_H

#include <stdbool.h>

void device_control_init(void);
void device_control_set_led(int gpio_num, bool on);

/**
 * Główna funkcja do aktualizacji/konfiguracji urządzenia
 * (LED lub Sensor ruchu) na podstawie danych z JSON.
 */
void device_control_update_device(
    const char *deviceId,
    const char *type,
    const char *port_str,
    const char *status_str,
    const char *cooldown_time_str,
    const char *led_on_duration_str
);

#endif // DEVICE_CONTROL_H
