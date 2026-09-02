`timescale 1ns/1ps
module tb_top;
    import uvm_pkg::*;
    import apb_pkg::*;

    logic PCLK = 0;
    apb_if vif(PCLK);

    always #5 PCLK = ~PCLK;

    apb_slave dut (
        .PCLK(PCLK), .PRESETn(vif.PRESETn), .PSEL(vif.PSEL),
        .PENABLE(vif.PENABLE), .PWRITE(vif.PWRITE), .PADDR(vif.PADDR),
        .PWDATA(vif.PWDATA), .PRDATA(vif.PRDATA), .PREADY(vif.PREADY),
        .PSLVERR(vif.PSLVERR)
    );

    initial begin
        vif.PRESETn = 0; vif.PSEL = 0; vif.PENABLE = 0;
        repeat (3) @(posedge PCLK);
        vif.PRESETn = 1;
    end

    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
        run_test("apb_test");
    end
endmodule
