#ifndef DOOM_PS2_KEYS_H
#define DOOM_PS2_KEYS_H
#include <stdint.h>
typedef struct {uint8_t extended,released,pause_skip;} Ps2Parser;
int ps2_key(Ps2Parser *parser,uint8_t byte,int *pressed,uint8_t *key);
#endif
