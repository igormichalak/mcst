package mcst

import "core:encoding/ansi"
import "core:fmt"
import "core:math"
import "core:strings"

ANSI_SEQ_LABEL    :: ansi.CSI + ansi.FG_COLOR_8_BIT + ";3"  + ansi.SGR // 172 is a nice alternative
ANSI_SEQ_MNEMONIC :: ansi.CSI + ansi.FG_COLOR_8_BIT + ";23" + ansi.SGR
ANSI_SEQ_LITERAL  :: ansi.CSI + ansi.FG_COLOR_8_BIT + ";96" + ansi.SGR
ANSI_SEQ_SYMBOL   :: ansi.CSI + ansi.FG_COLOR_8_BIT + ";60" + ansi.SGR
ANSI_SEQ_OPERAND  :: ansi.CSI + ansi.FG_COLOR_8_BIT + ";60" + ansi.SGR
ANSI_SEQ_COMMENT  :: ANSI_SEQ_RESET

ANSI_SEQ_RESET :: ansi.CSI + ansi.RESET + ansi.SGR

Character_Case :: enum u8 {
	UPPERCASE,
	LOWERCASE,
}

write_cased_string :: proc(sb: ^strings.Builder, s: string, cc: Character_Case) {
	for r in s {
		switch {
		case cc == .UPPERCASE && 'a' <= r && r <= 'z':
			strings.write_rune(sb, r - 32)
		case cc == .LOWERCASE && 'A' <= r && r <= 'Z':
			strings.write_rune(sb, r + 32)
		case:
			strings.write_rune(sb, r)
		}
	}
}

write_space :: proc(sb: ^strings.Builder, width: int) {
	for _ in 0..<width {
		strings.write_rune(sb, ' ')
	}
}

count_digits :: proc(n: int) -> int {
	n := n
	if n == 0 {
		return 1
	}
	n = abs(n)
	return int(math.floor(math.log10(f64(n)))) + 1
}

hex_string_u8 :: #force_inline proc(sb: ^strings.Builder, n: u8, uppercase := false) {
	fmt.sbprintf(sb, "%02X" if uppercase else "%02x", n)
}

hex_string_u16 :: #force_inline proc(sb: ^strings.Builder, n: u16, uppercase := false) {
	fmt.sbprintf(sb, "%04X" if uppercase else "%04x", n)
}

hex_string :: proc{hex_string_u8, hex_string_u16}

operand_to_string :: proc(sb: ^strings.Builder, operand: ^Operand, disasm_ctx: ^Disassembly_Context) {
	switch operand.type {
	case .ACC:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "A" + ANSI_SEQ_RESET)
	case .REG:
		fmt.sbprintf(sb, ANSI_SEQ_OPERAND + "R%d" + ANSI_SEQ_RESET, operand.value)
	case .AB:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "AB" + ANSI_SEQ_RESET)
	case .CARRY_BIT:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "C" + ANSI_SEQ_RESET)
	case .BIT_ADDR:
		symbol := symbol_from_address(u16(operand.value), .IRAM_BIT, disasm_ctx.sfr_page)
		if symbol == "" {
			fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "0x%02X" + ANSI_SEQ_RESET, operand.value)
		} else {
			fmt.sbprintf(sb, ANSI_SEQ_SYMBOL + "%s.%d" + ANSI_SEQ_RESET, symbol, operand.value & 0b111)
		}
	case .INV_BIT_ADDR:
		fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "/0x%02X" + ANSI_SEQ_RESET, operand.value)
	case .IMM, .IMM_LONG:
		fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "#0x%02X" + ANSI_SEQ_RESET, operand.value)
		if operand.value != 0x00 && operand.value != 0xFF && operand.value != 0xFFFF {
			fmt.sbprintf(sb, " " + ANSI_SEQ_COMMENT + "; %d" + ANSI_SEQ_RESET, operand.value)
		}
	case .DPTR:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "DPTR" + ANSI_SEQ_RESET)
	case .DIRECT_ADDR:
		symbol := symbol_from_address(u16(operand.value), .IRAM, disasm_ctx.sfr_page)
		if symbol == "" {
			fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "0x%02X" + ANSI_SEQ_RESET, operand.value)
		} else {
			strings.write_string(sb, ANSI_SEQ_SYMBOL)
			strings.write_string(sb, symbol)
			strings.write_string(sb, ANSI_SEQ_RESET)
		}
	case .INDIRECT_REG:
		fmt.sbprintf(sb, ANSI_SEQ_OPERAND + "@R%d" + ANSI_SEQ_RESET, operand.value)
	case .INDIRECT_DPTR:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "@DPTR" + ANSI_SEQ_RESET)
	case .INDIRECT_ACC_PLUS_DPTR:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "@A+DPTR" + ANSI_SEQ_RESET)
	case .INDIRECT_ACC_PLUS_PC:
		strings.write_string(sb, ANSI_SEQ_OPERAND + "@A+PC" + ANSI_SEQ_RESET)
	case .ADDR_11, .ADDR_16:
		fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "0x%04x" + ANSI_SEQ_RESET, operand.value)
	case .OFFSET:
		fmt.sbprintf(sb, ANSI_SEQ_LITERAL + "%d" + ANSI_SEQ_RESET, operand.value)
	case .NONE:
	}
}

instruction_to_string :: proc(
	sb: ^strings.Builder,
	instruction: ^Instruction,
	disasm_ctx: ^Disassembly_Context,
	jump_operand := "",
) {
	mnemonic := Op_Mnemonics[instruction.op]

	strings.write_string(sb, ANSI_SEQ_MNEMONIC)
	write_cased_string(sb, mnemonic, .LOWERCASE)
	strings.write_string(sb, ANSI_SEQ_RESET)

	for pad := 6 - len(mnemonic); pad > 0; pad -= 1 {
		strings.write_rune(sb, ' ')
	}
	strings.write_rune(sb, ' ')

	hasOperandA := false
	hasOperandB := false

	if instruction.a.type != .NONE {
		operand_to_string(sb, &instruction.a, disasm_ctx)
		hasOperandA = true
	}
	if instruction.b.type != .NONE {
		if hasOperandA {
			strings.write_string(sb, ", ")
		}
		operand_to_string(sb, &instruction.b, disasm_ctx)
		hasOperandB = true
	}
	if instruction.jump.type != .NONE {
		if hasOperandA || hasOperandB {
			strings.write_string(sb, ", ")
		}
		if jump_operand == "" {
			operand_to_string(sb, &instruction.jump, disasm_ctx)
		} else {
			strings.write_string(sb, jump_operand)
		}
	}
}
