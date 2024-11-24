idf_component_register(
        SRCS "temperature.c"
        INCLUDE_DIRS "include"
        REQUIRES gatt_client freertos
)
