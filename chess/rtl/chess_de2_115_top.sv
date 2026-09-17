module chess_de2_115_top(
    input logic CLOCK_50,
    input logic [0:0] KEY,
    input logic PS2_CLK,PS2_DAT,
    output wire [9:0] LEDR,
    output wire [7:0] VGA_R,VGA_G,VGA_B,
    output wire VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N
);
    wire clk=CLOCK_50;
    logic [15:0] power_on=0;
    (* altera_attribute="-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *) logic [1:0] key_sync=0;
    always_ff @(posedge clk) begin
        if(!(&power_on)) power_on<=power_on+1'b1;
        key_sync<={key_sync[0],KEY[0]};
    end
    wire reset=!(&power_on) || !key_sync[1];
    wire [7:0] scan_code,key_command,command;
    wire scan_valid,frame_error,key_valid,command_valid,command_ready;
    wire restart_pending,restart_pulse,overflow,activity;
    logic error_seen;
    always_ff @(posedge clk) begin
        if(reset) error_seen<=0;
        else if(frame_error) error_seen<=1;
    end
    ps2_receiver receiver(.clk,.reset,.ps2_clk(PS2_CLK),.ps2_data(PS2_DAT),
        .data(scan_code),.data_valid(scan_valid),.frame_error);
    ps2_decoder decoder(.clk,.reset,.data(scan_code),.data_valid(scan_valid),.frame_error,
        .command(key_command),.command_valid(key_valid));
    keyboard_commands keyboard(.clk,.reset,.input_command(key_command),.input_valid(key_valid),
        .command,.command_valid,.command_ready,.restart_pending,.restart_pulse,.overflow,.activity);
    wire game_reset=reset || restart_pulse;
    wire [255:0] board;
    wire side,selected_valid,last_valid,in_check,mate,stalemate,promotion_pending,busy;
    wire [5:0] cursor,selected,last_src,last_dst;
    wire [63:0] legal_mask;
    wire [15:0] ply_count;
    game_controller #(.AUTO_FLIP(1)) game(.clk,.reset(game_reset),.command,.command_valid,.command_ready,.board,.side,.cursor,.selected,
        .last_src,.last_dst,.selected_valid,.last_valid,.legal_mask,.in_check,.mate,.stalemate,.promotion_pending,.busy,.ply_count);
    wire [9:0] x,y;
    wire pixel_enable,active,hs,vs,frame_start;
    vga_timing timing(.clk,.reset,.x,.y,.pixel_enable,.active,.hs,.vs,.frame_start);
    logic [255:0] display_board;
    logic d_side,d_selected_valid,d_last_valid,d_check,d_mate,d_stale,d_promotion,d_restart;
    logic [5:0] d_cursor,d_selected,d_last_src,d_last_dst;
    logic [63:0] d_mask;
    always_ff @(posedge clk) begin
        if(reset) d_restart<=0;
        else if(frame_start) d_restart<=restart_pending;
        if(reset || (frame_start && !busy)) begin
            display_board<=reset ? chess_pkg::INITIAL_BOARD : board;
            d_side<=reset ? 1'b0 : side;d_cursor<=reset ? 6'd12 : cursor;
            d_selected<=selected;d_selected_valid<=!reset && selected_valid;
            d_last_src<=last_src;d_last_dst<=last_dst;d_last_valid<=!reset && last_valid;
            d_mask<=reset ? 64'd0 : legal_mask;d_check<=!reset && in_check;
            d_mate<=!reset && mate;d_stale<=!reset && stalemate;d_promotion<=!reset && promotion_pending;
        end
    end
    wire [3:0] red,green,blue;
    wire rendered_hs,rendered_vs,rendered_active;
    chess_renderer #(.CURSOR_RGB(12'h36f),.PS2_CONTROL(1),.AUTO_FLIP(1)) renderer(
        .clk,.reset,.x,.y,.active,.hs,.vs,.board(display_board),.side(d_side),
        .cursor(d_cursor),.selected(d_selected),.last_src(d_last_src),.last_dst(d_last_dst),
        .selected_valid(d_selected_valid),.last_valid(d_last_valid),.legal_mask(d_mask),.in_check(d_check),
        .mate(d_mate),.stalemate(d_stale),.promotion_pending(d_promotion),.restart_pending(d_restart),
        .red,.green,.blue,.hsync(rendered_hs),.vsync(rendered_vs),.display_active(rendered_active));
    de2_vga_output video_output(.clk,.reset,.pixel_enable,.red,.green,.blue,
        .hs(rendered_hs),.vs(rendered_vs),.active(rendered_active),
        .VGA_R,.VGA_G,.VGA_B,.VGA_CLK,.VGA_HS,.VGA_VS,.VGA_BLANK_N,.VGA_SYNC_N);
    assign LEDR={error_seen,overflow,restart_pending,busy,promotion_pending,stalemate,mate,in_check,side,activity};
endmodule
