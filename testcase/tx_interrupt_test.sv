class tx_interrupt_test extends ssp_base_test;
    `uvm_component_utils(tx_interrupt_test)

    function new(string name = "tx_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        tx_interrupt_seq seq;
        
        phase.raise_objection(this);
        
        // Create and start the TX interrupt test sequence
        seq = tx_interrupt_seq::type_id::create("tx_interrupt_seq");
        seq.start(ssp_env.agt.ssp_seq);

        phase.drop_objection(this);
    endtask : run_phase

endclass : tx_interrupt_test
