`timescale 1ns/1ps
module tb_de2_video;
    logic clk=0,reset=1;
    always #10 clk=~clk;
    wire pixel_enable,active,hs,vs,frame_start;
    wire [9:0] x,y;
    logic [3:0] red=3,green=6,blue=15;
    wire [7:0] VGA_R,VGA_G,VGA_B;
    wire VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N;
    integer rises=0;
    realtime last_rise=0;
    vga_timing timing(.*);
    de2_vga_output adapter(.*);
    always @(posedge VGA_CLK) if(!reset) begin
        if(rises>0 && $realtime-last_rise!=40) $fatal(1,"DAC clock period incorrect");
        last_rise=$realtime;rises++;
        if({VGA_R,VGA_G,VGA_B}!==24'h3366ff) $fatal(1,"Blue RGB mapping failed");
        if(VGA_BLANK_N!==active || VGA_SYNC_N!==0) $fatal(1,"DAC controls wrong");
    end
    initial begin
        repeat(4) @(negedge clk);#1;reset=0;
        repeat(4000) @(negedge clk);
        if(rises!=2000) $fatal(1,"DAC did not receive one clock per pixel: %d",rises);
        $display("PASS DE2 VGA: 25 MHz forwarded clock, 8-bit RGB expansion, DAC controls");$finish;
    end
endmodule
