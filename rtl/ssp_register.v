//------------------------------------------------------
// File: ssp_register.v
// Description: Register block for ARM PrimeCell SSP (PL022)
// Reference: ARM DDI 0194H, Chapter 3 – Programmer’s Model
//------------------------------------------------------

module ssp_register (
    input  wire        PCLK,       // APB clock
    input  wire        PRESETn,    // APB reset (active low)
    input  wire        PSEL,       // APB select
    input  wire        PENABLE,    // APB enable
    input  wire        PWRITE,     // APB write enable
    input  wire [11:2] PADDR,      // APB address (word aligned)
    input  wire [15:0] PWDATA,     // APB write data
    output reg  [15:0] PRDATA,     // APB read data

    // Status input (from core logic)
    input  wire [3:0]  status_in,  // {Busy, TNF, RNE, TFE}
    
    // Interrupt request outputs
    output wire        tx_intr_en,
    output wire        rx_intr_en,
    output wire        ror_intr_en,
    output wire        rti_intr_en,
    
    // DMA enable outputs
    output wire        tx_dma_en,
    output wire        rx_dma_en
);

//----------------------------------------------
// Register definitions
//----------------------------------------------
reg [15:0] SSPCR0;     // Control Register 0
reg [3:0]  SSPCR1;     // Control Register 1
reg [15:0] SSPDR;      // Data Register
reg [7:0]  SSPCPSR;    // Clock Prescale Register
reg [3:0]  SSPIMSC;    // Interrupt Mask Set/Clear
reg [3:0]  SSPRIS;     // Raw Interrupt Status
reg [3:0]  SSPMIS;     // Masked Interrupt Status
reg [1:0]  SSPDMACR;   // DMA Control Register

//----------------------------------------------
// Write operation
//----------------------------------------------
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        SSPCR0   <= 16'h0000;
        SSPCR1   <= 4'h0;
        SSPDR    <= 16'h0000;
        SSPCPSR  <= 8'h00;
        SSPIMSC  <= 4'h0;
        SSPRIS   <= 4'h0;
        SSPMIS   <= 4'h0;
        SSPDMACR <= 2'h0;
    end else if (PSEL && PENABLE && PWRITE) begin
        case (PADDR[7:2])
            6'h00: SSPCR0   <= PWDATA;             // +0x00
            6'h01: SSPCR1   <= PWDATA[3:0];        // +0x04
            6'h02: SSPDR    <= PWDATA;             // +0x08
            6'h04: SSPCPSR  <= PWDATA[7:0];        // +0x10
            6'h05: SSPIMSC  <= PWDATA[3:0];        // +0x14
            6'h08: SSPDMACR <= PWDATA[1:0];        // +0x24
            default: ;
        endcase
    end
end

//----------------------------------------------
// Read operation
//----------------------------------------------
always @(*) begin
    case (PADDR[7:2])
        6'h00: PRDATA = SSPCR0;                               // +0x00
        6'h01: PRDATA = {12'h000, SSPCR1};                    // +0x04
        6'h02: PRDATA = SSPDR;                                // +0x08
        6'h03: PRDATA = {11'h0, status_in};                   // +0x0C (SSPSR)
        6'h04: PRDATA = {8'h00, SSPCPSR};                     // +0x10
        6'h05: PRDATA = {12'h0, SSPIMSC};                     // +0x14
        6'h06: PRDATA = {12'h0, SSPRIS};                      // +0x18
        6'h07: PRDATA = {12'h0, SSPMIS};                      // +0x1C
        6'h08: PRDATA = {14'h0, SSPDMACR};                    // +0x24
        default: PRDATA = 16'h0000;
    endcase
end

//----------------------------------------------
// Interrupt logic
//----------------------------------------------
assign tx_intr_en = SSPIMSC[3];
assign rx_intr_en = SSPIMSC[2];
assign rti_intr_en = SSPIMSC[1];
assign ror_intr_en = SSPIMSC[0];

//----------------------------------------------
// DMA control logic
//----------------------------------------------
assign tx_dma_en = SSPDMACR[1];
assign rx_dma_en = SSPDMACR[0];

endmodule
