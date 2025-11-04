class dma_rx_single_req_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_rx_single_req_seq)

    function new(string name = "dma_rx_single_req_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_rx_single_req_seq", "=== RX DMA Single Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (slave mode for RX), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Slave mode for RX, TXD active
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "Step 1: SSPCR1 configured (SSE=1, Slave, RX active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark this as DMA RX test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA RX mode)", UVM_MEDIUM)

        // Step 2: Simulate receiving data from external source
        // Write to RX FIFO (simulating received data)
        `uvm_info("dma_rx_single_req_seq", "Step 2: Simulating received data into RX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register - RX FIFO)
            tx.data  = 16'h2000 + i;  // Simulated RX data: 0x2000-0x2003
            finish_item(tx);
            `uvm_info("dma_rx_single_req_seq", $sformatf("  RX data simulated #%0d: 0x%04x", i+1, 16'h2000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_single_req_seq", "        → RX FIFO now has 4 entries", UVM_MEDIUM)

        // Step 3: Wait for SSPRXDMASREQ to assert
        #500;
        `uvm_info("dma_rx_single_req_seq", "Step 3: Waiting 500ns - SSPRXDMASREQ should be asserted (FIFO has data)", UVM_MEDIUM)
        `uvm_info("dma_rx_single_req_seq", "        → SSPRXDMASREQ = 1 (RX FIFO not empty)", UVM_MEDIUM)

        // Step 4: Verify RX FIFO not empty by reading SSPSR
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "Step 4: Reading SSPSR to verify RX FIFO not empty", UVM_MEDIUM)

        // Step 5: DMA services - read data from RX FIFO (simulating DMA controller reading)
        `uvm_info("dma_rx_single_req_seq", "Step 5: DMA controller reading from RX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 2; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (reading from RX FIFO)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_rx_single_req_seq", $sformatf("  DMA read #%0d from RX FIFO", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_single_req_seq", "        → DMA read 2 entries, FIFO still has 2 more", UVM_MEDIUM)

        // Step 6: Clear RX DMA request via SSPRXDMACLR
        #500;
        `uvm_info("dma_rx_single_req_seq", "Step 6: DMA clearing RX request via SSPRXDMACLR...", UVM_MEDIUM)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h024;  // SSPRXDMACLR (RX DMA Clear Register)
        tx.data  = 16'h0001; // Write to clear
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "        → SSPRXDMACLR written", UVM_MEDIUM)

        // Step 7: Wait after clear
        #500;
        `uvm_info("dma_rx_single_req_seq", "Step 7: Waiting 500ns after clear...", UVM_MEDIUM)
        `uvm_info("dma_rx_single_req_seq", "        → SSPRXDMASREQ should now be LOW (after clear)", UVM_MEDIUM)

        // Step 8: Continue reading remaining data from RX FIFO
        `uvm_info("dma_rx_single_req_seq", "Step 8: Continuing to read remaining RX FIFO data...", UVM_MEDIUM)
        for (i = 0; i < 2; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_rx_single_req_seq", $sformatf("  DMA read #%0d from RX FIFO (after clear)", i+3), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_single_req_seq", "        → RX FIFO now empty (all 4 entries read)", UVM_MEDIUM)

        // Step 9: Verify RX FIFO is now empty
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "Step 9: Reading SSPSR to verify RX FIFO empty", UVM_MEDIUM)

        // Step 10: Simulate new data arriving (reassertion scenario)
        `uvm_info("dma_rx_single_req_seq", "Step 10: Simulating new data arrival for reassertion...", UVM_MEDIUM)
        for (i = 0; i < 3; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (RX FIFO)
            tx.data  = 16'h3000 + i;  // New RX data: 0x3000-0x3002
            finish_item(tx);
            `uvm_info("dma_rx_single_req_seq", $sformatf("  New RX data #%0d: 0x%04x", i+1, 16'h3000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_rx_single_req_seq", "        → RX FIFO has new data, SSPRXDMASREQ should reassert", UVM_MEDIUM)

        // Step 11: Wait to observe reassertion
        #1000;
        `uvm_info("dma_rx_single_req_seq", "Step 11: Waiting 1000ns - observing SSPRXDMASREQ reassertion...", UVM_MEDIUM)

        // Step 12: Final RX FIFO status check
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_rx_single_req_seq", "Step 12: Final SSPSR read - verify RX FIFO status", UVM_MEDIUM)

        `uvm_info("dma_rx_single_req_seq", "=== RX DMA Single Request Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : dma_rx_single_req_seq
