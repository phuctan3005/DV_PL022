class hd_single_data_transmit_test extends ssp_base_test;
    `uvm_component_utils (hd_single_data_transmit_test)
    hd_single_data_transmit_seq hd_single_data_transmit;
    function new(string name = "hd_single_data_transmit_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        hd_single_data_transmit = hd_single_data_transmit_seq::type_id::create("hd_single_data_transmit");
        hd_single_data_transmit.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : hd_single_data_transmit_test