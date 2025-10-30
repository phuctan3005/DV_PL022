class default_value_test extends ssp_base_test;
    `uvm_component_utils (default_value_test)
    default_value_seq default_value;
    function new(string name = "default_value_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        default_value = default_value_seq::type_id::create("default_value");
        default_value.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : default_value_test