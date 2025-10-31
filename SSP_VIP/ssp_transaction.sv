class ssp_transaction extends uvm_sequence_item;
    typedef enum bit { WRITE = 1 , READ = 0} transfer;
    rand transfer r_w;
    typedef enum bit { MASTER = 1 , SLAVE = 0} cf;
    rand cf config_mode;
    typedef enum bit[1:0] { SPI = 2'b00 , TI = 2'b01,MICROWIRE = 2'b10} fd;
    rand fd frame_data;
    typedef enum bit[1:0] { CPOL_CPHA_00 = 2'b00 , CPOL_CPHA_01 = 2'b01,CPOL_CPHA_10 = 2'b10 ,CPOL_CPHA_11 = 2'b11} SPI_setup;
    rand SPI_setup spi_setup;
    rand bit [11:0] addr;
    rand bit [15:0] data;
    
    bit        [15:0] SSPRXD;
    bit        [15:0] SSPTXD;

    `uvm_object_utils_begin (ssp_transaction)
        `uvm_field_enum (transfer,r_w           ,UVM_ALL_ON||UVM_HEX )
        `uvm_field_enum (cf,config_mode           ,UVM_ALL_ON||UVM_HEX )
        `uvm_field_enum (fd,frame_data           ,UVM_ALL_ON||UVM_HEX )
        `uvm_field_int (addr                    ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (data                    ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPRXD                  ,UVM_ALL_ON||UVM_HEX)
        `uvm_field_int (SSPTXD                  ,UVM_ALL_ON||UVM_HEX)
    `uvm_object_utils_end
    function new(string name = "ssp_transaction");
        super.new(name);
    endfunction : new
endclass : ssp_transaction