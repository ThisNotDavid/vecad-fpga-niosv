#include "fps_overlay.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
 FpsCounter c={0},wrap={0}; unsigned i; uint8_t guarded[FPS_WIDTH*FPS_HEIGHT+2];
 fps_sample(&c,0);assert(!c.valid);
 for(i=1;i<=8;i++)fps_sample(&c,i*125);
 assert(c.valid && c.tenths==80);
 fps_sample(&c,2500);assert(c.tenths==7);
 fps_sample(&wrap,0xffffff00u);
 for(i=1;i<=8;i++)fps_sample(&wrap,0xffffff00u+i*125);
 assert(wrap.valid && wrap.tenths==80);
 memset(guarded,0xa5,sizeof guarded);c.tenths=9999;
 fps_bitmap(&c,guarded+1);assert(guarded[0]==0xa5 && guarded[sizeof guarded-1]==0xa5);
 for(i=0;i<FPS_WIDTH*FPS_HEIGHT;i++)assert(guarded[i+1]<=1);
 c.tenths=80;fps_bitmap(&c,guarded+1);
 if(argc>1) {
 FILE *f=fopen(argv[1],"wb");assert(f);
 fprintf(f,"P6\n%d %d\n255\n",FPS_WIDTH,FPS_HEIGHT);
 for(i=0;i<FPS_WIDTH*FPS_HEIGHT;i++)for(unsigned j=0;j<3;j++)fputc(guarded[i+1]?255:0,f);
 fclose(f); }
 puts("PASS FPS: 8 FPS, irregular interval, timer wrap, raster bounds");return 0;
}
