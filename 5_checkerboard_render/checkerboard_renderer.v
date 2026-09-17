module checkerboard_renderer (
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       active_video,

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    // Board:
    // 400 x 400 pixels
    // centred in 640 x 480
    localparam BOARD_X = 120;
    localparam BOARD_Y = 40;
    localparam BOARD_SIZE = 400;
    localparam SQUARE_SIZE = 50;

    wire board_area;

    wire [9:0] board_x;
    wire [9:0] board_y;

    wire [2:0] board_col;
    wire [2:0] board_row;

    wire dark_square;


    assign board_area =
        (h_count >= BOARD_X) &&
        (h_count < BOARD_X + BOARD_SIZE) &&
        (v_count >= BOARD_Y) &&
        (v_count < BOARD_Y + BOARD_SIZE);


    assign board_x = h_count - BOARD_X;
    assign board_y = v_count - BOARD_Y;


    assign board_col = board_x / SQUARE_SIZE;
    assign board_row = board_y / SQUARE_SIZE;


    assign dark_square =
        board_row[0] ^ board_col[0];


    always @(*) begin

        // Default black
        VGA_R = 8'h00;
        VGA_G = 8'h00;
        VGA_B = 8'h00;

        if (active_video) begin

            if (board_area) begin

                if (dark_square) begin

                    // Dark square
                    VGA_R = 8'd70;
                    VGA_G = 8'd70;
                    VGA_B = 8'd70;

                end
                else begin

                    // Light square
                    VGA_R = 8'd220;
                    VGA_G = 8'd220;
                    VGA_B = 8'd220;

                end

            end
            else begin

                // Background
                VGA_R = 8'd20;
                VGA_G = 8'd20;
                VGA_B = 8'd20;

            end

        end
    end

endmodule