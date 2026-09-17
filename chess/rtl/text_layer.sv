// Three pipeline stages: choose line -> select character -> font row.
// All character cells use power-of-two dimensions; no pixel-path division.
module text_layer #(parameter bit PS2_CONTROL=0, parameter bit AUTO_FLIP=0)(
    input logic clk,
    input logic [9:0] x,y,
    input logic side,selected_valid,in_check,mate,stalemate,promotion_pending,
    input logic restart_pending,
    output logic ink,
    output logic [11:0] color
);
    `include "font_function.svh"
    logic [191:0] line_text,line_q;
    logic [4:0] index,index_q;
    logic [2:0] gx,gy,gx1,gy1,gx2,gy2,gx3;
    logic enabled,en1,en2,en3;
    logic [7:0] char_q;
    logic [4:0] bits_q;
    logic [11:0] tint,tint1,tint2;
    logic [9:0] sx,sy;
    integer c,r,j;
    always_comb begin
        line_text="                        ";index=0;gx=0;gy=0;enabled=0;tint=12'hbbb;
        sx=x-10'd440;sy=y; c=0;r=0;
        if(x>=440 && x<616) begin
            index=sx[7:3];gx=sx[2:0];gy=y[2:0];enabled=1;
            case(y[9:3])
                10: begin line_text="BLACK                   ";tint=12'haaa;end
                19: begin line_text="WHITE                   ";tint=12'haaa;end
                32: begin
                    if(restart_pending) line_text="ENTER CONFIRM           ";
                    else if(mate) line_text=side ? "WHITE WINS              " : "BLACK WINS              ";
                    else if(stalemate) line_text="STALEMATE               ";
                    else if(promotion_pending) line_text="1 QUEEN  2 ROOK         ";
                    else line_text=selected_valid ? "CHOOSE DESTINATION      " : "SELECT A PIECE          ";
                end
                34: if(restart_pending) line_text="ESC CANCEL              ";
                    else if(promotion_pending) line_text="3 BISHOP 4 KNIGHT       ";
                40: line_text="ARROWS / WASD           ";
                43: line_text="ENTER SELECT / MOVE     ";
                46: line_text="ESC   CANCEL            ";
                49: line_text="F2    NEW GAME          ";
                53: begin line_text=PS2_CONTROL ? "PS/2 KEYBOARD           " : "USB-BLASTER CONTROL     ";tint=12'h9b8;end
                default: enabled=0;
            endcase
            // Large labels have 16x16 character cells, with 2x font pixels.
            if(y>=96 && y<112) begin
                line_text=side ? "YOUR TURN               " : "WAITING                 ";
                enabled=1; index={1'b0,sx[7:4]};gx=sx[3:1];gy=y[3:1];tint=side ? 12'heee : 12'h888;
            end
            if(y>=176 && y<192) begin
                line_text=side ? "WAITING                 " : "YOUR TURN               ";
                enabled=1;index={1'b0,sx[7:4]};gx=sx[3:1];gy=y[3:1];tint=side ? 12'h888 : 12'heee;
            end
            if(y>=224 && y<240) begin
                enabled=1;index={1'b0,sx[7:4]};gx=sx[3:1];gy=y[3:1];tint=12'hbd7;
                if(restart_pending) begin line_text="NEW GAME                ";tint=12'h69f;end
                else if(mate) begin line_text="CHECKMATE               ";tint=12'hf98;end
                else if(stalemate) line_text="DRAW                    ";
                else if(promotion_pending) line_text="PROMOTE                 ";
                else if(in_check) begin line_text="CHECK                   ";tint=12'hf98;end
                else line_text="PLAY                    ";
            end
        end
        if(x>=24 && x<200 && y>=16 && y<32) begin
            sx=x-10'd24;line_text="VECAD CHESS             ";
            enabled=1;index={1'b0,sx[7:4]};gx=sx[3:1];gy=y[3:1];tint=12'heee;
        end
        if(x>=440 && x<616 && y>=24 && y<32) begin
            sx=x-10'd440;line_text="FPGA / LOCAL PLAY       ";
            enabled=1;index=sx[7:3];gx=sx[2:0];gy=y[2:0];tint=12'h9b8;
        end
        for(j=1;j<8;j=j+1) begin
            if(x>=24+j*48) c=j;
            if(y>=64+j*48) r=j;
        end
        if(y>=456 && y<464 && x>=44+c*48 && x<52+c*48 && x<408) begin
            sx=x-10'(44+c*48);line_text={8'((AUTO_FLIP && side) ? 72-c : 65+c),184'd0};
            enabled=1;index=0;gx=sx[2:0];gy=y[2:0];tint=12'haaa;
        end
        if(x>=8 && x<16 && y>=84+r*48 && y<92+r*48 && y<448) begin
            sy=y-10'(84+r*48);line_text={8'((AUTO_FLIP && side) ? 49+r : 56-r),184'd0};
            enabled=1;index=0;gx=x[2:0];gy=sy[2:0];tint=12'haaa;
        end
    end
    always_ff @(posedge clk) begin
        line_q<=line_text;index_q<=index;gx1<=gx;gy1<=gy;en1<=enabled;tint1<=tint;
        char_q<=line_q[191-index_q*8 -: 8];gx2<=gx1;gy2<=gy1;en2<=en1;tint2<=tint1;
        bits_q<=font_row(char_q,gy2);gx3<=gx2;en3<=en2;color<=tint2;
    end
    assign ink=en3 && gx3<5 && bits_q[4-gx3];
endmodule
