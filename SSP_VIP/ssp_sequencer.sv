class ssp_sequencer extends uvm_sequencer;
    //factory
    `uvm_component_utils(ssp_sequencer)
    function new(string name = "ssp_sequencer", uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction:build_phase
 

endclass : ssp_sequencer