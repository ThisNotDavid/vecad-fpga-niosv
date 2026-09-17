module game_controller #(parameter bit AUTO_FLIP=0)(
    input logic clk, reset,
    input logic command_valid,
    input logic [7:0] command,
    output logic command_ready,
    output logic [255:0] board,
    output logic side,
    output logic [5:0] cursor, selected, last_src, last_dst,
    output logic selected_valid, last_valid,
    output logic [63:0] legal_mask,
    output logic in_check, mate, stalemate, promotion_pending, busy,
    output logic [15:0] ply_count
);
    import chess_pkg::*;
    typedef enum logic [3:0] {WAIT_INPUT,SELECT_START,SELECT_WAIT,MOVE_START,MOVE_WAIT,
        STATUS_KING,STATUS_ATTACK_START,STATUS_ATTACK_WAIT,STATUS_START,STATUS_WAIT,PROMOTE} state_t;
    state_t state;
    logic [3:0] rights, next_rights;
    logic ep_valid,next_ep_valid;
    logic [5:0] ep_square,next_ep_square,check_src,check_dst,status_king;
    logic [2:0] promotion;
    logic check_start,check_done,move_legal;
    logic [255:0] next_board;
    logic status_start,status_done,status_attacked;
    wire flipped=AUTO_FLIP && side;
    wire [7:0] screen_command=flipped ? (command=="w" ? "s" : command=="s" ? "w" : command=="a" ? "d" : command=="d" ? "a" : command) : command;
    wire [3:0] cursor_piece=piece(board,cursor);
    wire [3:0] selected_piece=piece(board,selected);
    assign command_ready=state==WAIT_INPUT || state==PROMOTE;
    assign busy=!command_ready;
    assign promotion_pending=state==PROMOTE;
    move_checker checker_unit(.clk,.reset,.start(check_start),.board,.side,.rights,.ep_valid,.ep_square,
        .src(check_src),.dst(check_dst),.promotion,.done(check_done),.legal(move_legal),
        .result_board(next_board),.result_rights(next_rights),.result_ep_valid(next_ep_valid),.result_ep_square(next_ep_square));
    attack_detector status_detector(.clk,.reset,.start(status_start),.board,.target(status_king),
        .by_black(~side),.done(status_done),.attacked(status_attacked));
    always_ff @(posedge clk) begin
        if(reset) begin
            board<=INITIAL_BOARD; side<=0; rights<=15; ep_valid<=0; ep_square<=0;
            cursor<=12; selected<=0; selected_valid<=0; last_valid<=0; last_src<=0; last_dst<=0;
            legal_mask<=0; in_check<=0; mate<=0; stalemate<=0; ply_count<=0;
            state<=WAIT_INPUT; check_start<=0; status_start<=0;
            check_src<=0; check_dst<=0; status_king<=0; promotion<=QUEEN;
        end else begin
            check_start<=0; status_start<=0;
            case(state)
                WAIT_INPUT: if(command_valid) begin
                    case(screen_command)
                        "w": if(cursor[5:3]!=7) cursor<=cursor+6'd8;
                        "s": if(cursor[5:3]!=0) cursor<=cursor-6'd8;
                        "a": if(cursor[2:0]!=0) cursor<=cursor-1'b1;
                        "d": if(cursor[2:0]!=7) cursor<=cursor+1'b1;
                        "x": begin selected_valid<=0; legal_mask<=0; end
                        "e",8'h0d,8'h20: if(!mate && !stalemate) begin
                            if(selected_valid && cursor==selected) begin selected_valid<=0; legal_mask<=0; end
                            else if(cursor_piece!=0 && cursor_piece[3]==side) begin
                                selected<=cursor; selected_valid<=1; legal_mask<=0;
                                check_src<=cursor; check_dst<=0; promotion<=QUEEN; state<=SELECT_START;
                            end else if(selected_valid && legal_mask[cursor]) begin
                                check_src<=selected; check_dst<=cursor;
                                if(selected_piece[2:0]==PAWN && (cursor[5:3]==0 || cursor[5:3]==7)) state<=PROMOTE;
                                else begin promotion<=QUEEN; state<=MOVE_START; end
                            end
                        end
                        "!": begin
                            board<=INITIAL_BOARD; side<=0; rights<=15; ep_valid<=0;
                            cursor<=12; selected_valid<=0; last_valid<=0; legal_mask<=0;
                            in_check<=0; mate<=0; stalemate<=0; ply_count<=0;
                        end
                        default: begin end
                    endcase
                end
                SELECT_START: begin check_start<=1; state<=SELECT_WAIT; end
                SELECT_WAIT: if(check_done) begin
                    legal_mask[check_dst]<=move_legal;
                    if(check_dst==63) state<=WAIT_INPUT;
                    else begin check_dst<=check_dst+1'b1; state<=SELECT_START; end
                end
                PROMOTE: if(command_valid) begin
                    case(command)
                        "1","2","3","4": begin
                            case(command)
                                "1": promotion<=QUEEN;
                                "2": promotion<=ROOK;
                                "3": promotion<=BISHOP;
                                "4": promotion<=KNIGHT;
                            endcase
                            state<=MOVE_START;
                        end
                        "x": state<=WAIT_INPUT;
                        default: begin end
                    endcase
                end
                MOVE_START: begin check_start<=1; state<=MOVE_WAIT; end
                MOVE_WAIT: if(check_done) begin
                    if(move_legal) begin
                        board<=next_board; rights<=next_rights; ep_valid<=next_ep_valid; ep_square<=next_ep_square;
                        side<=~side; last_src<=check_src; last_dst<=check_dst; last_valid<=1;
                        selected_valid<=0; legal_mask<=0; ply_count<=ply_count+1'b1;
                        status_king<=0; state<=STATUS_KING;
                    end else state<=WAIT_INPUT;
                end
                STATUS_KING: if(piece(board,status_king)=={side,KING}) state<=STATUS_ATTACK_START;
                    else if(status_king==63) begin mate<=1; state<=WAIT_INPUT; end
                    else status_king<=status_king+1'b1;
                STATUS_ATTACK_START: begin status_start<=1; state<=STATUS_ATTACK_WAIT; end
                STATUS_ATTACK_WAIT: if(status_done) begin
                    in_check<=status_attacked; check_src<=0; check_dst<=0; promotion<=QUEEN; state<=STATUS_START;
                end
                STATUS_START: begin check_start<=1; state<=STATUS_WAIT; end
                STATUS_WAIT: if(check_done) begin
                    if(move_legal) state<=WAIT_INPUT;
                    else if(check_dst==63) begin
                        if(check_src==63) begin mate<=in_check; stalemate<=!in_check; state<=WAIT_INPUT; end
                        else begin check_src<=check_src+1'b1; check_dst<=0; state<=STATUS_START; end
                    end else begin check_dst<=check_dst+1'b1; state<=STATUS_START; end
                end
                default: state<=WAIT_INPUT;
            endcase
        end
    end
endmodule
