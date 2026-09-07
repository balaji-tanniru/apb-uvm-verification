#!/usr/bin/env bash
set -euo pipefail
rm -rf work transcript vsim.wlf
vlib work
vlog -sv +incdir+tb/uvm rtl/apb_slave.sv tb/assertions/apb_assertions.sv tb/uvm/apb_if.sv tb/uvm/apb_pkg.sv tb/uvm/tb_top.sv
vsim -c -coverage tb_top -do "log -r /*; vcd file proof/apb_uvm_wave.vcd; vcd add -r /*; run -all; coverage report -details -output proof/apb_coverage.txt; quit -f" | tee proof/apb_uvm.log
