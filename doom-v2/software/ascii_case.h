#ifndef DOOM_ASCII_CASE_H
#define DOOM_ASCII_CASE_H
#include <stddef.h>
#include <string.h>
#include <strings.h>
// WAD names are ASCII, fixed-width and may not contain a terminating NUL.
static int doom_ascii_ncasecmp(const char *a,const char *b,size_t n){
    size_t i;for(i=0;i<n;i++){
        unsigned char x=(unsigned char)a[i],y=(unsigned char)b[i];
        if(x>='a'&&x<='z')x-=32;if(y>='a'&&y<='z')y-=32;
        if(x!=y)return (int)x-y;if(!x)return 0;
    }return 0;
}
#endif
