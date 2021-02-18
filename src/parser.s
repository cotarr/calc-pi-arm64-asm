/* ----------------------------------------------------------------
	parser.s

	Command Parser Module

	Created:   2021-02-15
	Last edit: 2021-02-18

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
	.ascii	"cmdlist"
	.byte	0
	.quad	Command_cmdlist

	.ascii	"D.fill"
	.byte	0,0
	.quad	Command_D_fill

	.ascii	"exit"
	.byte	0,0,0,0
	.quad	Command_exit

	.ascii	"hex"
	.byte	0,0,0,0,0
	.quad	Command_hex

	.ascii	"prac"
	.byte	0,0,0,0
	.quad	Command_prac

	.ascii	"q"
	.byte	0,0,0,0,0,0,0
	.quad	Command_exit

	.ascii	"quit"
	.byte	0,0,0,0
	.quad	Command_exit

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
AlignErrorMsg:		.asciz	"\nError: Command table not aligned in 128 bit blocks\n\n"
Byte8ErrorMsg:		.asciz	"\nError: Command table not zero byte8\n\n"
OpCodeErrString:	.asciz	"     Input Error: Illegal Op Code.  (Type: cmdlist)\n\n"

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
	ldr	x0, =AlignErrorMsg	// Else Fatal error, exit program
	bl	StrOut
	b.al	ProgramExit
30:
//
// Show prompt string
//
	ldr	x0,=PromptString
	bl	StrOut
//
// Get input line from stdin
//
	bl	KeyIn			// Return pointer in x8
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
	ldr	x0, =Byte8ErrorMsg	// Else: fatal error, exit program
	bl	StrOut
	b.al	ProgramExit
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
Command_cmdlist:
	bl	CROut
	bl	PrintCommandList
	bl	CROut
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
	cmp	x0, #TOPHAND
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
	.align 2

//
//
//
Command_exit:
	ldr	x0, =exitMessage
	bl	StrOut
	b.al	ProgramExit
exitMessage:
	.asciz	"Graceful Exit\n"
	.align 3

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
	cmp	x0, #TOPHAND
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
	.align 3


//
//
//
Command_prac:
	bl	practice
	bl	CROut
	b	ParseCmd
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
	// ---------------------

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
	.align 3

Command_version:
	ldr	x0,=versionString
	bl	StrOut
	b	ParseCmd

versionString:
	.asciz	"\n     Version 1.0 - Debugging in progress\n\n"
	.align 3

CodeEnd:
	.end
