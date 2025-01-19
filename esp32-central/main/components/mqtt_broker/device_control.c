#include "device_control.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "string.h"
#include "stdlib.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_timer.h"

static const char *TAG = "DEVICE_CONTROL";

#define MAX_DEVICES 10

typedef struct {
    char deviceId[32];    
    char type[32];        // "LED" albo "Sensor ruchu"
    int gpio_num;         // numer GPIO np. 16
    bool status_on;       // on/off (dla LED lub sensor->włączony/wyłączony)
    int cooldownTime;     
    int ledOnDuration;    
    int64_t last_motion_time; 

    // Flaga informująca, że przerwanie wykryło ruch
    volatile bool motion_detected; 
} DeviceInfo;

static DeviceInfo devices[MAX_DEVICES];
static int num_devices = 0;

// Deklaracja tasku
static void sensor_task(void *param);

// Prototyp isr
static void IRAM_ATTR sensor_isr_handler(void *arg);

// Pomocnicza funkcja do "GPIO16" -> 16
static int parse_gpio_string(const char *gpio_str)
{
    if (strncmp(gpio_str, "GPIO", 4) == 0) {
        return atoi(gpio_str + 4);
    }
    return -1;
}

// Szuka urządzenia o zadanym deviceId
static DeviceInfo* find_or_create_device(const char *deviceId)
{
    // Sprawdź, czy już istnieje
    for (int i = 0; i < num_devices; i++){
        if (strcmp(devices[i].deviceId, deviceId) == 0){
            return &devices[i];
        }
    }
    // Jak nie ma, a jest miejsce, to utwórz nowy
    if (num_devices < MAX_DEVICES){
        DeviceInfo *dev = &devices[num_devices++];
        memset(dev, 0, sizeof(DeviceInfo));
        strncpy(dev->deviceId, deviceId, sizeof(dev->deviceId) - 1);
        dev->gpio_num = -1;
        dev->status_on = false;
        dev->cooldownTime = 0;
        dev->ledOnDuration = 0;
        dev->last_motion_time = 0;
        dev->motion_detected = false;
        return dev;
    }
    return NULL;
}

void device_control_init(void)
{
    ESP_LOGI(TAG, "Device control init complete");

    memset(devices, 0, sizeof(devices));
    num_devices = 0;

    // Zainstalowanie ISR service (dla przerwań GPIO)
    // (zwróć uwagę, że można wywołać tylko raz w całym programie)
    gpio_install_isr_service(0);

    // (Opcjonalnie) czekamy np. 30 s na stabilizację PIR
    // vTaskDelay(pdMS_TO_TICKS(30000));
    // ESP_LOGI(TAG, "Czujnik PIR powinien być gotowy...");

    // Uruchamiamy task do obsługi sensorów
    xTaskCreate(sensor_task, "sensor_task", 4096, NULL, 5, NULL);
}

void device_control_set_led(int gpio_num, bool on)
{
    gpio_reset_pin(gpio_num);
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT);
    gpio_set_level(gpio_num, on ? 1 : 0);

    ESP_LOGI(TAG, "LED on GPIO=%d, set to: %s", gpio_num, on ? "ON" : "OFF");
}

void device_control_update_device(
    const char *deviceId,
    const char *type,
    const char *port_str,
    const char *status_str,
    const char *cooldown_time_str,
    const char *led_on_duration_str)
{
    DeviceInfo *dev = find_or_create_device(deviceId);
    if(!dev){
        ESP_LOGW(TAG, "Brak miejsca w tablicy devices!");
        return;
    }

    strncpy(dev->type, type, sizeof(dev->type) - 1);
    dev->gpio_num = parse_gpio_string(port_str);
    dev->status_on = (strcmp(status_str, "on") == 0);

    // Wczytaj ewentualnie parametry
    if(strcmp(type, "Sensor ruchu") == 0){
        if(cooldown_time_str) {
            dev->cooldownTime = atoi(cooldown_time_str);
        }
        if(led_on_duration_str) {
            dev->ledOnDuration = atoi(led_on_duration_str);
        }
        ESP_LOGI(TAG, 
            "Zaktualizowano sensor: deviceId=%s, gpio=%d, status_on=%d, cooldown=%d, ledOnDur=%d",
            dev->deviceId, dev->gpio_num, dev->status_on,
            dev->cooldownTime, dev->ledOnDuration);

        // Konfiguracja pinu jako wejście z przerwaniem na zbocze narastające
        // Tylko jeśli sensor jest "on" - bo "off" = ignorujemy?
        if(dev->gpio_num >= 0 && dev->status_on){
            gpio_reset_pin(dev->gpio_num);

            gpio_config_t pir_config = {
                .pin_bit_mask = (1ULL << dev->gpio_num),
                .mode = GPIO_MODE_INPUT,
                .pull_up_en = GPIO_PULLUP_DISABLE,   // ewentualnie _ENABLE, w zależności od czujnika
                .pull_down_en = GPIO_PULLDOWN_DISABLE,
                .intr_type = GPIO_INTR_POSEDGE
            };
            gpio_config(&pir_config);

            // Dodajemy przerwanie
            // Jako argument przekazujemy wskaźnik do naszej struktury dev
            gpio_isr_handler_add(dev->gpio_num, sensor_isr_handler, (void*)dev);

            ESP_LOGI(TAG, "PIR pin %d zarejestrowany do przerwań POSEDGE", dev->gpio_num);
        }
        else {
            // Jeśli sensor jest off, to można usunąć przerwanie
            if(!dev->status_on && dev->gpio_num >= 0) {
                gpio_isr_handler_remove(dev->gpio_num);
                ESP_LOGI(TAG, "Sensor ruchu %s (GPIO=%d) wyłączony, przerwanie usunięte", dev->deviceId, dev->gpio_num);
            }
        }
    } 
    else if(strcmp(type, "LED") == 0){
        if(dev->gpio_num >= 0){
            device_control_set_led(dev->gpio_num, dev->status_on);
        }
    }
}

// ---- Obsługa przerwania: sensor_isr_handler ----

static void IRAM_ATTR sensor_isr_handler(void *arg)
{
    // Otrzymujemy wskaźnik do DeviceInfo
    DeviceInfo *sensor = (DeviceInfo*)arg;
    // Ustawiamy flagę motion_detected
    sensor->motion_detected = true;
}

// ---- Task sprawdzający flagi motion_detected ----

static void sensor_task(void *param)
{
    while(1) {
        // Przeglądamy wszystkie sensory
        for(int i = 0; i < num_devices; i++){
            DeviceInfo *sensor = &devices[i];
            if(strcmp(sensor->type, "Sensor ruchu") == 0 && sensor->status_on) {

                // Sprawdzamy, czy przerwanie coś zgłosiło
                if(sensor->motion_detected) {
                    ESP_LOGI(TAG, "Ruch wykryty przez sensor %s (GPIO=%d)!", sensor->deviceId, sensor->gpio_num);
                    sensor->motion_detected = false;  // kasujemy flagę

                    int64_t now = esp_timer_get_time() / 1000; // ms
                    if((now - sensor->last_motion_time) > sensor->cooldownTime){
                        sensor->last_motion_time = now;

                        // Sprawdzamy, czy wszystkie LED-y są off
                        bool all_off = true;
                        for(int j = 0; j < num_devices; j++){
                            if(strcmp(devices[j].type, "LED") == 0 && devices[j].status_on){
                                all_off = false;
                                break;
                            }
                        }

                        if(all_off) {
                            // Włączamy LED-y na ledOnDuration
                            ESP_LOGI(TAG, "Włączam LED-y na %d ms", sensor->ledOnDuration);
                            for(int j=0; j<num_devices; j++){
                                if(strcmp(devices[j].type, "LED") == 0){
                                    devices[j].status_on = true;
                                    if(devices[j].gpio_num >= 0){
                                        device_control_set_led(devices[j].gpio_num, true);
                                    }
                                }
                            }

                            vTaskDelay(pdMS_TO_TICKS(sensor->ledOnDuration));

                            // wyłączamy
                            for(int j=0; j<num_devices; j++){
                                if(strcmp(devices[j].type, "LED") == 0){
                                    devices[j].status_on = false;
                                    if(devices[j].gpio_num >= 0){
                                        device_control_set_led(devices[j].gpio_num, false);
                                    }
                                }
                            }
                        }
                        else {
                            ESP_LOGI(TAG, "Jakiś LED jest ON, wyłączam sensor");
                        }
                        // ewentualne mqtt_publish(...) że ruch wykryto
                    }
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}
