class read_write_value_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(read_write_value_seq)
    function new(string name = "read_write_value_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        bit [15:0]wdata;
        for(int i = 0 ; i <= 32 ; i = i +4) begin 
        ////////////////////WRITE////////////////////////////
            req =  ssp_transaction::type_id::create("req");
            start_item(req);
            wdata = $random;
            req.randomize() with{
                r_w == ssp_transaction::WRITE;
                addr == i;
                data == wdata;
            };
            `uvm_info (get_type_name(),$sformatf("Send to driver packet : \n %0s",req.sprint()),UVM_LOW)
            finish_item(req);
            get_response(rsp);
        
        /////////////////////READ///////////////////////////
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
            if (rsp.data != wdata) begin
                `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
            end else begin
                `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
            end

        end
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : read_write_value_seq