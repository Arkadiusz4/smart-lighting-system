#ifndef GATT_CLIENT_H
#define GATT_CLIENT_H

#include "esp_err.h"
#include "esp_gattc_api.h"
#include "esp_bt_defs.h"

typedef struct {
    esp_gattc_cb_t gattc_cb;
    esp_gatt_if_t gattc_if;
    uint16_t app_id;
    uint16_t conn_id;
    uint16_t service_start_handle;
    uint16_t service_end_handle;
    esp_bd_addr_t remote_bda;
} gattc_profile_inst_t;

extern esp_gatt_if_t gattc_if_global;
extern uint16_t conn_id_global;
extern bool connected;

extern gattc_profile_inst_t gl_profile_tab[];

esp_err_t gatt_client_init(void);

void gatt_client_register_callback(void);

#endif // GATT_CLIENT_H
