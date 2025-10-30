class ssp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ssp_scoreboard)
    virtual ssp_if ssp_vif; // interface config_db
    uvm_analysis_imp #(ssp_transaction,ssp_scoreboard) scoreboard_export;
    function new(string name = "ssp_scoreboard",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        scoreboard_export = new("scoreboard_export",this);
    endfunction:build_phase
    function void write (ssp_transaction trans);
        `uvm_info (get_type_name(),$sformatf("Get packet from monitor : \n %0s",trans.sprint()),UVM_LOW)
    endfunction:write
endclass : ssp_scoreboard