// Avalon-MM host for the installed Altera JTAG UART IP.
// Echo every consumed command; the PC uses stop-and-wait to avoid stale input.
module jtag_transport(
    input logic clk, reset,
    output logic [7:0] command,
    output logic command_valid,
    input logic command_ready,
    output logic activity,
    output logic av_address, av_chipselect, av_read_n, av_write_n,
    output logic [31:0] av_writedata,
    input logic [31:0] av_readdata,
    input logic av_waitrequest
);
    typedef enum logic [2:0] {POLL,DELIVER,GAP,SPACE,WRITE,END_WRITE} state_t;
    state_t state;
    always_comb begin
        av_address=0; av_chipselect=0; av_read_n=1; av_write_n=1;
        av_writedata={24'd0,command}; command_valid=state==DELIVER;
        case(state)
            POLL: begin av_chipselect=1; av_read_n=0; end
            SPACE: begin av_address=1; av_chipselect=1; av_read_n=0; end
            WRITE: begin av_chipselect=1; av_write_n=0; end
            default: begin end
        endcase
    end
    always_ff @(posedge clk) begin
        if(reset) begin state<=POLL; command<=0; activity<=0; end
        else case(state)
            POLL: if(!av_waitrequest) begin
                if(av_readdata[15]) begin command<=av_readdata[7:0]; state<=DELIVER; end
                else state<=END_WRITE;
            end
            DELIVER: if(command_ready) begin activity<=~activity; state<=GAP; end
            GAP: state<=SPACE;
            SPACE: if(!av_waitrequest) begin
                if(av_readdata[31:16]!=0) state<=WRITE;
                else state<=GAP;
            end
            WRITE: if(!av_waitrequest) state<=END_WRITE;
            END_WRITE: state<=POLL;
            default: state<=POLL;
        endcase
    end
endmodule
