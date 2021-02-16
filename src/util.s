/* -------------------------------------------------------------
	util.s

	Created:   2021-02-14
	Last Edit: 2021-02-16
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



        .global	PrintByteHex
	.global	PrintWordHex


	.text

	.align 4

/* **************************************

   PrintByteHex

   Print 8 bit byte in hexidecimal

   Input:  x0 input byte (bottom 8 bit of 64 bit word)

   Output: none

   x0 is preserved
   x10 scratch register

************************************** */
PrintByteHex:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
//
// Print upper nibble
//
	ldr	x0, [sp, #16]		// pick preserved agrument from stack
	and	x0, x0, #0xf0		// AND --> 4 bit nibble
	lsr	x0, x0, #4		// high nibble --> low nibble
	cmp	x0, #0x09		// is number A-F ?
	b.gt	10f
	orr	x0, x0, #0x30		// form ASCII 0-9
	b.al	20f
10:
	sub	x0, x0, #0x09
	orr	x0, x0, #0x40		// form ASCII A-F
20:
	mov	x0, x0			// Character to print in x0
	bl	CharOut			// Print ascii character

//
// Print lower nibble
//
	ldr	x0, [sp, #16]		// pick preserved agrument from stack
	and	x0, x0, #0x0F		// AND --> 4 bit nibble
	cmp	x0, #0x09		// is number A-F ?
	b.gt	30f
	orr	x0, x0, #0x30		// Form ASCII 0-9
	b.al	40f
30:
	sub	x0, x0, #0x09
	orr	x0, x0, #0x40		// Form ASCII A-F
40:
	mov	x0, x0			// Character to print
	bl	CharOut

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

/* **************************************

   PrintWordHex

   Print 32 bit byte in hexidecimal

   Input:  x0 input word (32 bit)

   Output: none

************************************** */
 PrintWordHex:
	 sub	sp, sp, #32		// Reserve 4 words
	 str	x30, [sp, #0]
	 str	x29, [sp, #8]
	 str	x0,  [sp, #16]

	ldr	x0, [sp, #16]		// Pick 64 bit word from stack
	lsr	x0, x0, #56		// Shift to align byte
	and	x0, x0, #0xff		// Mask to 1 byte (8 bit)
	bl	PrintByteHex		// Print the byte

	ldr	x0, [sp, #16]
	lsr	x0, x0, #48
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	lsr	x0, x0, #40
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	lsr	x0, x0, #32
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	lsr	x0, x0, #24
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	lsr	x0, x0, #16
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	lsr	x0, x0, #8
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x0, [sp, #16]
	and	x0, x0, #0xff
	bl	PrintByteHex

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret
