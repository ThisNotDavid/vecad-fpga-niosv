// Full move legality and resulting position. Board and request stable until done.
// rights bits: white king/queen side, black king/queen side.
module move_checker(
    input logic clk, reset, start,
    input logic [255:0] board,
    input logic side,
    input logic [3:0] rights,
    input logic ep_valid,
    input logic [5:0] ep_square, src, dst,
    input logic [2:0] promotion,
    output logic done, legal,
    output logic [255:0] result_board,
    output logic [3:0] result_rights,
    output logic result_ep_valid,
    output logic [5:0] result_ep_square
);
    import chess_pkg::*;
    typedef enum logic [3:0] {IDLE,VALIDATE,RAY,MAKE,MODIFY,FIND_KING,ATTACK_START,ATTACK_WAIT,FINISH} state_t;
    state_t state;
    logic [255:0] trial;
    logic [5:0] ray, scan, attack_target;
    logic signed [6:0] step;
    logic castle, enpassant;
    logic [1:0] phase;
    logic attack_start, attack_done, attacked;
    wire [3:0] mover=piece(board,src), victim=piece(board,dst);
    wire [5:0] home=side ? 6'd60 : 6'd4;
    wire [5:0] rook_src={src[5:3],(dst[2:0]==6 ? 3'd7 : 3'd0)};
    wire [5:0] rook_dst={src[5:3],(dst[2:0]==6 ? 3'd5 : 3'd3)};
    integer dx,dy;
    always_comb begin
        dx=int'(dst[2:0])-int'(src[2:0]);
        dy=int'(dst[5:3])-int'(src[5:3]);
    end
    attack_detector detector(.clk,.reset,.start(attack_start),.board(trial),
        .target(attack_target),.by_black(~side),.done(attack_done),.attacked);
    always_ff @(posedge clk) begin
        if(reset) begin
            state<=IDLE; done<=0; legal<=0; attack_start<=0;
            result_board<=0; result_rights<=0; result_ep_valid<=0; result_ep_square<=0;
            trial<=0; ray<=0; scan<=0; attack_target<=0; step<=0;
            castle<=0; enpassant<=0; phase<=0;
        end else begin
            done<=0; attack_start<=0;
            case(state)
                IDLE: if(start) begin legal<=0; castle<=0; enpassant<=0; phase<=0; state<=VALIDATE; end
                VALIDATE: begin
                    state<=FINISH;
                    if(src!=dst && mover[2:0]!=EMPTY && mover[3]==side &&
                       (victim[2:0]==EMPTY || (victim[3]!=side && victim[2:0]!=KING))) begin
                        case(mover[2:0])
                            PAWN: begin
                                if(dx==0 && dy==(side ? -1 : 1) && victim==0) state<=MAKE;
                                if(dx==0 && dy==(side ? -2 : 2) && src[5:3]==(side ? 6 : 1) && victim==0 &&
                                   piece(board,src+(side ? -6'd8 : 6'd8))==0) state<=MAKE;
                                if(abs_i(dx)==1 && dy==(side ? -1 : 1)) begin
                                    if(victim!=0) state<=MAKE;
                                    else if(ep_valid && dst==ep_square && src[5:3]==(side ? 3 : 4) &&
                                            piece(board,{src[5:3],dst[2:0]})=={~side,PAWN}) begin
                                        enpassant<=1; state<=MAKE;
                                    end
                                end
                            end
                            KNIGHT: if(attacks_geometry(mover,src,dst)) state<=MAKE;
                            BISHOP,ROOK,QUEEN: if(attacks_geometry(mover,src,dst)) begin
                                step<=direction(src,dst); ray<=6'(src+direction(src,dst)); state<=RAY;
                            end
                            KING: begin
                                if(attacks_geometry(mover,src,dst)) state<=MAKE;
                                else if(src==home && dy==0 && (dst[2:0]==2 || dst[2:0]==6) &&
                                    rights[(side ? 2 : 0)+(dst[2:0]==2 ? 1 : 0)] &&
                                    piece(board,rook_src)=={side,ROOK} &&
                                    piece(board,rook_dst)==0 && victim==0 &&
                                    (dst[2:0]==6 || piece(board,{src[5:3],3'd1})==0)) begin
                                    castle<=1; trial<=board; attack_target<=src; state<=ATTACK_START;
                                end
                            end
                            default: state<=FINISH;
                        endcase
                    end
                end
                RAY: if(ray==dst) state<=MAKE;
                     else if(piece(board,ray)!=0) state<=FINISH;
                     else ray<=6'(ray+step);
                MAKE: begin trial<=board; state<=MODIFY; end
                MODIFY: begin
                    trial[src*4 +: 4]<=0;
                    trial[dst*4 +: 4]<=mover;
                    if(enpassant) trial[({src[5:3],dst[2:0]})*4 +: 4]<=0;
                    if(castle) begin trial[rook_src*4 +: 4]<=0; trial[rook_dst*4 +: 4]<={side,ROOK}; end
                    if(mover[2:0]==PAWN && (dst[5:3]==0 || dst[5:3]==7)) begin
                        if(promotion==QUEEN || promotion==ROOK || promotion==BISHOP || promotion==KNIGHT)
                            trial[dst*4 +: 4]<={side,promotion};
                        else trial[dst*4 +: 4]<={side,QUEEN};
                    end
                    scan<=0; phase<=2; state<=FIND_KING;
                end
                FIND_KING: if(piece(trial,scan)=={side,KING}) begin
                    attack_target<=scan; state<=ATTACK_START;
                end else if(scan==63) state<=FINISH;
                else scan<=scan+1'b1;
                ATTACK_START: begin attack_start<=1; state<=ATTACK_WAIT; end
                ATTACK_WAIT: if(attack_done) begin
                    if(attacked) state<=FINISH;
                    else if(castle && phase==0) begin
                        trial[src*4 +: 4]<=0;
                        trial[rook_dst*4 +: 4]<=mover;
                        attack_target<=rook_dst; phase<=1; state<=ATTACK_START;
                    end else if(castle && phase==1) state<=MAKE;
                    else begin
                        legal<=1; result_board<=trial; result_rights<=rights;
                        if(mover[2:0]==KING) begin
                            if(side) result_rights[3:2]<=0; else result_rights[1:0]<=0;
                        end
                        // Captures on a rook's starting square revoke its right as well.
                        if(src==0 || dst==0) result_rights[1]<=0;
                        if(src==7 || dst==7) result_rights[0]<=0;
                        if(src==56 || dst==56) result_rights[3]<=0;
                        if(src==63 || dst==63) result_rights[2]<=0;
                        result_ep_valid<=mover[2:0]==PAWN && abs_i(dy)==2;
                        result_ep_square<=src+(side ? -6'd8 : 6'd8);
                        state<=FINISH;
                    end
                end
                FINISH: begin done<=1; state<=IDLE; end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
