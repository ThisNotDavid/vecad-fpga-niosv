#include "ramfs.h"
#include "ps2_keys.h"
#include "doomkeys.h"
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
int main(void){
    static const unsigned char wad[]={1,2,3,4,5};char buf[32];int a,b,n,down;unsigned char key;Ps2Parser p={0};
    assert(ramfs_mount_wad("/ram/test.wad",wad,sizeof(wad))==0);
    assert(ramfs_open("/ram/test.wad",O_WRONLY)==-EROFS);
    a=ramfs_open("/ram/test.wad",O_RDONLY);b=ramfs_open("/ram/test.wad",O_RDONLY);
    assert(a>=0&&b>=0&&a!=b);assert(ramfs_read(a,buf,3)==3&&buf[0]==1&&buf[2]==3);
    assert(ramfs_read(b,buf,1)==1&&buf[0]==1);assert(ramfs_seek(a,-1,SEEK_END)==4);
    assert(ramfs_read(a,buf,32)==1&&buf[0]==5);assert(ramfs_read(a,buf,1)==0);
    assert(ramfs_seek(a,-20,SEEK_CUR)==-EINVAL);assert(ramfs_close(a)==0);assert(ramfs_close(b)==0);
    a=ramfs_open("/ram/temp.dsg",O_CREAT|O_RDWR|O_TRUNC);assert(a>=0);
    assert(ramfs_write(a,"save",4)==4);assert(ramfs_seek(a,8,SEEK_SET)==8);assert(ramfs_write(a,"!",1)==1);
    assert(ramfs_seek(a,0,SEEK_SET)==0);assert(ramfs_read(a,buf,32)==9);assert(!memcmp(buf,"save\0\0\0\0!",9));
    assert(ramfs_unlink("/ram/temp.dsg")==-EBUSY);assert(ramfs_close(a)==0);
    assert(ramfs_rename("/ram/temp.dsg","/ram/doomsav0.dsg")==0);
    assert(ramfs_open("/ram/temp.dsg",O_RDONLY)==-ENOENT);
    a=ramfs_open("/ram/doomsav0.dsg",O_WRONLY|O_APPEND);assert(ramfs_seek(a,0,SEEK_SET)==0);
    assert(ramfs_write(a,"x",1)==1);assert(ramfs_size(a)==10);
    assert(ramfs_read(a,buf,1)==-EBADF);ramfs_close(a);
    a=ramfs_open("/ram/full",O_CREAT|O_RDWR);assert(ramfs_seek(a,512*1024,SEEK_SET)==512*1024);
    assert(ramfs_write(a,"x",1)==-ENOSPC);ramfs_close(a);
    assert(ramfs_rename("/ram/doomsav0.dsg","/ram/test.wad")==-EROFS);
    assert(ramfs_unlink("/ram/doomsav0.dsg")==0);
    assert(!ps2_key(&p,0xe0,&down,&key));assert(ps2_key(&p,0x75,&down,&key)&&down&&key==KEY_UPARROW);
    assert(!ps2_key(&p,0xe0,&down,&key));assert(!ps2_key(&p,0xf0,&down,&key));
    assert(ps2_key(&p,0x75,&down,&key)&&!down&&key==KEY_UPARROW);
    assert(ps2_key(&p,0x14,&down,&key)&&down&&key==KEY_RCTRL);
    assert(!ps2_key(&p,0xf0,&down,&key));assert(ps2_key(&p,0x14,&down,&key)&&!down);
    assert(!ps2_key(&p,0xe0,&down,&key));assert(ps2_key(&p,0x14,&down,&key)&&down&&key==KEY_RCTRL);
    assert(!ps2_key(&p,0xe0,&down,&key));assert(!ps2_key(&p,0xf0,&down,&key));
    assert(ps2_key(&p,0x14,&down,&key)&&!down&&key==KEY_RCTRL);
    assert(ps2_key(&p,0x83,&down,&key)&&key==KEY_F7);assert(ps2_key(&p,0x1c,&down,&key)&&key=='a');
    assert(!ps2_key(&p,0xe1,&down,&key));for(n=0;n<7;n++)assert(!ps2_key(&p,0x14,&down,&key));
    assert(ps2_key(&p,0x5a,&down,&key)&&key==KEY_ENTER);
    puts("PASS RAM filesystem and PS/2 make/break decoding");return 0;
}
