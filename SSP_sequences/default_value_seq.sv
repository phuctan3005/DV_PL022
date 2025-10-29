class default_value_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(default_value_seq)
    function new(string name = "default_value_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        for(int i = 0 ; i <= 32 ; i = i +4) begin 
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
            if (rsp.data != 32'h0000) begin
                `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
            end else begin
                `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
            end

        end
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : default_value_seq