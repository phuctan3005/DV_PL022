class default_value_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(default_value_seq)
    function new(string name = "default_value_seq") ;
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
            case (i)
                12 : if (rsp.data != 16'h0003) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                24 : if (rsp.data != 16'h0008) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                4064 : if (rsp.data != 16'h0022) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4068 : if (rsp.data != 16'h0010) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4072 : if (rsp.data != 16'h0034) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end   
                4076 : if (rsp.data != 16'h0000) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4080 : if (rsp.data != 16'h000D) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                4084 : if (rsp.data != 16'h00F0) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4088 : if (rsp.data != 16'h0005) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                4092 : if (rsp.data != 16'h00B1) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                default : if (rsp.data != 16'h0000) begin
                                `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                        end else begin
                            `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
            end
            endcase
            

        end
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : default_value_seq