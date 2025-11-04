class main_interrupt_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(main_interrupt_seq)

    function new(string name = "main_interrupt_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("main_interrupt_seq", "=== Combined Interrupt (SSPINTR) Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 2: Enable ALL interrupt sources in SSPIMSC
        // [3]=1 (TX interrupt), [2]=1 (RX interrupt), [1]=1 (Overrun), [0]=1 (Timeout)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h000F; // All 4 interrupt sources enabled
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 2: SSPIMSC configured - ALL interrupt sources enabled (0x000F)", UVM_MEDIUM)

        // Step 3: Trigger TX Interrupt
        // Write data to TX FIFO (should trigger TX interrupt at threshold)
        `uvm_info("main_interrupt_seq", "Step 3: Triggering TX Interrupt - Writing to TX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 5; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'hDD00 + i;  // Data: 0xDD00-0xDD04
            finish_item(tx);
            `uvm_info("main_interrupt_seq", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'hDD00 + i), UVM_MEDIUM)
        end
        `uvm_info("main_interrupt_seq", "        → SSPINTR should be HIGH (TX interrupt active)", UVM_MEDIUM)

        // Step 4: Wait and observe combined interrupt
        #1000;
        `uvm_info("main_interrupt_seq", "Step 4: Waiting 1000ns - SSPINTR should remain HIGH", UVM_MEDIUM)

        // Step 5: Trigger RX Interrupt
        // Write data to RX FIFO (representing received data)
        `uvm_info("main_interrupt_seq", "Step 5: Triggering RX Interrupt - Writing to RX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 6; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'hEE00 + i;  // Data: 0xEE00-0xEE05
            finish_item(tx);
            `uvm_info("main_interrupt_seq", $sformatf("  RX FIFO write #%0d: 0x%04x", i+1, 16'hEE00 + i), UVM_MEDIUM)
        end
        `uvm_info("main_interrupt_seq", "        → SSPINTR should remain HIGH (both TX and RX active)", UVM_MEDIUM)

        // Step 6: Wait with multiple interrupts active
        #1000;
        `uvm_info("main_interrupt_seq", "Step 6: Waiting 1000ns - SSPINTR HIGH (multiple sources active)", UVM_MEDIUM)

        // Step 7: Trigger Overrun Interrupt
        // Continue writing while RX FIFO full (causes overrun)
        `uvm_info("main_interrupt_seq", "Step 7: Triggering Overrun Interrupt - Writing while FIFO full...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'hFF00 + i;  // Data: 0xFF00-0xFF03 (overrun trigger)
            finish_item(tx);
        end
        `uvm_info("main_interrupt_seq", "        → SSPINTR should remain HIGH (TX, RX, and Overrun active)", UVM_MEDIUM)

        // Step 8: Wait with three interrupts active
        #1000;
        `uvm_info("main_interrupt_seq", "Step 8: Waiting 1000ns - SSPINTR HIGH (TX, RX, Overrun active)", UVM_MEDIUM)

        // Step 9: Trigger Timeout Interrupt
        // Leave unread data in FIFO and wait for timeout
        `uvm_info("main_interrupt_seq", "Step 9: Triggering Timeout Interrupt - Bus idle with unread data...", UVM_MEDIUM)
        #2000;
        `uvm_info("main_interrupt_seq", "        → SSPINTR should remain HIGH (all 4 interrupts potentially active)", UVM_MEDIUM)

        // Step 10: Start clearing interrupts one by one
        // Read from FIFO (should reduce RX interrupt if FIFO empties)
        `uvm_info("main_interrupt_seq", "Step 10: Reading from SSPDR to clear RX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 5; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR
            tx.data  = 16'h0000;
            finish_item(tx);
        end
        `uvm_info("main_interrupt_seq", "        → SSPINTR behavior depends on remaining active interrupts", UVM_MEDIUM)

        // Step 11: Clear Overrun interrupt
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h020;  // SSPICR (Interrupt Clear Register)
        tx.data  = 16'h0002; // Clear Overrun (RORIC)
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 11: Clearing Overrun Interrupt via SSPICR", UVM_MEDIUM)
        #500;

        // Step 12: Clear Timeout interrupt
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h020;  // SSPICR
        tx.data  = 16'h0004; // Clear Timeout (RTIC)
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 12: Clearing Timeout Interrupt via SSPICR", UVM_MEDIUM)
        #500;

        // Step 13: Mask all interrupts
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // Disable ALL interrupt sources
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 13: Masking all interrupts in SSPIMSC (0x0000)", UVM_MEDIUM)
        #500;
        `uvm_info("main_interrupt_seq", "        → SSPINTR should now be LOW (all masked)", UVM_MEDIUM)

        // Step 14: Re-enable one interrupt source to verify independence
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0008; // Enable only TX interrupt
        finish_item(tx);
        `uvm_info("main_interrupt_seq", "Step 14: Re-enabling TX interrupt in SSPIMSC", UVM_MEDIUM)
        #500;
        `uvm_info("main_interrupt_seq", "        → SSPINTR behavior depends on TX interrupt status", UVM_MEDIUM)

        `uvm_info("main_interrupt_seq", "=== Combined Interrupt (SSPINTR) Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : main_interrupt_seq
