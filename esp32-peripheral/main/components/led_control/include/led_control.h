// components/led_control/led_control.h

#ifndef LED_CONTROL_H
#define LED_CONTROL_H

#include <stdbool.h>
#include <stdint.h>

// Initialize the LED
void led_setup(void);

// Turn the LED on or off
void led_set_state(bool state);

// Blink the LED
void led_blink(int times, int delay_ms);

// Set the LED color (RGB)
void led_set_color(uint8_t red, uint8_t green, uint8_t blue);

#endif // LED_CONTROL_H
