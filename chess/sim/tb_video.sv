`timescale 1ns/1ps
module tb_video;
    logic clk=0,reset=1;
    always #10 clk=~clk;
    wire pixel_enable,active,hs,vs,frame_start;
    wire [9:0] x,y;
    integer pixels,visible,hs_low,vs_low,frames;
    vga_timing dut(.*);
    initial begin
        repeat(3) @(negedge clk);reset=0;
        pixels=0;visible=0;hs_low=0;vs_low=0;frames=0;
        repeat(800*525*2) begin
            @(negedge clk);
            if(pixel_enable) begin
                pixels++;if(active) visible++;if(!hs) hs_low++;if(!vs) vs_low++;
                if(frame_start) frames++;
            end
        end
        if(pixels!=420000 || visible!=307200 || hs_low!=96*525 || vs_low!=2*800 || frames!=1)
            $fatal(1,"VGA timing wrong pixels=%d active=%d hs=%d vs=%d frame=%d",pixels,visible,hs_low,vs_low,frames);
        $display("PASS video: 800x525 raster, 640x480 active, correct sync widths");$finish;
    end
endmodule
