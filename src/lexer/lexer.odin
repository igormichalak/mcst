package lexer

import "core:strings"
import "core:unicode/utf8"

Lexer :: struct {
	input:       string,
	curr_char:   rune,
	cc_width:    int,
	peek_char:   rune,
	pc_width:    int,
	read_offset: int,
	using pos:   Position,
}

lexer_init :: proc(l: ^Lexer, input: string) {
	l.input = input
	l.read_offset = 0
	read_char(l)
	read_char(l)
	l.line = 1
	l.column = 0
}

curr_char_offset :: #force_inline proc(l: ^Lexer) -> int {
	return l.read_offset - l.cc_width - l.pc_width
}

read_char :: proc(l: ^Lexer) {
	after_nl := l.curr_char == '\n'
	l.curr_char = l.peek_char
	l.cc_width = l.pc_width

	if l.read_offset >= len(l.input) {
		l.peek_char = utf8.RUNE_EOF
		l.pc_width = 0
	} else {
		l.peek_char, l.pc_width = utf8.decode_rune(l.input[l.read_offset:])
		l.read_offset += l.pc_width
	}

	if after_nl {
		l.line += 1
		l.column = 0
	} else {
		l.column += 1
	}
}

is_ident_char :: proc(c: rune) -> bool {
	switch c {
	case 'A'..='Z', 'a'..='z', '_', '0'..='9':
		return true
	case:
		return false
	}
}

read_identifier :: proc(l: ^Lexer) -> string {
	start_offset := curr_char_offset(l)

	for is_ident_char(l.curr_char) {
		read_char(l)
	}

	end_offset := curr_char_offset(l)
	return l.input[start_offset:end_offset]
}

is_decimal_digit :: proc(c: rune) -> bool {
	switch c {
	case '0'..='9':
		return true
	case:
		return false
	}
}

is_binary_digit :: proc(c: rune) -> bool {
	switch c {
	case '0', '1':
		return true
	case:
		return false
	}
}

is_hex_digit :: proc(c: rune) -> bool {
	switch c {
	case '0'..='9', 'A'..='F', 'a'..='f':
		return true
	case:
		return false
	}
}

read_number :: proc(l: ^Lexer) -> (string, bool) {
	start_offset := curr_char_offset(l)
	ok := true

	switch {
	case strings.has_prefix(l.input[start_offset:], "0x"):
		read_char(l)
		read_char(l)
		if !is_hex_digit(l.curr_char) {
			ok = false
			break
		}
		for is_hex_digit(l.curr_char) {
			read_char(l)
		}
	case strings.has_prefix(l.input[start_offset:], "0b"):
		read_char(l)
		read_char(l)
		if !is_binary_digit(l.curr_char) {
			ok = false
			break
		}
		for is_binary_digit(l.curr_char) {
			read_char(l)
		}
	case:
		for is_decimal_digit(l.curr_char) {
			read_char(l)
		}
	}

	end_offset := curr_char_offset(l)
	return l.input[start_offset:end_offset], ok
}

is_whitespace :: proc(c: rune) -> bool {
	switch c {
	case ' ', '\t', '\v', '\f', '\r':
		return true
	case:
		return false
	}
}

skip_whitespace :: proc(l: ^Lexer) {
	for is_whitespace(l.curr_char) {
		read_char(l)
	}
}

get_char_token :: proc(l: ^Lexer, kind: Token_Kind) -> Token {
	offset := curr_char_offset(l)
	return {kind=kind, text=l.input[offset:offset+l.cc_width], pos=l.pos}
}

next_token :: proc(l: ^Lexer) -> (tok: Token) {
	switch l.curr_char {
	case '-':
		tok = get_char_token(l, .MINUS)
		read_char(l)
		return
	case '#':
		tok = get_char_token(l, .HASH)
		read_char(l)
		return
	case ',':
		tok = get_char_token(l, .COMMA)
		read_char(l)
		return
	case ':':
		tok = get_char_token(l, .COLON)
		read_char(l)
		return
	case '.':
		tok = get_char_token(l, .DOT)
		read_char(l)
		return
	case '\n':
		tok = get_char_token(l, .NEWLINE)
		read_char(l)
		return
	case ' ', '\t', '\v', '\f', '\r':
		pos := l.pos
		skip_whitespace(l)
		return {.SPACE, "", pos}
	case '0'..='9':
		pos := l.pos
		text, ok := read_number(l)
		if ok {
			return {.INT, text, pos}
		} else {
			return {.ILLEGAL, text, pos}
		}
	case 'A'..='Z', 'a'..='z', '_':
		pos := l.pos
		text := read_identifier(l)
		return {lookup_ident(text), text, pos}
	case utf8.RUNE_EOF:
		return {.EOF, "", l.pos}
	case:
		tok = get_char_token(l, .ILLEGAL)
		read_char(l)
		return
	}
}
