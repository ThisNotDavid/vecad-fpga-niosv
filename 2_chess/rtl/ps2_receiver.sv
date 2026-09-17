// Receive-only PS/2 interface. Board pull-ups keep both lines high when idle.
// All state runs at clk; the asynchronous PS/2 clock is never used as a clock.
module ps2_receiver #(
    parameter integer FILTER_BITS=8,
    parameter integer TIMEOUT_CYCLES=100000 // 2 ms at 50 MHz, between frame edges
)(
    input logic clk,reset,ps2_clk,ps2_data,
    output logic [7:0] data,
    output logic data_valid,frame_error
);
    (* altera_attribute="-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] clock_sync=2'b11,data_sync=2'b11;
    logic [FILTER_BITS-1:0] clock_history;
    logic filtered_clock,previous_clock;
    logic [3:0] bit_count;
    logic [7:0] shift;
    logic parity_bit;
    localparam integer TIMER_BITS=$clog2(TIMEOUT_CYCLES+1);
    logic [TIMER_BITS-1:0] timer;
    wire falling=previous_clock && !filtered_clock;
    always_ff @(posedge clk) begin
        clock_sync<={clock_sync[0],ps2_clk};data_sync<={data_sync[0],ps2_data};
        if(reset) begin
            clock_history<='1;filtered_clock<=1;previous_clock<=1;
            bit_count<=0;shift<=0;parity_bit<=0;timer<=0;data<=0;data_valid<=0;frame_error<=0;
        end else begin
            clock_history<={clock_history[FILTER_BITS-2:0],clock_sync[1]};
            if(&clock_history) filtered_clock<=1;
            else if(~|clock_history) filtered_clock<=0;
            previous_clock<=filtered_clock;
            data_valid<=0;frame_error<=0;
            if(bit_count==0) timer<=0;
            else if(timer==TIMEOUT_CYCLES-1) begin bit_count<=0;timer<=0;frame_error<=1;end
            else timer<=timer+1'b1;
            if(falling) begin
                timer<=0;
                case(bit_count)
                    0: if(!data_sync[1]) bit_count<=1;
                    1,2,3,4,5,6,7,8: begin shift[bit_count-1'b1]<=data_sync[1];bit_count<=bit_count+1'b1;end
                    9: begin parity_bit<=data_sync[1];bit_count<=10;end
                    10: begin
                        bit_count<=0;
                        if(data_sync[1] && ((^shift)^parity_bit)) begin data<=shift;data_valid<=1;end
                        else frame_error<=1;
                    end
                    default: bit_count<=0;
                endcase
            end
        end
    end
endmodule
