`timescale 1ns/1ps
module tb_render;
    import chess_pkg::*;
    logic clk=0,reset=1;
    always #10 clk=~clk;
    logic [9:0] x=0,y=0;
    logic active=1,hs=1,vs=1;
    logic [255:0] board=INITIAL_BOARD;
    logic side=0,selected_valid=1,last_valid=0,in_check=0,mate=0,stalemate=0,promotion_pending=0;
    logic restart_pending=0;
    wire display_active;
    logic [5:0] cursor=12,selected=12,last_src=0,last_dst=0;
    logic [63:0] legal_mask=(64'b1<<20)|(64'b1<<28);
    wire [3:0] red,green,blue;
    wire hsync,vsync;
    integer f,px,py,mode,orientation,sq;
    reg [511:0] filename;
`ifdef DE2_115
    chess_renderer #(.CURSOR_RGB(12'h36f),.PS2_CONTROL(1),.AUTO_FLIP(1)) dut(.*);
`else
    chess_renderer dut(.*);
`endif
    initial begin
`ifdef DE2_115
        // Exhaustive board and coordinate mapping in both viewing orientations.
        for(orientation=0;orientation<2;orientation++) begin
            side=orientation;
            for(sq=0;sq<64;sq++) begin
                x=24+(sq%8)*48;y=64+(sq/8)*48;#1;
                if(dut.square !== (orientation ? (sq ^ 7) : (sq ^ 56)))
                    $fatal(1,"Board mapping orientation=%0d screen=%0d",orientation,sq);
                if(dut.cursor_edge !== (dut.square==cursor)) $fatal(1,"Cursor mapping");
            end
            for(sq=0;sq<8;sq++) begin
                x=44+sq*48;y=456;#1;
                if(dut.text_display.line_text[191:184] != (orientation ? 72-sq : 65+sq)) $fatal(1,"File label");
                x=8;y=84+sq*48;#1;
                if(dut.text_display.line_text[191:184] != (orientation ? 49+sq : 56-sq)) $fatal(1,"Rank label");
            end
        end
        side=0;
`endif
        mode=0;
        if($value$plusargs("MODE=%d",mode)) begin end
        case(mode)
            1: begin mate=1;in_check=1;selected_valid=0;legal_mask=0;end
            2: begin promotion_pending=1;selected_valid=0;legal_mask=0;end
            3: begin stalemate=1;selected_valid=0;legal_mask=0;end
            4: begin restart_pending=1;selected_valid=0;legal_mask=0;end
            5: begin side=1;board[12*4 +: 4]=0;board[28*4 +: 4]=1;cursor=52;selected=52;legal_mask=(64'b1<<44)|(64'b1<<36);last_valid=1;last_src=12;last_dst=28;end
        endcase
        $sformat(filename,"build/frame_%0d.ppm",mode);
        repeat(5) @(negedge clk);reset=0;
        f=$fopen(filename,"wb");$fwrite(f,"P6\n640 480\n255\n");
        for(py=0;py<480;py++) for(px=0;px<640;px++) begin
            x=px;y=py;repeat(4) @(negedge clk);
            if((^{red,green,blue,hsync,vsync})===1'bx) $fatal(1,"Unknown pixel %d %d rgb=%h%h%h hs=%b vs=%b ink=%b base=%h",px,py,red,green,blue,hsync,vsync,dut.text_ink,dut.rgb3);
            $fwrite(f,"%c%c%c",{red,red},{green,green},{blue,blue});
        end
        active=0;hs=0;vs=0;repeat(4) @(negedge clk);
        if({red,green,blue}!=0 || hsync || vsync) $fatal(1,"Output blanking or sync delay incorrect");
        $fclose(f);$display("PASS renderer: frame mode %0d and blanking",mode);$finish;
    end
endmodule
