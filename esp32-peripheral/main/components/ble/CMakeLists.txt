idf_component_register(
        SRCS "ble_init.c"
        INCLUDE_DIRS "include"
        REQUIRES gatt_server bt nvs_flash
)
