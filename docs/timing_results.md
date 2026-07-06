# Timing and Resource Results

## Overview

This document records the Vivado synthesis and timing results for the top-level FPGA market-data parser design.

The design under test is the integrated top-level module:

```text
market_data_top
```

This module connects the packet parser to the signal engine. The parser receives packet bytes, extracts the instrument ID, bid price, and ask price, then drives the signal engine using the parser valid output.

---

## Tool

Synthesis and timing analysis were run using AMD/Xilinx Vivado.

---

## Clock Constraint

The design was constrained using a 10 ns clock period:

```tcl
create_clock -name clk -period 10.000 [get_ports clk]
```

This corresponds to a target clock frequency of:

```text
100 MHz
```

---

## Resource Utilization

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 31 | 20800 | 0.15% |
| LUT as Logic | 31 | 20800 | 0.15% |
| LUT as Memory | 0 | 9600 | 0.00% |
| Slice Registers | 53 | 41600 | 0.13% |
| Registers as Flip-Flops | 53 | 41600 | 0.13% |
| Registers as Latches | 0 | 41600 | 0.00% |
| F7 Muxes | 0 | 16300 | 0.00% |
| F8 Muxes | 0 | 8150 | 0.00% |

The design inferred no latches.

---

## Timing Summary

| Metric | Value |
|---|---:|
| Target clock period | 10.000 ns |
| Target frequency | 100 MHz |
| Worst Negative Slack, WNS | 5.088 ns |
| Total Negative Slack, TNS | 0.000 ns |
| Setup failing endpoints | 0 |
| Setup total endpoints | 66 |
| Worst Hold Slack, WHS | 0.191 ns |
| Total Hold Slack, THS | 0.000 ns |
| Hold failing endpoints | 0 |
| Hold total endpoints | 66 |
| Worst Pulse Width Slack, WPWS | 4.500 ns |
| Total Pulse Width Slack, TPWS | 0.000 ns |
| Pulse width failing endpoints | 0 |
| Pulse width total endpoints | 55 |

---

## Timing Result

The design meets timing at the 100 MHz target clock frequency.

The positive WNS of 5.088 ns means the slowest setup path still has approximately 5 ns of timing margin with a 10 ns clock period.

Since:

```text
critical path delay ≈ clock period - WNS
```

The approximate critical path delay is:

```text
10.000 ns - 5.088 ns = 4.912 ns
```

This suggests the design has substantial timing margin at 100 MHz. This is only a rough estimate and should not be treated as a guaranteed maximum operating frequency.

---

## Latency Estimate

The parser consumes one byte per clock cycle when `in_valid = '1'`.

The current packet format is seven bytes long:

```text
AB CD II BB BB AA AA
```

The parser samples the final packet byte, then asserts `parsed_valid` after the packet has been fully received. The signal engine is also registered, so `action_valid` is asserted after the parsed data is accepted by the signal engine.

Approximate latency:

| Measurement | Latency |
|---|---:|
| Final packet byte sampled to `parsed_valid` | 1 clock cycle |
| `parsed_valid` to `action_valid` | 1 clock cycle |
| Final packet byte sampled to `action_valid` | 2 clock cycles |
| First packet byte sampled to `action_valid` | 8 clock cycles |

At 100 MHz, one clock cycle is 10 ns. Therefore, the approximate first-byte-to-action latency is:

```text
8 cycles × 10 ns = 80 ns
```

---

## Notes

Vivado reported unconstrained input and output delay checks because external board-level I/O timing constraints have not yet been added.

This is expected at the current stage because the project is being verified as an internal RTL design and is not yet connected to a physical FPGA board interface.

Future board-level implementation would require additional XDC constraints for physical pins, I/O standards, and external input/output timing.

---

## Summary

The integrated parser and signal engine design:

- synthesizes successfully
- uses 31 LUTs
- uses 53 flip-flops
- infers no latches
- meets a 100 MHz timing constraint
- has 5.088 ns positive setup slack
- has no setup or hold timing violations
