# APB Verification Plan

| Feature | Test | Expected result |
|---|---|---|
| Reset | Reset slave | All registers read zero |
| Write/read | Write then read each address class | Read data equals reference model |
| Setup/access | Observe every transfer | Setup phase is followed by access phase |
| Stable control | Wait-state assertion | Address/control/data remain stable |
| Address alignment | Unaligned access | PSLVERR asserted |
| Address range | Out-of-range access | PSLVERR asserted |
| Random traffic | 20 write/read pairs | Zero scoreboard errors |

Proof files are created in `proof/`: log, VCD waveform, UVM transcript and coverage report.
