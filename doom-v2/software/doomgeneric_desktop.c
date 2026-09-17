// Indexed Windows presentation plus deterministic, windowless validation mode.
#define WIN32_LEAN_AND_MEAN
#define boolean win_boolean
#include <windows.h>
#undef boolean
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "doomgeneric.h"
#include "doomkeys.h"
#include "i_video.h"
#include "g_game.h"
#include "doomstat.h"
#include "d_event.h"
#include "m_menu.h"
#include "doom_profile.h"
#ifdef DOOM_FPS_OVERLAY
#include "fps_overlay.h"
static FpsCounter fps_counter;
static uint8_t fps_pixels[FPS_WIDTH*FPS_HEIGHT];
#endif
static HWND window;
static uint32_t pixels[320*200];
static uint16_t queue[256];
static unsigned head,tail;
static unsigned frame,max_frames;
static int headless,save_test,controls_test;
static unsigned control_frame;
static int initial_ammo,resume_tic;
static fixed_t initial_x,initial_y;
static void post_key(int key,int down){event_t e={0};e.type=down?ev_keydown:ev_keyup;e.data1=key;D_PostEvent(&e);}
static void require_control(int ok,const char *what){if(!ok){fprintf(stderr,"FAIL controls: %s\n",what);exit(2);}}
static const char *capture="frame.ppm";
static unsigned virtual_ms;
extern char *savegamedir;
static unsigned char translate(WPARAM k){
    switch(k){case VK_UP:return KEY_UPARROW;case VK_DOWN:return KEY_DOWNARROW;
        case VK_LEFT:return KEY_LEFTARROW;case VK_RIGHT:return KEY_RIGHTARROW;
        case VK_RETURN:return KEY_ENTER;case VK_ESCAPE:return KEY_ESCAPE;
        case VK_CONTROL:return KEY_RCTRL;case VK_SHIFT:return KEY_RSHIFT;case VK_MENU:return KEY_RALT;
        case VK_TAB:return KEY_TAB;case VK_BACK:return KEY_BACKSPACE;
        default:if(k>=VK_F1&&k<=VK_F10)return KEY_F1+(k-VK_F1);
        if(k==VK_F11)return KEY_F11;if(k==VK_F12)return KEY_F12;
        if(k>='A'&&k<='Z')return k-'A'+'a';return (unsigned char)k;}
}
static LRESULT CALLBACK proc(HWND w,UINT m,WPARAM a,LPARAM b){
    if(m==WM_CLOSE){DestroyWindow(w);return 0;}
    if(m==WM_DESTROY){exit(0);}
    if(m==WM_KEYDOWN||m==WM_KEYUP||m==WM_SYSKEYDOWN||m==WM_SYSKEYUP){
        unsigned n=(head+1)&255;int down=m==WM_KEYDOWN||m==WM_SYSKEYDOWN;
        if(down&&(b&(1L<<30)))return 0;
        if(n!=tail){queue[head]=translate(a)|(down?256:0);head=n;}return 0;
    }
    return DefWindowProcA(w,m,a,b);
}
void DG_Init(void){
    if(!headless){
        WNDCLASSA wc={0};wc.lpfnWndProc=proc;wc.hInstance=GetModuleHandleA(NULL);wc.lpszClassName="DoomNiosVPreview";wc.hCursor=LoadCursor(NULL,IDC_ARROW);
        if(!RegisterClassA(&wc)){fprintf(stderr,"RegisterClass failed\n");exit(1);}
        window=CreateWindowA(wc.lpszClassName,"DOOM desktop validation",WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,CW_USEDEFAULT,660,520,NULL,NULL,wc.hInstance,NULL);
        if(!window){fprintf(stderr,"CreateWindow failed\n");exit(1);}ShowWindow(window,SW_SHOW);
    }
}
void DG_SetWindowTitle(const char *t){if(window)SetWindowTextA(window,t);}
uint32_t DG_GetTicksMs(void){return headless?virtual_ms++:GetTickCount();}
void DG_SleepMs(uint32_t ms){if(headless)virtual_ms+=ms;else Sleep(ms);}
int DG_GetKey(int *pressed,unsigned char *key){
    if(DP_IS_BENCHMARK)return 0;
    MSG m;while(PeekMessage(&m,NULL,0,0,PM_REMOVE)){TranslateMessage(&m);DispatchMessage(&m);}
    if(head==tail)return 0;*pressed=!!(queue[tail]&256);*key=(unsigned char)queue[tail];tail=(tail+1)&255;return 1;
}
void DG_DrawFrame(void){
    DP_Begin(DP_TRANSFER);
    unsigned i;for(i=0;i<320*200;i++){unsigned k=DG_ScreenBuffer[i];pixels[i]=(colors[k].r<<16)|(colors[k].g<<8)|colors[k].b;}
#ifdef DOOM_FPS_OVERLAY
    fps_bitmap(&fps_counter,fps_pixels);
    for(unsigned y=0;y<FPS_HEIGHT;y++)for(unsigned x=0;x<FPS_WIDTH;x++)
        pixels[(FPS_Y+y)*320+FPS_X+x]=fps_pixels[y*FPS_WIDTH+x]?0xffffff:0;
    fps_sample(&fps_counter,GetTickCount());
#endif
    frame++;
    if(save_test && gamestate==GS_LEVEL){
        if(frame==40)G_SaveGame(0,"BOARD-INDEPENDENT TEST");
        if(frame==80){static char saved[512];snprintf(saved,sizeof(saved),"%sdoomsav0.dsg",savegamedir);G_LoadGame(saved);}
    }
    if(controls_test && (gamestate==GS_LEVEL || control_frame)){
        player_t *p=&players[consoleplayer];
        control_frame++;
        if(control_frame==40){initial_x=p->mo->x;initial_y=p->mo->y;post_key('w',1);}
        if(control_frame==60){post_key('w',0);require_control(p->mo->x!=initial_x || p->mo->y!=initial_y,"W movement");}
        if(control_frame==70){initial_ammo=p->ammo[am_clip];post_key(KEY_RCTRL,1);}
        if(control_frame==110){post_key(KEY_RCTRL,0);require_control(p->ammo[am_clip]<initial_ammo,"Ctrl must fire and consume ammo");}
        if(control_frame==130){post_key(KEY_ESCAPE,1);post_key(KEY_ESCAPE,0);}
        if(control_frame==140){require_control(menuactive,"Esc opens menu");post_key(KEY_ESCAPE,1);post_key(KEY_ESCAPE,0);}
        if(control_frame==150){require_control(!menuactive,"Esc closes menu");resume_tic=gametic;}
        if(control_frame==200){post_key(KEY_F10,1);post_key(KEY_F10,0);}
        if(control_frame==210){post_key('y',1);post_key('y',0);}
        if(control_frame==240){require_control(gamestate==GS_DEMOSCREEN,"Quit confirmation returns to title");resume_tic=gametic;}
        if(control_frame==270){require_control(gametic>resume_tic,"Title remains running");puts("PASS confirmed Quit returns to a live title screen");}
        if(control_frame==190){require_control(gametic>resume_tic,"Game ticks resume after Esc");puts("PASS controls: W movement, Ctrl fire, Esc menu open/close and resumed ticks");}
    }
    if(window){
        BITMAPINFO bi={0};RECT r;HDC dc=GetDC(window);GetClientRect(window,&r);
        bi.bmiHeader.biSize=sizeof(BITMAPINFOHEADER);bi.bmiHeader.biWidth=320;bi.bmiHeader.biHeight=-200;bi.bmiHeader.biPlanes=1;bi.bmiHeader.biBitCount=32;bi.bmiHeader.biCompression=BI_RGB;
        StretchDIBits(dc,0,0,r.right,r.bottom,0,0,320,200,pixels,&bi,DIB_RGB_COLORS,SRCCOPY);ReleaseDC(window,dc);
    }
    DP_End(DP_TRANSFER);
    if(max_frames && frame>=max_frames){
        FILE *f=fopen(capture,"wb");if(!f){perror(capture);exit(1);}fprintf(f,"P6\n320 200\n255\n");
        for(i=0;i<320*200;i++){fputc(pixels[i]>>16,f);fputc(pixels[i]>>8,f);fputc(pixels[i],f);}fclose(f);
        printf("VALIDATION frames=%u gametic=%d state=%d capture=%s\n",frame,gametic,gamestate,capture);exit(0);
    }
}
int main(int argc,char **argv){
    setvbuf(stdout,NULL,_IONBF,0);setvbuf(stderr,NULL,_IONBF,0);
    int i;for(i=1;i<argc;i++){
        if(!strcmp(argv[i],"-headless"))headless=1;
        if(!strcmp(argv[i],"-controls-test"))controls_test=1;
        if(!strcmp(argv[i],"-frames")&&i+1<argc)max_frames=(unsigned)atoi(argv[++i]);
        if(!strcmp(argv[i],"-capture")&&i+1<argc)capture=argv[++i];
        if(!strcmp(argv[i],"-save-test"))save_test=1;
    }
    doomgeneric_Create(argc,argv);for(;;)doomgeneric_Tick();
}
