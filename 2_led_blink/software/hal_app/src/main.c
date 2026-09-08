#include <stdint.h>

#include "system.h"
#include "io.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_alarm.h"

int main(void)
{
    alt_u32 now;
    alt_u32 last_red;
    alt_u32 last_green;

    alt_u32 ticks_per_sec = alt_ticks_per_second();

    // RED: toggle every 500 ms -> 1 Hz complete blink cycle
    alt_u32 red_interval = ticks_per_sec / 2;

    // GREEN: toggle every 250 ms -> 2 Hz complete blink cycle
    alt_u32 green_interval = ticks_per_sec / 4;

    uint32_t red_state = 0;
    uint32_t green_state = 0;

    // Initially turn all LEDs off
    IOWR_ALTERA_AVALON_PIO_DATA(LEDR_BASE, 0x0);
    IOWR_ALTERA_AVALON_PIO_DATA(LEDG_BASE, 0x0);

    last_red = alt_nticks();
    last_green = last_red;

    while (1)
    {
        now = alt_nticks();

        // Red LEDs
        if ((now - last_red) >= red_interval)
        {
            last_red = now;
            red_state ^= 1;

            if (red_state)
                IOWR_ALTERA_AVALON_PIO_DATA(LEDR_BASE, 0xF);
            else
                IOWR_ALTERA_AVALON_PIO_DATA(LEDR_BASE, 0x0);
        }

        // Green LEDs
        if ((now - last_green) >= green_interval)
        {
            last_green = now;
            green_state ^= 1;

            if (green_state)
                IOWR_ALTERA_AVALON_PIO_DATA(LEDG_BASE, 0xF);
            else
                IOWR_ALTERA_AVALON_PIO_DATA(LEDG_BASE, 0x0);
        }
    }

    return 0;
}
