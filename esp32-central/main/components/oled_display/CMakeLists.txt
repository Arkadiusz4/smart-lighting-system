idf_component_register(
        SRCS "oled_display.c" "font5x7_full.c"
        INCLUDE_DIRS "include"
        REQUIRES driver freertos
)