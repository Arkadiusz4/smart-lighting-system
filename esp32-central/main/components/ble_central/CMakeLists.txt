idf_component_register(
        SRCS "ble_central.c"
        INCLUDE_DIRS "include"
        REQUIRES gatt_client temperature nvs_flash bt
)
