#include "nvs_flash.h"
#include "nvs.h"
#include <string.h>

char s_board_id[32] = "defaultBoardId";

esp_err_t save_board_id(const char *board_id) {
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &nvs_handle);
    if (err != ESP_OK) return err;

    err = nvs_set_str(nvs_handle, "boardId", board_id);
    if (err == ESP_OK) {
        err = nvs_commit(nvs_handle);
    }
    nvs_close(nvs_handle);
    strncpy(s_board_id, board_id, sizeof(s_board_id) - 1);
    return err;
}

void load_board_id(char *board_id, size_t max_len) {
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &nvs_handle);
    if (err == ESP_OK) {
        size_t required_size = max_len;

        err = nvs_get_str(nvs_handle, "boardId", board_id, &required_size);
        if (err != ESP_OK) {
            board_id[0] = '\0';
        }
        nvs_close(nvs_handle);
    } else {
        board_id[0] = '\0';
    }
}

void device_control_set_board_id(const char *board_id) {
    strncpy(s_board_id, board_id, sizeof(s_board_id) - 1);
}
