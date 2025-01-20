#ifndef BOARD_MANAGER_H
#define BOARD_MANAGER_H

#include "esp_err.h"

extern char s_board_id[32];
extern char remote_device_name[32];

void save_board_id(const char *board_id);

esp_err_t load_board_id(char *board_id, size_t board_id_size);

void device_control_set_board_id(const char *board_id);

#endif // BOARD_MANAGER_H
