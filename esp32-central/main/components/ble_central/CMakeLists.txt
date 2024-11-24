# components/ble_central/CMakeLists.txt

idf_component_register(
    SRCS "ble_central.c"
    INCLUDE_DIRS "include"
    REQUIRES bt nvs_flash
)
