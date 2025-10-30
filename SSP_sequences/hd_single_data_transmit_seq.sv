class hd_single_data_transmit_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(hd_single_data_transmit_seq)
    function new(string name = "hd_single_data_transmit_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        bit [15:0] wdata [0:2];
        int address;
        //wdata[0][3:0] = ;//SSPCR0
        //wdata[1] = ;//SSPCPSR
        //wdata[2] = ;//SSPCR1
        for(int i = 0 ; i <= 2; i = i+1) begin 
        ////////////////////WRITE////////////////////////////
            
            req =  ssp_transaction::type_id::create("req");
            start_item(req);
            if(i == 0) begin
                wdata[0][3:0] = $urandom;
                wdata[0][5:4] = 2'b10;// type MW
                wdata[0][15:8] = $urandom_range(0, 127) * 2;
                address = 0;
            end
            if(i == 1) begin
                wdata[1][7:0] = $urandom_range(0, 127) * 2;
                address = 16;
            end
            if(i == 2) begin
                wdata[2][3:0] = 4'b0010;
                address = 4;
            end
            req.randomize() with{
                r_w == ssp_transaction::WRITE;
                addr == address;
                data == wdata[i];
            };
            `uvm_info (get_type_name(),$sformatf("Send to driver packet : \n %0s",req.sprint()),UVM_LOW)
            finish_item(req);
            get_response(rsp);
        end 
    
        
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : hd_single_data_transmit_seq