module checkerboard_renderer (
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       active_video,

    input  wire [2:0] piece_row,
    input  wire [2:0] piece_col,

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    // =========================================================
    // Board geometry
    // =========================================================

    localparam BOARD_X     = 120;
    localparam BOARD_Y     = 40;
    localparam BOARD_SIZE  = 400;
    localparam SQUARE_SIZE = 50;


    wire board_area;

    wire [9:0] board_x;
    wire [9:0] board_y;

    wire [2:0] board_row;
    wire [2:0] board_col;

    wire dark_square;


    // =========================================================
    // Board area
    // =========================================================

    assign board_area =
        (h_count >= BOARD_X) &&
        (h_count <  BOARD_X + BOARD_SIZE) &&
        (v_count >= BOARD_Y) &&
        (v_count <  BOARD_Y + BOARD_SIZE);


    // Pixel position relative to board
    assign board_x = h_count - BOARD_X;
    assign board_y = v_count - BOARD_Y;


    // Current board square
    assign board_col = board_x / SQUARE_SIZE;
    assign board_row = board_y / SQUARE_SIZE;


    // Checker pattern
    assign dark_square =
        board_row[0] ^ board_col[0];


    // =========================================================
    // Position inside current 50 x 50 square
    // =========================================================

    wire [5:0] square_x;
    wire [5:0] square_y;

    assign square_x = board_x % SQUARE_SIZE;
    assign square_y = board_y % SQUARE_SIZE;


    // =========================================================
    // Circular piece
    //
    // Centre = (25,25)
    // Radius = 18
    // =========================================================

    wire signed [6:0] dx;
    wire signed [6:0] dy;

    wire signed [13:0] dx_squared;
    wire signed [13:0] dy_squared;

    wire [14:0] distance_squared;

    wire inside_piece_circle;


    assign dx =
        $signed({1'b0, square_x}) - 7'sd25;

    assign dy =
        $signed({1'b0, square_y}) - 7'sd25;


    assign dx_squared = dx * dx;
    assign dy_squared = dy * dy;


    assign distance_squared =
        dx_squared + dy_squared;


    assign inside_piece_circle =
        (distance_squared <= 15'd324);


    // =========================================================
    // Nios-controlled piece position
    // =========================================================

    wire selected_square;

    assign selected_square =
        board_area &&
        (board_row == piece_row) &&
        (board_col == piece_col);


    wire draw_piece;

    assign draw_piece =
        selected_square &&
        inside_piece_circle;


    // =========================================================
    // VGA renderer
    // =========================================================

    always @(*) begin

        VGA_R = 8'h00;
        VGA_G = 8'h00;
        VGA_B = 8'h00;


        if (active_video) begin

            // -------------------------------------------------
            // Nios-controlled piece
            // -------------------------------------------------

            if (draw_piece) begin

                VGA_R = 8'hE0;
                VGA_G = 8'h20;
                VGA_B = 8'h20;

            end


            // -------------------------------------------------
            // Checkerboard
            // -------------------------------------------------

            else if (board_area) begin

                if (dark_square) begin

                    VGA_R = 8'd70;
                    VGA_G = 8'd70;
                    VGA_B = 8'd70;

                end
                else begin

                    VGA_R = 8'd220;
                    VGA_G = 8'd220;
                    VGA_B = 8'd220;

                end

            end


            // -------------------------------------------------
            // Background
            // -------------------------------------------------

            else begin

                VGA_R = 8'd20;
                VGA_G = 8'd20;
                VGA_B = 8'd20;

            end

        end

    end

endmodule