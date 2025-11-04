class tx_interrupt_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(tx_interrupt_seq)

    function new(string name = "tx_interrupt_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        ssp_transaction tx;
        
        `uvm_info(get_type_name(), "=== Starting TX Interrupt Test Sequence ===", UVM_LOW)
        
        // 1. Configure SSPCR1: Disable loopback, Enable SSP, Set Master mode
        `uvm_info(get_type_name(), "Step 1: Configure SSPCR1 - Enable SSP", UVM_LOW)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.addr = 12'h004;  // SSPCR1 address
        tx.r_w = ssp_transaction::WRITE;
        tx.data = 16'h0002; // [0]=0 (no loopback), [1]=1 (SSE=1), [2]=0 (master), [3]=0 (TXD active)
        finish_item(tx);
        #100;

        // 2. Enable TX interrupt in SSPIMSC
        `uvm_info(get_type_name(), "Step 2: Enable TX interrupt in SSPIMSC", UVM_LOW)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.addr = 12'h014;  // SSPIMSC address
        tx.r_w = ssp_transaction::WRITE;
        tx.data = 16'h0002; // [1]=1 Enable TX interrupt
        finish_item(tx);
        #100;

        // 3. Write multiple data to fill FIFO (>4 entries)
        `uvm_info(get_type_name(), "Step 3: Fill TX FIFO with 8 entries (> 4)", UVM_LOW)
        for(int i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create($sformatf("tx_%0d", i));
            start_item(tx);
            tx.addr = 12'h008; // SSPDR address
            tx.r_w = ssp_transaction::WRITE;
            tx.data = 16'hA500 + i; // Test data pattern
            finish_item(tx);
        end
        #500;

        // 4. Wait for FIFO to drain below threshold (≤4 entries)
        `uvm_info(get_type_name(), "Step 4: Waiting for FIFO to drain...", UVM_LOW)
        #1000;
        `uvm_info(get_type_name(), "Step 4: FIFO should have <= 4 entries now, SSPTXINTR should be HIGH", UVM_LOW)

        // 5. Write more data to refill FIFO (>4 entries)
        `uvm_info(get_type_name(), "Step 5: Refill TX FIFO with 4 more entries", UVM_LOW)
        for(int i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create($sformatf("tx_refill_%0d", i));
            start_item(tx);
            tx.addr = 12'h008; // SSPDR address
            tx.r_w = ssp_transaction::WRITE;
            tx.data = 16'h5A00 + i; // Different test pattern
            finish_item(tx);
        end
        #500;
        
        `uvm_info(get_type_name(), "Step 5: FIFO should have > 4 entries now, SSPTXINTR should be LOW", UVM_LOW)
        
        #500;
        `uvm_info(get_type_name(), "=== TX Interrupt Test Sequence Completed ===", UVM_LOW)
    endtask : body
endclass : tx_interrupt_seq