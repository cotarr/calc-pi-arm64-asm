/*-------------------------------------------------------------
	io_module.s

	This module contains operating system input/output
	subroutines.

	Created:   02/14/2021
	Last Edit: 02/14/2021

	StrOut
	CharOut
	CROut
--------------------------------------------------------------
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
-------------------------------------------------------------*/
	.Include "arch.inc"	// .arch and .cpu directives
	.include "header.inc"

/*------------------------------------------------------------*/

	.bss    // Section containing uninitialized data

OutChar: // Character output buffer
	.skip	4

/*------------------------------------------------------------*/

	.text
	.align	4

	.global	StrOut
	.global	CharOut
	.global	CROut

/******************************************************
  StrOut - Print null-terminated string

  Input: x0 contains 64 bit address of string

  Output: none

*******************************************************/
StrOut:
	stp	x29, x30, [sp, -16]!	// Preserve regs
	stp	x0, x4, [sp, -16]!

	tst	x0,x0			//check for zero
	beq	20f			//yes, done, exit

	mov	x4, x0			// Setup pointer
	ldrb	w0, [x4], #1		// R0 = first character
	tst	w0, w0			// null string?
	beq	20f			// Yes, exit on empty string
10:
	bl	CharOut			// Output character
	ldrb	w0, [x4], #1		// R0 = next character
	tst	w0, w0			// End of string?
	bne	10b			// Yes, exit on zero byte

20:
	ldp	x0, x4, [sp], 16
	ldp	x29, x30, [sp], 16	// Restore regs
	ret

/******************************************************
  CharOut - Output character in R0 to stdout

  Input: low byte of X0 contains ASCII character to print

  Output: none

*******************************************************/
CharOut:
	ldr	x1, =OutChar		// buffer address
	str	x0, [x1]		// store character for print
	mov	x0, stdout		// stream
	mov	x2, #1  		// count
	mov	x8, sys_write		// write
	svc	#0			// syscall
	ldr	x0, [x1]		// restore x0
	ret

/******************************************************
  CROut - Output Return and LineFeed to stdout

  Input:  none

  Output: none


*******************************************************/
CROut:
	stp	x29, x30, [sp, -16]!	// Preserve regs
	mov	x0, #0x0D		// ASCII Return Char
	bl	CharOut
	mov	x0, #0x0A		// ASCII Linefeed Char
	bl	CharOut
	ldp	x29, x30, [sp], 16	// Restore regs
	ret

/*------------------------------------------------------------*/
	.data

	.end
	/*******************
	  end iomodule.s
	*******************/
