# APB Verification Test Plan

| Test | Expected result |
|---|---|
| Reset | Outputs return to known values |
| Aligned writes | Data is stored at valid word addresses |
| Aligned reads | Read data matches the reference value |
| PREADY timing | Master holds control signals during the wait state |
| Unaligned address | Slave responds with PSLVERR |
| Out-of-range address | Slave responds with PSLVERR |

The portable smoke regression generates the actual PASS/FAIL log and VCD proof.
The UVM source demonstrates the reusable sequence, driver, monitor, scoreboard,
coverage subscriber, agent, environment, and test architecture.
