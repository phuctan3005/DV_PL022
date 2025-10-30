class apb_clock_test extends ssp_base_test;
    `uvm_component_utils (apb_clock_test)
    apb_clock_seq apb_clock;
    function new(string name = "apb_clock_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        apb_clock = apb_clock_seq::type_id::create("apb_clock");
        fork
            apb_clock.start(ssp_env.agt.ssp_seq);//send data for sequencer
            begin 
                ssp_vif.PCLK = 0;
                `uvm_info (get_type_name(),$sformatf("inactive CLOCK !!!!"),UVM_LOW)
                #1000ns;
                repeat(100) #10 ssp_vif.PCLK = ~ssp_vif.PCLK ;
                ssp_vif.PCLK = 0;
                #2000ns;
            end
        join
        phase.drop_objection(this);
    endtask
endclass : apb_clock_test