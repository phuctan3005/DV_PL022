class rx_t_interrupt_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(rx_t_interrupt_seq)

    function new(string name = "rx_t_interrupt_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("rx_t_interrupt_seq", "=== RX Timeout Interrupt Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("rx_t_interrupt_seq", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 2: Enable RX Timeout interrupt in SSPIMSC
        // [0]=1 (enable receive timeout interrupt mask - RTIM bit)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0001; // RTIM=1 (Receive Timeout Interrupt Mask)
        finish_item(tx);
        `uvm_info("rx_t_interrupt_seq", "Step 2: SSPIMSC configured - RX timeout interrupt enabled", UVM_MEDIUM)

        // Step 3: Write several data frames to simulate received data
        // These represent data that has been received and is sitting in FIFO
        `uvm_info("rx_t_interrupt_seq", "Step 3: Writing data frames to RX FIFO (simulating received data)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'hC000 + i;  // Data: 0xC000-0xC003
            finish_item(tx);
            `uvm_info("rx_t_interrupt_seq", $sformatf("  Data frame write #%0d: 0x%04x", i+1, 16'hC000 + i), UVM_MEDIUM)
        end

        // Step 4: Wait for idle period (longer than 32-bit timeout)
        // PL022 timeout = 32-bit period with no activity
        // We wait 2000ns to ensure timeout condition triggers
        `uvm_info("rx_t_interrupt_seq", "Step 4: Waiting for timeout period (bus idle, no new data)...", UVM_MEDIUM)
        `uvm_info("rx_t_interrupt_seq", "        (waiting 2000ns for 32-bit timeout to trigger)", UVM_MEDIUM)
        `uvm_info("rx_t_interrupt_seq", "        SSPRTINTR should be HIGH - timeout detected", UVM_MEDIUM)
        #2000;

        // Step 5: Read SSPSR to verify timeout flag status
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("rx_t_interrupt_seq", "Step 5: Reading SSPSR to check timeout status", UVM_MEDIUM)

        // Step 6: Partial FIFO read to show that reading affects timeout
        // Read one entry - if FIFO becomes empty, timeout clears
        `uvm_info("rx_t_interrupt_seq", "Step 6: Reading from SSPDR (consuming data from FIFO)...", UVM_MEDIUM)
        for (i = 0; i < 2; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("rx_t_interrupt_seq", $sformatf("  FIFO read #%0d", i+1), UVM_MEDIUM)
        end

        // Step 7: Wait again (FIFO still has data if we only read 2 of 4)
        `uvm_info("rx_t_interrupt_seq", "Step 7: Waiting again for timeout (still idle with remaining data)...", UVM_MEDIUM)
        #1000;

        // Step 8: Clear timeout interrupt explicitly using SSPICR[1] (RTIC write)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h020;  // SSPICR (Interrupt Clear Register)
        tx.data  = 16'h0002; // RTIC=1 (Clear Receive Timeout interrupt)
        finish_item(tx);
        `uvm_info("rx_t_interrupt_seq", "Step 8: SSPICR configured - Writing 1 to RTIC to clear timeout", UVM_MEDIUM)

        // Step 9: Wait for clear to take effect
        #500;
        `uvm_info("rx_t_interrupt_seq", "Step 9: Waiting for timeout clear (500ns)...", UVM_MEDIUM)
        `uvm_info("rx_t_interrupt_seq", "        SSPRTINTR should be LOW after clear", UVM_MEDIUM)

        // Step 10: Read SSPSR to verify timeout is cleared
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("rx_t_interrupt_seq", "Step 10: Reading SSPSR to verify timeout is cleared", UVM_MEDIUM)

        // Step 11: Verify idle state again (no more timeout asserts until new idle period)
        #1000;
        `uvm_info("rx_t_interrupt_seq", "Step 11: Final idle wait - no new timeout should occur", UVM_MEDIUM)

        `uvm_info("rx_t_interrupt_seq", "=== RX Timeout Interrupt Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : rx_t_interrupt_seq
