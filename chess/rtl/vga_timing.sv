// 50 MHz system clock; 25 MHz pixel enable, 800 x 525 total raster.
module vga_timing(input logic clk,reset,
    output logic pixel_enable, output logic [9:0] x,y,
    output logic active,hs,vs,frame_start);
    always_ff @(posedge clk) begin
        if(reset) begin pixel_enable<=0; x<=0; y<=0; end
        else begin
            pixel_enable<=~pixel_enable;
            if(pixel_enable) begin
                if(x==799) begin x<=0; y<=y==524 ? 10'd0 : y+1'b1; end
                else x<=x+1'b1;
            end
        end
    end
    assign active=x<640 && y<480;
    assign hs=!(x>=656 && x<752);
    assign vs=!(y>=490 && y<492);
    assign frame_start=pixel_enable && x==0 && y==480;
endmodule
