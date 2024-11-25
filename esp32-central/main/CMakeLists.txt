idf_component_register(
        SRCS "main.c"
        INCLUDE_DIRS "."
        REQUIRES ble_central wifi_manager web_server http_client mqtt_broker esp-tls mqtt
)
