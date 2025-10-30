class read_write_value_test extends ssp_base_test;
    `uvm_component_utils (read_write_value_test)
    read_write_value_seq read_write_value;
    function new(string name = "read_write_value_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        read_write_value = read_write_value_seq::type_id::create("read_write_value");
        read_write_value.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : read_write_value_test