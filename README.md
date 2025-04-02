# MCST

Actively developed Intel 8051 toolchain with the goal of creating 
an assembler, disassembler, serial flasher and custom 
executable format containing debug symbols and relocatable program sections.

## Directory Structure

- **`/refs/`**: development references
- **`/src/`**: executable code

## Disassembler

For efficiency, it relies on a 256-entry table that gets addressed by the first instruction byte 
and contains such information as the instruction length, where to load the operands from (second byte, third byte, two bytes or special 11-bit mode).

It's possible to specify the target mcu to give the disassembler more context, 
which allows to translate addresses back into symbols of SFRs (special function registers). 
For microcontrollers with multiple SFR pages, it keeps track of writes to the SFRPAGE register.

The disassembler output is well-formatted and colored, resembling the source code as closely as possible and reconstructing the labels.
