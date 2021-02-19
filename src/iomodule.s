/* -------------------------------------------------------------
	io_module.s

	This module contains operating system input/output
	subroutines.

	Created:   2021-02-14
	Last Edit: 2021-02-18

	KeyIn
	StrOut
	CharOut
	CROut
	ClrScr
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

	.bss    // Section containing uninitialized data

OutChar: // Character output buffer (1 64 bit word)
	.skip	8

KeyBuf:	// Keyboard Input Buffer
	.set	KeyBufLen, 0x100
	.skip	KeyBufLen

/* ------------------------------------------------------------ */

	.text
	.align	4

	.global KeyIn
	.global	StrOut
	.global	CharOut
	.global	CROut
	.global	ClrScr

/******************************************************
  KeyIn - Read text line from console input

  Input: none

  Output: X8 = address of buffer

*******************************************************/
KeyIn:

	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	mov	x0, stdin		// stdin stream
	ldr	x1, =KeyBuf		// point to buffer
 	mov	x2, #(KeyBufLen-8)	// buffer size (count)
	mov	x8, sys_read		// Request code
	svc	#0			// kernel syscall

	tst	x0, x0			// count zero?
	b.eq	10f
	sub	x0, x0, #1		// point prior to LF (0x10)
10:
	mov	w2, #0			// null terminate string
	strb	w2, [x1,x0]		// Character EOL --> 0x00

	ldr	x8, =KeyBuf		// Return buffer address

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	add	sp, sp, #48
	ret

/* *****************************************************
  StrOut - Print null-terminated string

  Input: x0 contains 64 bit address of string

  Output: none

  x0 is preserved

****************************************************** */
StrOut:
	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x9, [sp, #24]

	tst	x0,x0			//check for zero in pointer
	b.eq	20f			//yes, done, exit

	mov	x9, x0			// Setup pointer
	ldrb	w0, [x9], #1		// w0 first character to print
	tst	w0, w0			// null string?
	b.eq	20f			// Yes, exit on empty string
10:
	bl	CharOut			// Output character
	ldrb	w0, [x9], #1		// w0 = next character
	tst	w0, w0			// End of string?
	b.ne	10b			// Yes, exit on zero byte

20:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x9, [sp, #24]
	add	sp, sp, #48
	ret

/* *****************************************************
  CharOut - Output character in R0 to stdout

  Input: low byte of X0 contains ASCII character to print

  Output: none

****************************************************** */
CharOut:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x8, [sp, #40]

	ldr	x1, =OutChar		// buffer address
	str	x0, [x1]		// store character for print
	mov	x0, stdout		// stream
	mov	x2, #1  		// count
	mov	x8, sys_write		// write
	svc	#0			// syscall

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	add	sp, sp, #64
	ret

/* *****************************************************
  CROut - Output Return and LineFeed to stdout

  Input:  none

  Output: none


****************************************************** */
CROut:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]

	mov	x0, #0x0A		// ASCII Linefeed Char
	bl	CharOut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

/* *****************************************************
  ClrScr - Output control characters to clear screen

  Input:  none

  Output: none

****************************************************** */
ClrScr:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]

	ldr	x0, =Clear_String
	bl	StrOut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

Clear_String:
	.byte	27
	.ascii 	"[2J"			// Clear Screen
	.byte	27
	.ascii	"[H"			// Home Cursor
	.byte	0			// End of string

/* ------------------------------------------------------------ */
	.data

	.end
