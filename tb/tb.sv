`timescale 1ns/1ps;
module tb ;

///interface 
ssp_if ssp_vif();
// dut
bit [15:0] DATA;
bit [15:0] WDATA;
bit [15:0] RDATA;
// PCLK INTI
initial begin
    SSP_vif.PCLK = 0;
    forever #10 SSP_vif.PCLK = ~SSP_vif.PCLK ;
end
// PRESETn
initial begin
    SSP_vif.PRESETn = 0;
    repeat(2) @(posedge SSP_vif.PCLK);
    #1ps; SSP_vif.PRESETn = 1;
end
// TEST 
initial begin
    // test_case 1 
    // test_case 2 - read_write_value check
    //test_case_2();
    // test_case 3
    #1000
    $finish;
end
task test_case_1();begin
    //default value check
    end
endtask
task test_case_2();begin
    //read_write_value check
    for(int i = 0 ;i <= 12;i=i+4) begin
        DATA = $random;
        write(i,WDATA);
        read(i,RDATA);
        $display ("At address : 12'h%0h get data : WDATA = 16'h%0h ---- RDATA = 16'h%0h",i,WDATA,RDATA);
    end
end
endtask
task write(bit [11:2] addr, bit [15:0] data);
        @(posedge SSP_vif.PCLK);
        SSP_vif.PADDR <= addr;
        SSP_vif.PWRITE <= 1'b1;
        SSP_vif.PSEL <= 1'b1;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PWDATA <= data;

        @(posedge SSP_vif.PCLK);
        SSP_vif.PENABLE <= 1'b1;

        @(posedge SSP_vif.PCLK);

        SSP_vif.PSEL <= 1'b0;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PADDR <= '0;
        SSP_vif.PWDATA <= '0;
    endtask

    task read(bit [7:2] addr, output bit [31:0] data);
        @(posedge SSP_vif.PCLK);
        SSP_vif.PADDR <= addr;
        SSP_vif.PWRITE <= 1'b0;
        SSP_vif.PSEL <= 1'b1;
        SSP_vif.PENABLE <= 1'b0;

        @(posedge SSP_vif.PCLK);
        SSP_vif.PENABLE <= 1'b1;

       @(posedge SSP_vif.PCLK);

        data = SSP_vif.PRDATA;

        SSP_vif.PSEL <= 1'b0;
        SSP_vif.PENABLE <= 1'b0;
        SSP_vif.PADDR <= '0;
        SSP_vif.PRDATA <= '0;
    endtask
endmodule