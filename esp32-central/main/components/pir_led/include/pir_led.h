#ifndef PIR_LED_H
#define PIR_LED_H

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"

#define PIR_SENSOR_PIN GPIO_NUM_16
#define LED_PIN GPIO_NUM_5

#define LED_ON_DURATION 1500
#define PIR_COOLDOWN_TIME 3000

void pir_led_init(void);

void pir_led_task(void *pvParameters);

#endif // PIR_LED_H
