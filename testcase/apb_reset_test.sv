class apb_reset_test extends ssp_base_test;
    `uvm_component_utils (apb_reset_test)
    apb_reset_seq apb_reset;
    function new(string name = "apb_reset_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        apb_reset = apb_reset_seq::type_id::create("apb_reset");
        fork
            apb_reset.start(ssp_env.agt.ssp_seq);//send data for sequencer
            begin 
                ssp_vif.PRESETn = 0;
                `uvm_info (get_type_name(),$sformatf("RESET reset !!!!"),UVM_LOW)
                #1000ns;
                ssp_vif.PRESETn = 1;
                #2000ns;
                ssp_vif.PRESETn = 0;
            end
        join
        phase.drop_objection(this);
    endtask
endclass : apb_reset_test