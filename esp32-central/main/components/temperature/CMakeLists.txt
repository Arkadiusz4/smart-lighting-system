idf_component_register(
        SRCS "temperature.c"
        INCLUDE_DIRS "include"
        REQUIRES mqtt_broker gatt_client freertos
)
