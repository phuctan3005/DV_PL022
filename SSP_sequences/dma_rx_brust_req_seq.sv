class dma_rx_brust_req_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_rx_brust_req_seq)

    function new(string name = "dma_rx_brust_req_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_rx_brust_req_seq", "=== RX DMA Burst Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (slave mode for RX), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Slave mode for RX, TXD active
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "Step 1: SSPCR1 configured (SSE=1, Slave, RX active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark this as DMA RX Burst test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA RX Burst mode)", UVM_MEDIUM)

        // Step 2: Simulate receiving initial burst of data (exactly 4 entries - at threshold)
        `uvm_info("dma_rx_brust_req_seq", "Step 2: Simulating initial RX burst (4 entries at threshold)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register - RX FIFO)
            tx.data  = 16'h2000 + i;  // Simulated RX data: 0x2000-0x2003
            finish_item(tx);
            `uvm_info("dma_rx_brust_req_seq", $sformatf("  RX burst data #%0d: 0x%04x", i+1, 16'h2000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_brust_req_seq", "        → RX FIFO now has exactly 4 entries (at threshold)", UVM_MEDIUM)

        // Step 3: Wait for SSPR XDMABREQ to assert
        #500;
        `uvm_info("dma_rx_brust_req_seq", "Step 3: Waiting 500ns - SSPR XDMABREQ should be asserted (FIFO = 4 entries)", UVM_MEDIUM)
        `uvm_info("dma_rx_brust_req_seq", "        → SSPR XDMABREQ = 1 (RX FIFO at threshold)", UVM_MEDIUM)

        // Step 4: Verify RX FIFO not empty by reading SSPSR
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "Step 4: Reading SSPSR to verify RX FIFO status", UVM_MEDIUM)

        // Step 5: Add more data to exceed threshold (>4 entries)
        `uvm_info("dma_rx_brust_req_seq", "Step 5: Adding more burst data (exceeding threshold)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (RX FIFO)
            tx.data  = 16'h3000 + i;  // More RX data: 0x3000-0x3003
            finish_item(tx);
            `uvm_info("dma_rx_brust_req_seq", $sformatf("  RX burst data #%0d: 0x%04x", i+5, 16'h3000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_brust_req_seq", "        → RX FIFO now has 8 entries (well above threshold)", UVM_MEDIUM)

        // Step 6: Wait to observe stable burst state
        #500;
        `uvm_info("dma_rx_brust_req_seq", "Step 6: Waiting 500ns - SSPR XDMABREQ should stay asserted (FIFO = 8 entries)", UVM_MEDIUM)
        `uvm_info("dma_rx_brust_req_seq", "        → SSPR XDMABREQ = 1 (remains asserted above threshold)", UVM_MEDIUM)

        // Step 7: DMA services - read data from RX FIFO (reducing level)
        `uvm_info("dma_rx_brust_req_seq", "Step 7: DMA controller reading from RX FIFO (servicing burst)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (reading from RX FIFO)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_rx_brust_req_seq", $sformatf("  DMA read #%0d from RX FIFO", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_brust_req_seq", "        → DMA read 4 entries, FIFO now has 4 remaining (at threshold)", UVM_MEDIUM)

        // Step 8: Wait to observe continued assertion at threshold
        #500;
        `uvm_info("dma_rx_brust_req_seq", "Step 8: Waiting 500ns - SSPR XDMABREQ should stay asserted (FIFO = 4 entries)", UVM_MEDIUM)

        // Step 9: Clear RX DMA burst request via SSPRXDMACLR
        #500;
        `uvm_info("dma_rx_brust_req_seq", "Step 9: DMA clearing RX burst request via SSPRXDMACLR...", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR (RX DMA Clear Register)
        tx.data  = 16'h0001; // Write to clear
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "        → SSPRXDMACLR written", UVM_MEDIUM)

        // Step 10: Wait after clear
        #500;
        `uvm_info("dma_rx_brust_req_seq", "Step 10: Waiting 500ns after clear...", UVM_MEDIUM)
        `uvm_info("dma_rx_brust_req_seq", "        → SSPR XDMABREQ should now be LOW (after clear)", UVM_MEDIUM)

        // Step 11: Continue reading remaining data
        `uvm_info("dma_rx_brust_req_seq", "Step 11: Continuing to read remaining RX FIFO data...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_rx_brust_req_seq", $sformatf("  DMA read #%0d from RX FIFO (after clear)", i+5), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_brust_req_seq", "        → RX FIFO now empty (all 8 entries read)", UVM_MEDIUM)

        // Step 12: Verify RX FIFO is now empty
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "Step 12: Reading SSPSR to verify RX FIFO empty", UVM_MEDIUM)

        // Step 13: Simulate new burst arriving (reassertion scenario)
        `uvm_info("dma_rx_brust_req_seq", "Step 13: Simulating new RX burst for reassertion test...", UVM_MEDIUM)
        for (i = 0; i < 5; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (RX FIFO)
            tx.data  = 16'h4000 + i;  // New RX data: 0x4000-0x4004
            finish_item(tx);
            `uvm_info("dma_rx_brust_req_seq", $sformatf("  New RX burst data #%0d: 0x%04x", i+1, 16'h4000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_brust_req_seq", "        → RX FIFO has new 5 entries, SSPR XDMABREQ should reassert", UVM_MEDIUM)

        // Step 14: Wait to observe reassertion
        #1000;
        `uvm_info("dma_rx_brust_req_seq", "Step 14: Waiting 1000ns - observing SSPR XDMABREQ reassertion...", UVM_MEDIUM)
        `uvm_info("dma_rx_brust_req_seq", "        → SSPR XDMABREQ = 1 (re-asserted with new burst)", UVM_MEDIUM)

        // Step 15: Final RX FIFO status check
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_brust_req_seq", "Step 15: Final SSPSR read - verify RX FIFO status", UVM_MEDIUM)

        `uvm_info("dma_rx_brust_req_seq", "=== RX DMA Burst Request Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : dma_rx_brust_req_seq
