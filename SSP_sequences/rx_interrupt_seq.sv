class rx_interrupt_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(rx_interrupt_seq)

    function new(string name = "rx_interrupt_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        ssp_transaction tx;
        
        `uvm_info(get_type_name(), "=== Starting RX Interrupt Test Sequence ===", UVM_LOW)
        
        // 1. Configure SSPCR1: Disable loopback, Enable SSP, Set Master mode, TXD active
        `uvm_info(get_type_name(), "Step 1: Configure SSPCR1 - Enable SSP, TXD active", UVM_LOW)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.addr = 12'h004;  // SSPCR1 address
        tx.r_w = ssp_transaction::WRITE;
        tx.data = 16'h0002; // [0]=0 (no loopback), [1]=1 (SSE=1), [2]=0 (master), [3]=0 (TXD active)
        finish_item(tx);
        #100;

        // 2. Enable RX interrupt in SSPIMSC
        `uvm_info(get_type_name(), "Step 2: Enable RX interrupt in SSPIMSC", UVM_LOW)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.addr = 12'h014;  // SSPIMSC address
        tx.r_w = ssp_transaction::WRITE;
        tx.data = 16'h0004; // [2]=1 Enable RX interrupt
        finish_item(tx);
        #100;

        // 3. Simulate RX FIFO filling with data (write to receive buffer simulation)
        // In real scenario, data comes from external source
        `uvm_info(get_type_name(), "Step 3: Fill RX FIFO with 8 entries (>= 4)", UVM_LOW)
        for(int i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create($sformatf("rx_write_%0d", i));
            start_item(tx);
            tx.addr = 12'h008; // SSPDR address (simulating RX data)
            tx.r_w = ssp_transaction::WRITE;
            tx.data = 16'hB500 + i; // RX test data pattern
            finish_item(tx);
        end
        #500;

        // 4. Read data from RX FIFO to trigger interrupt threshold changes
        `uvm_info(get_type_name(), "Step 4: Reading RX FIFO data to drop below threshold (< 4)", UVM_LOW)
        for(int i = 0; i < 5; i++) begin
            tx = ssp_transaction::type_id::create($sformatf("rx_read_%0d", i));
            start_item(tx);
            tx.addr = 12'h008; // SSPDR address
            tx.r_w = ssp_transaction::READ;
            tx.data = 16'h0000;
            finish_item(tx);
        end
        #500;
        `uvm_info(get_type_name(), "Step 4: FIFO should have < 4 entries now, SSPRXINTR should be LOW", UVM_LOW)

        // 5. Refill RX FIFO above threshold again
        `uvm_info(get_type_name(), "Step 5: Refill RX FIFO with 5 more entries (>= 4)", UVM_LOW)
        for(int i = 0; i < 5; i++) begin
            tx = ssp_transaction::type_id::create($sformatf("rx_refill_%0d", i));
            start_item(tx);
            tx.addr = 12'h008; // SSPDR address
            tx.r_w = ssp_transaction::WRITE;
            tx.data = 16'h6B00 + i; // Different RX data pattern
            finish_item(tx);
        end
        #500;
        
        `uvm_info(get_type_name(), "Step 5: FIFO should have >= 4 entries now, SSPRXINTR should be HIGH", UVM_LOW)
        
        #500;
        `uvm_info(get_type_name(), "=== RX Interrupt Test Sequence Completed ===", UVM_LOW)
    endtask : body
endclass : rx_interrupt_seq
