# FPGA Market Data Packet Parser

This project is currently implementing a simple VHDL FPGA market-data packet parser and signal engine.

The design currentlt receives a synthetic data packet one byte at a time, checks the packet header, extracts an instrument ID, bid price, and ask price, then feeds the parsed bid/ask values into a simple signal engine. The signal engine outputs one of three actions using very basic decision making:

```text
00 = IGNORE
01 = BUY
10 = SELL
```

This is a portfolio project intended to demonstrate and deepen my understanding of FPGA design fundamentals including VHDL, finite state machines, modular RTL design, simulation, self-checking testbenches, and Vivado-based verification.

The current design uses a simple synthetic packet format. It does not parse live exchange data, Ethernet frames, TCP/UDP packets, or any real trading protocol. However there are plans for that to be changed in the future.

---

## Current Status

The parser, signal engine, and top-level integration milestones are complete.

Implemented:

* FSM-based packet parser
* 8-bit input byte stream
* two-byte packet header check
* instrument ID extraction
* bid price extraction
* ask price extraction
* one-cycle parser `out_valid` pulse
* simple signal engine
* BUY / SELL / IGNORE action encoding
* top-level module connecting parser output to signal engine input
* self-checking VHDL testbenches for parser, signal engine, and top-level design

Verified:

* valid packet parsing
* bad first header byte rejection
* bad second header byte rejection
* signal engine reset behaviour
* BUY case
* SELL case
* IGNORE case
* BUY priority case
* full top-level BUY case
* full top-level SELL case
* full top-level IGNORE case
* top-level bad header rejection

---

## Packet Format

The parser expects the following packet format:

```text
AB CD II BB BB AA AA
```

Where:

```text
AB CD = two-byte packet header
II    = 8-bit instrument ID
BB BB = 16-bit bid price
AA AA = 16-bit ask price
```

Example packet:

```text
AB CD 07 12 34 12 50
```

Expected parsed output:

```text
instrument = 0x07
bid_price  = 0x1234
ask_price  = 0x1250
```

The parser reads one byte at a time on each rising clock edge when `in_valid = '1'`.

---

## Signal Engine

The signal engine receives:

```text
bid_price
ask_price
buy_threshold
sell_threshold
```

It produces:

```text
00 = IGNORE
01 = BUY
10 = SELL
```

Current decision rule:

```text
if ask_price < buy_threshold:
    BUY

elsif bid_price > sell_threshold:
    SELL

else:
    IGNORE
```

BUY has priority over SELL if both conditions are true.

This is not intended to be a real trading strategy and is currently a placeholder. It is a simple hardware decision block used to demonstrate comparison logic, valid signalling, and module integration.

---

## Architecture

The top-level design connects the packet parser to the signal engine.

```text
input byte stream
       |
       v
market_packet_parser
       |
       | instrument
       | bid_price
       | ask_price
       | out_valid
       v
signal_engine
       |
       v
signal_action
action_valid
```

The parser extracts the packet fields and asserts `out_valid` when the parsed data is ready.

The parser `out_valid` signal drives the signal engine `in_valid` input.

The signal engine then checks the parsed bid/ask prices against the configured thresholds and asserts `action_valid` when the output action is ready.

---

## Design Files

```text
rtl/market_packet_parser.vhd
```

Synthesizable VHDL packet parser. Implemented as a finite state machine that checks the packet header, extracts fields, and pulses `out_valid`.

```text
rtl/signal_engine.vhd
```

Synthesizable VHDL signal engine. Compares parsed bid/ask prices against buy/sell thresholds and outputs IGNORE, BUY, or SELL.

```text
rtl/market_data_top.vhd
```

Top-level structural module. Instantiates the packet parser and signal engine, connects parser outputs to signal engine inputs, and exposes parsed fields for verification/debugging.

```text
tb/tb_market_packet_parser.vhd
```

Self-checking parser testbench. Sends packet bytes, waits for `out_valid`, and checks parsed outputs using assertions.

```text
tb/tb_signal_engine.vhd
```

Self-checking signal engine testbench. Checks reset, BUY, SELL, IGNORE, and BUY-priority behaviour.

```text
tb/tb_market_data_top.vhd
```

Self-checking top-level testbench. Sends full packets into the integrated design and checks parsed fields plus final signal actions.

```text
docs/verification_plan.md
```

Documents the packet format, test cases, and verification status.

---

## Parser FSM

The parser moves through the following states:

```text
IDLE
READ_MAGIC
READ_INSTRUMENT
READ_BID_HIGH
READ_BID_LOW
READ_ASK_HIGH
READ_ASK_LOW
OUTPUT_RESULT
ERROR_STATE
```

The parser consumes one input byte on each rising clock edge only when `in_valid = '1'`.

If the packet header is invalid, the parser enters an error state and returns to idle without asserting `out_valid`.

---

## Verification

The design is verified using self-checking VHDL testbenches. The testbenches generate clocks, apply reset, drive input stimulus, wait for valid output pulses, and check results using assertions.

### Parser Tests

| Test                   | Input Packet           | Expected Result                                            | Status |
| ---------------------- | ---------------------- | ---------------------------------------------------------- | ------ |
| Valid packet           | `AB CD 07 12 34 12 50` | Parsed fields match expected values and `out_valid` pulses | Pass   |
| Bad first header byte  | `AA CD 07 12 34 12 50` | Parser rejects packet and does not assert `out_valid`      | Pass   |
| Bad second header byte | `AB CC 07 12 34 12 50` | Parser rejects packet and does not assert `out_valid`      | Pass   |

### Signal Engine Tests

| Test              | Expected Result                                        | Status |
| ----------------- | ------------------------------------------------------ | ------ |
| Reset             | `action_valid = 0`, action returns to IGNORE           | Pass   |
| BUY case          | Outputs BUY when ask price is below buy threshold      | Pass   |
| SELL case         | Outputs SELL when bid price is above sell threshold    | Pass   |
| IGNORE case       | Outputs IGNORE when neither condition is true          | Pass   |
| BUY priority case | Outputs BUY when both BUY and SELL conditions are true | Pass   |

### Top-Level Integration Tests

| Test                      | Expected Result                                      | Status |
| ------------------------- | ---------------------------------------------------- | ------ |
| TOP BUY case              | Packet is parsed and signal engine outputs BUY       | Pass   |
| TOP SELL case             | Packet is parsed and signal engine outputs SELL      | Pass   |
| TOP IGNORE case           | Packet is parsed and signal engine outputs IGNORE    | Pass   |
| TOP bad first header case | Bad packet is rejected; no parsed/action valid pulse | Pass   |

---

## Current Scope

The current design uses a simplified synthetic packet format:

```text
AB CD II BB BB AA AA
```

This allows the core FPGA design ideas to be developed and verified first:

* byte-by-byte parsing
* finite state machine control
* field extraction
* valid-output signalling
* modular RTL design
* self-checking simulation
* top-level module integration

The design does not currently parse live exchange data, Ethernet frames, TCP/UDP packets, or any real trading protocol.

---

## Planned Next Steps

Planned next milestones:

* add more parser tests, including back-to-back packets
* add tests where `in_valid` pauses between bytes
* check timing slack
* document latency in clock cycles
* document resource usage and timing results
* add a Python packet generator
* add file-based packet test vectors
* create a more realistic packet replay testbench

Longer-term possible extensions:

* sending packet bytes from a PC to an FPGA board over UART
* adapting the parser to a more realistic market-data message format
* eventually connecting the parser to an Ethernet/UDP receive path

The project is intentionally built in stages so that the parser, verification, and timing behaviour are correct before adding more complex input interfaces.

---

## Tools

* VHDL
* AMD/Xilinx Vivado
* Vivado Simulator / XSim
