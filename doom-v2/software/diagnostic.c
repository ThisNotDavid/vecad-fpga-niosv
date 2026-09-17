#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "io.h"
#include "sys/alt_cache.h"
#include "ramfs.h"
#include <fcntl.h>
#include <string.h>
static uint32_t ms(void){return IORD_32DIRECT(IO_BASE,0x21008);}
static int memory_test(void){
    volatile uint32_t *p=(volatile uint32_t *)(SDRAM_BASE+0x200000);
    unsigned i,pass;uint32_t got,expected;
    for(pass=0;pass<3;pass++){
        for(i=0;i<65536;i++)p[i]=(i*0x9e3779b9u)^(pass==0?0x55555555u:pass==1?0xaaaaaaaau:0);
        alt_dcache_flush_all();
        alt_dcache_flush_no_writeback((void *)p,65536*4);
        for(i=0;i<65536;i++){
            expected=(i*0x9e3779b9u)^(pass==0?0x55555555u:pass==1?0xaaaaaaaau:0);
            got=p[i];if(got!=expected){printf("FAIL SDRAM %08lx got %08lx expected %08lx\n",(unsigned long)&p[i],(unsigned long)got,(unsigned long)expected);return 1;}
        }
        alt_dcache_flush_all();
    }
    // Distinct addresses exercise all high address bits/banks, away from code,
    // heap and the top-of-memory stack.
    for(i=0;i<64;i++)*(volatile uint32_t *)(SDRAM_BASE+0x400000+i*0x100000)=0xdead0000u+i;
    alt_dcache_flush_all();
    for(i=0;i<64;i++)alt_dcache_flush_no_writeback((void *)(SDRAM_BASE+0x400000+i*0x100000),32);
    for(i=0;i<64;i++)if(*(volatile uint32_t *)(SDRAM_BASE+0x400000+i*0x100000)!=0xdead0000u+i){puts("FAIL SDRAM high-address alias");return 1;}
    return 0;
}
int main(void){
    unsigned i,x,y;uint32_t before,key;int f;char b[16];
    setvbuf(stdout,NULL,_IONBF,0);
    puts("DIAGNOSTIC START");
    if(IORD_32DIRECT(IO_BASE,0x21014)!=0x444f4f4d){puts("FAIL IO ID");for(;;){}}
    for(i=0;i<10000;i++){
        before=ms();
        if(IORD_32DIRECT(IO_BASE,0x21014)!=0x444f4f4d){puts("FAIL repeated IO ID");for(;;){}}
        (void)IORD_32DIRECT(IO_BASE,0x21000);
    }
    puts("PASS 10000 interleaved IO register reads");
    before=ms();while(ms()==before){}puts("PASS IO ID and timer");
    if(memory_test())for(;;){}puts("PASS SDRAM 3x256KiB and 64 high-address probes (cache flushed)");
    f=ramfs_open("/ram/test",O_CREAT|O_RDWR);ramfs_write(f,"save-test",9);ramfs_seek(f,0,SEEK_SET);
    if(ramfs_read(f,b,9)!=9||memcmp(b,"save-test",9)){puts("FAIL RAMFS");for(;;){}}
    ramfs_close(f);puts("PASS RAMFS");
    for(i=0;i<256;i++)IOWR_32DIRECT(IO_BASE,0x20400+i*4,((i&0xe0)<<16)|((i&0x1c)<<11)|((i&3)<<6));
    for(y=0;y<200;y++)for(x=0;x<320;x+=4){
        uint32_t p=0;for(i=0;i<4;i++)p|=((uint32_t)(((x+i)*8/320)*32+((y*8/200)*4)+3))<<(8*i);
        IOWR_32DIRECT(IO_BASE,0x10000+y*320+x,p);
    }
    IOWR_32DIRECT(IO_BASE,0x21004,3);before=ms();
    while(IORD_32DIRECT(IO_BASE,0x21000)&2)if(ms()-before>100){puts("FAIL swap timeout");for(;;){}}
    puts("PASS VGA swap. Color grid displayed. Press PS/2 keys; raw bytes follow.");
    for(;;){key=IORD_32DIRECT(IO_BASE,0x2100c);if(key&256)printf("KEY %02lx\n",(unsigned long)(key&255));}
}
