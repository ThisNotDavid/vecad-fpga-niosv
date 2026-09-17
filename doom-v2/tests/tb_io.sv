`timescale 1ns/1ps
module tb_io;
    reg clk=0,reset=1;always #10 clk=~clk;
    reg [15:0] address=0;reg read=0,write=0;reg [31:0] writedata=0;reg [3:0] byteenable=15;
    wire [31:0] readdata;reg ps2_clk=1,ps2_dat=1;
    wire [7:0] vga_r,vga_g,vga_b;wire vga_clk,vga_hs,vga_vs,vga_blank_n,vga_sync_n;
    doom_io dut(.*);
    integer i,red=0,green=0,blue=0,yellow=0,total=0;
    reg collect=0;reg [31:0] value;
    task put(input [15:0] a,input [31:0] d);
        begin @(negedge clk);address=a;writedata=d;write=1;@(negedge clk);write=0;end
    endtask
    task get(input [15:0] a);
        begin @(negedge clk);address=a;read=1;@(negedge clk);value=readdata;read=0;end
    endtask
    task keybit(input bit b);
        begin ps2_dat=b;#20000;ps2_clk=0;#20000;ps2_clk=1;end
    endtask
    task keybyte(input [7:0] b,input bit bad);
        integer k;begin keybit(0);for(k=0;k<8;k=k+1)keybit(b[k]);keybit((~^b)^bad);keybit(1);#30000;end
    endtask
    always @(posedge vga_clk) if(collect)begin
        if(vga_blank_n)begin
            total=total+1;
            case({vga_r,vga_g,vga_b})
                24'hff0000:red=red+1;24'h00ff00:green=green+1;
                24'h0000ff:blue=blue+1;24'hffff00:yellow=yellow+1;
                default:$fatal(1,"Unexpected pixel %h",{vga_r,vga_g,vga_b});
            endcase
        end else if({vga_r,vga_g,vga_b}!==24'b0)$fatal(1,"Blanking color");
    end
    initial begin
        repeat(5)@(negedge clk);reset=0;
        get(16'h8405);if(value!==32'h444f4f4d)$fatal(1,"ID");
        for(i=0;i<16000;i=i+1)put(16'h4000+i,32'h04030201);
        put(16'h8101,24'hff0000);put(16'h8102,24'h00ff00);
        put(16'h8103,24'h0000ff);put(16'h8104,24'hffff00);
        put(16'h8401,3);get(16'h8400);if(value[1:0]!=2)$fatal(1,"Swap not pending");
        // Writes during a pending swap must not corrupt its submitted frame.
        put(16'h4000,0);put(16'h8101,0);
        wait(dut.pending==0);get(16'h8400);if(value[2:0]!=5)$fatal(1,"Swap acknowledgment");
        @(negedge vga_vs);collect=1;@(negedge vga_vs);collect=0;
        if(total!=256000||red!=64000||green!=64000||blue!=64000||yellow!=64000)
            $fatal(1,"Raster counts %d %d %d %d %d",total,red,green,blue,yellow);
        keybyte(8'he0,0);keybyte(8'h75,0);get(16'h8403);if(value!=32'h1e0)$fatal(1,"PS2 E0");
        get(16'h8403);if(value!=32'h175)$fatal(1,"PS2 75");get(16'h8403);if(value!=0)$fatal(1,"PS2 empty");
        keybyte(8'h12,1);get(16'h8404);if(!value[1])$fatal(1,"Parity error not reported");
        put(16'h8404,2);get(16'h8404);if(value!=0)$fatal(1,"W1C");
        get(16'h8402);if(value<30)$fatal(1,"Timer");
        $display("PASS VGA 256000 pixels, palette, lane scaling, swap protection, PS2 FIFO and errors, timer");$finish;
    end
    initial begin #80000000;$fatal(1,"Timeout");end
endmodule
