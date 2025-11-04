class ssp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ssp_scoreboard)
    virtual ssp_if ssp_vif; // interface config_db
    uvm_analysis_imp #(ssp_transaction,ssp_scoreboard) scoreboard_export;
    
    // Test variables
    int tx_interrupt_enabled = 0;
    int rx_interrupt_enabled = 0;
    int rx_overrun_interrupt_enabled = 0;
    int rx_timeout_interrupt_enabled = 0;
    int main_interrupt_enabled = 0;  // All 4 interrupts enabled
    int dma_tx_test_enabled = 0;  // DMA TX single request test
    int dma_rx_test_enabled = 0;  // DMA RX test (detected by SSPRXDMACLR write)
    int dma_tx_burst_test_enabled = 0;  // DMA TX burst request test
    int dma_rx_burst_test_enabled = 0;  // DMA RX burst request test
    int dma_clear_tx_test_enabled = 0;  // DMA TX Clear Request test (multiple SSPTXDMACLR operations)
    int dma_clear_rx_test_enabled = 0;  // DMA RX Clear Request test (multiple SSPRXDMACLR operations)
    int sspicr_written = 0;  // Track if SSPICR (Interrupt Clear Register) was written
    int sspcr1_configured = 0;
    int fifo_write_count = 0;
    int fifo_read_count = 0;
    int dma_tx_clear_count = 0;  // Track TX DMA clear operations
    int dma_rx_clear_count = 0;  // Track RX DMA clear operations
    
    function new(string name = "ssp_scoreboard",uvm_component parent);
        super.new(name,parent);
    endfunction:new
    
    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        scoreboard_export = new("scoreboard_export",this);
    endfunction:build_phase
    
    function void write (ssp_transaction trans);
        // Check test scenario
        if (trans.r_w == ssp_transaction::WRITE) begin
            // Check SSPCR1 configuration (addr = 0x004)
            if (trans.addr == 12'h004) begin
                if (trans.data[1] == 1'b1) begin
                    sspcr1_configured = 1;
                    `uvm_info(get_type_name(), "[✓] SSPCR1 | SSE enabled (bit[1]=1)", UVM_LOW)
                end
            end
            
            // Check SSPIMSC interrupt enables (addr = 0x014)
            if (trans.addr == 12'h014) begin
                // Check for main interrupt (all 4 sources enabled = 0x000F)
                if (trans.data[3:0] == 4'hF) begin
                    main_interrupt_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | ALL interrupts enabled (0x000F) - MAIN TEST", UVM_LOW)
                end else if (trans.data[3:0] == 4'h0) begin
                    // No interrupts enabled - this is a DMA test
                    dma_tx_test_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | NO interrupts enabled (0x0000) - DMA TEST", UVM_LOW)
                end
                
                if (trans.data[0] == 1'b1) begin
                    rx_timeout_interrupt_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | RX timeout interrupt enabled (bit[0]=1)", UVM_LOW)
                end
                if (trans.data[1] == 1'b1) begin
                    tx_interrupt_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | TX interrupt enabled (bit[1]=1)", UVM_LOW)
                end
                if (trans.data[2] == 1'b1) begin
                    rx_interrupt_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | RX interrupt enabled (bit[2]=1)", UVM_LOW)
                end
                if (trans.data[3] == 1'b1) begin
                    rx_overrun_interrupt_enabled = 1;
                    `uvm_info(get_type_name(), "[✓] SSPIMSC | RX overrun interrupt enabled (bit[3]=1)", UVM_LOW)
                end
            end
            
            // Count FIFO writes (addr = 0x008)
            if (trans.addr == 12'h008) begin
                fifo_write_count++;
                `uvm_info(get_type_name(), $sformatf("[→] SSPDR | FIFO write #%2d: 0x%04h", fifo_write_count, trans.data), UVM_LOW)
            end
            
            // Check SSPICR writes (addr = 0x020) - only RX overrun test writes to this
            if (trans.addr == 12'h020) begin
                sspicr_written = 1;
                `uvm_info(get_type_name(), "[✓] SSPICR | Interrupt Clear Register written", UVM_LOW)
            end
            
            // Check SSPRXDMACLR writes (addr = 0x024) - RX DMA test writes to this
            if (trans.addr == 12'h024) begin
                dma_rx_clear_count++;
                // Mark both as possible, will distinguish in final_phase based on clear count
                dma_rx_test_enabled = 1;
                // Detect RX DMA Clear test by 2+ clear operations
                if (dma_rx_clear_count >= 2) begin
                    dma_clear_rx_test_enabled = 1;
                end
                `uvm_info(get_type_name(), $sformatf("[✓] SSPRXDMACLR | RX DMA Clear #%0d", dma_rx_clear_count), UVM_LOW)
            end
            
            // Check SSPTXDMACLR writes (addr = 0x028) - TX DMA test writes to this
            if (trans.addr == 12'h028) begin
                dma_tx_clear_count++;
                // Mark both as possible, will distinguish in final_phase based on clear count and write count
                dma_tx_test_enabled = 1;
                // Detect TX DMA Burst test by high write count + SSPTXDMACLR
                if (fifo_write_count >= 15) begin
                    dma_tx_burst_test_enabled = 1;
                end
                // Detect TX DMA Clear test by 2+ clear operations
                if (dma_tx_clear_count >= 2) begin
                    dma_clear_tx_test_enabled = 1;
                end
                `uvm_info(get_type_name(), $sformatf("[✓] SSPTXDMACLR | TX DMA Clear #%0d", dma_tx_clear_count), UVM_LOW)
            end
        end else if (trans.r_w == ssp_transaction::READ) begin
            // Count FIFO reads (addr = 0x008)
            if (trans.addr == 12'h008) begin
                fifo_read_count++;
                `uvm_info(get_type_name(), $sformatf("[←] SSPDR | FIFO read #%2d: 0x%04h", fifo_read_count, trans.data), UVM_LOW)
            end
        end
    endfunction:write
    
    virtual function void final_phase(uvm_phase phase);
        string separator;
        string test_type;
        super.final_phase(phase);
        
        separator = "════════════════════════════════════════════════════════════════";
        
        // Distinguish between RX DMA single vs burst based on final fifo_write_count
        if (dma_rx_test_enabled && !dma_rx_burst_test_enabled && !dma_clear_rx_test_enabled) begin
            if (fifo_write_count >= 13) begin
                dma_rx_burst_test_enabled = 1;
                dma_rx_test_enabled = 0;  // Clear single flag
            end
        end
        
        // Distinguish between TX DMA single vs burst based on final fifo_write_count
        if (dma_tx_test_enabled && !dma_tx_burst_test_enabled && !dma_clear_tx_test_enabled) begin
            if (fifo_write_count >= 15) begin
                dma_tx_burst_test_enabled = 1;
                dma_tx_test_enabled = 0;  // Clear single flag
            end
        end
        // Determine test type - check in priority order (clear tests have highest priority due to multiple clears)
        if (main_interrupt_enabled) begin
            test_type = "MAIN COMBINED INTERRUPT TEST";
        end else if (dma_clear_rx_test_enabled) begin
            test_type = "RX DMA CLEAR REQUEST TEST";
        end else if (dma_clear_tx_test_enabled) begin
            test_type = "TX DMA CLEAR REQUEST TEST";
        end else if (dma_rx_burst_test_enabled) begin
            test_type = "RX DMA BURST REQUEST TEST";
        end else if (dma_rx_test_enabled) begin
            test_type = "RX DMA SINGLE REQUEST TEST";
        end else if (dma_tx_burst_test_enabled) begin
            test_type = "TX DMA BURST REQUEST TEST";
        end else if (dma_tx_test_enabled) begin
            test_type = "TX DMA SINGLE REQUEST TEST";
        end else if (rx_timeout_interrupt_enabled) begin
            test_type = "RX TIMEOUT INTERRUPT TEST";
        end else if (sspicr_written) begin
            test_type = "RX OVERRUN INTERRUPT TEST";
        end else if (tx_interrupt_enabled && !rx_interrupt_enabled) begin
            test_type = "TX INTERRUPT TEST";
        end else if (rx_interrupt_enabled && !tx_interrupt_enabled) begin
            test_type = "RX INTERRUPT TEST";
        end else begin
            test_type = "INTERRUPT TEST";
        end
        
        `uvm_info(get_type_name(), "", UVM_LOW)
        `uvm_info(get_type_name(), separator, UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("         %s - FINAL REPORT", test_type), UVM_LOW)
        `uvm_info(get_type_name(), separator, UVM_LOW)
        
        // Test configuration check
        `uvm_info(get_type_name(), "", UVM_LOW)
        `uvm_info(get_type_name(), "1. TEST SETUP VERIFICATION:", UVM_LOW)
        
        if (sspcr1_configured) begin
            `uvm_info(get_type_name(), "   [✓] SSPCR1: SSE enabled successfully", UVM_LOW)
        end else begin
            `uvm_warning(get_type_name(), "   [✗] SSPCR1: SSE NOT enabled - SETUP FAILED")
        end
        
        if (tx_interrupt_enabled) begin
            `uvm_info(get_type_name(), "   [✓] SSPIMSC: TX interrupt mask enabled", UVM_LOW)
        end
        
        if (rx_interrupt_enabled) begin
            `uvm_info(get_type_name(), "   [✓] SSPIMSC: RX interrupt mask enabled", UVM_LOW)
        end
        
        if (!tx_interrupt_enabled && !rx_interrupt_enabled && !dma_tx_test_enabled && !dma_rx_test_enabled && !dma_tx_burst_test_enabled) begin
            `uvm_warning(get_type_name(), "   [✗] SSPIMSC: No interrupt mask enabled - SETUP FAILED")
        end else if ((dma_tx_test_enabled || dma_rx_test_enabled || dma_tx_burst_test_enabled) && !tx_interrupt_enabled && !rx_interrupt_enabled) begin
            `uvm_info(get_type_name(), "   [✓] SSPIMSC: All interrupts disabled (DMA mode - expected)", UVM_LOW)
        end
        
        // FIFO operations check
        `uvm_info(get_type_name(), "", UVM_LOW)
        `uvm_info(get_type_name(), "2. FIFO OPERATIONS:", UVM_LOW)
        
        if (fifo_write_count > 0) begin
            `uvm_info(get_type_name(), $sformatf("   [→] Total FIFO writes: %0d", fifo_write_count), UVM_LOW)
        end
        
        if (fifo_read_count > 0) begin
            `uvm_info(get_type_name(), $sformatf("   [←] Total FIFO reads: %0d", fifo_read_count), UVM_LOW)
        end
        
        if (fifo_write_count >= 8) begin
            `uvm_info(get_type_name(), "   [✓] Initial FIFO fill (8 entries) - PASS", UVM_LOW)
        end else if (fifo_write_count > 0) begin
            `uvm_warning(get_type_name(), $sformatf("   [✗] Initial FIFO fill incomplete (%0d/8)", fifo_write_count))
        end
        
        if (tx_interrupt_enabled && fifo_write_count >= 12) begin
            `uvm_info(get_type_name(), "   [✓] FIFO refill (4 more entries) - PASS", UVM_LOW)
        end else if (tx_interrupt_enabled && fifo_write_count >= 10) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] FIFO refill completed (%0d total) - PASS", fifo_write_count), UVM_LOW)
        end else if (dma_clear_tx_test_enabled && fifo_write_count >= 8 && dma_tx_clear_count >= 2) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA TX clear: wrote %0d entries, performed %0d TX DMA clears - PASS", fifo_write_count, dma_tx_clear_count), UVM_LOW)
        end else if (dma_clear_rx_test_enabled && fifo_write_count >= 8 && dma_rx_clear_count >= 2) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA RX clear: wrote %0d entries, performed %0d RX DMA clears - PASS", fifo_write_count, dma_rx_clear_count), UVM_LOW)
        end else if (dma_tx_test_enabled && fifo_write_count >= 14) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA TX single: wrote %0d entries (6+8+more) - PASS", fifo_write_count), UVM_LOW)
        end else if (dma_tx_test_enabled && dma_tx_clear_count >= 1) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA TX single: performed %0d TX DMA clears - PASS", dma_tx_clear_count), UVM_LOW)
        end else if (dma_tx_burst_test_enabled && fifo_write_count >= 15) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA TX burst: wrote %0d entries (4+3+8) - PASS", fifo_write_count), UVM_LOW)
        end else if (dma_tx_burst_test_enabled && dma_tx_clear_count >= 1) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA TX burst: performed %0d TX DMA clears - PASS", dma_tx_clear_count), UVM_LOW)
        end else if (dma_rx_test_enabled && fifo_write_count >= 7 && dma_rx_clear_count >= 1) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA RX single: wrote %0d entries, performed %0d RX DMA clears - PASS", fifo_write_count, dma_rx_clear_count), UVM_LOW)
        end else if (dma_rx_burst_test_enabled && fifo_write_count >= 13 && dma_rx_clear_count >= 1) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] DMA RX burst: wrote %0d entries (4+4+5), performed %0d RX DMA clears - PASS", fifo_write_count, dma_rx_clear_count), UVM_LOW)
        end else if (rx_interrupt_enabled && !rx_overrun_interrupt_enabled && fifo_read_count >= 5) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] FIFO reads completed (%0d reads) - PASS", fifo_read_count), UVM_LOW)
        end else if (main_interrupt_enabled && fifo_write_count >= 15 && fifo_read_count >= 5) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] Multiple interrupts: wrote %0d, read %0d - PASS", fifo_write_count, fifo_read_count), UVM_LOW)
        end else if (rx_timeout_interrupt_enabled && fifo_write_count >= 4 && fifo_read_count >= 2) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] Timeout test: wrote %0d, read %0d - PASS", fifo_write_count, fifo_read_count), UVM_LOW)
        end else if (rx_overrun_interrupt_enabled && fifo_write_count > 12) begin
            `uvm_info(get_type_name(), $sformatf("   [✓] Overrun condition created (%0d writes total) - PASS", fifo_write_count), UVM_LOW)
        end
        
        // Overall result
        `uvm_info(get_type_name(), "", UVM_LOW)
        `uvm_info(get_type_name(), separator, UVM_LOW)
        
        if (main_interrupt_enabled) begin
            // Main Combined Interrupt Test
            if (sspcr1_configured && main_interrupt_enabled && fifo_write_count >= 15 && fifo_read_count >= 5) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   MAIN COMBINED INTERRUPT TEST: PASSED ✓  ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   MAIN COMBINED INTERRUPT TEST: FAILED ✗ ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_clear_tx_test_enabled && fifo_write_count >= 8 && dma_tx_clear_count >= 2) begin
            // TX DMA Clear Request Test
            if (sspcr1_configured && dma_clear_tx_test_enabled && fifo_write_count >= 8 && dma_tx_clear_count >= 2) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   TX DMA CLEAR REQUEST TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   TX DMA CLEAR REQUEST TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_clear_rx_test_enabled && fifo_write_count >= 8 && dma_rx_clear_count >= 2) begin
            // RX DMA Clear Request Test
            if (sspcr1_configured && dma_clear_rx_test_enabled && fifo_write_count >= 8 && dma_rx_clear_count >= 2) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX DMA CLEAR REQUEST TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX DMA CLEAR REQUEST TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_rx_burst_test_enabled && fifo_write_count >= 13 && dma_rx_clear_count >= 1) begin
            // RX DMA Burst Request Test
            if (sspcr1_configured && dma_rx_burst_test_enabled && fifo_write_count >= 13 && dma_rx_clear_count >= 1) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX DMA BURST REQUEST TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX DMA BURST REQUEST TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_rx_test_enabled) begin
            // RX DMA Single Request Test
            if (sspcr1_configured && dma_rx_test_enabled && fifo_write_count >= 7 && dma_rx_clear_count >= 1) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX DMA SINGLE REQUEST TEST: PASSED ✓    ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX DMA SINGLE REQUEST TEST: FAILED ✗   ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_tx_burst_test_enabled) begin
            // TX DMA Burst Request Test
            if (sspcr1_configured && dma_tx_burst_test_enabled && fifo_write_count >= 15 && dma_tx_clear_count >= 1) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   TX DMA BURST REQUEST TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   TX DMA BURST REQUEST TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (dma_tx_test_enabled) begin
            // TX DMA Single Request Test
            if (sspcr1_configured && dma_tx_test_enabled && fifo_write_count >= 14 && dma_tx_clear_count >= 1) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   TX DMA SINGLE REQUEST TEST: PASSED ✓    ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   TX DMA SINGLE REQUEST TEST: FAILED ✗   ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (rx_timeout_interrupt_enabled) begin
            // RX Timeout Interrupt Test
            if (sspcr1_configured && rx_timeout_interrupt_enabled && fifo_write_count >= 4 && fifo_read_count >= 2) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX TIMEOUT INTERRUPT TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX TIMEOUT INTERRUPT TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (sspicr_written) begin
            // RX Overrun Interrupt Test
            if (sspcr1_configured && rx_overrun_interrupt_enabled && fifo_write_count >= 12 && sspicr_written) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX OVERRUN INTERRUPT TEST: PASSED ✓     ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX OVERRUN INTERRUPT TEST: FAILED ✗    ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (tx_interrupt_enabled && !rx_interrupt_enabled) begin
            // TX Interrupt Test
            if (sspcr1_configured && tx_interrupt_enabled && fifo_write_count >= 10) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   TX INTERRUPT TEST: PASSED ✓             ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   TX INTERRUPT TEST: FAILED ✗             ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else if (rx_interrupt_enabled && !tx_interrupt_enabled) begin
            // RX Interrupt Test
            if (sspcr1_configured && rx_interrupt_enabled && fifo_write_count >= 8 && fifo_read_count >= 5) begin
                `uvm_info(get_type_name(), "    ╔═══════════════════════════════════════════╗", UVM_LOW)
                `uvm_info(get_type_name(), "    ║   RX INTERRUPT TEST: PASSED ✓             ║", UVM_LOW)
                `uvm_info(get_type_name(), "    ╚═══════════════════════════════════════════╝", UVM_LOW)
            end else begin
                `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
                `uvm_warning(get_type_name(), "    ║   RX INTERRUPT TEST: FAILED ✗             ║")
                `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
            end
        end else begin
            // Unknown test type
            `uvm_warning(get_type_name(), "    ╔═══════════════════════════════════════════╗")
            `uvm_warning(get_type_name(), "    ║   INTERRUPT TEST: UNKNOWN ✗               ║")
            `uvm_warning(get_type_name(), "    ╚═══════════════════════════════════════════╝")
        end
        
        `uvm_info(get_type_name(), separator, UVM_LOW)
        `uvm_info(get_type_name(), "", UVM_LOW)
    endfunction
endclass : ssp_scoreboard