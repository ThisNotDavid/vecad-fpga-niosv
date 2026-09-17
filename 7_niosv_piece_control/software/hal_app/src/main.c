#include <stdio.h>
#include <unistd.h>

#include "system.h"
#include "altera_avalon_pio_regs.h"


int main(void)
{
    printf("Nios V checker piece control test\n");


    while (1)
    {
        // -----------------------------------------------------
        // Position 1
        // row = 2
        // col = 1
        // -----------------------------------------------------

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_ROW_BASE,
            2
        );

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_COL_BASE,
            1
        );

        usleep(1000000);


        // -----------------------------------------------------
        // Position 2
        // row = 2
        // col = 3
        // -----------------------------------------------------

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_ROW_BASE,
            2
        );

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_COL_BASE,
            3
        );

        usleep(1000000);


        // -----------------------------------------------------
        // Position 3
        // row = 3
        // col = 4
        // -----------------------------------------------------

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_ROW_BASE,
            3
        );

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_COL_BASE,
            4
        );

        usleep(1000000);


        // -----------------------------------------------------
        // Position 4
        // row = 4
        // col = 5
        // -----------------------------------------------------

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_ROW_BASE,
            4
        );

        IOWR_ALTERA_AVALON_PIO_DATA(
            PIECE_COL_BASE,
            5
        );

        usleep(1000000);

    }


    return 0;
}
