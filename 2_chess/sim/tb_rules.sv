`timescale 1ns/1ps
module tb_rules;
    logic clk=0,reset=1,start=0;
    always #10 clk=~clk;
    logic [255:0] board,expected_board,result_board;
    logic side,ep_valid,done,legal,result_ep_valid,expected_legal,expected_ep;
    logic [3:0] rights,result_rights,expected_rights;
    logic [5:0] ep_square,src,dst,result_ep_square,expected_ep_square;
    logic [2:0] promotion;
    integer file,fields,count,cycles;
    move_checker dut(.*);
    initial begin
        count=0;repeat(3) @(negedge clk);reset=0;
        file=$fopen("build/rule_vectors.txt","r");
        if(!file) $fatal(1,"Missing rule vectors");
        while(!$feof(file)) begin
            fields=$fscanf(file,"%h %d %h %d %h %h %h %h %d %h %h %d %h\n",
                board,side,rights,ep_valid,ep_square,src,dst,promotion,expected_legal,
                expected_board,expected_rights,expected_ep,expected_ep_square);
            if(fields==13) begin
                @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
                while(!done && cycles<2000) begin @(negedge clk);cycles=cycles+1;end
                if(!done) $fatal(1,"Move checker timeout case %0d",count);
                if(legal!==expected_legal) $fatal(1,"Legality mismatch case %0d board=%h side=%b move=%0d-%0d got=%b expected=%b",count,board,side,src,dst,legal,expected_legal);
                if(legal && (result_board!==expected_board || result_rights!==expected_rights || result_ep_valid!==expected_ep || (expected_ep && result_ep_square!==expected_ep_square)))
                    $fatal(1,"Result mismatch case %0d move=%0d-%0d got=%h expected=%h rights %h/%h ep %b/%b",count,src,dst,result_board,expected_board,result_rights,expected_rights,result_ep_valid,expected_ep);
                count=count+1;
            end else if(fields!=-1) $fatal(1,"Malformed vector");
        end
        $display("PASS rules: %0d independent reference cases",count);$finish;
    end
endmodule
