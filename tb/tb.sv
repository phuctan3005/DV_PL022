`timescale 1ns/1ps;
module tb ;
import uvm_pkg::*;
import test_pkg::*;

///interface 
ssp_if ssp_vif();
// dut
bit [15:0] DATA;
bit [15:0] WDATA;
bit [15:0] RDATA;
// PCLK INTI
initial begin
    ssp_vif.PCLK = 0;
    forever #10 ssp_vif.PCLK = ~ssp_vif.PCLK ;
end
// PRESETn
initial begin
    ssp_vif.PRESETn = 0;
    repeat(2) @(posedge ssp_vif.PCLK);
    #1ps; ssp_vif.PRESETn = 1;
end
// TEST 
initial begin
    // test_case 1 
    // test_case 2 - read_write_value check
    //test_case_2();
    // test_case 3
    /** Set virtual interface to driver for control, learn detail in next session */
    uvm_config_db#(virtual ssp_if)::set(null, "uvm_test_top", "ssp_vif",ssp_vif);
    /** Start the UVM test */
    run_test("default_value_test");
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
        @(posedge ssp_vif.PCLK);
        ssp_vif.PADDR <= addr;
        ssp_vif.PWRITE <= 1'b1;
        ssp_vif.PSEL <= 1'b1;
        ssp_vif.PENABLE <= 1'b0;
        ssp_vif.PWDATA <= data;

        @(posedge ssp_vif.PCLK);
        ssp_vif.PENABLE <= 1'b1;

        @(posedge ssp_vif.PCLK);

        ssp_vif.PSEL <= 1'b0;
        ssp_vif.PENABLE <= 1'b0;
        ssp_vif.PADDR <= '0;
        ssp_vif.PWDATA <= '0;
    endtask

task read(bit [7:2] addr, output bit [31:0] data);
        @(posedge ssp_vif.PCLK);
        ssp_vif.PADDR <= addr;
        ssp_vif.PWRITE <= 1'b0;
        ssp_vif.PSEL <= 1'b1;
        ssp_vif.PENABLE <= 1'b0;
        @(posedge ssp_vif.PCLK);
        ssp_vif.PENABLE <= 1'b1;
        @(posedge ssp_vif.PCLK);
        data = ssp_vif.PRDATA;
        ssp_vif.PSEL <= 1'b0;
        ssp_vif.PENABLE <= 1'b0;
        ssp_vif.PADDR <= '0;
        ssp_vif.PRDATA <= '0;
endtask
endmodule