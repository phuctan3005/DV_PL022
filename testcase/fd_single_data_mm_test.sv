class fd_single_data_mm_test extends ssp_base_test;
    `uvm_component_utils (fd_single_data_mm_test)
    fd_single_data_mm_seq fd_single_data_mm;
    function new(string name = "fd_single_data_mm_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        fd_single_data_mm = fd_single_data_mm_seq::type_id::create("fd_single_data_mm");
        fd_single_data_mm.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : fd_single_data_mm_test