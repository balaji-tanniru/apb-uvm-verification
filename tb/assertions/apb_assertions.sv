module apb_assertions (
    input logic        PCLK,
    input logic        PRESETn,
    input logic        PSEL,
    input logic        PENABLE,
    input logic        PWRITE,
    input logic        PREADY,
    input logic [7:0]  PADDR,
    input logic [31:0] PWDATA
);

`ifndef __ICARUS__

    property setup_before_access;
        @(posedge PCLK)
        disable iff (!PRESETn)
        $rose(PENABLE) |-> $past(PSEL && !PENABLE);
    endproperty

    property stable_during_wait;
        @(posedge PCLK)
        disable iff (!PRESETn)
        PSEL && PENABLE && !PREADY
        |=> $stable({PADDR, PWRITE, PWDATA});
    endproperty

    assert property (setup_before_access);
    assert property (stable_during_wait);

`else

    logic        prev_setup;
    logic        prev_penable;
    logic        prev_wait;
    logic [40:0] prev_ctrl;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            prev_setup   <= 1'b0;
            prev_penable <= 1'b0;
            prev_wait    <= 1'b0;
            prev_ctrl    <= '0;
        end
        else begin
            if (PENABLE && !prev_penable && !prev_setup)
                $error("APB access without setup");

            if (prev_wait &&
                ({PADDR, PWRITE, PWDATA} !== prev_ctrl))
                $error("APB controls changed during wait");

            prev_setup   <= PSEL && !PENABLE;
            prev_penable <= PENABLE;
            prev_wait    <= PSEL && PENABLE && !PREADY;
            prev_ctrl    <= {PADDR, PWRITE, PWDATA};
        end
    end

`endif

endmodule

`ifndef __ICARUS__
bind apb_slave apb_assertions apb_chk (.*);
`endif