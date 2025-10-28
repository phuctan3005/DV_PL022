class ssp_driver extends uvm_agent;
    //factory
    `uvm_component_utils(ssp_driver)
    //instance component


    function new(string name = "ssp_driver", uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction:build_phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // ssp_driver conect with sequencer
    endfunction:connect_phase    
    virtual task run_phase(uvm_phase phase);
    endtask:run_phase

endclass : ssp_driver