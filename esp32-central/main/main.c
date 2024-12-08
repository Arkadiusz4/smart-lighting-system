#include <stdio.h>
#include <string.h>
#include "driver/i2c.h"
#include "esp_log.h"

// Adres wyświetlacza
#define OLED_ADDR 0x3C

// Piny I2C
#define I2C_MASTER_SCL_IO 41
#define I2C_MASTER_SDA_IO 35
#define I2C_MASTER_NUM I2C_NUM_0
#define I2C_MASTER_FREQ_HZ 400000
#define I2C_MASTER_TX_BUF_DISABLE 0
#define I2C_MASTER_RX_BUF_DISABLE 0

#define TAG "SH1106"

// RAM ekranu (128x64 = 1024 bajtów)
uint8_t oled_buffer[128 * 8] = {0};

// Prototypy funkcji
esp_err_t oled_init();
esp_err_t oled_send_command(uint8_t cmd);
esp_err_t oled_update_display();
void oled_draw_pixel(int x, int y);
void oled_draw_char(int x, int y, char c);
void oled_draw_text(int x, int y, const char *text);

// Tablica znaków (font 5x7)
static const uint8_t font5x7[96][5] = {
    // Kod ASCII od 32 do 127 (5 kolumn na znak)
    {0x00, 0x00, 0x00, 0x00, 0x00}, /* Spacja */
    {0x00, 0x00, 0x5F, 0x00, 0x00}, /* ! */
    // Dodaj więcej znaków lub znajdź gotowe fonty
    {0x7C, 0x54, 0x54, 0x54, 0x28}  /* A */
    // Dodaj znaki do kompletu...
};

// Wysyłanie komendy do OLED
esp_err_t oled_send_command(uint8_t cmd) {
    uint8_t data[2] = {0x00, cmd}; // Bajt kontrolny + komenda
    return i2c_master_write_to_device(I2C_MASTER_NUM, OLED_ADDR, data, sizeof(data), pdMS_TO_TICKS(100));
}

// Inicjalizacja OLED
esp_err_t oled_init() {
    uint8_t init_cmds[] = {
        0xAE, // Display Off
        0xD5, 0x80, // Clock divide ratio
        0xA8, 0x3F, // Multiplex ratio
        0xD3, 0x00, // Display offset
        0x40, // Start line
        0xA1, // Segment remap
        0xC8, // COM output scan direction
        0xDA, 0x12, // COM pins hardware config
        0x81, 0x7F, // Contrast control
        0xA4, // Resume RAM content display
        0xA6, // Normal display
        0xD9, 0xF1, // Precharge period
        0xDB, 0x40, // VCOMH deselect level
        0xAF  // Display ON
    };
    for (size_t i = 0; i < sizeof(init_cmds); i++) {
        ESP_ERROR_CHECK(oled_send_command(init_cmds[i]));
    }
    return ESP_OK;
}

// Aktualizacja wyświetlacza
esp_err_t oled_update_display() {
    for (uint8_t page = 0; page < 8; page++) {
        ESP_ERROR_CHECK(oled_send_command(0xB0 + page)); // Set page
        ESP_ERROR_CHECK(oled_send_command(0x00));        // Lower column start
        ESP_ERROR_CHECK(oled_send_command(0x10));        // Higher column start
        uint8_t buffer[129] = {0x40}; // Bajt kontrolny + dane RAM
        memcpy(&buffer[1], &oled_buffer[page * 128], 128);
        ESP_ERROR_CHECK(i2c_master_write_to_device(I2C_MASTER_NUM, OLED_ADDR, buffer, sizeof(buffer), pdMS_TO_TICKS(100)));
    }
    return ESP_OK;
}

// Rysowanie piksela
void oled_draw_pixel(int x, int y) {
    if (x >= 0 && x < 128 && y >= 0 && y < 64) {
        oled_buffer[x + (y / 8) * 128] |= (1 << (y % 8));
    }
}

// Rysowanie znaku 5x7
void oled_draw_char(int x, int y, char c) {
    if (c < 32 || c > 127) return; // Poza zakresem
    for (int i = 0; i < 5; i++) {
        uint8_t line = font5x7[c - 32][i];
        for (int j = 0; j < 8; j++) {
            if (line & (1 << j)) {
                oled_draw_pixel(x + i, y + j);
            }
        }
    }
}

// Rysowanie tekstu
void oled_draw_text(int x, int y, const char *text) {
    while (*text) {
        oled_draw_char(x, y, *text++);
        x += 6; // Odstęp między znakami
        if (x + 6 >= 128) break; // Koniec wiersza
    }
}

// Główna funkcja
void app_main(void) {
    // Inicjalizacja magistrali I2C
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = I2C_MASTER_FREQ_HZ,
    };
    ESP_ERROR_CHECK(i2c_param_config(I2C_MASTER_NUM, &conf));
    ESP_ERROR_CHECK(i2c_driver_install(I2C_MASTER_NUM, conf.mode, I2C_MASTER_RX_BUF_DISABLE, I2C_MASTER_TX_BUF_DISABLE, 0));

    ESP_LOGI(TAG, "I2C zainicjalizowane.");

    // Inicjalizacja OLED
    ESP_ERROR_CHECK(oled_init());

    // Rysowanie "Hello, World!"
    oled_draw_text(0, 0, "Hello,");
    oled_draw_text(0, 8, "World!");
    oled_update_display();
    ESP_LOGI(TAG, "Tekst wyświetlony.");

    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
