module checkerboard_renderer (
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       active_video,

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    // =========================================================
    // Checkerboard geometry
    //
    // VGA resolution : 640 x 480
    // Board size     : 400 x 400
    // Square size    : 50 x 50
    //
    // Board location:
    // X = 120 ... 519
    // Y =  40 ... 439
    // =========================================================

    localparam BOARD_X     = 120;
    localparam BOARD_Y     = 40;
    localparam BOARD_SIZE  = 400;
    localparam SQUARE_SIZE = 50;


    // =========================================================
    // Board position
    // =========================================================

    wire board_area;

    wire [9:0] board_x;
    wire [9:0] board_y;

    wire [2:0] board_col;
    wire [2:0] board_row;

    wire dark_square;


    // Check whether current pixel is inside checkerboard
    assign board_area =
        (h_count >= BOARD_X) &&
        (h_count <  BOARD_X + BOARD_SIZE) &&
        (v_count >= BOARD_Y) &&
        (v_count <  BOARD_Y + BOARD_SIZE);


    // Pixel coordinate relative to top-left of board
    assign board_x = h_count - BOARD_X;
    assign board_y = v_count - BOARD_Y;


    // Determine checkerboard row and column
    assign board_col = board_x / SQUARE_SIZE;
    assign board_row = board_y / SQUARE_SIZE;


    // Alternating checkerboard squares
    //
    // row 0: light dark light dark ...
    // row 1: dark light dark light ...
    assign dark_square =
        board_row[0] ^ board_col[0];


    // =========================================================
    // Position within individual 50 x 50 square
    //
    // square_x = 0 ... 49
    // square_y = 0 ... 49
    // =========================================================

    wire [5:0] square_x;
    wire [5:0] square_y;

    assign square_x = board_x % SQUARE_SIZE;
    assign square_y = board_y % SQUARE_SIZE;


    // =========================================================
    // Circular checker piece
    //
    // Centre of square = (25, 25)
    // Radius           = 18 pixels
    //
    // Circle equation:
    //
    // dx^2 + dy^2 <= 18^2
    //             <= 324
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
    // Initial checker piece arrangement
    //
    // Player A:
    //
    // row 0 : . A . A . A . A
    // row 1 : A . A . A . A .
    // row 2 : . A . A . A . A
    //
    //
    // Player B:
    //
    // row 5 : A-style opposite side
    // row 6
    // row 7
    //
    // Only dark squares contain pieces.
    // =========================================================

    wire player_a_square;
    wire player_b_square;


    // Player A occupies rows 0, 1, 2
    assign player_a_square =
        board_area &&
        dark_square &&
        (board_row <= 3'd2);


    // Player B occupies rows 5, 6, 7
    assign player_b_square =
        board_area &&
        dark_square &&
        (board_row >= 3'd5);


    // =========================================================
    // Final piece pixel detection
    // =========================================================

    wire draw_player_a;
    wire draw_player_b;


    assign draw_player_a =
        player_a_square &&
        inside_piece_circle;


    assign draw_player_b =
        player_b_square &&
        inside_piece_circle;


    // =========================================================
    // VGA Renderer
    //
    // Priority:
    //
    // Player A piece
    //       ↓
    // Player B piece
    //       ↓
    // Board square
    //       ↓
    // Background
    // =========================================================

    always @(*) begin

        // Default black
        VGA_R = 8'h00;
        VGA_G = 8'h00;
        VGA_B = 8'h00;


        if (active_video) begin

            // =================================================
            // Player A pieces
            // Red
            // =================================================

            if (draw_player_a) begin

                VGA_R = 8'hE0;
                VGA_G = 8'h20;
                VGA_B = 8'h20;

            end


            // =================================================
            // Player B pieces
            // Blue
            // =================================================

            else if (draw_player_b) begin

                VGA_R = 8'h20;
                VGA_G = 8'h40;
                VGA_B = 8'hE0;

            end


            // =================================================
            // Checkerboard
            // =================================================

            else if (board_area) begin

                // Dark square
                if (dark_square) begin

                    VGA_R = 8'd70;
                    VGA_G = 8'd70;
                    VGA_B = 8'd70;

                end

                // Light square
                else begin

                    VGA_R = 8'd220;
                    VGA_G = 8'd220;
                    VGA_B = 8'd220;

                end

            end


            // =================================================
            // Background outside checkerboard
            // =================================================

            else begin

                VGA_R = 8'd20;
                VGA_G = 8'd20;
                VGA_B = 8'd20;

            end

        end

    end

endmodule