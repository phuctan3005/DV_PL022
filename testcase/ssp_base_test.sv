class ssp_base_test extends uvm_test;
    `uvm_component_utils (ssp_base_test)
    ssp_environment ssp_env;
    virtual ssp_if ssp_vif;
    function new(string name="ssp_base_test", uvm_component parent); 
        super.new(name, parent);
    endfunction: new
    virtual function void build_phase (uvm_phase phase); 
        super.build_phase (phase); 
        `uvm_info("build_phase", "Entered...", UVM_HIGH) 
        if(!uvm_config_db#(virtual ssp_if)::get(this, "", "ssp_vif", ssp_vif)) 
            `uvm_fatal (get_type_name(), $sformatf("Faile to get ssp_vif uvm_config_db")) 
        ssp_env = ssp_environment::type_id::create("ssp_env", this); 
        uvm_config_db#(virtual ssp_if)::set(this, "ssp_env", "ssp_vif", ssp_vif); 
        `uvm_info("build_phase", "Exiting...", UVM_HIGH)
    endfunction: build_phase
    virtual function void start_of_simulation_phase (uvm_phase phase);
        `uvm_info("start_of_simulation_phase", "Entered...", UVM_HIGH)
            uvm_top.print_topology(); 
        `uvm_info("start_of_simulation_phase", "Exiting...", UVM_HIGH)
    endfunction : start_of_simulation_phase

endclass