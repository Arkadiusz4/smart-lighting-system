idf_component_register(SRCS "main.c"
        INCLUDE_DIRS "."
        REQUIRES wifi_manager web_server http_client esp-tls
)
