#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void hello_world_task(void *pvParameter)
{
    while (1)
    {
        for (int i = 10; i > 0; i--)
        {
            printf("Odliczanie: %d sekund\n", i);
            vTaskDelay(1000 / portTICK_PERIOD_MS); 
        }

        printf("Hello World\n");
    }
}

void app_main(void)
{
    xTaskCreate(&hello_world_task, "hello_world_task", 2048, NULL, 5, NULL);
}
