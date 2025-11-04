class rx_interrupt_test extends ssp_base_test;
    `uvm_component_utils(rx_interrupt_test)

    function new(string name = "rx_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        rx_interrupt_seq seq;
        
        phase.raise_objection(this);
        
        // Create and start the RX interrupt test sequence
        seq = rx_interrupt_seq::type_id::create("rx_interrupt_seq");
        seq.start(ssp_env.agt.ssp_seq);

        phase.drop_objection(this);
    endtask : run_phase

endclass : rx_interrupt_test
