class ssp_driver extends uvm_driver #(ssp_transaction) ;
    //factory
    `uvm_component_utils(ssp_driver) 
    virtual ssp_if ssp_vif; // config_db
    //instance component
    function new(string name = "ssp_driver", uvm_component parent);
        super.new(name,parent);
    endfunction:new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ssp_if)::get(this,"","ssp_vif",ssp_vif))
        `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db"))
    endfunction:build_phase  

    virtual task run_phase(uvm_phase phase);
        wait (ssp_vif.PRESETn == 1'b1);
        forever begin
            wait (ssp_vif.PRESETn == 1'b1);
            seq_item_port.get_next_item(req);
            driver(req);

            //chay interrupt tat 3 dong nay
    //        $cast(rsp,req.clone());
      //      rsp.set_id_info(req);
        //    seq_item_port.put(rsp);
            seq_item_port.item_done();
        end
    endtask:run_phase
    task driver (inout ssp_transaction trans);
        @(posedge ssp_vif.PCLK);
        ssp_vif.PADDR   <= trans.addr;
        ssp_vif.PWRITE  <= trans.r_w;
        ssp_vif.PSEL    <= 1'b1;
        ssp_vif.PENABLE <= 1'b0;
        if (trans.r_w == ssp_transaction::WRITE) begin
            ssp_vif.PWDATA <= trans.data;
        end
        
        @(posedge ssp_vif.PCLK);
        ssp_vif.PENABLE <= 1'b1;
        if (trans.r_w == ssp_transaction::READ) begin
              trans.data <= ssp_vif.PRDATA ;
        end

        @(posedge ssp_vif.PCLK);
        ssp_vif.PSEL    <= 1'b0;
        ssp_vif.PENABLE <= 1'b0;
        ssp_vif.PADDR   <= 'z;
        ssp_vif.PRDATA  <= '0;
        ssp_vif.PWDATA  <= '0;
        ssp_vif.PWRITE  <= 1'b0;
    endtask
endclass : ssp_driver
