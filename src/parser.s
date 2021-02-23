/* ----------------------------------------------------------------
	parser.s

	Command Parser Module

	Created:   2021-02-15
	Last edit: 2021-02-21

	PrintCommandList
	ParseCmd

----------------------------------------------------------------
MIT License

Copyright 2021 David Bolenbaugh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
----------------------------------------------------------------
ParseCmd
PrintCommandList
------------------------------------------------------------- */

   	.include "arch-include.s"	// .arch and .cpu directives
   	.include "header-include.s"

/* ------------------------------------------------------------ */

	.global		ParseCmd

//----------------------------------------
	.data
//----------------------------------------

	.align 4 // <-- This is 128 bit alignment

//------------------------
//   Command Table
//
// format:
// 8 byte - null terminate string
// 8 byte - address to call
//
//  C0000000  1 charater command
//  0000000000000000  64 bit address word
//
//  CCCCCCC0  7 character command
//  0000000000000000  64 bit address word
//
//------------------------
Command_Table:
	.ascii	"."
	.byte	0,0,0,0,0,0,0
	.quad	Command_print

	.ascii	"clrstk"
	.byte	0,0
	.quad	Command_clrstk

	.ascii	"clrx"
	.byte	0,0,0,0
	.quad	Command_clrx

	.ascii	"cmdlist"
	.byte	0
	.quad	Command_cmdlist

	.ascii	"D.accv"
	.byte	0,0
	.quad	Command_D_accv

	.ascii	"D.fill"
	.byte	0,0
	.quad	Command_D_fill

	.ascii	"exit"
	.byte	0,0,0,0
	.quad	Command_exit

	.ascii	"help"
	.byte	0,0,0,0
	.quad	Command_help

	.ascii	"hex"
	.byte	0,0,0,0,0
	.quad	Command_hex

	.ascii	"prac"
	.byte	0,0,0,0
	.quad	Command_prac

	.ascii	"print"
	.byte	0,0,0
	.quad	Command_print

	.ascii	"q"
	.byte	0,0,0,0,0,0,0
	.quad	Command_exit

	.ascii	"quit"
	.byte	0,0,0,0
	.quad	Command_exit

	.ascii	"sf"
	.byte	0,0,0,0,0,0
	.quad	Command_sigfigs

	.ascii	"sigfigs"
	.byte	0
	.quad	Command_sigfigs

	.ascii	"test"
	.byte	0,0,0,0
	.quad	Command_test

	.ascii	"version"
	.byte	0
	.quad	Command_version

// End table marker
	.byte	0,0,0,0,0,0,0,0
	.quad	0
Command_TableEnd:

//----------------------------------------
//
//   Defined text messages
//
//----------------------------------------

	.align 4

StackPtrSnapshot:
// TODO what size?
	.quad	0

StackPtrErrorMsg:	.asciz	"\nWarning: Stack pointer moving.\n"
PromptString:		.asciz	"Op Code: "
OpCodeErrString:	.asciz	"     Input Error: Illegal Op Code.  (Type: cmdlist)\n\n"
// Fatal error messages
AlignErrorMsg:		.asciz	"Error: Command table not aligned in 128 bit blocks"
Byte8ErrorMsg:		.asciz	"Error: Command table not zero byte8"
ACC_Error:		.asciz	"\n     Warning: [No_Word] not equal [D_Flt_Word]\n"

message_input_error:
			// red text
			.byte	27
			.ascii	"[31m"
			.ascii	"\n  Error converting string to floating point number, stack not rotated.\n\n"
			.byte	27
			.ascii	"[0m"
			.byte 0

			.align 4
//----------------------------------------
	.text
	.align 4
//----------------------------------------


/*******************************************

   PrintCommandList

   Prints a list of commands separaed
   by space characters

   Input: none

   Output: none

*********************************************/
PrintCommandList:
	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x9, [sp, #24]
	str	x10, [sp, #32]

	ldr	x10, =Command_Table

	mov	x0, x10			// Address first command
10:
	bl	StrOut			// print command
	mov	x0, #32			// ASCII space
	bl	CharOut
	add	x10, x10, #16		// point next entry
	mov	x0, x10
	ldr	x9, [x0]
	tst	x9, x9			// is zero, last?
	b.ne	10b

	bl	CROut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x9, [sp, #24]
	ldr	x10, [sp, #32]
	add	sp, sp, #48
	ret

/*******************************************

   ParseCmd

   This is an infinite loop

   Each cycle prints prompt and then calls
   command handlers in a loop.

   Input: none

   Output: none

*********************************************/
ParseCmd:
//
// Check stack pointer for unexpected change
//
	ldr	x9, =StackPtrSnapshot	// x9 pointer
	ldr	x10, [x9]		// last stack pointer address
	tst	x10, x10		// Initialized? (zero?)
	b.ne	10f			// next, skip init
	mov	x10, sp
	str	x10, [x9]		// Initialize stack pointer snapshot
10:
	mov	x9, sp			// current
	cmp	x10, x9			// changed from last?
	b.eq	20f			// no, expected result
	ldr	x10, =StackPtrErrorMsg	// Error, stack is growing
	bl	StrOut
20:
//
// Check command table alignment
//
	ldr	x9, =Command_TableEnd	// get last address of table
	tst	x9, #0x07		// proper alignment 3 bit are zero
	b.eq	30f			// zero, no error
	ldr	x0, =AlignErrorMsg	// Error message pointer
	mov	x1, #2344		// 12 bit error code
	b	FatalError
30:

	ldr	x0, =No_Word
	ldr	x1, =D_Flt_Word
	ldr	x0, [x0]
	ldr	x1, [x1]
	cmp	x0, x1
	b.eq	35f
	ldr	x0, =ACC_Error		// Error message pointer
	mov	x1, #2345		// 12 bit error code
	b	FatalError
35:

//
// Show prompt string
//
	ldr	x0,=PromptString
	bl	StrOut
//
// Get input line from stdin
//
	bl	KeyIn			// Return pointer in x8
//
// check for number input
//
//
// Assume number start with '+' or '-' or '.' or digit '0' to '9'
//
// Case of '+' or '-' or '.' followed by 0x00 (string length = 1)
// In this case, it must be addition, subtraction or print command
//
// check 16 bit word  '+' + 00
//
	ldrh	w0, [x8]		// get 16 bit (character + next character)
	cmp	w0, #0x002b		// Compare '+' + 00
	b.eq	not_number
	cmp	w0, #0x002D		// Compare '-' + 00
	b.eq	not_number
	cmp	w0, #0x002E		// Compare '.' + 00
	b.eq	not_number
	// cmp	w0, #0x0020		// Compare ' ' + 00
	// b.eq	not_number
//
// Now check numeric characters
//
	ldrb	w0, [x8]		// get 8 bit character
	cmp	w0, #'+'
	b.eq	is_numeric
	cmp	w0, #'+'
	b.eq	is_numeric
	cmp	w0, #'-'
	b.eq	is_numeric
	cmp	w0, #'.'
	b.eq	is_numeric
	// cmp	w0, #' '
	// b.eq	is_numeric

	cmp	w0, #'0'
	b.lt	not_number
	cmp	w0, #'9'
	b.gt	not_number
//
// Must be a number, convert it
//
is_numeric:
	mov	x0, x8			// pointer to input string
	mov	x1, #0
	bl	InputVariable
	cmp	x1, #0			// Check for input error
	b.eq	100f
	ldr	x0, =message_input_error
	bl	StrOut
	b	ParseCmd
100:
	mov	x1, HAND_ZREG
	mov	x2, HAND_TREG
	bl	CopyVariable

	mov	x1, HAND_YREG
	mov	x2, HAND_ZREG
	bl	CopyVariable

	mov	x1, HAND_XREG
	mov	x2, HAND_YREG
	bl	CopyVariable

	mov	x1, HAND_ACC
	mov	x2, HAND_XREG
	bl	CopyVariable

	bl	PrintResult
	b	ParseCmd

not_number:
	mov	x20,  x8		// x20 pointer to input buffer
	ldr	x19,  =Command_Table	// x19 pointer to command table
//
// Loop here for check next command in table
//
40:
	ldr	w10, [x19, #8]		// Table + address_offset
	tst	w10, w10		// Zero? (past last command)
	b.eq	Command_Not_Found
	mov	x21, #0			// index to command character
	ldrb	w10, [x20, x21]		// character from input
	ldrb	w11, [x19, x21]		// character from table
//
// Loop here for character check
//
50:
	cmp	w10, w11			// character match?
	b.ne	70f			// no, get next command
	add	x21, x21, #1		// Yes, increment index to next char
	cmp	x21, #8			// Index > 7 is command table error
	b.ne	60f			// Command table is valid (< 7 chars)
	ldr	x0, =Byte8ErrorMsg	// Error message pointer
	mov	x1, #1224		// 12 bit error code
	b	FatalError
60:
	ldrb	w10, [x20, x21]		// next character from input
	ldrb	w11, [x19, x21]		// next character in table
	tst	w11, w11		// Different? (not match)
	b.ne	50b			// Yes, check next char for match
//
// Check if command has agrument after space character
//
	tst	w10, w10		// Next input char 0 or space?
	b.eq	Com_Tab_MatchNoArg
	cmp	w10, #32		// ascii space?
	b.eq	Com_Tab_MatchWithArg
//
// Move pointer to next command in table
//
70:
	add	x19, x19, #16		// increment to next command
	b.al	40b			// loop back, nect command
//
// Exit - Command not found in table
//
Command_Not_Found:
	ldr	x0, =OpCodeErrString
	bl	StrOut
	b	ParseCmd		// loop always taken
//
// Exit - Command matches, no argument
//
Com_Tab_MatchNoArg:
	add	x9, x19, #8		// x9 address pointer
	ldr	x10, [x9]		// x10 executable address
	mov	x0, xzr			// x0 arg pointer zero when no argument
	br	x10			// jump to handler at [x10]
//
// Exit - Command matches, additional arguments on input line
//
Com_Tab_MatchWithArg:
	add	x21, x20, x21		// address + index pointer to space char
	add	x21, x21, #1		// increment past space char
	ldrb	w10, [x21]		// first argument character
	tst	w10, w10		// zero?
	b.eq	Com_Tab_MatchNoArg	// then space without argument
	add	x9, x19, #8		// x9 address pointer
	ldr	x10, [x9]		// x10 executable address
	mov	x0, x21			// x0 pointer to argument
	br	x10			// jump to handler at [x10]

ParseCmdEnd:

/*-------------------------------------------------------------
    Command Handlers
-------------------------------------------------------------*/
	.align 4

//
//
//
Command_clrx:
	mov	x1, HAND_XREG
	bl	ClearVariable

	bl	PrintResult
	b	ParseCmd

//
//
//
Command_clrstk:
	mov	x1, HAND_XREG
	bl	ClearVariable
	mov	x1, HAND_YREG
	bl	ClearVariable
	mov	x1, HAND_ZREG
	bl	ClearVariable
	mov	x1, HAND_TREG
	bl	ClearVariable
	bl	PrintResult
	b	ParseCmd

//
//
//
Command_cmdlist:
	bl	CROut
	bl	PrintCommandList
	bl	CROut
	b	ParseCmd

//
//
//
Command_D_accv:
	bl	PrintAccuracyVars
	b	ParseCmd
//
//
//
Command_D_fill:

	cmp	x0, #0			// Check for argument
	b.eq	10f			// No argument
	ldrb	w1, [x0]
	cmp	w1, #0x30			// Check first character of command
	b.lt	10f			// less than '0'? then skip
	cmp	w1, #0x39			// greater than '9'? then skip
	b.gt	10f
	bl	IntWordInput		// x0 in binary 32 bit data
	cmp	x1, #0			// Check for input error
	b.ne	10f			// yes error
	cmp	x0, TOPHAND
	b.gt	10f
	mov	x1, x0
	bl	DebugFillVariable
	b	ParseCmd
10:
	ldr	x0,=20f
	bl	StrOut
	b	ParseCmd

20:
	.asciz	"D.fill: Error, invalid argument\n\n"
	.align 4

//
//
//
Command_exit:
	b.al	ProgramExit


Command_help:
	bl	Help
	b	ParseCmd

//
//
//
Command_hex:
	cmp	x0, #0			// Check for argument
	b.eq	10f			// No argument
	ldrb	w1, [x0]
	cmp	w1, #0x30		// Check first character of command
	b.lt	20f			// less than '0'? then skip
	cmp	w1, #0x39		// greater than '9'? then skip
	b.gt	20f
	bl	IntWordInput		// x0 in binary 64 bit data
	cmp	x1, #0			// Check for input error
	b.ne	20f			// yes error
	cmp	x0, TOPHAND
	b.gt	20f
	mov	x1, x0			// Argument x1 register index
	bl	PrintVar		// Display register in hex
	b	ParseCmd
10:
	bl	PrintHex
	b	ParseCmd
20:
	ldr	x0, =30f
	bl	StrOut
	b	ParseCmd
30:
	.asciz	"Hex: Error, invalid argument\n\n"
	.align 4

//
//
//
Command_prac:
	bl	practice
	bl	CROut
	b	ParseCmd

Command_print:
	mov	x1, HAND_XREG
	mov	x2, HAND_ACC
	bl	CopyVariable

	bl	CROut
	bl	PrintVariable
	b	ParseCmd

Command_sigfigs:
	cmp	x0, #0			// Check for argument
	b.ne	10f
	bl	CROut
	bl	PrintAccuracy
	bl	CROut
	b	ParseCmd

10:
	ldrb	w1, [x0]		// character argument
	cmp	w1, #'v'		// 'v' --> view verbose
	b.ne	20f
	bl	PrintAccVerbose
	b	ParseCmd

20:
	ldrb	w1,[x0]			// character argument
	cmp	w1, #'e'		// 'e' --> enter extended digits
	b.ne	30f
	ldrb	w1, [x0, #1]		// next character space
	cmp	w1, #0x020		// ascii space
	b.ne	30f
	ldrb	w1, [x0, #2]		// first digit of numberic input
	cmp	w1, #0x30		// Check first character of command
	b.lt	30f			// less than '0'? then skip
	cmp	w1, #0x39		// greater than '9'? then skip
	b.gt	30f
	add	x0, x0, #2		// move pointer 2 digits
	bl	IntWordInput		// convert ascii to binary
	bl	SetExtendedDigits	// set extended digits
	bl	CROut
	b	ParseCmd
30:
	ldrb	w1, [x0]
	cmp	w1, #0x30		// Check first character of command
	b.lt	55f			// less than '0'? then skip
	cmp	w1, #0x39		// greater than '9'? then skip
	b.gt	55f
	bl	IntWordInput		// x0 in binary 64 bit data
	bl	SetDigitAccuracy
	b	ParseCmd

55:	ldr	x0, =60f
	bl	StrOut
	b	ParseCmd
60:
	.asciz	"\nCommand Parser: sigfigs command invalid argument\n\n"
	.align 4

//
//
//
Command_test:
	stp	x0, x1, [sp, -16]!	// preserve pointer
	ldr	x0, =TestMessageString
	bl	StrOut
	ldp	x0, x1, [sp], 16	// restore pointer
	//-------------------------------------
	//  I N S E R T   T E S T   H  E R E
	//-------------------------------------
	//

	// ---- Disabled ------------
	// ldr	x0, =NoTestString
	// bl	StrOut
	// b	ParseCmd
	// --------------------------

	mov	x1, HAND_XREG
	bl	SetToTwo
//	bl	DivideByTen
//	bl	MultiplyByTen

	b	ParseCmd

	// ----------------------

	mov	x1, #3
	mov	x2, #4
	mov	x3, #5

//	bl	ClearVariable
//	bl	SetToOne
// 	bl	SetToTwo
//	bl	Right1Bit
//	bl	Left1Bit
//	bl	CopyVariable
//	bl	ExchangeVariable
//	bl	TwosCompliment
//	bl	AddVariable

	b	ParseCmd

	// --------------------------

	// Argument string located in x0
	bl	IntWordInput		// x0=value no error then x1=0

	cmp	x1, #0
	b.ne	22f			// Error, skip processing
	bl	PrintWordHex		// This is processing...
	bl	CROut
	bl	PrintWordB10
22:

	// -------- End Test ------------------

	bl	CROut
	bl	CROut
	b	ParseCmd

TestMessageString:
	.asciz	"\nTest Command execution:\n\n"
NoTestString:
	.asciz	"No test is select in parser.s\n\n"
	.align 4

Command_version:
	ldr	x0,=versionString
	bl	StrOut
	b	ParseCmd

versionString:
	.asciz	"\n     Version 1.0 - Debugging in progress\n\n"
	.align 4

CodeEnd:
	.end
