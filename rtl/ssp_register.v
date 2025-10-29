//---------------------------------------------------------
// ARM PL022 SSP - Register Block (Accurate Access Control)
// Author: ChatGPT (Nguyen Tan Project)
//---------------------------------------------------------
module ssp_register (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [11:2] PADDR,
    input  wire [15:0] PWDATA,
    output reg  [15:0] PRDATA,

    // External status input (from TX/RX FIFO or other logic)
    input  wire [4:0]  ssp_status,   // {BSY, RFF, RNE, TNF, TFE}

    // External interrupt source signals (raw interrupt requests)
    input  wire [3:0]  intr_raw_in,  // {RT, RX, TX, OVR}

    // Outputs to other modules
    output reg  [15:0] SSPCR0,
    output reg  [3:0]  SSPCR1,
    output reg  [15:0] SSPDR,
    output reg  [7:0]  SSPCPSR,
    output reg  [3:0]  SSPIMSC,
    output reg  [1:0]  SSPDMACR,

    // Interrupt status outputs
    output reg  [3:0]  SSPRIS,       // raw interrupt status
    output wire [3:0]  SSPMIS        // masked interrupt status
);

    //-----------------------------------------------------
    // Internal registers
    //-----------------------------------------------------
    reg [3:0] intr_pending;  // internal interrupt pending flags

    //-----------------------------------------------------
    // Reset & Write logic (RW / WO handled separately)
    //-----------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            SSPCR0      <= 16'h0000;
            SSPCR1      <= 4'h0;
            SSPDR       <= 16'h0000;
            SSPCPSR     <= 8'h00;
            SSPIMSC     <= 4'h0;
            SSPDMACR    <= 2'h0;
            intr_pending<= 4'h0;
        end else begin
            // Handle write accesses
            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[7:2])
                    6'h00: SSPCR0   <= PWDATA;              // RW
                    6'h01: SSPCR1   <= PWDATA[3:0];         // RW
                    6'h02: SSPDR    <= PWDATA;              // RW (TX write)
                    6'h04: if (PWDATA[0] == 1'b0)           // RW (even prescale)
                               SSPCPSR <= PWDATA[7:0];
                    6'h05: SSPIMSC  <= PWDATA[3:0];         // RW
                    6'h08: intr_pending <= intr_pending & ~PWDATA[3:0]; // WO: SSPICR
                    6'h09: SSPDMACR <= PWDATA[1:0];         // RW
                    default: ;
                endcase
            end
        end
    end

    //-----------------------------------------------------
    // Interrupt logic
    //-----------------------------------------------------
    // Update raw interrupt status
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SSPRIS <= 4'b0000;
        else
            // Lưu cờ ngắt pending từ nguồn ngắt thô (intr_raw_in)
            SSPRIS <= intr_raw_in | intr_pending;
    end

    // Masked interrupt output
    assign SSPMIS = SSPRIS & SSPIMSC;

    //-----------------------------------------------------
    // Read logic (RO/RW/WO behavior)
    //-----------------------------------------------------
    always @(*) begin
        if (PSEL && !PWRITE) begin
            case (PADDR[7:2])
                6'h00: PRDATA = SSPCR0;                            // RW
                6'h01: PRDATA = {12'h0, SSPCR1};                  // RW
                6'h02: PRDATA = SSPDR;                            // RW
                6'h03: PRDATA = {11'h0, ssp_status};              // RO
                6'h04: PRDATA = {8'h00, SSPCPSR};                 // RW
                6'h05: PRDATA = {12'h0, SSPIMSC};                 // RW
                6'h06: PRDATA = {12'h0, SSPRIS};                  // RO
                6'h07: PRDATA = {12'h0, SSPMIS};                  // RO
                6'h08: PRDATA = 16'h0000;                         // WO → read as 0
                6'h09: PRDATA = {14'h0, SSPDMACR};                // RW
                default: PRDATA = 16'h0000;
            endcase
        end else begin
            PRDATA = 16'h0000;
        end
    end

endmodule
