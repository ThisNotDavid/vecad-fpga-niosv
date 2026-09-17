module chess_top(
    input logic MAX10_CLK1_50,
    input logic [1:0] KEY,
    output logic [9:0] LEDR,
    output wire [3:0] VGA_R,VGA_G,VGA_B,
    output wire VGA_HS,VGA_VS
);
    wire clk=MAX10_CLK1_50;
    logic [15:0] power_on=0;
    (* altera_attribute="-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *) logic [1:0] key_sync=0;
    always_ff @(posedge clk) begin
        if(!(&power_on)) power_on<=power_on+1'b1;
        key_sync<={key_sync[0],KEY[0]};
    end
    wire reset=!(&power_on) || !key_sync[1];
    wire [7:0] command;
    wire command_valid,command_ready,activity;
    wire av_address,av_chipselect,av_read_n,av_write_n,av_waitrequest;
    wire [31:0] av_writedata,av_readdata;
    altera_avalon_jtag_uart uart(.clk,.rst_n(~reset),.av_address,.av_chipselect,.av_read_n,.av_write_n,
        .av_writedata,.av_readdata,.av_waitrequest,.av_irq());
    jtag_transport transport(.clk,.reset,.command,.command_valid,.command_ready,.activity,
        .av_address,.av_chipselect,.av_read_n,.av_write_n,.av_writedata,.av_readdata,.av_waitrequest);
    wire [255:0] board;
    wire side,selected_valid,last_valid,in_check,mate,stalemate,promotion_pending,busy;
    wire [5:0] cursor,selected,last_src,last_dst;
    wire [63:0] legal_mask;
    wire [15:0] ply_count;
    game_controller game(.clk,.reset,.command,.command_valid,.command_ready,.board,.side,.cursor,.selected,
        .last_src,.last_dst,.selected_valid,.last_valid,.legal_mask,.in_check,.mate,.stalemate,.promotion_pending,.busy,.ply_count);
    wire [9:0] x,y;
    wire pixel_enable,active,hs,vs,frame_start;
    vga_timing timing(.clk,.reset,.x,.y,.pixel_enable,.active,.hs,.vs,.frame_start);
    // Frame-boundary snapshot keeps trial positions and partial move masks off-screen.
    logic [255:0] display_board;
    logic d_side,d_selected_valid,d_last_valid,d_check,d_mate,d_stale,d_promotion;
    logic [5:0] d_cursor,d_selected,d_last_src,d_last_dst;
    logic [63:0] d_mask;
    always_ff @(posedge clk) begin
        if(reset || (frame_start && !busy)) begin
            display_board<=reset ? chess_pkg::INITIAL_BOARD : board;
            d_side<=reset ? 1'b0 : side; d_cursor<=reset ? 6'd12 : cursor;
            d_selected<=selected; d_selected_valid<=!reset && selected_valid;
            d_last_src<=last_src;d_last_dst<=last_dst;d_last_valid<=!reset && last_valid;
            d_mask<=reset ? 64'd0 : legal_mask; d_check<=!reset && in_check;
            d_mate<=!reset && mate; d_stale<=!reset && stalemate;d_promotion<=!reset && promotion_pending;
        end
    end
    chess_renderer renderer(.clk,.reset,.x,.y,.active,.hs,.vs,.board(display_board),.side(d_side),
        .cursor(d_cursor),.selected(d_selected),.last_src(d_last_src),.last_dst(d_last_dst),
        .selected_valid(d_selected_valid),.last_valid(d_last_valid),.legal_mask(d_mask),.in_check(d_check),
        .mate(d_mate),.stalemate(d_stale),.promotion_pending(d_promotion),
        .restart_pending(1'b0),.display_active(),
        .red(VGA_R),.green(VGA_G),.blue(VGA_B),.hsync(VGA_HS),.vsync(VGA_VS));
    assign LEDR={ply_count[3:0],promotion_pending,stalemate,mate,in_check,side,activity};
endmodule
