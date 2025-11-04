class dma_tx_brust_req_test extends ssp_base_test;
    `uvm_component_utils(dma_tx_brust_req_test)

    function new(string name = "dma_tx_brust_req_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        dma_tx_brust_req_seq seq = dma_tx_brust_req_seq::type_id::create("dma_tx_brust_req_seq");
        phase.raise_objection(this);
        seq.start(ssp_env.agt.ssp_seq);
        phase.drop_objection(this);
    endtask

endclass : dma_tx_brust_req_test
