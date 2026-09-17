// Fixed workload, real clock measurements. No serial output in the measured run.
#include "doom_profile.h"
#ifdef DOOM_BENCHMARK
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "doomgeneric.h"
#include "doomstat.h"
#ifdef DOOM_NIOSV
#include "system.h"
#include "intel_niosv.h"
#include <fcntl.h>
#define DP_PLATFORM "niosv"
#else
#define boolean win_boolean
#include <windows.h>
#undef boolean
#define DP_PLATFORM "desktop"
#endif
#define WARMUP 70
#define SAMPLES 350
volatile unsigned benchmark_done;
static unsigned ticks, count;
static int active, measuring;
static uint64_t frequency, run_start, frame_start, frame_samples[SAMPLES];
static uint64_t stage_start[DP_STAGE_COUNT], stages[DP_STAGE_COUNT], frame_stages[DP_STAGE_COUNT];
static uint64_t clock_ticks(void) {
#ifdef DOOM_NIOSV
    return alt_niosv_mtime_get();
#else
    LARGE_INTEGER value;QueryPerformanceCounter(&value);return (uint64_t)value.QuadPart;
#endif
}
static int compare(const void *a,const void *b){
    uint64_t x=*(const uint64_t *)a,y=*(const uint64_t *)b;return (x>y)-(x<y);
}
static uint64_t us(uint64_t value){return value*1000000/frequency;}
#ifdef DOOM_PROFILE
void DP_Begin(int stage){if(active)stage_start[stage]=clock_ticks();}
void DP_End(int stage){if(active)frame_stages[stage]+=clock_ticks()-stage_start[stage];}
#endif
void DP_TickBegin(void){
    unsigned i;
    active=gamestate==GS_LEVEL && demoplayback;
    if(!active)return;
    if(!frequency){
#ifdef DOOM_NIOSV
        frequency=alt_niosv_timer_timestamp_freq();
#else
        LARGE_INTEGER value;QueryPerformanceFrequency(&value);frequency=value.QuadPart;
#endif
    }
    for(i=0;i<DP_STAGE_COUNT;i++)frame_stages[i]=0;
    measuring=ticks>=WARMUP;
    frame_start=clock_ticks();
    if(measuring && !count)run_start=frame_start;
}
void DP_TickEnd(void){
    uint64_t end,elapsed,total=0,classified=0;
    uint32_t hash=2166136261u;
    unsigned i;
    if(!active)return;
    end=clock_ticks();active=0;ticks++;
    if(!measuring)return;
    frame_samples[count++]=end-frame_start;
    for(i=0;i<DP_STAGE_COUNT;i++)stages[i]+=frame_stages[i];
    if(count<SAMPLES)return;
    elapsed=end-run_start;
    if(!elapsed){puts("FAIL benchmark timestamp did not advance");exit(2);}
    for(i=0;i<count;i++)total+=frame_samples[i];
    for(i=0;i<DP_STAGE_COUNT;i++)classified+=stages[i];
    for(i=0;i<320*200;i++)hash=(hash^DG_ScreenBuffer[i])*16777619u;
    qsort(frame_samples,count,sizeof(frame_samples[0]),compare);
    benchmark_done=1;
#ifdef DOOM_NIOSV
    // Final report only: capture must be connected. No logging in timed frames.
    fcntl(1,F_SETFL,0);clearerr(stdout);
#endif
    printf("BENCHMARK {\"platform\":\"" DP_PLATFORM "\",\"clock_hz\":%llu,\"profile\":%d,\"frames\":%u,\"warmup\":%u,\"elapsed_us\":%llu,\"fps_x100\":%llu,"
           "\"median_us\":%llu,\"p95_us\":%llu,\"max_us\":%llu,\"gametic\":%d,\"frame_hash\":\"%08lx\","
           "\"x\":%ld,\"y\":%ld,\"health\":%d,\"ammo\":%d,\"logic_us\":%llu,\"render_us\":%llu,"
           "\"convert_us\":%llu,\"wait_us\":%llu,\"transfer_us\":%llu,\"other_us\":%llu}\n",
           (unsigned long long)frequency,
#ifdef DOOM_PROFILE
           1,
#else
           0,
#endif
           count,WARMUP,(unsigned long long)us(elapsed),(unsigned long long)(count*frequency*100/elapsed),
           (unsigned long long)us(frame_samples[count/2]),(unsigned long long)us(frame_samples[(count*95+99)/100-1]),
           (unsigned long long)us(frame_samples[count-1]),gametic,(unsigned long)hash,
           (long)players[consoleplayer].mo->x,(long)players[consoleplayer].mo->y,
           players[consoleplayer].health,players[consoleplayer].ammo[am_clip],
           (unsigned long long)us(stages[0]),(unsigned long long)us(stages[1]),
           (unsigned long long)us(stages[2]),(unsigned long long)us(stages[3]),
           (unsigned long long)us(stages[4]),(unsigned long long)us(total>classified?total-classified:0));
    fflush(stdout);
    exit(0);
}
#endif
