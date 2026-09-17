`timescale 1ns/1ps
module tb_io_bus;
    parameter READ_WAIT=0;
    reg clk=0,reset=1; always #10 clk=~clk;
    reg [31:0] request_address=0;
    reg request_read=0;
    wire waitrequest,valid;
    wire [31:0] response,readdata,writedata;
    wire [15:0] address;
    wire [3:0] byteenable;
    wire read,write;
    integer pulses=0,i;
    doom_io dut(.clk(clk),.reset(reset),.address(address),.read(read),.write(write),
        .writedata(writedata),.byteenable(byteenable),.readdata(readdata),.ps2_clk(1'b1),.ps2_dat(1'b1));
    altera_merlin_slave_translator #(.AV_ADDRESS_W(16),.UAV_ADDRESS_W(32),
        .AV_BURSTCOUNT_W(1),.UAV_BURSTCOUNT_W(3),.AV_READLATENCY(1),
        .AV_READ_WAIT_CYCLES(READ_WAIT),.USE_READDATAVALID(0),.USE_WAITREQUEST(0)) bridge(
        .clk(clk),.reset(reset),.uav_address(request_address),.uav_read(request_read),
        .uav_write(1'b0),.uav_writedata(32'b0),.uav_byteenable(4'hf),.uav_burstcount(3'd4),
        .uav_lock(1'b0),.uav_debugaccess(1'b0),.uav_clken(1'b1),
        .uav_waitrequest(waitrequest),.uav_readdatavalid(valid),.uav_readdata(response),
        .av_address(address),.av_read(read),.av_write(write),.av_writedata(writedata),
        .av_byteenable(byteenable),.av_readdata(readdata),.av_readdatavalid(1'b0),
        .av_waitrequest(1'b0),.av_response(2'b0),.av_writeresponsevalid(1'b0));
    always @(posedge clk) if(!reset && read) pulses=pulses+1;
    initial begin
        repeat(5) @(negedge clk); reset=0;
        repeat(3) @(negedge clk);
        for(i=0;i<100;i=i+1) begin
            pulses=0;request_address=32'h21014;request_read=1;
            @(posedge clk);while(waitrequest) @(posedge clk);
            @(negedge clk);request_read=0;
            if(!valid || response!==32'h444f4f4d) $fatal(1,"Read response timing");
            if(pulses!=1) $fatal(1,"One request produced %d peripheral read strobes",pulses);
            @(negedge clk);
        end
        $display("PASS vendor Avalon translator: 100 responses, exactly one read strobe per request");
        $finish;
    end
    initial begin #100000;$fatal(1,"Timeout");end
endmodule
