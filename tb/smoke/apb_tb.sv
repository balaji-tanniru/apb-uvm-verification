`timescale 1ns/1ps

module apb_tb;
    logic        PCLK = 0;
    logic        PRESETn = 0;
    logic        PSEL = 0;
    logic        PENABLE = 0;
    logic        PWRITE = 0;
    logic [7:0]  PADDR = 0;
    logic [31:0] PWDATA = 0;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    integer checks = 0;
    integer errors = 0;

    always #5 PCLK = ~PCLK;

    apb_slave dut (.*);

    task automatic check(input logic condition, input string message);
        begin
            checks = checks + 1;
            if (!condition) begin
                errors = errors + 1;
                $display("CHECK_FAIL: %s", message);
            end else begin
                $display("CHECK_PASS: %s", message);
            end
        end
    endtask

    task automatic apb_write(
        input logic [7:0] address,
        input logic [31:0] data,
        input logic expected_error
    );
        integer wait_count;
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 1;
            PADDR = address; PWDATA = data;
            @(negedge PCLK);
            PENABLE = 1;
            wait_count = 0;
            while (!PREADY) begin
                check(PSEL && PENABLE && PWRITE && PADDR == address && PWDATA == data,
                      "write controls stable while waiting");
                wait_count = wait_count + 1;
                @(negedge PCLK);
            end
            check(wait_count >= 1, "write inserted a PREADY wait state");
            check(PSLVERR == expected_error, "write error response correct");
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0; PWRITE = 0;
        end
    endtask

    task automatic apb_read(
        input logic [7:0] address,
        input logic [31:0] expected_data,
        input logic expected_error
    );
        integer wait_count;
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 0;
            PADDR = address; PWDATA = 0;
            @(negedge PCLK);
            PENABLE = 1;
            wait_count = 0;
            while (!PREADY) begin
                check(PSEL && PENABLE && !PWRITE && PADDR == address,
                      "read controls stable while waiting");
                wait_count = wait_count + 1;
                @(negedge PCLK);
            end
            check(wait_count >= 1, "read inserted a PREADY wait state");
            check(PSLVERR == expected_error, "read error response correct");
            if (!expected_error)
                check(PRDATA == expected_data, "read data matches reference model");
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0;
        end
    endtask

    initial begin
        $dumpfile("proof/apb_wave.vcd");
        $dumpvars(0, apb_tb);

        repeat (3) @(posedge PCLK);
        @(negedge PCLK);
        PRESETn = 1;
        @(posedge PCLK);
        #1;
        check(PRDATA == 0 && !PREADY && !PSLVERR, "reset outputs are clean");

        apb_write(8'h00, 32'h1234_ABCD, 0);
        apb_write(8'h04, 32'hCAFE_BABE, 0);
        apb_write(8'h3C, 32'h55AA_55AA, 0);

        apb_read(8'h00, 32'h1234_ABCD, 0);
        apb_read(8'h04, 32'hCAFE_BABE, 0);
        apb_read(8'h3C, 32'h55AA_55AA, 0);

        apb_write(8'h02, 32'hDEAD_BEEF, 1);
        apb_read(8'h40, 32'h0000_0000, 1);

        check(errors == 0, "all APB protocol and data checks passed");
        if (errors == 0)
            $display("APB_TEST_PASS checks=%0d errors=%0d", checks, errors);
        else
            $display("APB_TEST_FAIL checks=%0d errors=%0d", checks, errors);

        #10;
        $finish;
    end
endmodule
