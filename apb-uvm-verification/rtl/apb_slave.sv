module apb_slave #(
  parameter int ADDR_WIDTH=8,
  parameter int DATA_WIDTH=32,
  parameter int DEPTH=16
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
  logic valid_addr;
  integer i;
  assign valid_addr = (PADDR[1:0] == 2'b00) && (PADDR[ADDR_WIDTH-1:2] < DEPTH);
  assign PREADY = PSEL && PENABLE;
  assign PSLVERR = PREADY && !valid_addr;
  always_comb begin
    PRDATA = '0;
    if (PSEL && !PWRITE && valid_addr) PRDATA = mem[PADDR[ADDR_WIDTH-1:2]];
  end
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      for (i=0; i<DEPTH; i=i+1) mem[i] <= '0;
    end else if (PSEL && PENABLE && PREADY && PWRITE && valid_addr) begin
      mem[PADDR[ADDR_WIDTH-1:2]] <= PWDATA;
    end
  end
endmodule
