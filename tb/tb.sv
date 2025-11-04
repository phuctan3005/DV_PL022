`timescale 1ns/1ps
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
initial begin
    ssp_vif.SSPCLK = 0;
    forever #10 ssp_vif.SSPCLK = ~ssp_vif.SSPCLK ;
end
// PRESETn
initial begin
    ssp_vif.PRESETn = 0;
    repeat(2) @(posedge ssp_vif.PCLK);
    #1ps; ssp_vif.PRESETn = 1;
end
initial begin
    ssp_vif.nSSPRST = 0;
    repeat(2) @(posedge ssp_vif.PCLK);
    #1ps; ssp_vif.nSSPRST = 1;
end
//TEST 
initial begin
    /** Set virtual interface to driver for control, learn detail in next session */
    uvm_config_db#(virtual ssp_if)::set(null, "uvm_test_top", "ssp_vif",ssp_vif);
    /** Start the UVM test */

        //run_test( "apb_clock_test");
        // run_test( "apb_reset_test");

        // run_test( "default_value_test");
        // run_test ("read_write_value_test");
        //run_test( "reset_on_fly_test");

       //  run_test( "hd_single_data_transmit_test"); // neu su dung test case nay hay tat dong 30-39 
        // run_test( "hd_multi_data_transmit_test");

        // run_test( "hd_single_data_receive_test");
        // run_test( "hd_multi_data_receive_test");

        // run_test( "fd_single_data_mm_test");
        // run_test( "fd_multi_data_mm_test");

        // run_test( "fd_single_data_sm_test");
        // run_test( "fd_multi_data_sm_test");

         //INterrupt
         //run_test( "tx_interrupt_test");    // Test TX interrupt behavior
         //run_test("rx_interrupt_test");
         //run_test("rx_o_interrupt_test");   // Test RX overrun interrupt behavior
         //run_test("rx_t_interrupt_test");   // Test RX timeout interrupt behavior
         //run_test("main_interrupt_test");    // Test combined interrupt (SSPINTR) behavior

         //DMA
         run_test("dma_tx_single_req_test");  // Test TX DMA single request behavior
         //run_test("dma_rx_single_req_test");  // Test RX DMA single request behavior
         //run_test("dma_tx_brust_req_test");  // Test TX DMA burst request behavior
         //run_test("dma_rx_brust_req_test");  // Test RX DMA burst request behavior
         //run_test("dma_clear_tx_test");  // Test TX DMA clear behavior
         //run_test("dma_clear_rx_test");  // Test RX DMA clear behavior
    #100000ns;
    $finish;
end

endmodule