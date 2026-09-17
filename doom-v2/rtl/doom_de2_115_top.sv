module doom_de2_115_top(
    input wire CLOCK_50,input wire [0:0] KEY,
    input wire PS2_CLK,PS2_DAT,
    output wire [7:0] VGA_R,VGA_G,VGA_B,
    output wire VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,
    output wire [12:0] DRAM_ADDR, output wire [1:0] DRAM_BA,
    output wire DRAM_CAS_N,DRAM_RAS_N,DRAM_WE_N,DRAM_CS_N,DRAM_CKE,DRAM_CLK,
    output wire [3:0] DRAM_DQM,inout wire [31:0] DRAM_DQ
);
    wire debug_reset;
    reg [2:0] power_reset=3'b111;
    always @(posedge CLOCK_50 or negedge KEY[0])
        if(!KEY[0]) power_reset<=3'b111;else power_reset<={power_reset[1:0],1'b0};
    assign DRAM_CLK=~CLOCK_50;
    doom_system system_inst(
        .clk_clk(CLOCK_50),.reset_reset_n(!(power_reset[2] || debug_reset)),
        .debug_reset_reset(debug_reset),
        .io_ps2_clk(PS2_CLK),.io_ps2_dat(PS2_DAT),
        .io_vga_r(VGA_R),.io_vga_g(VGA_G),.io_vga_b(VGA_B),
        .io_vga_clk(VGA_CLK),.io_vga_hs(VGA_HS),.io_vga_vs(VGA_VS),
        .io_vga_blank_n(VGA_BLANK_N),.io_vga_sync_n(VGA_SYNC_N),
        .dram_addr(DRAM_ADDR),.dram_ba(DRAM_BA),.dram_cas_n(DRAM_CAS_N),
        .dram_ras_n(DRAM_RAS_N),.dram_we_n(DRAM_WE_N),.dram_cs_n(DRAM_CS_N),
        .dram_cke(DRAM_CKE),.dram_dqm(DRAM_DQM),.dram_dq(DRAM_DQ),.dram_ready()
    );
endmodule
