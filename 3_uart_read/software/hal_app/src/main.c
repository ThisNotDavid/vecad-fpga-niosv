#include <stdio.h>

int main(void)
{
    char c;

    printf("UART Read Test\n");
    printf("Type a character: ");

    while (1)
    {
        c = getchar();

        printf("\nReceived: %c\n", c);
        printf("ASCII: %d\n", c);
        printf("Type another character: ");
    }

    return 0;
}
