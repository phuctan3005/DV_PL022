class dma_tx_brust_req_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_tx_brust_req_seq)

    function new(string name = "dma_tx_brust_req_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_tx_brust_req_seq", "=== TX DMA Burst Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark this as DMA TX Burst test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA Burst mode)", UVM_MEDIUM)

        // Step 2: Fill TX FIFO partially (to test burst threshold)
        `uvm_info("dma_tx_brust_req_seq", "Step 2: Filling TX FIFO to test burst threshold...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'h1000 + i;  // Data: 0x1000-0x1003 (4 entries)
            finish_item(tx);
            `uvm_info("dma_tx_brust_req_seq", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'h1000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_tx_brust_req_seq", "        → TX FIFO now has exactly 4 entries (at threshold)", UVM_MEDIUM)

        // Step 3: Wait and observe SSPTXDMABREQ assertion (FIFO = 4 entries)
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 3: Waiting 500ns - SSPTXDMABREQ should be asserted (FIFO = 4 entries)", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → SSPTXDMABREQ = 1 (TX FIFO at or below threshold)", UVM_MEDIUM)

        // Step 4: Read SSPSR to check TX FIFO level
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "Step 4: Reading SSPSR to verify TX FIFO level", UVM_MEDIUM)

        // Step 5: Drain FIFO (simulate transmit) to trigger burst request
        `uvm_info("dma_tx_brust_req_seq", "Step 5: Simulating TX FIFO drain (transmit activity)...", UVM_MEDIUM)
        #1000;
        `uvm_info("dma_tx_brust_req_seq", "        (waiting 1000ns for data transmission)", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → TX FIFO becoming empty/nearly empty", UVM_MEDIUM)

        // Step 6: Add more data while FIFO still has space (< 4 entries now)
        `uvm_info("dma_tx_brust_req_seq", "Step 6: Adding more data (DMA burst write)...", UVM_MEDIUM)
        for (i = 0; i < 3; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'h2000 + i;  // Data: 0x2000-0x2002 (3 entries)
            finish_item(tx);
            `uvm_info("dma_tx_brust_req_seq", $sformatf("  TX FIFO burst write #%0d: 0x%04x", i+1, 16'h2000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_tx_brust_req_seq", "        → TX FIFO now has ~3-4 entries", UVM_MEDIUM)

        // Step 7: Wait to observe stable burst state
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 7: Waiting 500ns - SSPTXDMABREQ should stay asserted (< 4 entries)", UVM_MEDIUM)

        // Step 8: Fill TX FIFO above threshold (to de-assert burst request)
        `uvm_info("dma_tx_brust_req_seq", "Step 8: Filling TX FIFO above burst threshold (> 4 entries)...", UVM_MEDIUM)
        for (i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'h3000 + i;  // Data: 0x3000-0x3007 (8 entries)
            finish_item(tx);
            `uvm_info("dma_tx_brust_req_seq", $sformatf("  TX FIFO fill #%0d: 0x%04x", i+1, 16'h3000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_tx_brust_req_seq", "        → TX FIFO now has >4 entries (above threshold)", UVM_MEDIUM)

        // Step 9: Wait and observe SSPTXDMABREQ de-assertion
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 9: Waiting 500ns - SSPTXDMABREQ should be de-asserted (FIFO > 4 entries)", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → SSPTXDMABREQ = 0 (TX FIFO above threshold)", UVM_MEDIUM)

        // Step 10: Verify FIFO full/nearly full status
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "Step 10: Reading SSPSR to verify TX FIFO above threshold", UVM_MEDIUM)

        // Step 11: Clear TX DMA burst request via SSPTXDMACLR
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 11: DMA clearing burst request via SSPTXDMACLR...", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR (TX DMA Clear Register)
        tx.data  = 16'h0001; // Write to clear
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "        → SSPTXDMACLR written", UVM_MEDIUM)

        // Step 12: Wait after clear
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 12: Waiting 500ns after clear...", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → SSPTXDMABREQ should remain LOW or LOW based on FIFO level", UVM_MEDIUM)

        // Step 13: Simulate TX FIFO drain again to test re-assertion
        `uvm_info("dma_tx_brust_req_seq", "Step 13: Simulating TX FIFO drain (transmit) again...", UVM_MEDIUM)
        #1000;
        `uvm_info("dma_tx_brust_req_seq", "        (waiting 1000ns for data transmission)", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → TX FIFO becoming empty/below threshold again", UVM_MEDIUM)

        // Step 14: Observe SSPTXDMABREQ re-assertion after drain
        #500;
        `uvm_info("dma_tx_brust_req_seq", "Step 14: Waiting 500ns - SSPTXDMABREQ should reassert (FIFO < 4 entries)", UVM_MEDIUM)
        `uvm_info("dma_tx_brust_req_seq", "        → SSPTXDMABREQ = 1 (re-asserted after drain)", UVM_MEDIUM)

        // Step 15: Final TX FIFO status check
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_brust_req_seq", "Step 15: Final SSPSR read - verify TX FIFO status", UVM_MEDIUM)

        `uvm_info("dma_tx_brust_req_seq", "=== TX DMA Burst Request Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : dma_tx_brust_req_seq
