    package seq_pkg;
        
        import uvm_pkg::*;
        `include "uvm_macros.svh"
        import ssp_pkg::*;
        `include "default_value_seq.sv"
        `include "read_write_value_seq.sv"
        `include "reset_on_fly_seq.sv"
        `include "apb_clock_seq.sv"
        `include "apb_reset_seq.sv"
        `include "hd_single_data_transmit_seq.sv"
        `include "hd_multi_data_transmit_seq.sv"
        `include "hd_single_data_receive_seq.sv"
        `include "hd_multi_data_receive_seq.sv"
        `include "fd_single_data_mm_seq.sv"
        `include "fd_multi_data_mm_seq.sv"
        `include "fd_single_data_sm_seq.sv"
        `include "fd_multi_data_sm_seq.sv"

    endpackage