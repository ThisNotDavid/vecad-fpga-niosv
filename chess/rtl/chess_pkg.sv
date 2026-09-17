package chess_pkg;
    localparam [2:0] EMPTY=0, PAWN=1, KNIGHT=2, BISHOP=3, ROOK=4, QUEEN=5, KING=6;
    // Four bits per square: {black, kind}; a1 is square 0.
    localparam [255:0] INITIAL_BOARD = 256'hcabedbac99999999000000000000000000000000000000001111111142365324;
    function automatic [3:0] piece(input [255:0] b, input [5:0] sq);
        piece = b[sq*4 +: 4];
    endfunction
    function automatic integer abs_i(input integer v);
        abs_i = v < 0 ? -v : v;
    endfunction
    function automatic signed [6:0] direction(input [5:0] src, dst);
        integer dx,dy;
        begin
            dx = int'(dst[2:0])-int'(src[2:0]);
            dy = int'(dst[5:3])-int'(src[5:3]);
            direction = 7'((dx>0 ? 1 : dx<0 ? -1 : 0) + (dy>0 ? 8 : dy<0 ? -8 : 0));
        end
    endfunction
    function automatic logic attacks_geometry(input [3:0] p, input [5:0] src,dst);
        integer dx,dy,ax,ay;
        begin
            dx=int'(dst[2:0])-int'(src[2:0]); dy=int'(dst[5:3])-int'(src[5:3]);
            ax=abs_i(dx); ay=abs_i(dy);
            attacks_geometry=0;
            if (src!=dst) case(p[2:0])
                PAWN: attacks_geometry=(ax==1 && dy==(p[3] ? -1 : 1));
                KNIGHT: attacks_geometry=(ax==1 && ay==2)||(ax==2 && ay==1);
                BISHOP: attacks_geometry=ax==ay;
                ROOK: attacks_geometry=dx==0 || dy==0;
                QUEEN: attacks_geometry=dx==0 || dy==0 || ax==ay;
                KING: attacks_geometry=ax<=1 && ay<=1;
                default: attacks_geometry=0;
            endcase
        end
    endfunction
endpackage
