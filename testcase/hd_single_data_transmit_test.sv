class hd_single_data_transmit_test extends ssp_base_test;
    `uvm_component_utils (hd_single_data_transmit_test)
    hd_single_data_transmit_seq hd_single_data_transmit;
    function new(string name = "hd_single_data_transmit_test",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        clock_reset_domain();
        hd_single_data_transmit = hd_single_data_transmit_seq::type_id::create("hd_single_data_transmit");
        hd_single_data_transmit.start(ssp_env.agt.ssp_seq);//send data for sequencer
        phase.drop_objection(this);
    endtask
    task clock_reset_domain();
        ssp_vif.SSPCLK= 0;
        ssp_vif.nSSPRST = 0;
        #100ns;
        fork
            forever #10 ssp_vif.SSPCLK = ~ssp_vif.SSPCLK ;
            begin
                #1000ns;
                ssp_vif.nSSPRST = 1;
                #10ns;
            end
        join_any
    endtask
endclass : hd_single_data_transmit_test