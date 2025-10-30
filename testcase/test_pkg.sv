package test_pkg;    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import ssp_pkg::*;
    import seq_pkg::*;
    import test_pkg::*;
        `include "ssp_base_test.sv"

        `include "apb_clock_test.sv"
        `include "apb_reset_test.sv"
        `include "default_value_test.sv"
        `include "read_write_value_test.sv"
        `include "reset_on_fly_test.sv"

        `include "hd_single_data_transmit_test.sv"
        `include "hd_multi_data_transmit_test.sv"
        `include "hd_single_data_receive_test.sv"
        `include "hd_multi_data_receive_test.sv"
        `include "fd_single_data_mm_test.sv"
        `include "fd_multi_data_mm_test.sv"
        `include "fd_single_data_sm_test.sv"
        `include "fd_multi_data_sm_test.sv"
endpackage