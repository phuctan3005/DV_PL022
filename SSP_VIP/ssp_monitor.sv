class ssp_monitor extends uvm_monitor ;
    //factory
    `uvm_component_utils(ssp_monitor) 
    virtual ssp_if ssp_vif; // interface config_db
    uvm_analysis_port #(ssp_transaction) monitor_port;
    //instance component
    function new(string name = "ssp_monitor", uvm_component parent);
        super.new(name,parent);
    endfunction:new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_port = new("monitor_port",this); /// TLM export
        
        if(!uvm_config_db#(virtual ssp_if)::get(this,"","ssp_vif",ssp_vif))
        `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db"))

    endfunction:build_phase  

    virtual task run_phase(uvm_phase phase);
        
        wait (ssp_vif.PRESETn == 1'b1);
        forever begin
            ssp_transaction trans;
            trans = ssp_transaction::type_id::create("trans",this);
            @(posedge ssp_vif.PCLK);#1ps;
            trans.addr = ssp_vif.PADDR ;
            $cast(trans.r_w , ssp_vif.PWRITE);
            if (ssp_vif.PWRITE == 1) begin
                trans.data = ssp_vif.PWDATA;
            end           
            @(posedge ssp_vif.PCLK);#1ps;
            if (ssp_vif.PWRITE == 0) begin
                trans.data = ssp_vif.PRDATA;
            end
            `uvm_info(get_type_name(),$sformatf("Observed transaction : \n %s",trans.sprint()),UVM_LOW)
            monitor_port.write(trans);
        end
        
    endtask:run_phase

endclass : ssp_monitor
