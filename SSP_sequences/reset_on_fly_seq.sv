class reset_on_fly_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(reset_on_fly_seq)
    function new(string name = "reset_on_fly_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        bit [15:0]wdata;
        for(int i = 0 ; i <=4092 ; i = i +4) begin 
        ////////////////////WRITE////////////////////////////
            if (i >= 40 && i <= 4060)
                    continue;
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
        end 
        /////////////////////READ///////////////////////////
        for(int i = 0 ; i <=4092 ; i = i +4) begin 
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
            case(i)
                12 :    if (rsp.data == wdata) begin
                            `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
                        end else begin
                            `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
                        end  

                24 :    if (rsp.data == wdata) begin
                            `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
                        end else begin
                            `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
                        end 
                28 :    if (rsp.data == wdata) begin
                            `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
                        end else begin
                            `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
                        end    
                32 :    if (rsp.data != 16'd0) begin
                            `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
                        end else begin
                            `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
                        end
                4064 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4068 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4072 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end   
                4076 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4080 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                4084 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end
                4088 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                4092 : if (rsp.data == wdata) begin
                        `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h0000 actual: 15'h%0h", i, rsp.data)) 
                    end else begin
                        `uvm_info(get_type_name(), $sformatf("default_value_pass"), UVM_LOW);
                    end 
                default :   if (rsp.data != wdata) begin
                                `uvm_error(get_type_name(), $sformatf ("At address: 16'h%0h expected value: 16'h%0h actual: 16'h%0h", i,wdata, rsp.data)) 
                            end else begin
                                `uvm_info(get_type_name(), $sformatf("read_write_value_pass"), UVM_LOW);
                            end
            endcase
            

        end
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : reset_on_fly_seq