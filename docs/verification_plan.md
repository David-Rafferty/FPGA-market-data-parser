# Verification Plan

## Module: market_packet_parser

The `market_packet_parser` module is tested using a self-checking VHDL testbench.

The testbench:
- generates a clock
- applies reset
- sends fake packet bytes into the parser
- waits for `out_valid`
- checks the parsed outputs using assertion

## Packet Formatting 

Valid packet:

```text
AB CD II BB BB AA AA

Where:

AB CD = two-byte packet header
II = 8-bit instrument ID
BB BB = 16-bit bid price
AA AA = 16-bit ask price

Example packet:

AB CD 07 12 34 12 50

Expected output:

instrument = 0x07
bid_price  = 0x1234
ask_price  = 0x1250

| Test                   | Input packet           | Expected result                                            |
| ---------------------- | ---------------------- | ---------------------------------------------------------- |
| Valid packet           | `AB CD 07 12 34 12 50` | `out_valid` pulses and parsed fields match expected values |
| Bad first header byte  | `AA CD 07 12 34 12 50` | Parser rejects packet; no valid output pulse               |
| Bad second header byte | `AB CC 07 12 34 12 50` | Parser rejects packet; no valid output pulse               |

## Current Status:

- Valid packet test passes.
- Bad first header byte test passes.
- Bad second header byte test passes.
- Parser correctly rejects invalid packet headers without asserting `out_valid`.



