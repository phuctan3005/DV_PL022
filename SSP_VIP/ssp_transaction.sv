class ssp_transaction extends uvm_sequence_item;
    typedef enum bit { WRITE = 1 , READ = 0} transfer;
    rand transfer r_w;
    rand bit [11:0] addr;
    rand bit [15:0] data;
    bit        SSPFSSOUT;
    bit        SSPCLKOUT;
    bit        SSPRXD;
    bit        SSPTXD;
    bit        nSSPCTLOE;
    bit        SSPFSSIN;
    bit        SSPCLKIN;
    bit        nSSPOE;
    `uvm_object_utils_begin (ssp_transaction)
        `uvm_field_enum (transfer,r_w           ,UVM_ALL_ON||UVM_HEX )
        `uvm_field_int (addr                    ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (data                    ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPFSSOUT               ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPCLKOUT               ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPRXD                  ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPTXD                  ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (nSSPCTLOE               ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPFSSIN                ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPCLKIN                ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (nSSPOE                  ,UVM_ALL_ON||UVM_HEX)
    `uvm_object_utils_end
    function new(string name = "ssp_transaction");
        super.new(name);
    endfunction : new
endclass : ssp_transaction