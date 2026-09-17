module vga_test (
    input  wire       clk_50,
    input  wire       reset_n,
    input  wire [2:0] color_select,

    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS,
    output wire       VGA_CLK,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N
);

    // ---------------------------------------------------------
    // 50 MHz -> 25 MHz pixel clock
    // ---------------------------------------------------------
    reg pixel_clk;

    always @(posedge clk_50 or negedge reset_n) begin
        if (!reset_n)
            pixel_clk <= 1'b0;
        else
            pixel_clk <= ~pixel_clk;
    end

    assign VGA_CLK = pixel_clk;

    // ---------------------------------------------------------
    // VGA counters
    // ---------------------------------------------------------
    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge pixel_clk or negedge reset_n) begin
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

    // ---------------------------------------------------------
    // Active display region
    // ---------------------------------------------------------
    wire active_video;

    assign active_video =
        (h_count < 10'd640) &&
        (v_count < 10'd480);

    // ---------------------------------------------------------
    // Synchronisation
    // Active low
    // ---------------------------------------------------------
    assign VGA_HS =
        ~((h_count >= 10'd656) &&
          (h_count <  10'd752));

    assign VGA_VS =
        ~((v_count >= 10'd490) &&
          (v_count <  10'd492));

    // ---------------------------------------------------------
    // DE2-115 VGA control
    // ---------------------------------------------------------
    assign VGA_BLANK_N = active_video;
    assign VGA_SYNC_N  = 1'b0;

    // ---------------------------------------------------------
    // Colour controlled by Nios V
    //
    // color_select[2] = Red
    // color_select[1] = Green
    // color_select[0] = Blue
    // ---------------------------------------------------------
    assign VGA_R =
        active_video && color_select[2]
        ? 8'hFF
        : 8'h00;

    assign VGA_G =
        active_video && color_select[1]
        ? 8'hFF
        : 8'h00;

    assign VGA_B =
        active_video && color_select[0]
        ? 8'hFF
        : 8'h00;

endmodule