"""Board-specific Quartus configuration, verified against Terasic System CDs."""
COMMON=['chess_pkg','attack_detector','move_checker','game_controller','vga_timing','text_layer','chess_renderer']
BOARDS={
    'de10-lite':dict(project='chess',top='chess_top',family='MAX 10',device='10M50DAF484C7G',
        idcode='031050DD',output='output_files',build='build',sources=COMMON+['jtag_transport','chess_top']),
    'de2-115':dict(project='chess_de2_115',top='chess_de2_115_top',family='Cyclone IV E',device='EP4CE115F29C7',
        idcode='020F70DD',output='output_files/de2_115',build='build/de2_115',
        sources=COMMON+['ps2_receiver','ps2_decoder','keyboard_commands','de2_vga_output','chess_de2_115_top'])
}
def pins_for(board):
    if board=='de2-115':
        pins={'CLOCK_50':'Y2','KEY[0]':'M23','PS2_CLK':'G6','PS2_DAT':'H5',
              'VGA_HS':'G13','VGA_VS':'C13','VGA_CLK':'A12','VGA_BLANK_N':'F11','VGA_SYNC_N':'C10'}
        buses={'VGA_R':['E12','E11','D10','F12','G10','J12','H8','H10'],
               'VGA_G':['G8','G11','F8','H12','C8','B8','F10','C9'],
               'VGA_B':['B10','A10','C11','B11','A11','C12','D11','D12'],
               'LEDR':['G19','F19','E19','F21','F18','E18','J19','H19','J17','G17']}
    else:
        pins={'MAX10_CLK1_50':'P11','KEY[0]':'B8','KEY[1]':'A7','VGA_HS':'N3','VGA_VS':'N1'}
        buses={'VGA_R':['AA1','V1','Y2','Y1'],'VGA_G':['W1','T2','R2','R1'],
               'VGA_B':['P1','T1','P4','N2'],'LEDR':['A8','A9','A10','B10','D13','C13','E14','D14','A11','B11']}
    for name,locs in buses.items():pins.update({f'{name}[{i}]':loc for i,loc in enumerate(locs)})
    return pins
def io_standard(board,name):
    if board=='de2-115':return '2.5 V' if name.startswith(('KEY','LEDR')) else '3.3-V LVTTL'
    return '3.3 V SCHMITT TRIGGER' if name.startswith('KEY') else '3.3-V LVTTL'
