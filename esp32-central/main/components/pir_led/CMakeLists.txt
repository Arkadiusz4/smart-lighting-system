idf_component_register(
        SRCS "pir_led.c"
        INCLUDE_DIRS "include"
        REQUIRES driver esp_timer oled_display
)
