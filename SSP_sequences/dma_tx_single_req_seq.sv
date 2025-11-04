class dma_tx_single_req_seq extends uvm_sequence #(ssp_transaction);
    `uvm_object_utils(dma_tx_single_req_seq)

    function new(string name = "dma_tx_single_req_seq");
        super.new(name);
    endfunction

    virtual task body();
        ssp_transaction tx;
        int i;

        `uvm_info("dma_tx_single_req_seq", "=== TX DMA Single Request Test Sequence Started ===", UVM_MEDIUM)

        // Step 1: Configure SSPCR1
        // [0]=0 (no loopback), [1]=1 (SSE enable), [2]=0 (master), [3]=0 (TXD active)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h004;  // SSPCR1
        tx.data  = 16'h0002; // SSE=1, Master mode, TXD active
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "Step 1: SSPCR1 configured (SSE=1, Master, TXD active)", UVM_MEDIUM)

        // Step 1b: Disable ALL interrupts (SSPIMSC = 0x0000) - mark this as DMA test
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h014;  // SSPIMSC
        tx.data  = 16'h0000; // All interrupts disabled (DMA mode)
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "Step 1b: SSPIMSC configured (All interrupts disabled - DMA mode)", UVM_MEDIUM)

        // Step 2: Fill TX FIFO partially
        // Write data to TX FIFO (not completely full)
        `uvm_info("dma_tx_single_req_seq", "Step 2: Writing initial data to TX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 6; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR (Data Register)
            tx.data  = 16'h1000 + i;  // Data: 0x1000-0x1005
            finish_item(tx);
            `uvm_info("dma_tx_single_req_seq", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'h1000 + i), UVM_MEDIUM)
        end

        // Step 3: Wait for TX FIFO to drain (simulating transmit activity)
        `uvm_info("dma_tx_single_req_seq", "Step 3: Waiting for TX FIFO to drain (simulating transmit)...", UVM_MEDIUM)
        `uvm_info("dma_tx_single_req_seq", "        (waiting 1000ns for data transmission)", UVM_MEDIUM)
        `uvm_info("dma_tx_single_req_seq", "        → SSPTXDMASREQ should be HIGH (FIFO has empty slots)", UVM_MEDIUM)
        #1000;

        // Step 4: Read SSPSR to check TX FIFO status
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR (Status Register)
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "Step 4: Reading SSPSR to check TX FIFO level", UVM_MEDIUM)

        // Step 5: Simulate DMA clearing the request by writing SSPTXDMACLR
        `uvm_info("dma_tx_single_req_seq", "Step 5: Clearing TX DMA request via SSPTXDMACLR...", UVM_MEDIUM)
        // SSPTXDMACLR at offset 0x028 (write to clear)
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::WRITE;
        tx.addr  = 12'h028;  // SSPTXDMACLR
        tx.data  = 16'h0001; // Write to clear
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "        → SSPTXDMACLR written to clear TX DMA request", UVM_MEDIUM)

        // Step 6: Wait again to observe stable state
        #500;
        `uvm_info("dma_tx_single_req_seq", "Step 6: Waiting 500ns after DMA service...", UVM_MEDIUM)

        // Step 7: Fill TX FIFO more aggressively
        `uvm_info("dma_tx_single_req_seq", "Step 7: Writing more data to fill TX FIFO...", UVM_MEDIUM)
        for (i = 0; i < 8; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::WRITE;
            tx.addr  = 12'h008;       // SSPDR
            tx.data  = 16'h2000 + i;  // Data: 0x2000-0x2007
            finish_item(tx);
            `uvm_info("dma_tx_single_req_seq", $sformatf("  TX FIFO write #%0d: 0x%04x", i+1, 16'h2000 + i), UVM_MEDIUM)
        end
        `uvm_info("dma_tx_single_req_seq", "        → FIFO now full or nearly full", UVM_MEDIUM)

        // Step 8: Wait for FIFO to become full
        #500;
        `uvm_info("dma_tx_single_req_seq", "Step 8: Waiting 500ns - TX FIFO becoming full...", UVM_MEDIUM)
        `uvm_info("dma_tx_single_req_seq", "        → SSPTXDMASREQ should transition LOW (no empty slots)", UVM_MEDIUM)

        // Step 9: Verify FIFO full status
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "Step 9: Reading SSPSR to verify FIFO full status", UVM_MEDIUM)

        // Step 10: Simulate more DMA activity - continue reading/clearing
        `uvm_info("dma_tx_single_req_seq", "Step 10: Simulating continued DMA service (FIFO reads)...", UVM_MEDIUM)
        for (i = 0; i < 4; i++) begin
            tx = ssp_transaction::type_id::create("tx");
            start_item(tx);
            tx.r_w   = ssp_transaction::READ;
            tx.addr  = 12'h008;  // SSPDR (DMA reading to clear)
            tx.data  = 16'h0000;
            finish_item(tx);
            `uvm_info("dma_tx_single_req_seq", $sformatf("  DMA read #%0d from TX FIFO", i+1), UVM_MEDIUM)
        end
        `uvm_info("dma_tx_single_req_seq", "        → SSPTXDMASREQ should reassert (FIFO has empty slots again)", UVM_MEDIUM)

        // Step 11: Wait to observe reassertion
        #1000;
        `uvm_info("dma_tx_single_req_seq", "Step 11: Waiting 1000ns - observing SSPTXDMASREQ reassertion...", UVM_MEDIUM)

        // Step 12: Final FIFO status check
        tx = ssp_transaction::type_id::create("tx");
        start_item(tx);
        tx.r_w   = ssp_transaction::READ;
        tx.addr  = 12'h00C;  // SSPSR
        tx.data  = 16'h0000;
        finish_item(tx);
        `uvm_info("dma_tx_single_req_seq", "Step 12: Final SSPSR read to verify FIFO state", UVM_MEDIUM)

        `uvm_info("dma_tx_single_req_seq", "=== TX DMA Single Request Test Sequence Completed ===", UVM_MEDIUM)
    endtask

endclass : dma_tx_single_req_seq
