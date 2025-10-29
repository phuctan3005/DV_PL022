class ssp_agent extends uvm_agent;
    //factory
    `uvm_component_utils(ssp_agent)
    //instance component
    ssp_sequencer   ssp_seq;
    ssp_driver      ssp_drv;
    ssp_monitor     ssp_mon;
    virtual ssp_if ssp_vif; // interface config_db
    function new(string name = "ssp_agent", uvm_component parent);
        super.new(name,parent);
    endfunction:new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ssp_if)::get(this,"","ssp_vif",ssp_vif))
        `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db"))
        if (is_active == UVM_ACTIVE) begin
            `uvm_info(get_type_name(), $sformatf ("Active agent is configued"), UVM_LOW)
            ssp_seq = ssp_sequencer::type_id::create("ssp_seq",this);
            ssp_drv = ssp_driver::type_id::create("ssp_drv",this);
            ssp_mon = ssp_monitor::type_id::create("ssp_mon",this);
            uvm_config_db#(virtual ssp_if)::set(this,"ssp_drv","ssp_vif",ssp_vif);
            uvm_config_db#(virtual ssp_if)::set(this,"ssp_mon","ssp_vif",ssp_vif);
        end else begin 
            `uvm_info(get_type_name(), $sformatf("Passive agent is configued"), UVM_LOW)
            ssp_mon = ssp_monitor::type_id::create("ssp_mon",this);
            uvm_config_db#(virtual ssp_if)::set(this,"ssp_mon","ssp_vif",ssp_vif);
        end

    endfunction:build_phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
       if (is_active == UVM_ACTIVE) begin
            // đảm bảo cả 2 instance tồn tại trước khi connect
            if (ssp_drv != null && ssp_seq != null) begin
                // connect driver port -> sequencer export
                ssp_drv.seq_item_port.connect(ssp_seq.seq_item_export);
            end else begin
                `uvm_warning(get_type_name(), "Attempt to connect driver<->sequencer but one of them is null")
            end
        end
    endfunction: connect_phase    


endclass : ssp_agent