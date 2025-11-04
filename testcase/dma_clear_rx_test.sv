class dma_clear_rx_test extends ssp_base_test;
    `uvm_component_utils(dma_clear_rx_test)

    function new(string name = "dma_clear_rx_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        dma_clear_rx_req seq = dma_clear_rx_req::type_id::create("dma_clear_rx_req");
        phase.raise_objection(this);
        seq.start(ssp_env.agt.ssp_seq);
        phase.drop_objection(this);
    endtask

endclass : dma_clear_rx_test
