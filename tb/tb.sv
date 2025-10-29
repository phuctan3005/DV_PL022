`timescale 1ns/1ps;
module tb ;
import uvm_pkg::*;
import test_pkg::*;

///interface 
ssp_if ssp_vif();
// dut

ssp_register dut_reg(
    .PCLK(ssp_vif.PCLK),
    .PRESETn(ssp_vif.PRESETn),
    .PSEL(ssp_vif.PSEL),
    .PENABLE(ssp_vif.PENABLE),
    .PWRITE(ssp_vif.PWRITE),
    .PADDR(ssp_vif.PADDR),
    .PWDATA(ssp_vif.PWDATA),
    .PRDATA(ssp_vif.PRDATA)
    );
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
    /** Set virtual interface to driver for control, learn detail in next session */
    uvm_config_db#(virtual ssp_if)::set(null, "uvm_test_top", "ssp_vif",ssp_vif);
    /** Start the UVM test */
    run_test("default_value_test");
    #1000
    $finish;
end

endmodule