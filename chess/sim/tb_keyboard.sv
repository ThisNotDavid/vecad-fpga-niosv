`timescale 1ns/1ps
module tb_keyboard;
    import chess_pkg::*;
    logic clk=0,reset=1,input_valid=0;
    always #10 clk=~clk;
    logic [7:0] input_command=0;
    wire [7:0] command;
    wire command_valid,command_ready,restart_pending,restart_pulse,overflow,activity;
    wire [255:0] board;
    wire side,selected_valid,last_valid,in_check,mate,stalemate,promotion_pending,busy;
    wire [5:0] cursor,selected,last_src,last_dst;
    wire [63:0] legal_mask;
    wire [15:0] ply_count;
    wire game_reset=reset || restart_pulse;
    integer n;
    logic [255:0] saved_board;
    keyboard_commands adapter(.*);
    game_controller game(.clk,.reset(game_reset),.command,.command_valid,.command_ready,.board,.side,.cursor,.selected,
        .last_src,.last_dst,.selected_valid,.last_valid,.legal_mask,.in_check,.mate,.stalemate,.promotion_pending,.busy,.ply_count);
    task automatic send(input [7:0] value);
        begin @(negedge clk);input_command=value;input_valid=1;@(negedge clk);input_valid=0;end
    endtask
    task automatic settle;
        integer timeout;
        begin
            timeout=0;repeat(4) @(negedge clk);
            while((busy || adapter.count!=0 || restart_pulse) && timeout<1000000) begin @(negedge clk);timeout++;end
            if(timeout==1000000) $fatal(1,"Keyboard/game timeout");
        end
    endtask
    initial begin
        repeat(4) @(negedge clk);reset=0;
        // Queue navigation while legal-move generation backpressures the input.
        send("e");send("w");send("w");send("e");settle();
        if(piece(board,28)!=PAWN || piece(board,12)!=0 || side!=1 || ply_count!=1 || overflow)
            $fatal(1,"Buffered e2-e4 failed");
        saved_board=board;
        send("r");settle();if(!restart_pending) $fatal(1,"F2 modal missing");
        send("w");send("1");settle();if(board!==saved_board || cursor!=28) $fatal(1,"Modal leaked input");
        send("x");settle();if(restart_pending || board!==saved_board) $fatal(1,"Cancel reset game");
        send("r");send("e");send("w");settle();
        if(board!==INITIAL_BOARD || cursor!=12 || ply_count || restart_pending) $fatal(1,"Confirm/reset queue flush failed");
        // F2 also works during promotion without committing the pawn.
        @(negedge clk);game.board=0;game.board[16 +: 4]=6;game.board[240 +: 4]=14;game.board[192 +: 4]=1;
        game.cursor=48;game.rights=0;
        send("e");settle();send("w");send("e");settle();
        if(!promotion_pending) $fatal(1,"Promotion fixture failed");
        saved_board=board;send("r");settle();send("x");settle();
        if(!promotion_pending || board!==saved_board) $fatal(1,"Modal cancel lost promotion state");
        send("r");send("e");settle();if(board!==INITIAL_BOARD || promotion_pending) $fatal(1,"Restart from promotion failed");
        // Deliberately exceed FIFO capacity while the engine is busy.
        send("e");for(n=0;n<24;n++) send("d");settle();
        if(!overflow || cursor[2:0]!=7) $fatal(1,"Overflow handling failed");
        $display("PASS keyboard adapter: busy buffering, modal confirmation/cancel, promotion restart, stale queue flush, overflow");$finish;
    end
endmodule
