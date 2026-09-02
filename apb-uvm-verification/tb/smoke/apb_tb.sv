`timescale 1ns/1ps
module apb_tb;
  logic PCLK=0, PRESETn=0, PSEL=0, PENABLE=0, PWRITE=0;
  logic [7:0] PADDR=0; logic [31:0] PWDATA=0, PRDATA; logic PREADY, PSLVERR;
  integer checks=0, errors=0, seed=32'hA9B2_2026, i;
  logic [31:0] model [0:15];
  apb_slave dut(.*);
  always #5 PCLK=~PCLK;

  task automatic apb_write(input logic [7:0] addr,input logic [31:0] data,input bit expect_error);
    begin
      @(negedge PCLK); PSEL=1; PENABLE=0; PWRITE=1; PADDR=addr; PWDATA=data;
      @(negedge PCLK); PENABLE=1;
      @(posedge PCLK); #1; checks=checks+1;
      if(!PREADY || PSLVERR!==expect_error) begin $display("ERROR write addr=%0h ready=%0b err=%0b",addr,PREADY,PSLVERR); errors=errors+1; end
      if(!expect_error) model[addr>>2]=data;
      @(negedge PCLK); PSEL=0; PENABLE=0;
    end
  endtask
  task automatic apb_read(input logic [7:0] addr,input bit expect_error);
    begin
      @(negedge PCLK); PSEL=1; PENABLE=0; PWRITE=0; PADDR=addr;
      @(negedge PCLK); PENABLE=1;
      @(posedge PCLK); #1; checks=checks+1;
      if(!PREADY || PSLVERR!==expect_error) begin $display("ERROR read protocol addr=%0h",addr); errors=errors+1; end
      if(!expect_error && PRDATA!==model[addr>>2]) begin $display("ERROR read addr=%0h expected=%0h actual=%0h",addr,model[addr>>2],PRDATA); errors=errors+1; end
      @(negedge PCLK); PSEL=0; PENABLE=0;
    end
  endtask
  always @(posedge PCLK) if(PRESETn) begin
    if(PENABLE && !PSEL) begin $display("ERROR PENABLE without PSEL"); errors=errors+1; end
    if(PSEL && !PENABLE && PREADY) begin $display("ERROR PREADY in setup phase"); errors=errors+1; end
  end
  initial begin
    $dumpfile("proof/apb_wave.vcd"); $dumpvars(0,apb_tb);
    for(i=0;i<16;i=i+1) model[i]='0;
    repeat(3) @(posedge PCLK); PRESETn=1;
    apb_write(8'h00,32'h1234_5678,0); apb_read(8'h00,0);
    apb_write(8'h3C,32'hCAFE_BABE,0); apb_read(8'h3C,0);
    repeat(20) begin
      i=$urandom(seed)%16; apb_write(i*4,$urandom(seed),0); apb_read(i*4,0);
    end
    apb_write(8'h03,32'hDEAD_BEEF,1); apb_read(8'h80,1);
    if(errors==0) $display("APB_TEST_PASS checks=%0d",checks);
    else begin $display("APB_TEST_FAIL errors=%0d",errors); $fatal(1); end
    $finish;
  end
endmodule
