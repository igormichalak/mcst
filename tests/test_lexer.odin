package tests

import "core:fmt"
import "core:testing"
import "../src/lexer"

expect_token :: proc(t: ^testing.T, tok, exp_tok: lexer.Token, msg_prefix := "", loc := #caller_location) -> bool {
	position_mismatch := testing.expectf(t, tok.line == exp_tok.line && tok.column == exp_tok.column,
		"%swrong token position. expected=(%d:%d), got=(%d:%d)",
		msg_prefix, exp_tok.line, exp_tok.column, tok.line, tok.column, loc=loc)

	kind_mismatch := testing.expectf(t, tok.kind == exp_tok.kind,
		"%swrong token (%d:%d) kind. expected=%v, got=%v",
		msg_prefix, exp_tok.line, exp_tok.column, exp_tok.kind, tok.kind, loc=loc)

	text_mismatch := testing.expectf(t, tok.text == exp_tok.text,
		"%swrong token (%d:%d) text. expected=%q, got=%q",
		msg_prefix, exp_tok.line, exp_tok.column, exp_tok.text, tok.text, loc=loc)

	return !position_mismatch && !kind_mismatch && !text_mismatch
}

@(test)
test_lexer :: proc(t: ^testing.T) {
	input := `
.equ SFRPAGE, 0xA7
.equ WDTCN, 0x97
.equ P1MDIN, 0xF2
.equ P1MDOUT, 0xA5
.equ P1SKIP, 0xD5
.equ XBR2, 0xE3

.org 0
start:
	mov SFRPAGE, #0x00
	mov WDTCN, #0xDE
	mov WDTCN, #0xAD
	mov P1MDIN, #0xFF
	mov P1MDOUT, #0xFF
	mov P1SKIP, #0xFF
	mov XBR2, #0x40

loop:
	setb P1.4
	acall delay

	clr P1.4
	acall delay

	sjmp loop

delay:
	mov R0, #0xFF
outer_loop:
	mov R1, #0xFF
inner_loop:
	djnz R1, inner_loop
	djnz R0, outer_loop
	ret
`
	tokens := [?]lexer.Token {
		{.NEWLINE, "\n", {1, 0}},

		// .equ SFRPAGE, 0xA7
		{.DOT, ".", {2, 0}}, {.EQU, "equ", {2, 1}}, {.SPACE, "", {2, 4}}, {.IDENT, "SFRPAGE", {2, 5}},
		{.COMMA, ",", {2, 12}}, {.SPACE, "", {2, 13}}, {.INT, "0xA7", {2, 14}}, {.NEWLINE, "\n", {2, 18}},

		// .equ WDTCN, 0x97
		{.DOT, ".", {3, 0}}, {.EQU, "equ", {3, 1}}, {.SPACE, "", {3, 4}}, {.IDENT, "WDTCN", {3, 5}},
		{.COMMA, ",", {3, 10}}, {.SPACE, "", {3, 11}}, {.INT, "0x97", {3, 12}}, {.NEWLINE, "\n", {3, 16}},

		// .equ P1MDIN, 0xF2
		{.DOT, ".", {4, 0}}, {.EQU, "equ", {4, 1}}, {.SPACE, "", {4, 4}}, {.IDENT, "P1MDIN", {4, 5}},
		{.COMMA, ",", {4, 11}}, {.SPACE, "", {4, 12}}, {.INT, "0xF2", {4, 13}}, {.NEWLINE, "\n", {4, 17}},

		// .equ P1MDOUT, 0xA5
		{.DOT, ".", {5, 0}}, {.EQU, "equ", {5, 1}}, {.SPACE, "", {5, 4}}, {.IDENT, "P1MDOUT", {5, 5}},
		{.COMMA, ",", {5, 12}}, {.SPACE, "", {5, 13}}, {.INT, "0xA5", {5, 14}}, {.NEWLINE, "\n", {5, 18}},

		// .equ P1SKIP, 0xD5
		{.DOT, ".", {6, 0}}, {.EQU, "equ", {6, 1}}, {.SPACE, "", {6, 4}}, {.IDENT, "P1SKIP", {6, 5}},
		{.COMMA, ",", {6, 11}}, {.SPACE, "", {6, 12}}, {.INT, "0xD5", {6, 13}}, {.NEWLINE, "\n", {6, 17}},

		// .equ XBR2, 0xE3
		{.DOT, ".", {7, 0}}, {.EQU, "equ", {7, 1}}, {.SPACE, "", {7, 4}}, {.IDENT, "XBR2", {7, 5}},
		{.COMMA, ",", {7, 9}}, {.SPACE, "", {7, 10}}, {.INT, "0xE3", {7, 11}}, {.NEWLINE, "\n", {7, 15}},

		{.NEWLINE, "\n", {8, 0}},

		// .org 0
		{.DOT, ".", {9, 0}}, {.ORG, "org", {9, 1}}, {.SPACE, "", {9, 4}}, {.INT, "0", {9, 5}}, {.NEWLINE, "\n", {9, 6}},

		// start:
		{.IDENT, "start", {10, 0}}, {.COLON, ":", {10, 5}}, {.NEWLINE, "\n", {10, 6}},

		// mov SFRPAGE, #0x00
		{.SPACE, "", {11, 0}}, {.IDENT, "mov", {11, 1}}, {.SPACE, "", {11, 4}}, {.IDENT, "SFRPAGE", {11, 5}},
		{.COMMA, ",", {11, 12}}, {.SPACE, "", {11, 13}}, {.HASH, "#", {11, 14}},
		{.INT, "0x00", {11, 15}}, {.NEWLINE, "\n", {11, 19}},

		// mov WDTCN, #0xDE
		{.SPACE, "", {12, 0}}, {.IDENT, "mov", {12, 1}}, {.SPACE, "", {12, 4}}, {.IDENT, "WDTCN", {12, 5}},
		{.COMMA, ",", {12, 10}}, {.SPACE, "", {12, 11}}, {.HASH, "#", {12, 12}},
		{.INT, "0xDE", {12, 13}}, {.NEWLINE, "\n", {12, 17}},

		// mov WDTCN, #0xAD
		{.SPACE, "", {13, 0}}, {.IDENT, "mov", {13, 1}}, {.SPACE, "", {13, 4}}, {.IDENT, "WDTCN", {13, 5}},
		{.COMMA, ",", {13, 10}}, {.SPACE, "", {13, 11}}, {.HASH, "#", {13, 12}},
		{.INT, "0xAD", {13, 13}}, {.NEWLINE, "\n", {13, 17}},

		// mov P1MDIN, #0xFF
		{.SPACE, "", {14, 0}}, {.IDENT, "mov", {14, 1}}, {.SPACE, "", {14, 4}}, {.IDENT, "P1MDIN", {14, 5}},
		{.COMMA, ",", {14, 11}}, {.SPACE, "", {14, 12}}, {.HASH, "#", {14, 13}},
		{.INT, "0xFF", {14, 14}}, {.NEWLINE, "\n", {14, 18}},

		// mov P1MDOUT, #0xFF
		{.SPACE, "", {15, 0}}, {.IDENT, "mov", {15, 1}}, {.SPACE, "", {15, 4}}, {.IDENT, "P1MDOUT", {15, 5}},
		{.COMMA, ",", {15, 12}}, {.SPACE, "", {15, 13}}, {.HASH, "#", {15, 14}},
		{.INT, "0xFF", {15, 15}}, {.NEWLINE, "\n", {15, 19}},

		// mov P1SKIP, #0xFF
		{.SPACE, "", {16, 0}}, {.IDENT, "mov", {16, 1}}, {.SPACE, "", {16, 4}}, {.IDENT, "P1SKIP", {16, 5}},
		{.COMMA, ",", {16, 11}}, {.SPACE, "", {16, 12}}, {.HASH, "#", {16, 13}},
		{.INT, "0xFF", {16, 14}}, {.NEWLINE, "\n", {16, 18}},

		// mov XBR2, #0x40
		{.SPACE, "", {17, 0}}, {.IDENT, "mov", {17, 1}}, {.SPACE, "", {17, 4}}, {.IDENT, "XBR2", {17, 5}},
		{.COMMA, ",", {17, 9}}, {.SPACE, "", {17, 10}}, {.HASH, "#", {17, 11}},
		{.INT, "0x40", {17, 12}}, {.NEWLINE, "\n", {17, 16}},

		{.NEWLINE, "\n", {18, 0}},

		// loop:
		{.IDENT, "loop", {19, 0}}, {.COLON, ":", {19, 4}}, {.NEWLINE, "\n", {19, 5}},

		// setb P1.4
		{.SPACE, "", {20, 0}}, {.IDENT, "setb", {20, 1}}, {.SPACE, "", {20, 5}}, {.IDENT, "P1", {20, 6}},
		{.DOT, ".", {20, 8}}, {.INT, "4", {20, 9}}, {.NEWLINE, "\n", {20, 10}},

		// acall delay
		{.SPACE, "", {21, 0}}, {.IDENT, "acall", {21, 1}}, {.SPACE, "", {21, 6}}, {.IDENT, "delay", {21, 7}},
		{.NEWLINE, "\n", {21, 12}},

		{.NEWLINE, "\n", {22, 0}},

		// clr P1.4
		{.SPACE, "", {23, 0}}, {.IDENT, "clr", {23, 1}}, {.SPACE, "", {23, 4}}, {.IDENT, "P1", {23, 5}},
		{.DOT, ".", {23, 7}}, {.INT, "4", {23, 8}}, {.NEWLINE, "\n", {23, 9}},

		// acall delay
		{.SPACE, "", {24, 0}}, {.IDENT, "acall", {24, 1}}, {.SPACE, "", {24, 6}}, {.IDENT, "delay", {24, 7}},
		{.NEWLINE, "\n", {24, 12}},

		{.NEWLINE, "\n", {25, 0}},

		// sjmp loop
		{.SPACE, "", {26, 0}}, {.IDENT, "sjmp", {26, 1}}, {.SPACE, "", {26, 5}}, {.IDENT, "loop", {26, 6}}, {.NEWLINE, "\n", {26, 10}},

		{.NEWLINE, "\n", {27, 0}},

		// delay:
		{.IDENT, "delay", {28, 0}}, {.COLON, ":", {28, 5}}, {.NEWLINE, "\n", {28, 6}},

		// mov R0, #0xFF
		{.SPACE, "", {29, 0}}, {.IDENT, "mov", {29, 1}}, {.SPACE, "", {29, 4}}, {.IDENT, "R0", {29, 5}},
		{.COMMA, ",", {29, 7}}, {.SPACE, "", {29, 8}}, {.HASH, "#", {29, 9}}, {.INT, "0xFF", {29, 10}}, {.NEWLINE, "\n", {29, 14}},

		// outer_loop:
		{.IDENT, "outer_loop", {30, 0}}, {.COLON, ":", {30, 10}}, {.NEWLINE, "\n", {30, 11}},

		// mov R1, #0xFF
		{.SPACE, "", {31, 0}}, {.IDENT, "mov", {31, 1}}, {.SPACE, "", {31, 4}}, {.IDENT, "R1", {31, 5}},
		{.COMMA, ",", {31, 7}}, {.SPACE, "", {31, 8}}, {.HASH, "#", {31, 9}}, {.INT, "0xFF", {31, 10}}, {.NEWLINE, "\n", {31, 14}},

		// inner_loop:
		{.IDENT, "inner_loop", {32, 0}}, {.COLON, ":", {32, 10}}, {.NEWLINE, "\n", {32, 11}},

		// djnz	R1, inner_loop
		{.SPACE, "", {33, 0}}, {.IDENT, "djnz", {33, 1}}, {.SPACE, "", {33, 5}}, {.IDENT, "R1", {33, 6}},
		{.COMMA, ",", {33, 8}}, {.SPACE, "", {33, 9}}, {.IDENT, "inner_loop", {33, 10}}, {.NEWLINE, "\n", {33, 20}},

		// djnz	R0, outer_loop
		{.SPACE, "", {34, 0}}, {.IDENT, "djnz", {34, 1}}, {.SPACE, "", {34, 5}}, {.IDENT, "R0", {34, 6}},
		{.COMMA, ",", {34, 8}}, {.SPACE, "", {34, 9}}, {.IDENT, "outer_loop", {34, 10}}, {.NEWLINE, "\n", {34, 20}},

		// ret
		{.SPACE, "", {35, 0}}, {.IDENT, "ret", {35, 1}}, {.NEWLINE, "\n", {35, 4}},

		{.EOF, "", {36, 0}},
	}

	l: lexer.Lexer
	lexer.lexer_init(&l, input)

	for exp_tok, idx in tokens {
		tok := lexer.next_token(&l)
		expect_token(t, tok, exp_tok, fmt.tprintf("tokens[%d]: ", idx))
	}
}

@(test)
test_lexer_various :: proc(t: ^testing.T) {
	Test_Case :: struct {
		input: string,
		tokens: []lexer.Token,
	}

	test_cases := [?]Test_Case {
		{
			input = " \n  \n  ",
			tokens = {
				{.SPACE, "", {1, 0}},
				{.NEWLINE, "\n", {1, 1}},
				{.SPACE, "", {2, 0}},
				{.NEWLINE, "\n", {2, 2}},
				{.SPACE, "", {3, 0}},
				{.EOF, "", {3, 2}},
			},
		},
	}


	for tc, tc_idx in test_cases {
		l: lexer.Lexer
		lexer.lexer_init(&l, tc.input)

		for exp_tok in tc.tokens {
			tok := lexer.next_token(&l)
			expect_token(t, tok, exp_tok, fmt.tprintf("test_cases[%d]: ", tc_idx))
		}
	}
}
