class hd_multi_data_receive_test extends ssp_base_test;
    `uvm_component_utils (hd_multi_data_receive_test)
    hd_multi_data_receive_seq hd_multi_data_receive;
    function new(string name = "hd_multi_data_receive_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        hd_multi_data_receive = hd_multi_data_receive_seq::type_id::create("hd_multi_data_receive");
        hd_multi_data_receive.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
endclass : hd_multi_data_receive_test