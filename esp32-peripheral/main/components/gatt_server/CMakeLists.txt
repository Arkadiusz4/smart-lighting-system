idf_component_register(
        SRCS "gatt_server.c"
        INCLUDE_DIRS "include"
        REQUIRES ble temperature bt
)