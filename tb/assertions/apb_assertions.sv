module apb_assertions (
    input logic PCLK, PRESETn, PSEL, PENABLE, PWRITE, PREADY,
    input logic [7:0] PADDR,
    input logic [31:0] PWDATA
);
    property setup_before_access;
        @(posedge PCLK) disable iff (!PRESETn) PENABLE |-> PSEL;
    endproperty
    property stable_during_wait;
        @(posedge PCLK) disable iff (!PRESETn)
        PSEL && PENABLE && !PREADY |=> $stable({PADDR,PWRITE,PWDATA});
    endproperty
    assert property(setup_before_access);
    assert property(stable_during_wait);
endmodule
