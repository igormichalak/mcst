# CLI

Planned command-line interface of the toolchain.

```
mcst assemble file0.asm [ file1.asm ... ]
--help
--output { file.bin | file.hex | file.neef }
--format { AUTO | BINARY | HEX | NEEF }

mcst disassemble { file.bin | file.hex | file.neef }
--help
--bounds address:address
--no-labels
--no-address
--no-raw
--immediate-base int
--lowercase
--column-gap int,...
--no-color

mcst convert file.neef { file.bin | file.hex }
--help
--format { AUTO | BINARY | HEX }
```
