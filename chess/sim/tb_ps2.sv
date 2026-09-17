`timescale 1ns/1ps
module tb_ps2;
    logic clk=0,reset=1,ps2_clk=1,ps2_data=1;
    always #10 clk=~clk;
    wire [7:0] data,command;
    wire data_valid,frame_error,command_valid;
    integer received=0,errors=0,commands=0,old_count,i;
    reg [7:0] last_byte,last_command;
    ps2_receiver #(.TIMEOUT_CYCLES(500)) rx(.*);
    ps2_decoder #(.REPEAT_CYCLES(5000),.PREFIX_TIMEOUT(2000)) dec(.*);
    always @(negedge clk) begin
        if(data_valid) begin received++;last_byte=data;end
        if(frame_error) errors++;
        if(command_valid) begin commands++;last_command=command;end
    end
    task automatic bit_clock(input logic bit_value);
        begin
            ps2_data=bit_value;repeat(12) @(negedge clk);
            ps2_clk=0;repeat(20) @(negedge clk);
            ps2_clk=1;repeat(20) @(negedge clk);
        end
    endtask
    task automatic byte_frame(input [7:0] value,input logic bad_parity,bad_stop);
        integer bit_index;
        begin
            bit_clock(0);
            for(bit_index=0;bit_index<8;bit_index++) bit_clock(value[bit_index]);
            bit_clock((~^value)^bad_parity);bit_clock(!bad_stop);
            ps2_data=1;repeat(20) @(negedge clk);
        end
    endtask
    task automatic scan(input [7:0] value);begin byte_frame(value,0,0);end endtask
    task automatic expect_delta(input integer before_count,delta,input [7:0] expected);
        begin
            if(commands!=before_count+delta || (delta!=0 && last_command!=expected))
                $fatal(1,"Command mismatch before=%0d now=%0d delta=%0d expected=%h last=%h",before_count,commands,delta,expected,last_command);
        end
    endtask
    initial begin
        repeat(5) @(negedge clk);reset=0;repeat(20) @(negedge clk);
        // A short clock glitch must not begin a frame.
        ps2_data=0;ps2_clk=0;repeat(2) @(negedge clk);ps2_clk=1;ps2_data=1;
        repeat(600) @(negedge clk);if(received || errors) $fatal(1,"Clock filter failed");
        old_count=commands;scan(8'he0);scan(8'h75);expect_delta(old_count,1,"w");
        old_count=commands;scan(8'he0);scan(8'h75);expect_delta(old_count,0,0);
        repeat(5100) @(negedge clk);
        scan(8'he0);scan(8'h75);expect_delta(old_count,1,"w");
        scan(8'he0);scan(8'hf0);scan(8'h75);
        old_count=commands;scan(8'he0);scan(8'h75);expect_delta(old_count,1,"w");
        old_count=commands;scan(8'h5a);expect_delta(old_count,1,"e");
        repeat(5100) @(negedge clk);scan(8'h5a);expect_delta(old_count,1,"e");
        scan(8'hf0);scan(8'h5a);scan(8'h5a);expect_delta(old_count,2,"e");
        // Extended keypad Enter has its own press/release state.
        old_count=commands;scan(8'he0);scan(8'h5a);expect_delta(old_count,1,"e");
        old_count=commands;scan(8'h06);scan(8'h06);expect_delta(old_count,1,"r");
        scan(8'hf0);scan(8'h06);
        old_count=commands;scan(8'h16);scan(8'h1e);scan(8'h26);scan(8'h25);expect_delta(old_count,4,"4");
        old_count=commands;scan(8'h1d);scan(8'h1b);scan(8'h1c);scan(8'h23);expect_delta(old_count,4,"d");
        old_count=commands;scan(8'h75);scan(8'h12);expect_delta(old_count,0,0);
        // Pause's entire eight-byte sequence is ignored.
        scan(8'he1);scan(8'h14);scan(8'h77);scan(8'he1);scan(8'hf0);scan(8'h14);scan(8'hf0);scan(8'h77);
        expect_delta(old_count,0,0);
        // Bad parity and stop bits must never become a command.
        i=received;byte_frame(8'h76,1,0);byte_frame(8'h76,0,1);
        if(received!=i || errors!=2) $fatal(1,"Frame validation failed");
        scan(8'h76);expect_delta(old_count,1,"x");
        // Partial frames time out; the following start bit resynchronizes.
        bit_clock(0);bit_clock(1);ps2_data=1;repeat(510) @(negedge clk);
        if(errors!=3) $fatal(1,"Partial-frame timeout failed");
        scan(8'h29);expect_delta(old_count,2,"e");
        // A stranded E0 prefix expires without interpreting a later keypad key as an arrow.
        old_count=commands;scan(8'he0);repeat(2100) @(negedge clk);scan(8'h75);expect_delta(old_count,0,0);
        // Keyboard reboot clears held-key tracking.
        scan(8'haa);scan(8'h5a);expect_delta(old_count,1,"e");
        $display("PASS PS/2: framing, filtering, parity/stop/timeout, prefixes, arrows/WASD, make/break, typematic, Pause, reboot");$finish;
    end
endmodule
