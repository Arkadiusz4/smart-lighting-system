idf_component_register(
    SRCS "ble_init.c"
    INCLUDE_DIRS "include"
    REQUIRES led_control bt nvs_flash
)
