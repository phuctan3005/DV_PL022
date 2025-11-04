// ============================================================================
// File: rx_o_interrupt_seq.sv
// Description: Sequence to verify Receive Overrun Interrupt (SSPRORINTR)
//              - Fill RX FIFO to full (8 entries)
//              - Send additional frames while FIFO is full (create overrun)
//              - Verify SSPRORINTR = 1 and SSPSR[ROR] = 1
//              - Clear overrun using SSPICR[0] (RORIC)
//              - Verify SSPRORINTR = 0 and SSPSR[ROR] = 0
// ============================================================================

class rx_o_interrupt_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(rx_o_interrupt_seq)

    function new(string name = "rx_o_interrupt_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("rx_o_interrupt_seq", "=== RX Overrun Interrupt Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("rx_o_interrupt_seq", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 2: Enable RX Overrun interrupt in SSPIMSC
        // [1]=1 (enable receive overrun interrupt mask)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0002; // RORIM=1 (Receive Overrun Interrupt Mask)
        finish_item(tx);
        `uvm_info("rx_o_interrupt_seq", "Step 2: SSPIMSC configured - RX overrun interrupt enabled", UVM_MEDIUM)

        // Step 3: Fill RX FIFO to full (8 valid entries)
        `uvm_info("rx_o_interrupt_seq", "Step 3: Filling RX FIFO to full capacity (8 entries)...", UVM_MEDIUM)
        for (i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'hA500 + i;  // Data: 0xA500-0xA507
            finish_item(tx);
            `uvm_info("rx_o_interrupt_seq", $sformatf("  FIFO write #%0d: 0x%04x", i+1, 16'hA500 + i), UVM_MEDIUM)
        end

        // Step 4: Send additional frames to create overrun condition
        // FIFO is full, so new data cannot be stored → creates overrun
        `uvm_info("rx_o_interrupt_seq", "Step 4: Sending additional frames to trigger overrun (FIFO is full)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'h5A00 + i;  // Data: 0x5A00-0x5A03 (will trigger overrun)
            finish_item(tx);
            `uvm_info("rx_o_interrupt_seq", $sformatf("  Overrun trigger write #%0d: 0x%04x", i+1, 16'h5A00 + i), UVM_MEDIUM)
        end

        // Step 5: Wait for overrun condition to be latched
        #1000;
        `uvm_info("rx_o_interrupt_seq", "Step 5: Waiting for overrun condition to settle (1000ns)...", UVM_MEDIUM)
        `uvm_info("rx_o_interrupt_seq", "        SSPRORINTR should be HIGH, SSPSR[ROR] should be 1", UVM_MEDIUM)

        // Step 6: Read SSPSR to verify ROR flag is set
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("rx_o_interrupt_seq", "Step 6: Reading SSPSR to verify ROR flag (bit 3) is set", UVM_MEDIUM)

        // Step 7: Clear the overrun condition using SSPICR[0] (RORIC)
        // Write 1 to SSPICR[0] to clear the overrun interrupt and ROR flag
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h020;  // SSPICR (Interrupt Clear Register)
        tx.data  = 16'h0001; // RORIC=1 (Clear Receive Overrun interrupt)
        finish_item(tx);
        `uvm_info("rx_o_interrupt_seq", "Step 7: SSPICR configured - Writing 1 to RORIC to clear overrun", UVM_MEDIUM)

        // Step 8: Wait for clear operation to complete
        #500;
        `uvm_info("rx_o_interrupt_seq", "Step 8: Waiting for clear operation (500ns)...", UVM_MEDIUM)
        `uvm_info("rx_o_interrupt_seq", "        SSPRORINTR should be LOW, SSPSR[ROR] should be 0", UVM_MEDIUM)

        // Step 9: Read SSPSR again to verify ROR flag is cleared
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("rx_o_interrupt_seq", "Step 9: Reading SSPSR to verify ROR flag is cleared (bit 3 = 0)", UVM_MEDIUM)

        `uvm_info("rx_o_interrupt_seq", "=== RX Overrun Interrupt Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : rx_o_interrupt_seq
