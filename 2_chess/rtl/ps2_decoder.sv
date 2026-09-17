// Scan-code set 2: E0 extended keys, F0 releases, E1 Pause sequence suppression.
// Typematic repeats move the cursor at most once per 120 ms. Other commands
// require a release between makes, including Enter/Space/F2/promotion.
module ps2_decoder #(
    parameter integer REPEAT_CYCLES=6000000,
    parameter integer PREFIX_TIMEOUT=1000000
)(
    input logic clk,reset,
    input logic [7:0] data,
    input logic data_valid,frame_error,
    output logic [7:0] command,
    output logic command_valid
);
    logic extended,released;
    logic [2:0] pause_remaining;
    logic [16:0] pressed;
    logic [$clog2(REPEAT_CYCLES+1)-1:0] repeat_timer;
    logic [$clog2(PREFIX_TIMEOUT+1)-1:0] prefix_timer;
    logic [4:0] key_index;
    logic [7:0] mapped;
    logic movement;
    always_comb begin
        mapped=0;key_index=0;movement=0;
        case({extended,data})
            9'h175: begin mapped="w";key_index=0;movement=1;end
            9'h172: begin mapped="s";key_index=1;movement=1;end
            9'h16b: begin mapped="a";key_index=2;movement=1;end
            9'h174: begin mapped="d";key_index=3;movement=1;end
            9'h01d: begin mapped="w";key_index=4;movement=1;end
            9'h01b: begin mapped="s";key_index=5;movement=1;end
            9'h01c: begin mapped="a";key_index=6;movement=1;end
            9'h023: begin mapped="d";key_index=7;movement=1;end
            9'h05a: begin mapped="e";key_index=8;end
            9'h15a: begin mapped="e";key_index=9;end
            9'h029: begin mapped="e";key_index=10;end
            9'h076: begin mapped="x";key_index=11;end
            9'h016: begin mapped="1";key_index=12;end
            9'h01e: begin mapped="2";key_index=13;end
            9'h026: begin mapped="3";key_index=14;end
            9'h025: begin mapped="4";key_index=15;end
            9'h006: begin mapped="r";key_index=16;end
            default: begin end
        endcase
    end
    always_ff @(posedge clk) begin
        if(reset) begin
            extended<=0;released<=0;pause_remaining<=0;pressed<=0;
            repeat_timer<=0;prefix_timer<=0;command<=0;command_valid<=0;
        end else begin
            command_valid<=0;
            if(repeat_timer!=0) repeat_timer<=repeat_timer-1'b1;
            if(extended || released || pause_remaining!=0) begin
                if(prefix_timer==PREFIX_TIMEOUT-1) begin
                    extended<=0;released<=0;pause_remaining<=0;prefix_timer<=0;
                end else prefix_timer<=prefix_timer+1'b1;
            end else prefix_timer<=0;
            if(frame_error) begin
                extended<=0;released<=0;pause_remaining<=0;pressed<=0;prefix_timer<=0;
            end else if(data_valid) begin
                prefix_timer<=0;
                if(data==8'haa) begin // Keyboard power-on/self-test complete.
                    extended<=0;released<=0;pause_remaining<=0;pressed<=0;
                end else if(pause_remaining!=0) pause_remaining<=pause_remaining-1'b1;
                else if(data==8'he1) begin pause_remaining<=7;extended<=0;released<=0;end
                else if(data==8'he0) extended<=1;
                else if(data==8'hf0) released<=1;
                else begin
                    extended<=0;released<=0;
                    if(mapped!=0) begin
                        if(released) pressed[key_index]<=0;
                        else begin
                            pressed[key_index]<=1;
                            if(!pressed[key_index] || (movement && repeat_timer==0)) begin
                                command<=mapped;command_valid<=1;
                                if(movement) repeat_timer<=$bits(repeat_timer)'(REPEAT_CYCLES);
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
