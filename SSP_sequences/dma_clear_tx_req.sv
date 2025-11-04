class dma_clear_tx_req extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_clear_tx_req)

    function new(string name = "dma_clear_tx_req");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_clear_tx_req", "=== TX DMA Clear Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark as DMA Clear TX test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA Clear mode)", UVM_MEDIUM)

        // Step 2: Fill TX FIFO to assert SSPTXDMASREQ (at least 1 entry needed)
        `uvm_info("dma_clear_tx_req", "Step 2: Filling TX FIFO to assert SSPTXDMASREQ...", UVM_MEDIUM)
        for (i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'h1000 + i;  // Data: 0x1000-0x1007 (8 entries)
            finish_item(tx);
            `uvm_info("dma_clear_tx_req", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'h1000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_tx_req", "        → TX FIFO now has 8 entries (SSPTXDMASREQ should be HIGH)", UVM_MEDIUM)

        // Step 3: Wait for DMA requests to assert
        #500;
        `uvm_info("dma_clear_tx_req", "Step 3: Waiting 500ns for SSPTXDMASREQ/SSPTXDMABREQ to assert", UVM_MEDIUM)

        // Step 4: Verify TX FIFO status via SSPSR read
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "Step 4: Read SSPSR - TX FIFO should show data present", UVM_MEDIUM)

        // Step 5: Simulate transmit drain (data leaves FIFO)
        `uvm_info("dma_clear_tx_req", "Step 5: Simulating TX FIFO drain (data transmission)...", UVM_MEDIUM)
        #1000;
        `uvm_info("dma_clear_tx_req", "        → DMA requests should still be asserted (FIFO empty → need more data)", UVM_MEDIUM)

        // Step 6: NOW - Assert SSPTXDMACLR to clear DMA requests
        `uvm_info("dma_clear_tx_req", "Step 6: Asserting SSPTXDMACLR (0x028) to CLEAR TX DMA requests", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR
        tx.data  = 16'h0001; // Assert clear signal
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMACLR = 1 asserted", UVM_MEDIUM)

        // Step 7: Wait and observe SSPTXDMASREQ/SSPTXDMABREQ deasserted
        #500;
        `uvm_info("dma_clear_tx_req", "Step 7: Waiting 500ns with SSPTXDMACLR=1", UVM_MEDIUM)
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMASREQ should be LOW (cleared)", UVM_MEDIUM)
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMABREQ should be LOW (cleared)", UVM_MEDIUM)

        // Step 8: Release SSPTXDMACLR (return to 0)
        `uvm_info("dma_clear_tx_req", "Step 8: Releasing SSPTXDMACLR back to 0", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR
        tx.data  = 16'h0000; // Release clear signal
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMACLR = 0 released", UVM_MEDIUM)

        // Step 9: Wait and check if DMA requests reassert (if FIFO is empty)
        #500;
        `uvm_info("dma_clear_tx_req", "Step 9: After SSPTXDMACLR release, checking if requests reassert", UVM_MEDIUM)
        `uvm_info("dma_clear_tx_req", "        → Expected: SSPTXDMASREQ reasserts (TX FIFO empty → needs data)", UVM_MEDIUM)

        // Step 10: Fill TX FIFO again to verify requests can be reasserted
        `uvm_info("dma_clear_tx_req", "Step 10: Filling TX FIFO again to trigger reassertion...", UVM_MEDIUM)
        for (i = 0; i < 6; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'h2000 + i;  // Data: 0x2000-0x2005 (6 entries)
            finish_item(tx);
            `uvm_info("dma_clear_tx_req", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'h2000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_tx_req", "        → TX FIFO refilled with 6 entries", UVM_MEDIUM)

        // Step 11: Wait for requests to reassert
        #500;
        `uvm_info("dma_clear_tx_req", "Step 11: Waiting 500ns for SSPTXDMASREQ/SSPTXDMABREQ to reassert", UVM_MEDIUM)
        `uvm_info("dma_clear_tx_req", "        → Requests should be reasserted (FIFO has data)", UVM_MEDIUM)

        // Step 12: Verify with another SSPSR read
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "Step 12: Read SSPSR again - TX FIFO should show data present again", UVM_MEDIUM)

        // Step 13: Drain FIFO once more (simulate another transmit cycle)
        `uvm_info("dma_clear_tx_req", "Step 13: Simulating another TX FIFO drain cycle...", UVM_MEDIUM)
        #1000;
        `uvm_info("dma_clear_tx_req", "        → Requests remain asserted (FIFO empty again)", UVM_MEDIUM)

        // Step 14: Assert SSPTXDMACLR once more to verify consistent behavior
        `uvm_info("dma_clear_tx_req", "Step 14: Asserting SSPTXDMACLR again (cycle 2)", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR
        tx.data  = 16'h0001; // Assert clear signal (cycle 2)
        finish_item(tx);
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMACLR = 1 asserted (second time)", UVM_MEDIUM)

        // Step 15: Wait and observe final clear
        #500;
        `uvm_info("dma_clear_tx_req", "Step 15: Waiting 500ns - requests should be cleared again", UVM_MEDIUM)
        `uvm_info("dma_clear_tx_req", "        → SSPTXDMASREQ and SSPTXDMABREQ deasserted", UVM_MEDIUM)

        // Release SSPTXDMACLR for clean completion
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR
        tx.data  = 16'h0000; // Release
        finish_item(tx);

        #500;
        `uvm_info("dma_clear_tx_req", "=== TX DMA Clear Request Test Sequence Completed ===", UVM_MEDIUM)

    endtask

endclass : dma_clear_tx_req
