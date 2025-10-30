class reset_on_fly_test extends ssp_base_test;
    `uvm_component_utils (reset_on_fly_test)
    reset_on_fly_seq reset_on_fly;
    function new(string name = "reset_on_fly_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        reset_on_fly = reset_on_fly_seq::type_id::create("reset_on_fly");
        fork
            reset_on_fly.start(ssp_env.agt.ssp_seq);//send data for sequencer
            begin 
                #1200ns;
                ssp_vif.PRESETn = 0;
                `uvm_info (get_type_name(),$sformatf("Active Reset !!!!"),UVM_LOW)
                #100ns;
                ssp_vif.PRESETn = 1;
                #2000ns;
            end
        join
        phase.drop_objection(this);
    endtask
endclass : reset_on_fly_test