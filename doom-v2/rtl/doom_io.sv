// Single 50 MHz domain, 25 MHz pixel enable. Avalon word address, 32-bit data.
// Byte offsets: FB0 0, FB1 0x10000; PAL0 0x20000, PAL1 0x20400;
// 0x21000 status: bit0 front bank, bit1 pending, bit2 enabled;
// 0x21004 submit: bit0 bank, bit1 enable; 0x21008 milliseconds;
// 0x2100c PS/2 pop: bit8 valid; 0x21010 errors W1C: bit0 overflow bit1 frame.
module doom_io(
    input wire clk, reset,
    input wire [15:0] address,
    input wire read,write,
    input wire [31:0] writedata,
    input wire [3:0] byteenable,
    output reg [31:0] readdata,
    input wire ps2_clk,ps2_dat,
    output wire [7:0] vga_r,vga_g,vga_b,
    output reg vga_clk,
    output wire vga_hs,vga_vs,vga_blank_n,vga_sync_n
);
    // Four byte lanes infer simple dual-port M9Ks; 65536 bytes per bank.
    (* ramstyle="M9K" *) reg [7:0] lane0[0:32767],lane1[0:32767],lane2[0:32767],lane3[0:32767];
    (* ramstyle="M9K" *) reg [23:0] palettes[0:511];
    reg front,pending,requested,enabled,requested_enable;
    reg [9:0] x,y;
    reg phase;
    wire vblank=phase && x==0 && y==480;
    wire visible=x<640 && y>=40 && y<440;
    wire [15:0] pixel_address=((y-10'd40)>>1)*16'd320+(x>>1);
    wire [14:0] scan_word={front,pixel_address[15:2]};
    reg [7:0] p0,p1,p2,p3;
    reg [1:0] lane_sel;
    wire [7:0] index=lane_sel==0 ? p0 : lane_sel==1 ? p1 : lane_sel==2 ? p2 : p3;
    reg [23:0] rgb;
    reg hs1,vs1,act1,hs2,vs2,act2,hs3,vs3;
    reg [15:0] ms_div;
    reg [31:0] milliseconds;
    wire [7:0] key_byte;
    wire key_valid,key_error;
    reg [7:0] fifo[0:255];
    reg [7:0] wr_ptr,rd_ptr;
    reg [8:0] count;
    reg overflow,frame_error;
    wire pop=read && address==16'h8403 && count!=0;
    wire push=key_valid && (count!=256 || pop);
    ps2_receiver receiver(.clk(clk),.reset(reset),.ps2_clk(ps2_clk),.ps2_data(ps2_dat),
        .data(key_byte),.data_valid(key_valid),.frame_error(key_error));
    assign vga_r=act2 ? rgb[23:16] : 8'b0;
    assign vga_g=act2 ? rgb[15:8] : 8'b0;
    assign vga_b=act2 ? rgb[7:0] : 8'b0;
    assign vga_blank_n=act2;
    assign vga_hs=hs3;assign vga_vs=vs3;assign vga_sync_n=0;
    // Pixel RGB is registered at phase=0; the DAC captures half a cycle later.
    always @(negedge clk) if(reset) vga_clk<=0;else vga_clk<=phase;
    always @(posedge clk) begin
        // Independent RAM read/write ports; never reset RAM arrays.
        p0<=lane0[scan_word];p1<=lane1[scan_word];p2<=lane2[scan_word];p3<=lane3[scan_word];
        lane_sel<=pixel_address[1:0];
        rgb<=palettes[{front,index}];
        hs1<=!(x>=656 && x<752);vs1<=!(y>=490 && y<492);act1<=visible && enabled;
        hs2<=hs1;vs2<=vs1;act2<=act1;hs3<=hs2;vs3<=vs2;
        if(write && address<16'h8000 && address[14]!=front && !pending) begin
            if(byteenable[0]) lane0[address[14:0]]<=writedata[7:0];
            if(byteenable[1]) lane1[address[14:0]]<=writedata[15:8];
            if(byteenable[2]) lane2[address[14:0]]<=writedata[23:16];
            if(byteenable[3]) lane3[address[14:0]]<=writedata[31:24];
        end
        if(write && address>=16'h8000 && address<16'h8200 && address[8]!=front && !pending)
            palettes[address[8:0]]<=writedata[23:0];
        if(reset) begin
            front<=0;pending<=0;requested<=0;enabled<=0;requested_enable<=0;
            phase<=0;x<=0;y<=0;milliseconds<=0;ms_div<=0;
            wr_ptr<=0;rd_ptr<=0;count<=0;overflow<=0;frame_error<=0;readdata<=0;
            hs1<=1;hs2<=1;hs3<=1;vs1<=1;vs2<=1;vs3<=1;act1<=0;act2<=0;
        end else begin
            phase<=~phase;
            if(phase) begin
                if(x==799) begin x<=0;y<=y==524 ? 10'd0 : y+1'b1;end
                else x<=x+1'b1;
            end
            if(ms_div==49999) begin ms_div<=0;milliseconds<=milliseconds+1'b1;end
            else ms_div<=ms_div+1'b1;
            if(write && address==16'h8401 && byteenable[0] && !pending) begin
                requested<=writedata[0];requested_enable<=writedata[1];pending<=1;
            end
            if(vblank && pending) begin front<=requested;enabled<=requested_enable;pending<=0;end
            if(write && address==16'h8404 && byteenable[0]) begin
                if(writedata[0]) overflow<=0;
                if(writedata[1]) frame_error<=0;
            end
            if(key_error) frame_error<=1;
            if(key_valid && !push) overflow<=1;
            if(push) begin fifo[wr_ptr]<=key_byte;wr_ptr<=wr_ptr+1'b1;end
            if(pop) rd_ptr<=rd_ptr+1'b1;
            case({push,pop})
                2'b10: count<=count+1'b1;
                2'b01: count<=count-1'b1;
                default: ;
            endcase
            // Read latency 1, no waitrequest. Framebuffer aperture is write-only.
            readdata<=0;
            if(read) case(address)
                16'h8400: readdata<={29'b0,enabled,pending,front};
                16'h8402: readdata<=milliseconds;
                16'h8403: readdata<=count!=0 ? {23'b0,1'b1,fifo[rd_ptr]} : 0;
                16'h8404: readdata<={30'b0,frame_error,overflow};
                16'h8405: readdata<=32'h444f4f4d;
                default: readdata<=0;
            endcase
        end
    end
endmodule
