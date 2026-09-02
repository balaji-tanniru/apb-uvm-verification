#!/usr/bin/env bash
set -euo pipefail
mkdir -p sim_build proof
iverilog -g2012 -o sim_build/apb_sim rtl/apb_slave.sv tb/smoke/apb_tb.sv
vvp sim_build/apb_sim | tee proof/apb_test.log
grep -q APB_TEST_PASS proof/apb_test.log
