#!/usr/bin/env bash
set -euo pipefail
mkdir -p sim_build proof
iverilog -g2012 -D__ICARUS__ -o sim_build/apb_smoke rtl/apb_slave.sv tb/assertions/apb_assertions.sv tb/smoke/apb_tb.sv
vvp sim_build/apb_smoke | tee proof/apb_test.log
grep -q "APB_TEST_PASS" proof/apb_test.log
