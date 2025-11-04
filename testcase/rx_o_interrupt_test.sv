// ============================================================================
// File: rx_o_interrupt_test.sv
// Description: Test case for Receive Overrun Interrupt (SSPRORINTR)
// ============================================================================

class rx_o_interrupt_test extends ssp_base_test;
    `uvm_component_utils(rx_o_interrupt_test)

    function new(string name = "rx_o_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rx_o_interrupt_seq seq;
        
        phase.raise_objection(this);
        seq = rx_o_interrupt_seq::type_id::create("rx_o_interrupt_seq");
        seq.start(ssp_env.agt.ssp_seq);
        #1000;
        phase.drop_objection(this);
    endtask

endclass : rx_o_interrupt_test
