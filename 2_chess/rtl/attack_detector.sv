// Sequential scan: one candidate piece or one ray square per cycle.
// Inputs must remain stable from start through done.
module attack_detector(
    input logic clk, reset, start,
    input logic [255:0] board,
    input logic [5:0] target,
    input logic by_black,
    output logic done, attacked
);
    import chess_pkg::*;
    typedef enum logic [1:0] {IDLE,SCAN,RAY,NEXT} state_t;
    state_t state;
    logic [5:0] index, ray;
    logic signed [6:0] step;
    wire [3:0] p=piece(board,index);
    always_ff @(posedge clk) begin
        if(reset) begin state<=IDLE; done<=0; attacked<=0; index<=0; ray<=0; step<=0; end
        else begin
            done<=0;
            case(state)
                IDLE: if(start) begin index<=0; attacked<=0; state<=SCAN; end
                SCAN: begin
                    if(p[2:0]!=EMPTY && p[3]==by_black && attacks_geometry(p,index,target)) begin
                        if(p[2:0]==BISHOP || p[2:0]==ROOK || p[2:0]==QUEEN) begin
                            step<=direction(index,target); ray<=6'(index+direction(index,target)); state<=RAY;
                        end else begin attacked<=1; done<=1; state<=IDLE; end
                    end else state<=NEXT;
                end
                RAY: if(ray==target) begin attacked<=1; done<=1; state<=IDLE; end
                    else if(piece(board,ray)!=0) state<=NEXT;
                    else ray<=6'(ray+step);
                NEXT: if(index==63) begin done<=1; state<=IDLE; end
                    else begin index<=index+1'b1; state<=SCAN; end
            endcase
        end
    end
endmodule
