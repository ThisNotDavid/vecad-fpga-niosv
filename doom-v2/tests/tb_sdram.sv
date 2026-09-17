`timescale 1ns/1ps
module tb_sdram;
    reg clk=0,reset=1,read=0,write=0;always #10 clk=~clk;
    reg [24:0] address=0;reg [31:0] writedata=0;reg [3:0] byteenable=15;
    wire waitrequest,readdatavalid,ready;wire [31:0] readdata;
    wire [12:0] dram_addr;wire [1:0] dram_ba;wire dram_cs_n,dram_cke,dram_ras_n,dram_cas_n,dram_we_n;
    wire [3:0] dram_dqm;wire [31:0] dram_dq;
    doom_sdram #(.INIT_CYCLES(20),.REFRESH_CYCLES(80)) dut(.*);
    // Independent sparse SDRAM protocol model. Keys include full bank/row/col.
    reg [12:0] row[0:3];reg [24:0] tags[0:127];reg [31:0] mem[0:127];
    integer used=0,refs=0,cycles=0,last_ref=0,i,j,slot,delay_read=0;
    reg [24:0] addr;reg [31:0] read_value,model_data;reg model_drive=0;
    assign dram_dq=model_drive?model_data:32'bz;
    function integer lookup(input [24:0] key);
        integer k;begin lookup=-1;for(k=0;k<used;k=k+1)if(tags[k]==key)lookup=k;end
    endfunction
    always @(negedge clk) begin
        cycles=cycles+1;model_drive<=0;
        if(delay_read>0)begin
            delay_read=delay_read-1;
            if(delay_read==0)begin model_drive<=1;model_data<=read_value;end
        end
        if(!reset)case({dram_ras_n,dram_cas_n,dram_we_n})
            3'b011: row[dram_ba]=dram_addr;
            3'b101,3'b100:begin
                if(!dram_addr[10])$fatal(1,"Expected auto precharge");
                addr={dram_ba,row[dram_ba],dram_addr[9:0]};slot=lookup(addr);
                if(!dram_we_n)begin
                    if(slot<0)begin slot=used;tags[used]=addr;mem[used]=0;used=used+1;end
                    for(j=0;j<4;j=j+1)if(!dram_dqm[j])mem[slot][8*j+:8]=dram_dq[8*j+:8];
                end else begin
                    if(slot<0)$fatal(1,"Read unwritten address %h",addr);
                    read_value=mem[slot];delay_read=2;
                end
            end
            3'b001:begin refs=refs+1;last_ref=cycles;end
            3'b000:if(dram_addr!==13'h220)$fatal(1,"Bad SDRAM mode");
            default:;
        endcase
        if(ready && cycles-last_ref>105)$fatal(1,"Refresh starved");
    end
    task put(input [24:0] a,input [31:0] d,input [3:0] be);
        begin @(negedge clk);address=a;writedata=d;byteenable=be;write=1;
            @(posedge clk);while(waitrequest)@(posedge clk);
            @(negedge clk);write=0;end
    endtask
    task get(input [24:0] a,input [31:0] expected);
        begin @(negedge clk);address=a;read=1;@(posedge clk);while(waitrequest)@(posedge clk);
            @(negedge clk);read=0;wait(readdatavalid);#1;
            if(readdata!==expected)$fatal(1,"SDRAM %h got %h expected %h",a,readdata,expected);
        end
    endtask
    initial begin
        repeat(4)@(negedge clk);reset=0;wait(ready);if(refs!=8)$fatal(1,"Init refresh count %d",refs);
        for(i=0;i<32;i=i+1)put((i<<20)|i,32'haabb0000+i,15);
        for(i=0;i<32;i=i+1)get((i<<20)|i,32'haabb0000+i);
        put(0,32'h11223344,4'b0101);get(0,32'haa220044);
        repeat(200)@(negedge clk);if(refs<=8)$fatal(1,"No runtime refresh");
        $display("PASS SDRAM init, full-address read/write, byte masks, refresh under traffic");$finish;
    end
    initial begin #1000000;$fatal(1,"Timeout");end
endmodule
