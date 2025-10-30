class ssp_sequencer extends uvm_sequencer #(ssp_transaction);
    //factory
    `uvm_component_utils(ssp_sequencer)
    function new(string name = "ssp_sequencer", uvm_component parent);
        super.new(name,parent);
    endfunction:new
endclass : ssp_sequencer