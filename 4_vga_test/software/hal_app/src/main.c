#include <stdio.h>
#include <unistd.h>

#include "system.h"
#include "altera_avalon_pio_regs.h"

int main(void)
{
    printf("VGA colour test\n");

    while (1)
    {
        // Red
        IOWR_ALTERA_AVALON_PIO_DATA(
            VGA_BASE,
            0b100
        );

        usleep(1000000);


        // Green
        IOWR_ALTERA_AVALON_PIO_DATA(
            VGA_BASE,
            0b010
        );

        usleep(1000000);


        // Blue
        IOWR_ALTERA_AVALON_PIO_DATA(
            VGA_BASE,
            0b001
        );

        usleep(1000000);


        // White
        IOWR_ALTERA_AVALON_PIO_DATA(
            VGA_BASE,
            0b111
        );

        usleep(1000000);


        // Black
        IOWR_ALTERA_AVALON_PIO_DATA(
            VGA_BASE,
            0b000
        );

        usleep(1000000);
    }

    return 0;
}
