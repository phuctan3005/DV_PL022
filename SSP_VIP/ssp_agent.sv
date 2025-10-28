class ssp_agent extends uvm_agent;
    //factory
    `uvm_component_utils(ssp_agent)
    //instance component
    ssp_sequencer ssp_seq;
    ssp_driver ssp_drv;
    ssp_monitor ssp_mon;

    function new(string name = "ssp_agent", uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction:build_phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // driver conect with sequencer
    endfunction:connect_phase    
    virtual task run_phase(uvm_phase phase);
    endtask:run_phase

endclass : ssp_agent