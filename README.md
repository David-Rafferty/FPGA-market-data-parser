FPGA Market Data Packet Parser

This project implements a simplified VHDL FPGA market-data packet parser.

The parser receives a synthetic market-data packet one byte at a time, checks the packet header, extracts an instrument ID, bid price, and ask price, then asserts out_valid for one clock cycle when the parsed fields are ready.

This is a portfolio project intended to help me learn and demonstrate FPGA design fundamentals including VHDL, finite state machines, simulation, self-checking testbenches, and Vivado-based verification.

**Current Status**

The first parser milestone is complete.

Implemented:

FSM-based packet parser
8-bit input byte stream
two-byte packet header check
instrument ID extraction
bid price extraction
ask price extraction
one-cycle out_valid pulse
self-checking VHDL testbench

Verified tests:

valid packet test
bad first header byte test
bad second header byte test
**Packet Format**

The parser expects the following packet format:

AB CD II BB BB AA AA

Where:

AB CD = packet header
II    = 8-bit instrument ID
BB BB = 16-bit bid price
AA AA = 16-bit ask price

Example packet:

AB CD 07 12 34 12 50

Expected parsed output:

instrument = 0x07
bid_price  = 0x1234
ask_price  = 0x1250

**Design Files**
rtl/market_packet_parser.vhd

Contains the synthesizable VHDL parser. The parser is implemented as a finite state machine.

tb/tb_market_packet_parser.vhd

Contains the self-checking VHDL testbench. It generates a clock, applies reset, sends test packets, waits for out_valid, and checks the parser outputs using assertions.

docs/verification_plan.md

Documents the packet format, test cases, and current verification status.

**Parser FSM**

The parser moves through the following states:

IDLE
READ_MAGIC
READ_INSTRUMENT
READ_BID_HIGH
READ_BID_LOW
READ_ASK_HIGH
READ_ASK_LOW
OUTPUT_RESULT
ERROR_STATE

The parser reads one byte on each rising clock edge when in_valid = '1'.

**Verification**

The current self-checking testbench verifies:

Test	                  |        Input Packet	      |           Expected Result	                                     | Status
Valid packet	          |    AB CD 07 12 34 12 50	  |     Parsed fields match expected values and out_valid pulses	 |  Pass
Bad first header byte	  |    AA CD 07 12 34 12 50	  |     Parser rejects packet and does not assert out_valid	       |  Pass
Bad second header byte	|    AB CC 07 12 34 12 50	  |     Parser rejects packet and does not assert out_valid	       |  Pass


**Next Steps**

Planned next milestones:

Add a simple signal engine
Generate BUY, SELL, or IGNORE output
Connect parser output to signal engine input
Add more parser tests, including back-to-back packets
Run Vivado synthesis and collect timing/resource reports
Document latency in clock cycles

**Tools**

VHDL
AMD/Xilinx Vivado
Vivado Simulator / XSim

**Current Scope and Future Expansion**

The current version of this project uses a simplified synthetic packet format:

AB CD II BB BB AA AA

This allows the core FPGA design ideas to be developed and verified first, including byte-by-byte parsing, finite state machine control, field extraction, valid-output signalling, and self-checking simulation.

The design does not currently parse live exchange data, Ethernet frames, TCP/UDP packets, or any real trading protocol.

Future extensions could include:

feeding recorded packet byte streams into the VHDL testbench
loading packet test vectors from a file
sending packet bytes from a PC to an FPGA board over UART
adding a simple packet replay tool in Python
adapting the parser to a more realistic market-data message format
eventually connecting the parser to an Ethernet/UDP receive path

The project is intentionally built in stages so that the parser, verification, and timing behaviour are correct before adding more complex input interfaces.
