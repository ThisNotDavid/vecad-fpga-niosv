module chess_renderer #(
    parameter [11:0] CURSOR_RGB=12'hfff,
    parameter bit PS2_CONTROL=0,
    parameter bit AUTO_FLIP=0
)(
    input logic clk,reset,
    input logic [9:0] x,y,
    input logic active,hs,vs,
    input logic [255:0] board,
    input logic side,
    input logic [5:0] cursor,selected,last_src,last_dst,
    input logic selected_valid,last_valid,
    input logic [63:0] legal_mask,
    input logic in_check,mate,stalemate,promotion_pending,
    input logic restart_pending,
    output logic [3:0] red,green,blue,
    output logic hsync,vsync,display_active
);
    import chess_pkg::*;
    logic [3:0] sprites [0:8191];
    initial $readmemh("assets/pieces.mem",sprites);
    integer col,row,lx,ly,i;
    logic on_board, sprite_on,cursor_edge;
    logic [5:0] square;
    logic [3:0] p;
    logic [12:0] sprite_addr;
    logic [11:0] rgb;
    logic [3:0] sprite_q;
    logic [11:0] rgb_q;
    logic sprite_on_q,black_q,cursor_q,active_q,hs_q,vs_q;
    wire text_ink;
    wire [11:0] text_color;
    logic [11:0] rgb2,rgb3;
    logic hs2,vs2,hs3,vs3,active2,active3;
    text_layer #(.PS2_CONTROL(PS2_CONTROL),.AUTO_FLIP(AUTO_FLIP)) text_display(.clk,.x,.y,.side,.selected_valid,.in_check,.mate,.stalemate,.promotion_pending,.restart_pending,
        .ink(text_ink),.color(text_color));
    always_comb begin
        rgb=12'h222; col=0;row=0;lx=0;ly=0; square=0;p=0;
        sprite_addr=0;sprite_on=0;cursor_edge=0;
        on_board=x>=24 && x<408 && y>=64 && y<448;
        // Comparators replace division by square size in the pixel-critical path.
        for(i=1;i<8;i=i+1) begin
            if(x>=24+i*48) col=i;
            if(y>=64+i*48) row=i;
        end
        lx=int'(x)-24-col*48; ly=int'(y)-64-row*48;
        if(x>=20 && x<412 && y>=60 && y<452) rgb=12'h111;
        if(x>=428 && x<624 && y>=64 && y<448) rgb=12'h333;
        if(on_board) begin
            square={(3'd7-row[2:0]),col[2:0]};
            if(AUTO_FLIP && side) square=square ^ 6'd63;
            p=piece(board,square);
            rgb=(col[0]^row[0]) ? 12'h795 : 12'hedc;
            if(last_valid && (square==last_src || square==last_dst)) rgb=(col[0]^row[0]) ? 12'ha95 : 12'hdd8;
            if(selected_valid && square==selected) rgb=12'hcb5;
            if(in_check && p=={side,KING}) rgb=12'hc55;
            if(legal_mask[square]) begin
                if(p==0 && lx>=20 && lx<28 && ly>=20 && ly<28 &&
                    (lx>=22 && lx<26 || ly>=22 && ly<26 || lx>=21 && lx<27 && ly>=21 && ly<27)) rgb=12'h576;
                if(p!=0 && ((lx<4 || lx>=44) && (ly<12 || ly>=36) || (ly<4 || ly>=44) && (lx<12 || lx>=36))) rgb=12'hbd7;
            end
            sprite_on=p[2:0]!=0 && lx>=8 && lx<40 && ly>=8 && ly<40;
            if(sprite_on) sprite_addr={p[2:0],5'(ly-8),5'(lx-8)};
            cursor_edge=square==cursor && (lx<2 || lx>=46 || ly<2 || ly>=46);
        end
        if(x>=440 && x<612 && (y==136 || y==208 || y==300)) rgb=12'h555;
    end
    always_ff @(posedge clk) begin
        sprite_q<=sprites[sprite_addr]; rgb_q<=rgb; sprite_on_q<=sprite_on;
        black_q<=p[3]; cursor_q<=cursor_edge; active_q<=active; hs_q<=hs; vs_q<=vs;
        hs2<=hs_q;vs2<=vs_q;active2<=active_q;
        hs3<=hs2;vs3<=vs2;active3<=active2;rgb3<=rgb2;
        hsync<=hs3;vsync<=vs3;
        display_active<=!reset && active3;
        if(reset || !active3) {red,green,blue}<=0;
        else {red,green,blue}<=text_ink ? text_color : rgb3;
        if(cursor_q) rgb2<=CURSOR_RGB;
        else if(sprite_on_q && sprite_q!=0) begin
            if(black_q) rgb2<=sprite_q==1 ? 12'h888 : 12'h222;
            else rgb2<=sprite_q==1 ? 12'h444 : 12'hfff;
        end else rgb2<=rgb_q;
    end
endmodule
