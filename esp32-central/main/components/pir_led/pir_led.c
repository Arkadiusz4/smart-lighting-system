#include <stdio.h>
#include "pir_led.h"
#include "esp_timer.h"
#include "oled_display.h"

volatile int motion_detected = 0;

static void IRAM_ATTR

pir_isr_handler(void *arg) {
    motion_detected = 1;
}

void pir_led_init(void) {
    gpio_config_t pir_config = {
            .pin_bit_mask = (1ULL << PIR_SENSOR_PIN),
            .mode = GPIO_MODE_INPUT,
            .pull_up_en = GPIO_PULLUP_DISABLE,
            .pull_down_en = GPIO_PULLDOWN_DISABLE,
            .intr_type = GPIO_INTR_POSEDGE
    };
    gpio_config(&pir_config);

    gpio_config_t led_config = {
            .pin_bit_mask = (1ULL << LED_PIN),
            .mode = GPIO_MODE_OUTPUT,
            .pull_up_en = GPIO_PULLUP_DISABLE,
            .pull_down_en = GPIO_PULLDOWN_DISABLE,
            .intr_type = GPIO_INTR_DISABLE
    };
    gpio_config(&led_config);

    gpio_install_isr_service(0);
    gpio_isr_handler_add(PIR_SENSOR_PIN, pir_isr_handler, NULL);


    if (oled_init() == ESP_OK) {
        oled_clear_display();
        printf("Wyświetlacz OLED zainicjalizowany.\n");
    } else {
        printf("Błąd inicjalizacji OLED.\n");
    }

    printf("Czekam na stabilizację czujnika PIR...\n");
    vTaskDelay(pdMS_TO_TICKS(30000));
    printf("Czujnik PIR gotowy do pracy.\n");
}

void pir_led_task(void *pvParameters) {
    int64_t last_motion_time = 0;

    while (1) {
        if (motion_detected) {
            printf("Ruch wykryty przez przerwanie!\n");

            oled_clear_display();
            oled_draw_text(0, 24, "Ruch wykryty!");
            oled_update_display();

            int64_t current_time = esp_timer_get_time() / 1000;
            if (current_time - last_motion_time > PIR_COOLDOWN_TIME) {
                last_motion_time = current_time;

                gpio_set_level(LED_PIN, 1);
                vTaskDelay(pdMS_TO_TICKS(LED_ON_DURATION));
                gpio_set_level(LED_PIN, 0);
            }

            vTaskDelay(pdMS_TO_TICKS(3000));
            oled_clear_display();
            oled_update_display();

            motion_detected = 0;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}
