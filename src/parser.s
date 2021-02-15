/* ----------------------------------------------------------------
	parser.s

	Command Parser Module

	Created:   2021-02-15
	Last edit: 2021-02-15

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

   	.Include "arch.inc"	// .arch and .cpu directives
   	.include "header.inc"

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
	.word	Command_cmdlist,0

	.ascii	"exit"
	.byte	0,0,0,0
	.word	Command_exit,0

	.ascii	"q"
	.byte	0,0,0,0,0,0,0
	.word	Command_exit,0

	.ascii	"quit"
	.byte	0,0,0,0
	.word	Command_exit,0

	.ascii	"test"
	.byte	0,0,0,0
	.word	Command_test,0

	.ascii	"version"
	.byte	0
	.word	Command_version,0

// End table marker
	.byte	0,0,0,0,0,0,0,0
	.word	0,0
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
	sub	sp, sp, #64		// Space for 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x0, [sp, #8]
	str	x1, [sp, #16]
	str	x8, [sp, #24]

	ldr	x8, =Command_Table

	mov	x0, x8			// Address first command
10:
	bl	StrOut			// print command
	mov	x0, #32			// ASCII space
	bl	CharOut
	add	x8, x8, #16		// point next entry
	mov	x0, x8
	ldr	x1, [x0]
	tst	x1, x1			// is zero, last?
	b.ne	10b

	bl	CROut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x0, [sp, #8]
	ldr	x1, [sp, #16]
	ldr	x8, [sp, #24]
	add	sp, sp, #64
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
	ldr	x1, =StackPtrSnapshot
	ldr	x0, [x1]
	tst	x0, x0
	b.ne	10f
	mov	x0, sp
	str	x0, [x1]
10:
	mov	x1, sp
	cmp	x0, x1
	b.eq	20f
	ldr	x0, =StackPtrErrorMsg
	bl	StrOut
20:
//
// Check command table alignment
//
	ldr	x0, =Command_TableEnd
	tst	x0, #0x07
	b.eq	30f
	ldr	x0, =AlignErrorMsg
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
	bl	KeyIn
	mov	x8,  x0			// Address of input string
	ldr	x9,  =Command_Table
//
// Loop here for check next command in table
//
40:
	ldr	w0, [x9, #8]		// Table + index + address_offset
	tst	w0, w0			// Zero? (past last command)
	b.eq	Com_Tab_Not_Found
	mov	x10, #0			// index to command
	ldrb	w0, [x8, x10]		// character from input
	ldrb	w1, [x9, x10]		// character from table
//
// Loop here for character check
//
50:
	cmp	w0, w1			// character match?
	b.ne	70f			// no, get next command
	add	x10, x10, #1
	cmp	x10, #8			// command table error?
	b.ne	60f
	ldr	x0, =Byte8ErrorMsg
	bl	StrOut
	b.al	ProgramExit
60:
	ldrb	w0, [x8, x10]		// character from input
	ldrb	w1, [x9, x10]		// Next character in table
	tst	w1, w1			// more characters?
	b.ne	50b			// Yes, check next for match
	tst	w0, w0			// Next input char 0 or space?
	b.eq	Com_Tab_MatchNoArg
	cmp	w0, #32			// ascii space?
	b.eq	Com_Tab_MatchWithArg
//
// Move pointer to next command in table
//
70:
	add	x9, x9, #16		// increment to next command
	b.al	40b
//
// Exit - Command not found in table
//
Com_Tab_Not_Found:
	ldr	x0, =OpCodeErrString
	bl	StrOut
	b	ParseCmd		// loop always taken
//
// Exit - Command matches, no argument
//
Com_Tab_MatchNoArg:
	add	x2, x9, #8		// c0 command from table
	ldr	x30, [x2]		// c2 command address
	ret				// using return as a jump
//
// Exit - Command matches, additional arguments on input line
//
Com_Tab_MatchWithArg:
	add	x10, x8, x10		// addr of space character
	add	x10, x10, #1
	ldrb	w0, [x10]
	tst	w0, w0			// x10 point next char
	b.eq	Com_Tab_MatchNoArg
	add	x2, x9, #8		// x2 command from table
	ldr	x30, [x2]		// x2 command address
	ret				// using return as a jump

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
Command_exit:
	ldr	x0, =10f
	bl	StrOut
	b.al	ProgramExit
10:	.asciz	"Graceful Exit\n"
	.align 4

//
//
//
Command_test:
	ldr	x0, =10f
	bl	StrOut

//	bl	Test_Div

	bl	CROut
	b	ParseCmd
10:	.asciz	"\nTest Command:\n\n"
	.align 4

Command_version:
	ldr	x0,=10f
	bl	StrOut
	b	ParseCmd
10:	.asciz	"\n     Version 1.0 - Debugging in progress\n\n"


CodeEnd:
	.end
