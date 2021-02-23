/* -------------------------------------------------------------
	help.s

 This module contains user help

	Created:   2021-02-19
	Last Edit: 2021-02-21

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
	Help
	Help_Welcome
------------------------------------------------------------- */

	.include "arch-include.s"	// .arch and .cpu directives
	.include "header-include.s"

	.global Help
	.global	Help_Welcome

// ------------------------------------------------------------
	.data
// ------------------------------------------------------------


/*---------------------------------------------------------------------

  Help Table

  8 character command for up to 7 character command zero terminated

  64 bit address pointer

--------------------------------------------------------------------*/

	.align 4
Help_Table:
	.ascii	"."
	.byte	0,0,0,0,0,0,0
	.quad	Help_print

	.ascii	"clrstk"
	.byte	0,0
	.quad	Help_clrstk

	.ascii	"clrx"
	.byte	0,0,0,0
	.quad	Help_clrx

	.ascii	"cmdlist"
	.byte	0
	.quad	Help_cmdlist

	.ascii	"D.accv"
	.byte	 0, 0
	.quad	Help_D_accv

	.ascii	"D.fill"
	.byte	 0, 0
	.quad	Help_D_fill

	.ascii	"exit"
	.byte	0, 0, 0, 0
	.quad	Help_exit

	.ascii	"hex"
	.byte	0, 0, 0, 0, 0
	.quad	Help_hex

	.ascii	"print"
	.byte	0,0,0
	.quad	Help_print

	.ascii	"q"
	.byte	0, 0, 0, 0, 0, 0, 0
	.quad	Help_q

	.ascii	"quit"
	.byte	0, 0, 0, 0
	.quad	Help_q

	.ascii	"sf"
	.byte	0,0,0,0,0,0
	.quad	Help_sigfigs

	.ascii	"sigfigs"
	.byte	0
	.quad	Help_sigfigs

Help_Table_End:
	.byte	0, 0, 0, 0, 0, 0, 0, 0
	.quad	0			// End of list


Help_clrstk:
	.ascii	"Usage: clrstk\n\n"
	.ascii	"Description: Clear floating point stack to zero.\n"
	.ascii	"(XReg, YReg, Zreg, Treg)\n"
	.byte	0

Help_clrx:
	.ascii	"Usage: clrx\n\n"
	.ascii	"Description: Clear X, floating point XReg\n"
	.byte 	0

Help_cmdlist:
	.ascii	"Usage: cmdlist <optional first letter>\n\n"
	.ascii	"Description: Prints a list of availble commands. \n"
	.ascii	"To shorten the list provide the  first letter as a\n"
	.ascii	"command argument.\n"
	.byte	0

Help_D_accv:
	.ascii	"Usage: D.accv\n\n"
	.ascii	"Description: Show accuracy variables in hex and decimal\n"
	.byte	0

Help_D_fill:
	.ascii	"Usage: D.fill <handle>\n\n"
	.ascii	"Description: This is a debug command to fill a variable with\n"
	.ascii	"sequential byte value numbers. It starts with the exponent \n"
	.ascii	"0102030405060708 (exponent)\n"
	.ascii	"1011121314151617 (most significant word)\n"
	.ascii	"18191A1B1C1D1E1F (next word in mantissa)\n"
	.ascii	"This is very useful to check low level functions, such as \n"
	.ascii	"shifting memory left or right 1 bit.\n"
	.byte	0

Help_exit:
	.ascii	"Usage: exit\n\n"
	.ascii	"Description: Quit the program.\n"
	.byte	0

Help_hex:
	.ascii	"Usage: hex <optoinal variable handle number>\n\n"
	.ascii	"Description: Hex command is used to display variables in \n"
	.ascii	"binary (hexidecimal) format. If the hex command is called\n"
	.ascii	"without an argument, all the registers are printed showing\n"
	.ascii	"showing the first 3 words, the last word, and exponent in\n"
	.ascii	"64-bit words in hexidecimal. If a variable hands is \n"
	.ascii	"is provided, the entire variable is printed.\n"
	.byte	0

Help_print:
	.ascii	"Usage: .   (print X-Reg, equivalent command is 'print')\n\n"
//	.ascii	"Usage: . f (formated - 10 and 1000 digit block output.\n"
//	.ascii	"Usage: . q (quiet - terminal output suppressed, 10 1000 format\n"
//	.ascii	"Usage: . u (unformatted - no line feed or page formatting\n"
	.ascii	"Description: The . (period character) or 'print' will convert\n"
	.ascii	"the contents of X-reg from binary to decimail. The output\n"
	.ascii	"will be printed to stdout.\n"
	.byte	0

Help_q:
	.ascii	"Usage: quit\n\n"
	.ascii	"Description: Quit the program.\n"
	.byte	0

Help_sigfigs:
	.ascii	"Usage: sf             (prints current accuracy)\n\n"
	.ascii	"Usage: sf   <integer> (set new accuracy digits base 10)\n"
//	.ascii	"Usage: sf w <integer> (set new accuracy 64 bit words)\n"
	.ascii	"Usage: sf e <integer> (set new extended digits, 0 for none)\n"
	.ascii	"Usage: sf v           (display accuracy verbose)\n"
//	.ascii	"Usage: sf K           (sets accuracy to 1K 1, 000 digits base 10)\n"
//	.ascii	"Usage: sf M           (sets accuracy to 1M 1, 000, 000 digits base 10)\n"
//	.ascii	"Usage: sf x           (sets accuracy to maximum)\n"
	.ascii	"\nThe sf (and sigfigs) commands aure used to set or display the current\n"
	.ascii	"precision level (significant digits) for floating point variables.\n"
	.ascii	"64 bit word size can be converted to base 10 number size by:\n"
	.ascii	"19.2659197224948 digit/QWord(64 bit) = log_base10(2^64)\n"
	.ascii	"Guard words provide additional precision to absorb rounding errors.\n"
	.ascii	"Set extended digits show result past specified accuracy.\n"
	.ascii	"Variable size INT_WSIZE, FCT_WSIZE and GUARDWORDS specified \n"
	.ascii	"in var_header.inc.\n"
	.byte	0

//=====================================
// Default help message
//=====================================
//
DefaultHelp:
	.ascii	"Usage: help <command name>\n\n"
	.ascii	"Description: help will provide description and\n"
	.ascii	"instructions for the use of a specific command.\n"
	.ascii	"To see a list of all commands, type 'cmdlist'. \n\n"
//	.ascii	"Help in html format is in the docs/ folder or on the web at \n"
//	.ascii      "https://cotarr.github.io/calc-pi-x86-64-asm/docs/\n\n"
	.ascii	"Help is available for the following commands:\n\n"
	.byte	0

HelpNotFound:
	.ascii	"No help was found for that command.\n\n"
	.ascii	"To see a list of all commands, type 'cmdlist'.\n"
	.ascii	"To see help for a specific command type: 'help <command>'.\n"
	.ascii	"Help is available for the following commands:\n\n"
	.byte	0

//
// Welcome message shown at program start
//
WelcomeMsg:
	.ascii	"SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR\n\n"
	.ascii	"MIT License\n\n"
	.ascii	"Copyright 2021 David Bolenbaugh\n\n",
	.ascii	"Permission is hereby granted, free of charge, to any person obtaining a copy\n"
	.ascii	"of this software and associated documentation files (the \"Software\"), to deal\n"
	.ascii	"in the Software without restriction, including without limitation the rights\n"
	.ascii	"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
	.ascii	"copies of the Software, and to permit persons to whom the Software is\n"
	.ascii	"furnished to do so, subject to the following conditions:\n\n"
	.ascii	"The above copyright notice and this permission notice shall be included in all\n"
	.ascii	"copies or substantial portions of the Software.\n\n"
	.ascii	"THE SOFTWARE IS PROVIDED \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
	.ascii	"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \n"
	.ascii	"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
	.ascii	"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
	.ascii	"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \n"
	.ascii	"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"
	.ascii	"SOFTWARE.\n\n"
	.ascii	"Source code: https://github.com/cotarr/calc-pi-arm64-asm\n\n"

	.ascii	"\nW O R K  I N   P R O G R E S S (no calculation yet)\n"
	.ascii	"\nCalculation of Pi on Raspberry Pi\n"
	.ascii	"Written in GNU Assembler (as)\n"
	.ascii	"Assembled arch=armv8-a cpu=cortex-a72\n\n"
	.byte	0
	.align 4

// ------------------------------------------------------------
	.text
	.align 4
// ------------------------------------------------------------


/* -----------------------------------------------------------------------------

    Help Interface

    Input: x0 address to input command buffer

     Output: none

----------------------------------------------------------------------------- */
Help:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// Command line argument pointer
	str	x9,  [sp, #24]		// Scratch
	str	x10, [sp, #32]		// Index
	str	x11, [sp, #40]		// Argument address pointer
	str	x12, [sp, #48]		// Table address pointer

	bl	CROut
	mov	x11, x0			// Save pointer to command line argument
//
// Check alignment of command table (could be entry/code error)
//
	ldr	x0, =Help_Table_End	// Check for byte alignment
	ands	x0, x0, #0x0f		// Should be zero
	b.eq	10f
	ldr	x0, =Command_Error2	// Error \message pointer
	mov	x1, #2732		// 12 bit error code
	b	FatalError
10:
//
// Check for help argument, if no argument then show default help
	cmp	w11, #0			// Is argument pointer = 0?
	b.ne	20f			// No, parse argument
	ldr	x0, =DefaultHelp	// Else, yes zero, no argument, default help
	bl	StrOut
	bl	PrintHelpList
	b.al	help_exit
20:
	ldr	x12, =Help_Table	// Initialize address pointer to Table Address
//
// Loop here for next help command check
//
Help_next_cmd:
	ldr	x0, [x12]		// Check for past last command in table
	cmp	x0, #0
	b.ne	30f			// Zero marker found, end of command table
	ldr	x0, =HelpNotFound
	bl	StrOut
	bl	PrintHelpList
	b.al	help_exit

30:
	mov	x10, #0			// Reset pointer to start of record
//
// Loop here for next character check
//
Help_next_char:
	ldrb	w0, [x11, x10]
	ldrb	w9, [x12, x10]
	cmp	w0, w9
	b.ne	Help_Tab_Next
	cmp	x10, #8			// Only 7 char + zero allowed
	b.ne	40f			// 8 Found is fatal error in table
	ldr	x0, =Command_Error1	// Error message pointer
	mov	x1, #2455		// 12 bit error code
	b	FatalError
40:
	add	X10, X10, #1
	ldrb	w9, [x12, x10]
	cmp	w9, #0			// No more characters?
	b.ne	Help_next_char		// Not zero, more to check
	ldrb	w0, [x11, x10]
	cmp	w0, #0x20		// ascii space
	b.eq	Help_Tab_Match
	cmp	w0, #0x00		// ascii space
	b.eq	Help_Tab_Match
	b.al	Help_Tab_Next			// Not match zero or space on next char
Help_Tab_Match:
	mov	x10, #8
	ldr	x0, [x12, x10]
	bl	StrOut
	b.al	help_exit
Help_Tab_Next:
	add	x12, x12, #16		// Point to next command
	b.al	Help_next_cmd
help_exit:
	bl	CROut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x9,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	ldr	x12, [sp, #48]
	add	sp, sp, #64
	ret

Command_Error1:
	.ascii	"HelpCmd: zero end marker not found in text table"
	.byte	0
Command_Error2:
	.ascii	"HelpCmd: End of help table not QWord aligned, probably table error"
	.byte 	0
	.align 4
/* ----------------------------------------------

 Print Command List

 Input:

--------------------------------------------- */

PrintHelpList:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x9,  [sp, #24]
	str	x10, [sp, #32]
	str	x11, [sp, #40]

	mov	x9, #0			// Index to character
	mov	x11, #0			// Line feed counter
	ldr	x10, =Help_Table	// Address of command table
loop1:
	ldrb	w0, [x10, x9]		// Get character to see if done
	cmp	w0, #0			// Is it zero, then done
	b.eq	done
	mov	x0, X10			// address of command string in table
	bl	StrOut			// Print command
	mov	x0, #0x020		// ascii space
	bl	CharOut
//	add	x11, x11, #1			// Increment line feed counter
//	cmp	x11, #3			// Check limit
//	bl	PrintFlags
//	b.	.skip2
//	mov	r15, 0			// Reset counter
//	call	CROut			// Return + line feed
skip2:
	add	x10, x10, #16		// increment to next work
	mov	x9, #0
	b.al	loop1
done:
	bl	CROut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x9,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	add	sp, sp, #80
	ret

// TODO print all help

Help_Welcome:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]

	ldr	x0, =WelcomeMsg
	bl	StrOut

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

	.end
