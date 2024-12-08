#include <stdio.h>
#include "driver/i2c.h"
#include "esp_log.h"
#include "esp_system.h"

// Adres wyświetlacza (typowy dla SH1106)
#define OLED_ADDR 0x3C

// Piny I2C (dostosować do własnej płytki)
#define I2C_MASTER_SCL_IO 41
#define I2C_MASTER_SDA_IO 35
#define I2C_MASTER_NUM I2C_NUM_0
#define I2C_MASTER_FREQ_HZ 400000
#define I2C_MASTER_TX_BUF_DISABLE 0
#define I2C_MASTER_RX_BUF_DISABLE 0
#define TAG "SH1106"

// Funkcja pomocnicza do wysyłania komendy
esp_err_t sh1106_send_command(uint8_t cmd) {
    uint8_t buffer[2];
    buffer[0] = 0x00;  // Control byte wskazujący na komendę
    buffer[1] = cmd;
    return i2c_master_write_to_device(I2C_MASTER_NUM, OLED_ADDR, buffer, 2, pdMS_TO_TICKS(100));
}

// Funkcja pomocnicza do wysyłania wielu komend
esp_err_t sh1106_send_commands(const uint8_t *cmds, size_t len) {
    esp_err_t ret;
    for (size_t i = 0; i < len; i++) {
        ret = sh1106_send_command(cmds[i]);
        if (ret != ESP_OK) return ret;
    }
    return ESP_OK;
}

// Przykładowa inicjalizacja wyświetlacza (minimalna)
esp_err_t sh1106_init() {
    // Sekwencja inicjalizacji - minimalna, można ją rozszerzyć
    // Z dokumentacji: włączamy wyświetlacz, ustawiamy multiplex, offset, itd.
    // Poniższa sekwencja jest uproszczona i może wymagać dostosowania.
    
    uint8_t init_cmds[] = {
        0xAE, // Display Off
        0xD5, // Set display clock divide ratio/oscillator freq
        0x80, // Recomm. value
        0xA8, // Set multiplex ratio
        0x3F, // 1/64 duty (dla 128x64)
        0xD3, // Set display offset
        0x00, // No offset
        0x40, // Set start line at 0
        0x8D, // Charge pump setting (dla SH1106 może nie być potrzebne, zależy od modul)
        0x14, // Enable charge pump
        0x20, // Memory addressing mode
        0x00, // Horizontal addressing mode
        0xA1, // Set segment re-map 0 to 127
        0xC8, // Set COM output scan direction
        0xDA, // Set COM pins
        0x12,
        0x81, // Set contrast
        0x7F,
        0xD9, // Set pre-charge period
        0xF1,
        0xDB, // Set VCOMH deselect level
        0x40,
        0xA4, // Resume to RAM content display
        0xA6, // Normal display (not inverted)
        0xAF  // Display ON
    };

    return sh1106_send_commands(init_cmds, sizeof(init_cmds));
}

void app_main(void) {
    // Konfiguracja i inicjalizacja magistrali I2C w trybie master
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = I2C_MASTER_FREQ_HZ,
    };
    ESP_ERROR_CHECK(i2c_param_config(I2C_MASTER_NUM, &conf));
    ESP_ERROR_CHECK(i2c_driver_install(I2C_MASTER_NUM, conf.mode,
                                       I2C_MASTER_RX_BUF_DISABLE, 
                                       I2C_MASTER_TX_BUF_DISABLE, 0));
    ESP_LOGI(TAG, "I2C zainicjalizowane.");

    // Inicjalizacja wyświetlacza
    if (sh1106_init() == ESP_OK) {
        ESP_LOGI(TAG, "SH1106 zainicjalizowany pomyślnie.");
    } else {
        ESP_LOGE(TAG, "Błąd inicjalizacji SH1106.");
        while (1) { vTaskDelay(pdMS_TO_TICKS(1000)); }
    }

    // Teraz możemy wysłać prostą komendę, np. "All On" (0xA5) i po chwili "A4" (normal display),
    // aby zobaczyć efekt.
    ESP_ERROR_CHECK(sh1106_send_command(0xA5)); // Entire Display On
    ESP_LOGI(TAG, "Wszystkie piksele ON.");
    vTaskDelay(pdMS_TO_TICKS(2000));

    ESP_ERROR_CHECK(sh1106_send_command(0xA4)); // Return to displaying RAM content
    ESP_LOGI(TAG, "Powrót do normalnego trybu.");

    // Tutaj można zaimplementować własne funkcje rysujące piksele, linie, tekst
    // "Rysowanie" to nic innego jak wysłanie bajtów do pamięci RAM wyświetlacza.
    // Aby to zrobić, musisz wysłać bajt kontrolny 0x40 przed danymi obrazu.
    // Na przykład:
    // - Ustawienie kursora (page, column)
    // - Wysłanie danych do wyświetlacza.
    // W tym momencie najważniejsze jest, że potrafisz:
    // 1) Inicjalizować wyświetlacz
    // 2) Wysyłać komendy
    // 3) Odczytywać dokumentację i wysyłać odpowiednie dane

    // Przykładowe ustawienie pozycji i wysłanie kilku bajtów danych:
    // (Każdy bajt reprezentuje kolumnę 8 pikseli w trybie podstawowym)
    /*
    sh1106_send_command(0xB0); // Set page address = 0
    sh1106_send_command(0x00); // Set lower column start address
    sh1106_send_command(0x10); // Set higher column start address

    // Teraz wysłanie danych (np. 16 bajtów zapełnionych 0xFF)
    uint8_t data_buffer[17];
    data_buffer[0] = 0x40; // kontrolny bajt dla danych
    for (int i = 1; i < 17; i++) data_buffer[i] = 0xFF; 
    i2c_master_write_to_device(I2C_MASTER_NUM, OLED_ADDR, data_buffer, 17, pdMS_TO_TICKS(100));
    // Powinno to wyświetlić 16 kolumn pełnych pikseli w górnej linii wyświetlacza
    */

    // W pętli nic nie robimy, wyświetlacz pozostał w inicjalnym stanie:
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
