module vga_timing (
    input  wire       clk_50,
    input  wire       reset_n,

    output reg  [9:0] h_count,
    output reg  [9:0] v_count,
    output wire       active_video,

    output wire       VGA_HS,
    output wire       VGA_VS,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N,
    output wire       VGA_CLK
);

    // =========================================================
    // Internal pixel clock
    //
    // Input clock : 50 MHz
    // Pixel clock : 25 MHz
    // =========================================================

    reg pixel_clk_reg;

    always @(posedge clk_50 or negedge reset_n) begin

        if (!reset_n)
            pixel_clk_reg <= 1'b0;

        else
            pixel_clk_reg <= ~pixel_clk_reg;

    end


    // VGA DAC receives the same 25 MHz pixel clock
    assign VGA_CLK = pixel_clk_reg;


    // =========================================================
    // VGA timing parameters
    //
    // 640 x 480 @ approximately 60 Hz
    //
    // Horizontal:
    // Visible      = 640
    // Front porch  = 16
    // Sync pulse   = 96
    // Back porch   = 48
    // Total        = 800
    //
    // Vertical:
    // Visible      = 480
    // Front porch  = 10
    // Sync pulse   = 2
    // Back porch   = 33
    // Total        = 525
    // =========================================================


    // =========================================================
    // Horizontal and vertical counters
    // =========================================================

    always @(posedge pixel_clk_reg or negedge reset_n) begin

        if (!reset_n) begin

            h_count <= 10'd0;
            v_count <= 10'd0;

        end

        else begin

            // End of horizontal line
            if (h_count == 10'd799) begin

                h_count <= 10'd0;

                // End of entire frame
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


    // =========================================================
    // Active video region
    //
    // Visible pixels:
    // X = 0 ... 639
    // Y = 0 ... 479
    // =========================================================

    assign active_video =
        (h_count < 10'd640) &&
        (v_count < 10'd480);


    // =========================================================
    // Horizontal sync
    //
    // Active-low pulse:
    //
    // 640 + 16 = 656
    // 656 + 96 = 752
    //
    // Sync interval:
    // 656 ... 751
    // =========================================================

    assign VGA_HS =
        ~((h_count >= 10'd656) &&
          (h_count <  10'd752));


    // =========================================================
    // Vertical sync
    //
    // Active-low pulse:
    //
    // 480 + 10 = 490
    // 490 + 2  = 492
    //
    // Sync interval:
    // 490 ... 491
    // =========================================================

    assign VGA_VS =
        ~((v_count >= 10'd490) &&
          (v_count <  10'd492));


    // =========================================================
    // VGA control signals
    // =========================================================

    assign VGA_BLANK_N = active_video;

    assign VGA_SYNC_N = 1'b0;


endmodule