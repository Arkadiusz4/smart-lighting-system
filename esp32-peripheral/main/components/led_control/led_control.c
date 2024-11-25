// components/led_control/led_control.c

#include "led_control.h"
#include "driver/rmt_tx.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

#define LED_GPIO GPIO_NUM_10  // WS2812 connected to GPIO10
#define RMT_CHANNEL RMT_CHANNEL_0
#define TAG "LED_CONTROL"

static rmt_channel_handle_t rmt_handle;
static rmt_encoder_handle_t led_encoder;

void led_setup(void) {
    // Configure RMT channel
    rmt_tx_channel_config_t config = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .gpio_num = LED_GPIO,
        .mem_block_symbols = 48,
        .resolution_hz = 1000000,  // 1us resolution
        .trans_queue_depth = 2,
    };
    
    esp_err_t err = rmt_new_tx_channel(&config, &rmt_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to create RMT channel: %s", esp_err_to_name(err));
        return;
    }

    ESP_ERROR_CHECK(rmt_enable(rmt_handle));

    // Configure encoder
    rmt_bytes_encoder_config_t encoder_config = {
        .bit0 = {
            .level0 = 1,
            .duration0 = 6,  // High level duration for bit '0'
            .level1 = 0,
            .duration1 = 10, // Low level duration for bit '0'
        },
        .bit1 = {
            .level0 = 1,
            .duration0 = 10, // High level duration for bit '1'
            .level1 = 0,
            .duration1 = 6,  // Low level duration for bit '1'
        },
        .flags.msb_first = true,
    };
    ESP_ERROR_CHECK(rmt_new_bytes_encoder(&encoder_config, &led_encoder));
}

void led_set_color(uint8_t red, uint8_t green, uint8_t blue) {
    uint8_t colors[3] = {green, red, blue};  // WS2812 uses GRB format
    rmt_transmit_config_t tx_config = {
        .loop_count = 0,
    };

    // Transmit color data via RMT
    ESP_ERROR_CHECK(rmt_transmit(rmt_handle, led_encoder, colors, sizeof(colors), &tx_config));
}

void led_blink(int times, int delay_ms) {
    for (int i = 0; i < times; i++) {
        led_set_state(true);
        vTaskDelay(pdMS_TO_TICKS(delay_ms));
        led_set_state(false);
        vTaskDelay(pdMS_TO_TICKS(delay_ms));
    }
}

void led_set_state(bool state) {
    if (state) {
        // Turn LED on (e.g., blue color)
        led_set_color(0, 0, 139);
    } else {
        // Turn LED off
        led_set_color(0, 0, 0);
    }
}
