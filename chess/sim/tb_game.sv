`timescale 1ns/1ps
module tb_game #(parameter bit AUTO_FLIP=0);
    import chess_pkg::*;
    logic clk=0,reset=1,command_valid=0;
    always #10 clk=~clk;
    logic [7:0] command=0;
    wire command_ready,side,selected_valid,last_valid,in_check,mate,stalemate,promotion_pending,busy;
    wire [255:0] board;
    wire [63:0] legal_mask;
    wire [5:0] cursor,selected,last_src,last_dst;
    wire [15:0] ply_count;
    logic [255:0] fixture;
    integer choice;
    game_controller #(.AUTO_FLIP(AUTO_FLIP)) dut(.*);
    task automatic idle;
        integer timeout;
        begin
            timeout=0;
            while(!command_ready && timeout<1000000) begin @(negedge clk); timeout++;end
            if(!command_ready) $fatal(1,"Game controller timeout");
        end
    endtask
    task automatic key(input [7:0] k);
        begin idle();@(negedge clk);command=k;command_valid=1;@(negedge clk);command_valid=0;idle();end
    endtask
    task automatic go(input [5:0] sq);
        begin
            while(cursor[2:0]<sq[2:0]) key(AUTO_FLIP && side ? "a" : "d");
            while(cursor[2:0]>sq[2:0]) key(AUTO_FLIP && side ? "d" : "a");
            while(cursor[5:3]<sq[5:3]) key(AUTO_FLIP && side ? "s" : "w");
            while(cursor[5:3]>sq[5:3]) key(AUTO_FLIP && side ? "w" : "s");
        end
    endtask
    task automatic move(input [5:0] a,b);
        begin go(a);key("e"); if(!legal_mask[b]) $fatal(1,"Move missing from UI mask: %0d-%0d",a,b);go(b);key("e");end
    endtask
    initial begin
        repeat(3) @(negedge clk);reset=0;
        if(board!==INITIAL_BOARD) $fatal(1,"Initial position wrong");
        go(12);key("e");
        if(legal_mask!==((64'b1<<20)|(64'b1<<28))) $fatal(1,"e2 destinations wrong %h",legal_mask);
        go(36);key("e");if(board!==INITIAL_BOARD) $fatal(1,"Illegal e2-e5 changed board");
        key("x"); if(selected_valid || legal_mask) $fatal(1,"Cancel failed");
        if(side) $fatal(1,"Invalid move or cancel changed orientation");
        if(AUTO_FLIP) begin
            move(12,28);if(!side) $fatal(1,"White move did not flip");
            go(0);key("d");key("w");if(cursor!=0) $fatal(1,"Black view a1 edge");
            go(63);key("a");key("s");if(cursor!=63) $fatal(1,"Black view h8 edge");
            move(52,36);if(side) $fatal(1,"Black move did not restore white view");
            key("!");
        end
        // Fool's mate, entirely through the public keyboard interface.
        move(13,21);move(52,36);move(14,30);move(59,31);
        if(!mate || !in_check || side!=0 || ply_count!=4) $fatal(1,"Fool's mate not detected");
        go(12);key("e");if(selected_valid) $fatal(1,"Game accepted move after mate");
        key("!");if(board!==INITIAL_BOARD || mate || ply_count) $fatal(1,"Restart failed");
        go(0);key(AUTO_FLIP && side ? "d" : "a");key(AUTO_FLIP && side ? "w" : "s");if(cursor!=0) $fatal(1,"Cursor wrapped at a1");
        go(63);key(AUTO_FLIP && side ? "a" : "d");key(AUTO_FLIP && side ? "s" : "w");if(cursor!=63) $fatal(1,"Cursor wrapped at h8");
        // Directed fixtures are testbench-only; the production interface cannot load positions.
        for(choice=1;choice<=4;choice++) begin
            key("!");@(negedge clk);
            fixture=0;fixture[4*4 +: 4]=6;fixture[60*4 +: 4]=14;fixture[48*4 +: 4]=1;
            dut.board=fixture;dut.rights=0;
            move(48,56);
            if(!promotion_pending || side || board!==fixture) $fatal(1,"Promotion must wait for choice");
            key("x");if(promotion_pending || side || !selected_valid) $fatal(1,"Promotion cancellation failed");
            key("e");if(!promotion_pending) $fatal(1,"Promotion reselection failed");
            key(8'd48+choice);
            case(choice)
                1: if(piece(board,56)!=QUEEN) $fatal(1,"Queen promotion failed");
                2: if(piece(board,56)!=ROOK) $fatal(1,"Rook promotion failed");
                3: if(piece(board,56)!=BISHOP) $fatal(1,"Bishop promotion failed");
                4: if(piece(board,56)!=KNIGHT) $fatal(1,"Knight promotion failed");
            endcase
            if(!side || piece(board,48)!=0) $fatal(1,"Promotion commit failed");
        end
        key("!");@(negedge clk);
        fixture=0;fixture[53*4 +: 4]=6;fixture[38*4 +: 4]=5;fixture[63*4 +: 4]=14;
        dut.board=fixture;dut.rights=0;
        move(38,46);
        if(!stalemate || mate || in_check) $fatal(1,"Stalemate controller result wrong");
        key("!");@(negedge clk);
        fixture=0;fixture[4*4 +: 4]=6;fixture[60*4 +: 4]=14;fixture[36*4 +: 4]=1;fixture[35*4 +: 4]=9;
        dut.board=fixture;dut.rights=0;dut.ep_valid=1;dut.ep_square=43;
        move(36,43);
        if(piece(board,35)!=0 || piece(board,43)!=1 || dut.ep_valid) $fatal(1,"En passant commit failed");
        key("!");@(negedge clk);
        fixture=0;fixture[4*4 +: 4]=6;fixture[60*4 +: 4]=14;fixture[7*4 +: 4]=4;
        dut.board=fixture;dut.rights=1;
        move(4,6);
        if(piece(board,6)!=6 || piece(board,5)!=4 || piece(board,7)!=0 || dut.rights!=0) $fatal(1,"Castling commit failed");
        $display("PASS game: input, Fool's mate, stalemate, all promotions/cancel, en passant, castling, restart");$finish;
    end
endmodule
