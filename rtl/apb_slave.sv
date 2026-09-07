module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic [DATA_WIDTH-1:0] PWDATA,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic                  PREADY,
    output logic                  PSLVERR
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic wait_cycle;
    integer i;

    wire address_valid = (PADDR[1:0] == 2'b00) && (PADDR < DEPTH * 4);
    wire [$clog2(DEPTH)-1:0] word_index = PADDR[2 +: $clog2(DEPTH)];

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA    <= '0;
            PREADY    <= 1'b0;
            PSLVERR   <= 1'b0;
            wait_cycle <= 1'b0;
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= '0;
        end else begin
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

            if (PSEL && PENABLE) begin
                if (!wait_cycle) begin
                    wait_cycle <= 1'b1;
                end else begin
                    wait_cycle <= 1'b0;
                    PREADY     <= 1'b1;
                    PSLVERR    <= !address_valid;
                    if (address_valid) begin
                        if (PWRITE)
                            mem[word_index] <= PWDATA;
                        else
                            PRDATA <= mem[word_index];
                    end
                end
            end else begin
                wait_cycle <= 1'b0;
            end
        end
    end
endmodule
