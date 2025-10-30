class apb_reset_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(apb_reset_seq)
    function new(string name = "apb_reset_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        for(int i = 0 ; i <= 4092; i = i+4) begin 
            if (i >= 40 && i <= 4060)
                    continue;
            req =  ssp_transaction::type_id::create("req");
            start_item(req);
            req.randomize() with{
                r_w == ssp_transaction::READ;
                addr == i;
                //data == 0;
            };
            `uvm_info (get_type_name(),$sformatf("Send to driver packet : \n %0s",req.sprint()),UVM_LOW)
            finish_item(req);
            get_response(rsp);
        end
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : apb_reset_seq