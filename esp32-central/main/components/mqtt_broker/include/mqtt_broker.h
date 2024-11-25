#ifndef MQTT_BROKER_H
#define MQTT_BROKER_H

void mqtt_app_start(void);

void mqtt_publish(const char *topic, const char *message);

#endif // MQTT_BROKER_H
