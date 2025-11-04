class dma_clear_rx_req extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_clear_rx_req)

    function new(string name = "dma_clear_rx_req");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_clear_rx_req", "=== RX DMA Clear Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark as DMA Clear RX test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA Clear mode)", UVM_MEDIUM)

        // Step 2: Simulate RX FIFO receiving data (drive RX data into FIFO)
        `uvm_info("dma_clear_rx_req", "Step 2: Simulating RX FIFO receiving data...", UVM_MEDIUM)
        for (i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register - simulating RX)
            tx.data  = 16'h3000 + i;  // Data: 0x3000-0x3007 (8 RX entries)
            finish_item(tx);
            `uvm_info("dma_clear_rx_req", $sformatf("  RX FIFO write #%0d: 0x%04x", i+1, 16'h3000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_rx_req", "        → RX FIFO now has 8 entries (SSPRXDMASREQ should be HIGH)", UVM_MEDIUM)

        // Step 3: Wait for DMA requests to assert
        #500;
        `uvm_info("dma_clear_rx_req", "Step 3: Waiting 500ns for SSPRXDMASREQ/SSPRXDMABREQ to assert", UVM_MEDIUM)

        // Step 4: Verify RX FIFO status via SSPSR read
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "Step 4: Read SSPSR - RX FIFO should show data present", UVM_MEDIUM)

        // Step 5: Simulate DMA service (read from FIFO)
        `uvm_info("dma_clear_rx_req", "Step 5: Simulating DMA service (reading from RX FIFO)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (read data)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_clear_rx_req", $sformatf("  RX FIFO read #%0d", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_rx_req", "        → DMA read 4 entries, 4 remain in FIFO", UVM_MEDIUM)

        // Step 6: NOW - Assert SSPRXDMACLR to clear DMA requests
        `uvm_info("dma_clear_rx_req", "Step 6: Asserting SSPRXDMACLR (0x024) to CLEAR RX DMA requests", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR
        tx.data  = 16'h0001; // Assert clear signal
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMACLR = 1 asserted", UVM_MEDIUM)

        // Step 7: Wait and observe SSPRXDMASREQ/SSPRXDMABREQ deasserted
        #500;
        `uvm_info("dma_clear_rx_req", "Step 7: Waiting 500ns with SSPRXDMACLR=1", UVM_MEDIUM)
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMASREQ should be LOW (cleared)", UVM_MEDIUM)
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMABREQ should be LOW (cleared)", UVM_MEDIUM)

        // Step 8: Release SSPRXDMACLR (return to 0)
        `uvm_info("dma_clear_rx_req", "Step 8: Releasing SSPRXDMACLR back to 0", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR
        tx.data  = 16'h0000; // Release clear signal
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMACLR = 0 released", UVM_MEDIUM)

        // Step 9: Wait and check if DMA requests reassert (if FIFO still has data)
        #500;
        `uvm_info("dma_clear_rx_req", "Step 9: After SSPRXDMACLR release, checking if requests reassert", UVM_MEDIUM)
        `uvm_info("dma_clear_rx_req", "        → Expected: SSPRXDMASREQ reasserts (RX FIFO has remaining data)", UVM_MEDIUM)

        // Step 10: Read remaining data from FIFO
        `uvm_info("dma_clear_rx_req", "Step 10: Reading remaining data from RX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (read data)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_clear_rx_req", $sformatf("  RX FIFO read #%0d", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_rx_req", "        → RX FIFO now empty", UVM_MEDIUM)

        // Step 11: Simulate new RX data arriving to verify reassertion cycle
        `uvm_info("dma_clear_rx_req", "Step 11: Simulating new RX data arriving (reassertion cycle)...", UVM_MEDIUM)
        for (i = 0; i < 6; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (simulating RX)
            tx.data  = 16'h4000 + i;  // Data: 0x4000-0x4005 (6 new RX entries)
            finish_item(tx);
            `uvm_info("dma_clear_rx_req", $sformatf("  RX FIFO write #%0d: 0x%04x", i+1, 16'h4000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_rx_req", "        → RX FIFO refilled with 6 entries", UVM_MEDIUM)

        // Step 12: Wait for requests to reassert
        #500;
        `uvm_info("dma_clear_rx_req", "Step 12: Waiting 500ns for SSPRXDMASREQ/SSPRXDMABREQ to reassert", UVM_MEDIUM)
        `uvm_info("dma_clear_rx_req", "        → Requests should be reasserted (RX FIFO has new data)", UVM_MEDIUM)

        // Step 13: Verify with another SSPSR read
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "Step 13: Read SSPSR again - RX FIFO should show data present again", UVM_MEDIUM)

        // Step 14: Read some data to reduce FIFO level
        `uvm_info("dma_clear_rx_req", "Step 14: Reading some data to reduce RX FIFO level...", UVM_MEDIUM)
        for (i = 0; i < 3; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (read data)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_clear_rx_req", $sformatf("  RX FIFO read #%0d", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_clear_rx_req", "        → 3 remaining entries in RX FIFO", UVM_MEDIUM)

        // Step 15: Assert SSPRXDMACLR once more to verify consistent behavior
        `uvm_info("dma_clear_rx_req", "Step 15: Asserting SSPRXDMACLR again (cycle 2)", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR
        tx.data  = 16'h0001; // Assert clear signal (cycle 2)
        finish_item(tx);
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMACLR = 1 asserted (second time)", UVM_MEDIUM)

        // Step 16: Wait and observe final clear
        #500;
        `uvm_info("dma_clear_rx_req", "Step 16: Waiting 500ns - requests should be cleared again", UVM_MEDIUM)
        `uvm_info("dma_clear_rx_req", "        → SSPRXDMASREQ and SSPRXDMABREQ deasserted", UVM_MEDIUM)

        // Release SSPRXDMACLR for clean completion
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR
        tx.data  = 16'h0000; // Release
        finish_item(tx);

        #500;
        `uvm_info("dma_clear_rx_req", "=== RX DMA Clear Request Test Sequence Completed ===", UVM_MEDIUM)

    endtask

endclass : dma_clear_rx_req
