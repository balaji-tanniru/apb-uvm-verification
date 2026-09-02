interface apb_if(input logic PCLK);
  logic PRESETn,PSEL,PENABLE,PWRITE;
  logic [7:0] PADDR; logic [31:0] PWDATA,PRDATA; logic PREADY,PSLVERR;
  property setup_to_access; @(posedge PCLK) disable iff(!PRESETn) PSEL && !PENABLE |=> PSEL && PENABLE; endproperty
  property stable_in_access; @(posedge PCLK) disable iff(!PRESETn) PSEL && PENABLE && !PREADY |=> $stable({PADDR,PWRITE,PWDATA,PSEL,PENABLE}); endproperty
  property penable_requires_psel; @(posedge PCLK) disable iff(!PRESETn) PENABLE |-> PSEL; endproperty
  a_setup_access: assert property(setup_to_access);
  a_stable_access: assert property(stable_in_access);
  a_enable_select: assert property(penable_requires_psel);
endinterface
