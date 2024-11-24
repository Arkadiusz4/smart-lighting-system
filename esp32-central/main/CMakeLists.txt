idf_component_register(SRCS "main.c"
        INCLUDE_DIRS "."
        REQUIRES ble_central bt nvs_flash 
)