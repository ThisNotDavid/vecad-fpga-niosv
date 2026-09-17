`timescale 1ns/1ps
module tb_transport;
    logic clk=0,reset=1,command_ready=0;
    always #10 clk=~clk;
    wire [7:0] command;
    wire command_valid,activity,av_address,av_chipselect,av_read_n,av_write_n;
    wire [31:0] av_writedata;
    logic [31:0] av_readdata=0;
    logic av_waitrequest=1;
    integer reads=0,writes=0,consumed=0,tick=0;
    reg [7:0] seq [0:3];
    jtag_transport dut(.*);
    // Model the IP's registered waitrequest and data-valid behavior.
    always @(posedge clk) begin
        if(reset) begin av_waitrequest<=1;av_readdata<=0;end
        else begin
            tick<=tick+1;
            av_waitrequest<=!(av_chipselect && (!av_read_n || !av_write_n) && av_waitrequest);
            if(av_chipselect && av_waitrequest) begin
                if(!av_read_n) begin
                    if(av_address) av_readdata<=tick<150 ? 0 : 32'h00400000;
                    else if(reads<4) begin av_readdata<=32'h8000|seq[reads];reads<=reads+1;end
                    else av_readdata<=0;
                end
                if(!av_write_n) begin
                    if(writes>=4 || av_writedata[7:0]!==seq[writes]) $fatal(1,"Bad echo");
                    writes<=writes+1;
                end
            end
            if(command_valid && command_ready) begin
                if(consumed>=4 || command!==seq[consumed]) $fatal(1,"Dropped/duplicated command");
                consumed<=consumed+1;
            end
        end
    end
    initial begin
        seq[0]="w";seq[1]="e";seq[2]="x";seq[3]="?";
        repeat(3) @(negedge clk);reset=0;
        repeat(60) @(negedge clk);
        if(reads!=1 || consumed!=0 || !command_valid || command!="w") $fatal(1,"Backpressure failed");
        command_ready=1;
        repeat(500) @(negedge clk);
        if(consumed!=4 || writes!=4) $fatal(1,"Transport did not complete");
        $display("PASS transport: waitrequest, backpressure, full TX FIFO, ordered echo");$finish;
    end
endmodule
