idf_component_register(SRCS "web_server.c"
        INCLUDE_DIRS "include"
        REQUIRES esp_http_server oled_display mqtt_manager
        PRIV_REQUIRES wifi_manager
)
