class fd_single_data_sm_test extends ssp_base_test;
    `uvm_component_utils (fd_single_data_sm_test)
    fd_single_data_sm_seq fd_single_data_sm;
    function new(string name = "fd_single_data_sm_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        fd_single_data_sm = fd_single_data_sm_seq::type_id::create("fd_single_data_sm");
        fd_single_data_sm.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : fd_single_data_sm_test