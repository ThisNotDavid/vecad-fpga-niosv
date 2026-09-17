// Sixteen-event FIFO and restart modal. PS/2 reception cannot be backpressured;
// overflow drops the newest event and lights a sticky diagnostic LED.
module keyboard_commands(
    input logic clk,reset,
    input logic [7:0] input_command,
    input logic input_valid,
    output logic [7:0] command,
    output logic command_valid,
    input logic command_ready,
    output logic restart_pending,restart_pulse,overflow,activity
);
    logic [7:0] fifo [0:15];
    logic [3:0] rd,wr;
    logic [4:0] count;
    wire [7:0] head=fifo[rd];
    wire pop=count!=0 && (restart_pending || head=="r" || command_ready);
    wire push=input_valid && (count<16 || pop);
    wire confirm=pop && restart_pending && head=="e";
    assign command=head;
    assign command_valid=count!=0 && !restart_pending && head!="r" && !restart_pulse;
    always_ff @(posedge clk) begin
        if(reset) begin
            rd<=0;wr<=0;count<=0;restart_pending<=0;restart_pulse<=0;overflow<=0;activity<=0;
        end else begin
            restart_pulse<=0;
            if(input_valid && !push) overflow<=1;
            if(confirm) begin
                restart_pending<=0;restart_pulse<=1;rd<=0;wr<=0;count<=0;
            end else if(!restart_pulse) begin
                if(push) begin fifo[wr]<=input_command;wr<=wr+1'b1;end
                if(pop) begin
                    rd<=rd+1'b1;activity<=~activity;
                    if(restart_pending) begin if(head=="x") restart_pending<=0;end
                    else if(head=="r") restart_pending<=1;
                end
                case({push,pop})
                    2'b10: count<=count+1'b1;
                    2'b01: count<=count-1'b1;
                    default: begin end
                endcase
            end
        end
    end
endmodule
