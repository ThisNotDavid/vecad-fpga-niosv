// ADV7123 adapter: nibble replication maps 12'h36f to 24'h3366ff.
// RGB/blank are stable before the DAC clock's rising edge (half a system cycle
// after the renderer registers update). HS/VS bypass the DAC, so delay them by
// one pixel to match its documented one-clock conversion pipeline.
module de2_vga_output(
    input logic clk,reset,pixel_enable,
    input logic [3:0] red,green,blue,
    input logic hs,vs,active,
    output wire [7:0] VGA_R,VGA_G,VGA_B,
    output logic VGA_CLK,
    output wire VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N
);
    logic [1:0] hs_delay,vs_delay;
    always_ff @(negedge clk) begin
        if(reset) VGA_CLK<=0;
        else VGA_CLK<=pixel_enable;
    end
    always_ff @(posedge clk) begin
        if(reset) begin hs_delay<=2'b11;vs_delay<=2'b11;end
        else begin hs_delay<={hs_delay[0],hs};vs_delay<={vs_delay[0],vs};end
    end
    assign VGA_R={red,red};assign VGA_G={green,green};assign VGA_B={blue,blue};
    assign VGA_BLANK_N=active;
    assign VGA_SYNC_N=1'b0;
    assign VGA_HS=hs_delay[1];assign VGA_VS=vs_delay[1];
endmodule
