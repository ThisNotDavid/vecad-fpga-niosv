module vga_timing (
    input  wire       clk_50,
    input  wire       reset_n,

    output wire       pixel_clk,
    output reg  [9:0] h_count,
    output reg  [9:0] v_count,
    output wire       active_video,

    output wire       VGA_HS,
    output wire       VGA_VS,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N,
    output wire       VGA_CLK
);

    reg pixel_clk_reg;

    // 50 MHz -> 25 MHz
    always @(posedge clk_50 or negedge reset_n) begin
        if (!reset_n)
            pixel_clk_reg <= 1'b0;
        else
            pixel_clk_reg <= ~pixel_clk_reg;
    end

    assign pixel_clk = pixel_clk_reg;
    assign VGA_CLK   = pixel_clk_reg;

    // Horizontal / vertical counters
    always @(posedge pixel_clk_reg or negedge reset_n) begin
        if (!reset_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count == 10'd799) begin
                h_count <= 10'd0;

                if (v_count == 10'd524)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    assign active_video =
        (h_count < 10'd640) &&
        (v_count < 10'd480);

    assign VGA_HS =
        ~((h_count >= 10'd656) &&
          (h_count <  10'd752));

    assign VGA_VS =
        ~((v_count >= 10'd490) &&
          (v_count <  10'd492));

    assign VGA_BLANK_N = active_video;
    assign VGA_SYNC_N  = 1'b0;

endmodule