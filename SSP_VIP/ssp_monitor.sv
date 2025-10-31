class ssp_monitor extends uvm_monitor;
    `uvm_component_utils(ssp_monitor)
    virtual ssp_if ssp_vif;
    uvm_analysis_port #(ssp_transaction) monitor_port;
    bit ssp_enable;
    // -------------------------------------------------------------
    function new(string name="ssp_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_port = new("monitor_port", this);
        if(!uvm_config_db#(virtual ssp_if)::get(this, "", "ssp_vif", ssp_vif))
            `uvm_fatal(get_type_name(), "Failed to get ssp_vif from config_db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (ssp_vif.PRESETn == 1);
        fork
            apb_register();
            //communication();
        join_none
    endtask


    //   APB REGISTER MONITOR

   task apb_register();
        forever begin
            ssp_transaction trans;
            trans = ssp_transaction::type_id::create("trans", this);
            @(posedge ssp_vif.PCLK);
            if (ssp_vif.PSEL && ssp_vif.PENABLE) begin
                trans.addr = ssp_vif.PADDR;
                $cast(trans.r_w , ssp_vif.PWRITE);
            if (ssp_vif.PWRITE == 1) begin
                trans.data = ssp_vif.PWDATA;
                case (ssp_vif.PADDR)
                        'h00: begin // SSPCR0
                            $cast(trans.frame_data,ssp_vif.PWDATA[5:4]);
                            $cast(trans.spi_setup,ssp_vif.PWDATA[7:6]);
                            `uvm_info(get_type_name(), $sformatf("Frame format set to %0s", trans.frame_data), UVM_LOW)
                        end
                        'h04: begin // SSPCR1
                            $cast(trans.config_mode,ssp_vif.PWDATA[2]);
                            if (trans.config_mode==ssp_transaction::MASTER) begin
                                `uvm_info(get_type_name(), $sformatf("Master MODE !!!!!!"), UVM_LOW)
                            end else begin
                                `uvm_info(get_type_name(), $sformatf("Slave MODE !!!!!!"), UVM_LOW)
                            end
                            ssp_enable = ssp_vif.PWDATA[1];
                        end
                endcase
            end           
            @(posedge ssp_vif.PCLK);#1ps;
            if (ssp_vif.PWRITE == 0) begin
                trans.data = ssp_vif.PRDATA;
            end
            `uvm_info(get_type_name(),$sformatf("Observed transaction : \n %s",trans.sprint()),UVM_LOW)
            monitor_port.write(trans);
            end
        end
    endtask


    // 
    //   COMMUNICATION MONITOR
 
    task communication();
        wait(ssp_enable == 1);
        forever begin
            // Chờ frame bắt đầu
            ssp_transaction trans;
            trans = ssp_transaction::type_id::create("trans", this);
            @(negedge ssp_vif.SSPFSSOUT or negedge ssp_vif.SSPFSSIN);
            case (trans.frame_data)
                ssp_transaction::SPI: begin
                    if (trans.config_mode == ssp_transaction::MASTER)
                        capture_spi_master(trans);
                    else
                        capture_spi_slave(trans);
                end
                ssp_transaction::TI: begin
                    if (trans.config_mode == ssp_transaction::MASTER)
                        capture_ti_master(trans);
                    else
                        capture_ti_slave(trans);
                end
                ssp_transaction::MICROWIRE: begin
                    if (trans.config_mode == ssp_transaction::MASTER)
                        capture_microwire_master(trans);
                    else
                        `uvm_error(get_type_name(), $sformatf("MICROWIRE no supportor SLAVE MODE")) 
                end
            endcase

            monitor_port.write(trans);
        end
    endtask

    // --- SPI Master ---
    task capture_spi_master(inout ssp_transaction tr);
        bit [15:0] tx=0, rx=0;
        `uvm_info("SPI_MASTER","Frame start",UVM_LOW)
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKOUT);
            tx = {tx[14:0], ssp_vif.SSPTXD};
            rx = {rx[14:0], ssp_vif.SSPRXD};
        end
        tr.SSPTXD = tx; tr.SSPRXD = rx;
        `uvm_info("SPI_MASTER",$sformatf("TX=0x%0h RX=0x%0h",tx,rx),UVM_LOW)
    endtask

    // --- SPI Slave ---
    task capture_spi_slave(inout ssp_transaction tr);
        bit [15:0] tx=0, rx=0;
        `uvm_info("SPI_SLAVE","Frame start",UVM_LOW)
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKIN);
            tx = {tx[14:0], ssp_vif.SSPTXD};
            rx = {rx[14:0], ssp_vif.SSPRXD};
        end
        tr.SSPTXD = tx; tr.SSPRXD = rx;
        `uvm_info("SPI_SLAVE",$sformatf("TX=0x%0h RX=0x%0h",tx,rx),UVM_LOW)
    endtask

    // --- TI Master ---
    task capture_ti_master(inout ssp_transaction tr);
        bit [15:0] tx=0, rx=0;
        `uvm_info("TI_MASTER","Frame start",UVM_LOW)
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKOUT);
            tx = {tx[14:0], ssp_vif.SSPTXD};
            rx = {rx[14:0], ssp_vif.SSPRXD};
        end
        tr.SSPTXD = tx; tr.SSPRXD = rx;
    endtask

    // --- TI Slave ---
    task capture_ti_slave(inout ssp_transaction tr);
        bit [15:0] tx=0, rx=0;
        `uvm_info("TI_SLAVE","Frame start",UVM_LOW)
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKIN);
            tx = {tx[14:0], ssp_vif.SSPTXD};
            rx = {rx[14:0], ssp_vif.SSPRXD};
        end
        tr.SSPTXD = tx; tr.SSPRXD = rx;
    endtask

    // --- Microwire Master ---
    task capture_microwire_master(inout ssp_transaction tr);
        bit [15:0] tx=0, rx=0;
        `uvm_info("MW_MASTER","Frame start",UVM_LOW)
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKOUT);
            tx = {tx[14:0], ssp_vif.SSPTXD};
        end
        @(posedge ssp_vif.SSPCLKOUT);
        repeat (8) begin
            @(posedge ssp_vif.SSPCLKOUT);
            rx = {rx[14:0], ssp_vif.SSPRXD};
        end
        tr.SSPTXD = tx; tr.SSPRXD = rx;
    endtask

   

endclass
