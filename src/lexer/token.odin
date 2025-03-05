package lexer

Token_Kind :: enum {
	ILLEGAL, // Illegal token
	EOF,     // End-of-file token
	NEWLINE, // New line token
	SPACE,   // Whitespace token

	// Identifiers + literals
	IDENT, // Token 'string'
	INT,   // Token '0x00..' | '0b00..' | '128..'

	// Operators + modifiers
	MINUS, // Token '-'
	HASH,  // Token '#'

	// Delimiters
	COMMA, // Token ','
	COLON, // Token ':'
	DOT,   // Token '.'

	// Keywords
	ORG, // Token 'org'
	EQU, // Token 'equ'
}

Position :: struct {
	line:   int,
	column: int,
}

Token :: struct {
	kind: Token_Kind,
	text: string,
	using pos: Position,
}

lookup_ident :: proc(ident: string) -> Token_Kind {
	switch ident {
	case "org", "ORG":
		return .ORG
	case "equ", "EQU":
		return .EQU
	case:
		return .IDENT
	}
}
