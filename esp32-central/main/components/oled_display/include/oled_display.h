#ifndef OLED_DISPLAY_H
#define OLED_DISPLAY_H

#include "esp_err.h"
#include "driver/gpio.h"

esp_err_t oled_i2c_init(gpio_num_t sda_pin, gpio_num_t scl_pin);

esp_err_t oled_init();

esp_err_t oled_send_command(uint8_t cmd);

esp_err_t oled_update_display();

void oled_clear_display();

void oled_draw_pixel(int x, int y);

void oled_draw_char(int x, int y, char c);

void oled_draw_text(int x, int y, const char *text);

esp_err_t oled_set_contrast(uint8_t contrast);

esp_err_t oled_set_invert(bool invert);

void oled_draw_rect(int x, int y, int width, int height);

void oled_draw_line(int x1, int y1, int x2, int y2);

void oled_fill_rect(int x, int y, int width, int height);

esp_err_t oled_scroll_horizontal(bool direction, uint8_t start_page, uint8_t end_page);

void oled_scroll_text_programmatically(const char *text, int row, int delay_ms);

void oled_stop_scroll();

void oled_draw_circle(int x0, int y0, int radius);

void oled_write_buffer(const uint8_t *buffer, size_t size);

esp_err_t oled_display_on();

esp_err_t oled_display_off();

void oled_draw_bitmap(const uint8_t *bitmap, int x, int y, int width, int height);

void oled_demo();


#endif // OLED_DISPLAY_H
