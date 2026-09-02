`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;import apb_pkg::*;logic PCLK=0;always #5 PCLK=~PCLK;apb_if vif(PCLK);
  apb_slave dut(.PCLK(PCLK),.PRESETn(vif.PRESETn),.PSEL(vif.PSEL),.PENABLE(vif.PENABLE),.PWRITE(vif.PWRITE),.PADDR(vif.PADDR),.PWDATA(vif.PWDATA),.PRDATA(vif.PRDATA),.PREADY(vif.PREADY),.PSLVERR(vif.PSLVERR));
  initial begin vif.PRESETn=0;vif.PSEL=0;vif.PENABLE=0;vif.PWRITE=0;vif.PADDR=0;vif.PWDATA=0;repeat(4)@(posedge PCLK);vif.PRESETn=1;uvm_config_db#(virtual apb_if)::set(null,"*","vif",vif);run_test("apb_test");end
endmodule
