"""Patch only the generated engine copy. Fail on upstream layout changes."""
def instrument(out):
    def edit(name,before,after):
        p=out/name;s=p.read_text()
        if s.count(before)!=1:raise RuntimeError('Instrumentation anchor changed: '+name+' '+before[:65])
        p.write_text(s.replace(before,after))
    for name in ('d_main.c','i_video.c'):
        p=out/name;p.write_text('#include "doom_profile.h"\n'+p.read_text())
    edit('d_main.c','void doomgeneric_Tick()\n{','void doomgeneric_Tick()\n{\n    DP_TickBegin();')
    edit('d_main.c','    TryRunTics (); // will run at least one tic',
         '    DP_Begin(DP_LOGIC);\n    TryRunTics (); // will run at least one tic\n    DP_End(DP_LOGIC);')
    # Insert at the end of the complete tick body, independent of tab formatting.
    p=out/'d_main.c';s=p.read_text();start=s.index('void doomgeneric_Tick()');end=s.index('//  D_DoomLoop',start)
    block=s[start:end];at=block.rfind('}')
    block=block[:at]+'    DP_TickEnd();\n'+block[at:];p.write_text(s[:start]+block+s[end:])
    edit('d_main.c','if (gamestate != wipegamestate)','if (gamestate != wipegamestate && !DP_IS_BENCHMARK)')
    edit('d_main.c','R_RenderPlayerView (&players[displayplayer]);',
         '{ DP_Begin(DP_RENDER); R_RenderPlayerView (&players[displayplayer]); DP_End(DP_RENDER); }')
    edit('i_video.c','void I_FinishUpdate (void)\n{',
         'void I_FinishUpdate (void)\n{\n    DP_Begin(DP_CONVERT);')
    edit('i_video.c','DG_DrawFrame();','DP_End(DP_CONVERT);\n\tDG_DrawFrame();')
    # Lock graphics settings after config loading, identically in off/on builds.
    p=out/'d_main.c';s=p.read_text()
    import re
    s,n=re.subn(r'(M_LoadDefaults\s*\(\s*\);)',r'\1\n#if DP_IS_BENCHMARK\n    { extern int screenblocks, detailLevel; screenblocks=10; detailLevel=0; }\n#endif',s)
    if n!=1:raise RuntimeError('Config-load anchor changed')
    p.write_text(s)
