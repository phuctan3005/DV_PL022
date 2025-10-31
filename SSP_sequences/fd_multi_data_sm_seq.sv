class fd_multi_data_sm_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(fd_multi_data_sm_seq)
    function new(string name = "fd_multi_data_sm_seq") ;
        super.new(name);
    endfunction :new
    virtual task body ();
        bit [15:0] wdata [0:3];
        int address;
        //wdata[0][3:0] = ;//SSPCR0
        //wdata[1] // SSPDR
        //wdata[1] = ;//SSPCPSR
        //wdata[2] = ;//SSPCR1
        for(int i = 0 ; i <= 6; i = i+1) begin 
        ////////////////////WRITE////////////////////////////
            
            req =  ssp_transaction::type_id::create("req");
            start_item(req);
            if(i == 0) begin
                wdata[i][3:0] = $urandom;
                wdata[i][5:4] = $urandom;
                wdata[i][7:6] = $urandom;
                wdata[i][15:8] = $urandom_range(0, 127) * 2;
                address = 0;
                req.data = wdata[i];
            end
            if(i>0&&i<5) begin
                wdata[1] = $urandom;
                address = 8;
                req.data = wdata[1];
            end
            if(i == 5) begin
                wdata[2][7:0] = $urandom_range(0, 127) * 2;
                address = 16;
                req.data = wdata[2];
            end
            if(i == 6) begin
                wdata[3][3:0] = 4'b0110;
                address = 4;
                req.data = wdata[3];
            end

                req.r_w = ssp_transaction::WRITE;
                req.addr = address;
                

            `uvm_info (get_type_name(),$sformatf("Send to driver packet : \n %0s",req.sprint()),UVM_LOW)
            finish_item(req);
            get_response(rsp);
        end 
    
        
        //#lus;
        `uvm_info(get_type_name(), $sformatf ("Recevied rsp to driver: \n %s", rsp.sprint()),UVM_LOW);
    endtask :body
endclass : fd_multi_data_sm_seq