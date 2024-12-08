#include "oled_display.h"
#include "font5x7_full.h"
#include "driver/i2c.h"
#include "esp_log.h"
#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define OLED_ADDR 0x3C
#define TAG "SH1106"

static uint8_t oled_buffer[128 * 8] = {0};

static gpio_num_t i2c_sda_pin = GPIO_NUM_NC;
static gpio_num_t i2c_scl_pin = GPIO_NUM_NC;

esp_err_t oled_i2c_init(gpio_num_t sda_pin, gpio_num_t scl_pin) {
    i2c_sda_pin = sda_pin;
    i2c_scl_pin = scl_pin;

    i2c_config_t conf = {
            .mode = I2C_MODE_MASTER,
            .sda_io_num = i2c_sda_pin,
            .scl_io_num = i2c_scl_pin,
            .sda_pullup_en = GPIO_PULLUP_ENABLE,
            .scl_pullup_en = GPIO_PULLUP_ENABLE,
            .master.clk_speed = 400000,
    };

    esp_err_t err;
    err = i2c_param_config(I2C_NUM_0, &conf);
    if (err != ESP_OK)
        return err;

    err = i2c_driver_install(I2C_NUM_0, conf.mode, 0, 0, 0);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "I2C zainicjalizowane. SDA=%d, SCL=%d", sda_pin, scl_pin);
    }

    return err;
}

esp_err_t oled_send_command(uint8_t cmd) {
    uint8_t data[2] = {0x00, cmd};
    return i2c_master_write_to_device(I2C_NUM_0, OLED_ADDR, data, 2, pdMS_TO_TICKS(100));
}

esp_err_t oled_init() {
    uint8_t init_cmds[] = {
            0xAE,       // Display Off
            0xD5, 0x80, // Clock divide ratio
            0xA8, 0x3F, // Multiplex ratio (64)
            0xD3, 0x00, // Display offset
            0x40,       // Start line at 0
            0xA1,       // Segment remap (flip horizontally)
            0xC8,       // COM output scan direction (flip vertically)
            0xDA, 0x12, // COM pins hardware config
            0x81, 0x7F, // Contrast control
            0xA4,       // Resume to RAM content
            0xA6,       // Normal display
            0xD9, 0xF1, // Precharge period
            0xDB, 0x40, // VCOMH deselect level
            0xAF        // Display ON
    };
    for (size_t i = 0; i < sizeof(init_cmds); i++) {
        esp_err_t err = oled_send_command(init_cmds[i]);
        if (err != ESP_OK) {
            return err;
        }
    }

    return ESP_OK;
}

esp_err_t oled_update_display() {
    for (uint8_t page = 0; page < 8; page++) {
        ESP_ERROR_CHECK(oled_send_command(0xB0 + page));
        ESP_ERROR_CHECK(oled_send_command(0x02)); // Lower column start (offset)
        ESP_ERROR_CHECK(oled_send_command(0x10)); // Higher column start

        uint8_t buffer[129];
        buffer[0] = 0x40; // Bajt kontrolny do danych
        memcpy(&buffer[1], &oled_buffer[page * 128], 128);
        ESP_ERROR_CHECK(i2c_master_write_to_device(I2C_NUM_0, OLED_ADDR, buffer, sizeof(buffer), pdMS_TO_TICKS(100)));
    }
    return ESP_OK;
}

void oled_clear_display() {
    memset(oled_buffer, 0, sizeof(oled_buffer));

    oled_update_display();

    ESP_LOGI(TAG, "Wyświetlacz wyczyszczony.");
}

void oled_draw_pixel(int x, int y) {
    if (x < 0 || x >= 128 || y < 0 || y >= 64)
        return;
    oled_buffer[x + (y / 8) * 128] |= (1 << (y % 8));
}

void oled_draw_char(int x, int y, char c) {
    if (c < 32 || c > 127)
        return;
    for (int i = 0; i < 5; i++) {
        uint8_t line = font5x7_full[c - 32][i];
        for (int j = 0; j < 8; j++) {
            if (line & (1 << j)) {
                oled_draw_pixel(x + i, y + j);
            }
        }
    }
}

void oled_draw_text(int x, int y, const char *text) {
    while (*text) {
        oled_draw_char(x, y, *text);
        x += 6;
        text++;
        if (x + 6 >= 128)
            break;
    }
}

esp_err_t oled_set_contrast(uint8_t contrast) {
    if (contrast > 0xFF) {
        return ESP_ERR_INVALID_ARG;
    }
    ESP_ERROR_CHECK(oled_send_command(0x81)); // Komenda "Set Contrast"
    ESP_ERROR_CHECK(oled_send_command(contrast));
    return ESP_OK;
}

esp_err_t oled_set_invert(bool invert) {
    return oled_send_command(invert ? 0xA7 : 0xA6); // 0xA7: Invert, 0xA6: Normal
}

void oled_draw_rect(int x, int y, int width, int height) {
    for (int i = 0; i < width; i++) {
        oled_draw_pixel(x + i, y);              // Górna krawędź
        oled_draw_pixel(x + i, y + height - 1); // Dolna krawędź
    }
    for (int i = 0; i < height; i++) {
        oled_draw_pixel(x, y + i);             // Lewa krawędź
        oled_draw_pixel(x + width - 1, y + i); // Prawa krawędź
    }
}

void oled_draw_line(int x1, int y1, int x2, int y2) {
    int dx = abs(x2 - x1), sx = x1 < x2 ? 1 : -1;
    int dy = -abs(y2 - y1), sy = y1 < y2 ? 1 : -1;
    int err = dx + dy, e2;

    while (true) {
        oled_draw_pixel(x1, y1);
        if (x1 == x2 && y1 == y2)
            break;
        e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x1 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y1 += sy;
        }
    }
}

void oled_fill_rect(int x, int y, int width, int height) {
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            oled_draw_pixel(x + i, y + j);
        }
    }
}

void oled_scroll_text_programmatically(const char *text, int row, int delay_ms) {
    size_t len = strlen(text);
    if (len == 0)
        return;

    for (int offset = 0; offset < len * 6; offset++) {
        oled_clear_display();

        // Przesuwamy tekst o `-offset`
        oled_draw_text(-offset, row, text);

        // Aktualizujemy wyświetlacz
        oled_update_display();

        // Opóźnienie
        vTaskDelay(pdMS_TO_TICKS(delay_ms));
    }
}

esp_err_t oled_scroll_horizontal(bool direction, uint8_t start_page, uint8_t end_page) {
    if (start_page > 7 || end_page > 7) {
        return ESP_ERR_INVALID_ARG;
    }
    ESP_ERROR_CHECK(oled_send_command(direction ? 0x27 : 0x26)); // 0x26: Right, 0x27: Left
    ESP_ERROR_CHECK(oled_send_command(0x00));                    // Dummy byte
    ESP_ERROR_CHECK(oled_send_command(start_page));
    ESP_ERROR_CHECK(oled_send_command(0x00)); // Frame interval
    ESP_ERROR_CHECK(oled_send_command(end_page));
    ESP_ERROR_CHECK(oled_send_command(0x00)); // Dummy byte
    ESP_ERROR_CHECK(oled_send_command(0xFF)); // Dummy byte
    ESP_ERROR_CHECK(oled_send_command(0x2F)); // Activate scroll
    return ESP_OK;
}

void oled_stop_scroll(void) {
    // Komenda do zatrzymania przewijania (SH1106/SSD1306)
    uint8_t stop_scroll_cmd = 0x2E; // Stop scroll command
    oled_send_command(stop_scroll_cmd);
    ESP_LOGI("OLED", "Przewijanie zatrzymane.");
}

void oled_draw_circle(int x0, int y0, int radius) {
    int x = radius, y = 0;
    int radiusError = 1 - x;

    while (x >= y) {
        oled_draw_pixel(x0 + x, y0 + y);
        oled_draw_pixel(x0 - x, y0 + y);
        oled_draw_pixel(x0 + x, y0 - y);
        oled_draw_pixel(x0 - x, y0 - y);
        oled_draw_pixel(x0 + y, y0 + x);
        oled_draw_pixel(x0 - y, y0 + x);
        oled_draw_pixel(x0 + y, y0 - x);
        oled_draw_pixel(x0 - y, y0 - x);
        y++;
        if (radiusError < 0) {
            radiusError += 2 * y + 1;
        } else {
            x--;
            radiusError += 2 * (y - x) + 1;
        }
    }
}

void oled_write_buffer(const uint8_t *buffer, size_t size) {
    if (size > sizeof(oled_buffer)) {
        size = sizeof(oled_buffer);
    }
    memcpy(oled_buffer, buffer, size);
}

esp_err_t oled_display_on() {
    return oled_send_command(0xAF); // Display ON
}

esp_err_t oled_display_off() {
    return oled_send_command(0xAE); // Display OFF
}

void oled_draw_bitmap(const uint8_t *bitmap, int x, int y, int width, int height) {
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            if (bitmap[j * width + i]) {
                oled_draw_pixel(x + i, y + j);
            }
        }
    }
}

void oled_demo(void) {
    ESP_LOGI("DEMO", "Rozpoczynanie demonstracji funkcji wyświetlacza...");

    // Wyczyść wyświetlacz na początek
    oled_clear_display();
    oled_update_display();
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Wyświetl podstawowy tekst
    oled_draw_text(0, 0, "Hello, World!");
    oled_draw_text(0, 8, "OLED Display");
    oled_draw_text(0, 16, "ESP32 Demo");
    oled_update_display();
    ESP_LOGI("DEMO", "Wyświetlono tekst.");
    vTaskDelay(pdMS_TO_TICKS(2000));

    // Test zmiany kontrastu
    for (int contrast = 0x00; contrast <= 0xFF; contrast += 0x40) {
        oled_set_contrast(contrast);
        vTaskDelay(pdMS_TO_TICKS(500));
    }
    oled_set_contrast(0x7F); // Przywrócenie domyślnego kontrastu
    ESP_LOGI("DEMO", "Zmieniono kontrast.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Inwersja kolorów
    oled_set_invert(true);
    oled_update_display();
    vTaskDelay(pdMS_TO_TICKS(1000));
    oled_set_invert(false);
    oled_update_display();
    ESP_LOGI("DEMO", "Przetestowano inwersję kolorów.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Rysowanie prostokąta
    oled_clear_display();
    oled_draw_rect(10, 10, 50, 30);
    oled_update_display();
    ESP_LOGI("DEMO", "Narysowano prostokąt.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Rysowanie wypełnionego prostokąta
    oled_clear_display();
    oled_fill_rect(20, 20, 40, 20);
    oled_update_display();
    ESP_LOGI("DEMO", "Narysowano wypełniony prostokąt.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Rysowanie linii
    oled_clear_display();
    oled_draw_line(0, 0, 127, 63);
    oled_draw_line(127, 0, 0, 63);
    oled_update_display();
    ESP_LOGI("DEMO", "Narysowano linie.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Rysowanie okręgu
    oled_clear_display();
    oled_draw_circle(64, 32, 20);
    oled_update_display();
    ESP_LOGI("DEMO", "Narysowano okrąg.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Przewijanie tekstu programowo
    oled_clear_display();
    oled_scroll_text_programmatically("Hello, this is a scrolling text demo using ESP32!", 0, 100);
    ESP_LOGI("DEMO", "Przewijanie tekstu programowe zakończone.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    // Wyświetlanie bitmapy
    oled_clear_display();
    const uint8_t smiley_bitmap[8] = {
            0b00111100, 0b01000010, 0b10100101, 0b10000001,
            0b10100101, 0b10011001, 0b01000010, 0b00111100}; // Prosty obrazek uśmiechu
    oled_draw_bitmap(smiley_bitmap, 56, 28, 8, 8);
    oled_update_display();
    ESP_LOGI("DEMO", "Wyświetlono bitmapę.");
    vTaskDelay(pdMS_TO_TICKS(2000));

    // Wyłączanie i włączanie wyświetlacza
    oled_display_off();
    vTaskDelay(pdMS_TO_TICKS(1000));
    oled_display_on();
    ESP_LOGI("DEMO", "Wyłączono i włączono wyświetlacz.");
    vTaskDelay(pdMS_TO_TICKS(1000));

    ESP_LOGI("DEMO", "Demonstracja funkcji zakończona.");
}
