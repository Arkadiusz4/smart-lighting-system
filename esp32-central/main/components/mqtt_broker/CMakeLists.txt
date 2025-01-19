idf_component_register(SRCS "mqtt_broker.c" "device_control.c"
        INCLUDE_DIRS "include"
        REQUIRES mqtt mqtt_manager json driver
)
