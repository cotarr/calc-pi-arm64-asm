/* -------------------------------------------------------------
	util.s

	Created:   2021-02-14
	Last Edit: 2021-02-18
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

        .global	PrintByteHex
	.global	PrintWordHex
	.global PrintFlags
	.global ClearRegisters
	.global PrintRegisters
	.global PrintWordB10
	.global	IntWordInput

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

/***************************************

   PrintFlags

   Print x0-x31 in hexidecimal

   Input:  x0-x31 for printing

   Output: none

***************************************/
PrintFlags:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x19,  [sp, #24]
//
// get status of flags before they are changed
//
	mov	x19, xzr		// x19 = 0
	b.ne	10f			// zero flag 1 = zero
	orr	x19, x19, #1
10:	b.lo	20f			// carry flag
	orr	x19, x19, #2
20:	b.pl	30f			// sign flag 1 = negative
	orr	x19, x19, #4
30:	b.vc	40f			// overflow flag
	orr	x19, x19, #8

//
// Display status flags
//
40:
	bl	CROut
	mov	x0, #0x20		// ascii space
	bl	CharOut
	tst	x19, #1
	b.eq	45f
	mov	x0, #'E'		// z = 1
	bl	CharOut
	mov	x0, #'Q'
 	bl	CharOut
	b.al	50f
45:	mov	x0, #'N'		// z = 0
	bl	CharOut
	mov	x0, #'E'
 	bl	CharOut
50:	mov	x0, #0x20
	bl	CharOut
	tst	x19, #2
	b.eq	55f
	mov	x0, #'H'		// c = 1
	bl	CharOut
	mov	x0, #'S'
	bl	CharOut
	mov	x0, #'/'
	bl	CharOut
	mov	x0, #'C'
	bl	CharOut
	mov	x0, #'S'
	bl	CharOut
	b.al	60f
55:	mov	x0, #'L'		// c = 0
	bl	CharOut
	mov	x0, #'O'
	bl	CharOut
	mov	x0, #'/'
	bl	CharOut
	mov	x0, #'C'
	bl	CharOut
	mov	x0, #'C'
	bl	CharOut
60:	mov	x0, #0x20
	bl	CharOut
	tst	x19, #4
	b.eq	65f
	mov	x0, #'M'		// n = 1
	bl	CharOut
	mov	x0, #'I'
	bl	CharOut
	b.al	70f
65:	mov	x0, #'P'		// n = 0
	bl	CharOut
	mov	x0, #'L'
	bl	CharOut
70:	mov	x0, #0x20
	bl	CharOut
	tst	x19, #4
	b.eq	75f
	mov	x0, #'V'		// v = 1
	bl	CharOut
	mov	x0, #'S'
	bl	CharOut
	b.al	80f
75:	mov	x0, #'V'		// v = 0
	bl	CharOut
	mov	x0, #'C'
	bl	CharOut
80:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x19,  [sp, #24]
	add	sp, sp, #32
	ret

/***************************************

   ClearRegisters

   Input:  none

   Output: (all registers as listed below)

***************************************/
ClearRegisters:
	mov	x0, xzr
	mov	x1, xzr
	mov	x2, xzr
	mov	x3, xzr
	mov	x4, xzr
	mov	x5, xzr
	mov	x6, xzr
	mov	x7, xzr
	mov	x8, xzr
	mov	x9, xzr
	mov	x10, xzr
	mov	x11, xzr
	mov	x12, xzr
	mov	x13, xzr
	mov	x14, xzr
	mov	x15, xzr
	mov	x16, xzr
	mov	x17, xzr
	//mov	x18, xzr // platform register
	mov	x19, xzr
	mov	x20, xzr
	mov	x21, xzr
	mov	x22, xzr
	mov	x23, xzr
	mov	x24, xzr
	mov	x25, xzr
	mov	x26, xzr
	mov	x27, xzr
	mov	x28, xzr
	// mov	x29, xzr // frame pointer
	// mov	x30, xzr // link address
	// mov	x31, xzr // Stack pointer
	ret

/***************************************

   PrintRegisters

   Print R0-R15 in hexidecimal

   Input:  R0-R15 for printing

   Output: none

***************************************/
PrintRegisters:
	sub	sp, sp, #256		// Reserve 32 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x3, [sp, #40]
	str	x4, [sp, #48]
	str	x5, [sp, #56]
	str	x6, [sp, #64]
	str	x7, [sp, #72]
	str	x8, [sp, #80]
	str	x9, [sp, #88]
	str	x10, [sp, #96]
	str	x11, [sp, #104]
	str	x12, [sp, #112]
	str	x13, [sp, #120]
	str	x14, [sp, #128]
	str	x15, [sp, #136]
	str	x16, [sp, #144]
	str	x17, [sp, #152]
	str	x18, [sp, #160]
	str	x19, [sp, #168]
	str	x20, [sp, #176]
	str	x21, [sp, #184]
	str	x22, [sp, #192]
	str	x23, [sp, #200]
	str	x24, [sp, #208]
	str	x25, [sp, #216]
	str	x26, [sp, #224]
	str	x27, [sp, #232]
	str	x28, [sp, #240]
	mov	x9, sp		// special case stack pointer
	sub	x9, x9, #256	// value before preserve stack
	str	x9, [sp, #248]


// ---------------------
// print 32 ARM64 registers
// ---------------------

	ldr	x9, =.LTR_RegNames

	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #16]		// x0
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #24]		// x1
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #32]		// x2
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #40]		// x3
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #48]		// x4
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #56]		// x5
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #64]		// x6
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #72]		// x7
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #80]		// x8
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #88]		// x9
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #96]		// x10
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #104]		// x11
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #112]		// x12
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #120]		// x13
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #128]		// x14
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #136]		// x15
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #144]		// x16
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #152]		// x17
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #160]		// x18
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #168]		// x19
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #176]		// x20
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #184]		// x21
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #192]		// x22
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #200]		// x23
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #208]		// x24
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #216]		// x25
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #224]		// x26
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #232]		// x27
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #240]		// x28
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #8]		// x29
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #0]		// x30
	bl	PrintWordHex
	bl	CROut

	add	x9, x9, #RegNameLen
	mov	x0, x9
	bl	StrOut
	ldr	x0, [sp, #248]		// x31 Stack pointer sp
	bl	PrintWordHex
	bl	CROut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]		// restore registers
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x3, [sp, #40]
	str	x4, [sp, #48]
	str	x5, [sp, #56]
	str	x6, [sp, #64]
	str	x7, [sp, #72]
	str	x8, [sp, #80]
	str	x9, [sp, #88]
	str	x10, [sp, #96]
	str	x11, [sp, #104]
	str	x12, [sp, #112]
	str	x13, [sp, #120]
	str	x14, [sp, #128]
	str	x15, [sp, #136]
	str	x16, [sp, #144]
	str	x17, [sp, #152]
	str	x18, [sp, #160]
	str	x19, [sp, #168]
	str	x20, [sp, #176]
	str	x21, [sp, #184]
	str	x22, [sp, #192]
	str	x23, [sp, #200]
	str	x24, [sp, #208]
	str	x25, [sp, #216]
	str	x26, [sp, #224]
	str	x27, [sp, #232]
	str	x28, [sp, #240]
	add	sp, sp, #256
	ret

	.set	RegNameLen, 9
.LTR_RegNames:
	.asciz	"  x0  = "
	.asciz	"  x1  = "
	.asciz	"  x2  = "
	.asciz	"  x3  = "
	.asciz	"  x4  = "
	.asciz	"  x5  = "
	.asciz	"  x6  = "
	.asciz	"  x7  = "
	.asciz	"  x8  = "
	.asciz	"  x9  = "
	.asciz	"  x10 = "
	.asciz	"  x11 = "
	.asciz	"  x12 = "
	.asciz	"  x13 = "
	.asciz	"  x14 = "
	.asciz	"  x15 = "
	.asciz	"  x16 = "
	.asciz	"  x17 = "
	.asciz	"  x18 = "
	.asciz	"  x19 = "
	.asciz	"  x20 = "
	.asciz	"  x21 = "
	.asciz	"  x22 = "
	.asciz	"  x23 = "
	.asciz	"  x24 = "
	.asciz	"  x25 = "
	.asciz	"  x26 = "
	.asciz	"  x27 = "
	.asciz	"  x28 = "
	.asciz	"  x29 = "
	.asciz	"  x30 = "
	.asciz	"  sp  = "

	.align 4

/***************************************

   PrintWordB10

   Input:  x0 = Number to print

   Output: none

***************************************/
PrintWordB10:
	sub	sp, sp, #80		// Reserve 20 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x9, [sp, #24]
	str	x10, [sp, #32]
	str	x11, [sp, #40]
	str	x12, [sp, #48]
	str	x13, [sp, #56]
//
// Setup counters and variables
//
	mov	x9, #10			// x9 Used as constant x9 = #10
	mov	x10, #0			// x10 Initialize digit counter
	mov	x11, x0			// x11 Running remainder
	mov	x12, #1			// x12 initialize multiples of 10
					// x13 is scratch register
//
// Generate powers of 10 until bigger than number to print
//
10:
	udiv	x13, x11, x12		// x13 = x12/x11  (number / 10^?)
	cmp	x13, x9			// Is result of div < 10 (x9=10)
	b.lo	20f			// Yes, cf = 0, less than 10, done counting
	mov	x13, x12, lsl #1	// Mult x 2
	mov	x12, x12, lsl #3	// Mult x 8
	add	x12, x12, x13		// x2 + x8 --> x10
	add	x10, x10, #1		// increment digit counter
        b.al    10b
//
//  Recursively divide by power of 10 to get digits
//
20:
	udiv	x13, x11, x12		// Quotient x13 = x11/x12 (remainder/ power-10)
	msub	x11, x13, x12, x11	// Rem x11 = (last rem) - (power-10 * quot)
	and	x0, x13, #0x0F
	orr 	x0, x0, #0x30		// Form ascii
	bl	CharOut			// Output character
	udiv	x12, x12, x9		// Next power of 10 x12=x12/x9 (x9=#10)
	subs	x10, x10, #1		// Decrement digit counter
	b.hs 	20b

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x9, [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	ldr	x12, [sp, #48]
	ldr	x13, [sp, #56]
	add	sp, sp, #80
	ret

/*;--------------------------------------------------------------
; Integer input routine
;
; This routine will put an integer value from terminal input
; and convert ASCII to binary, returning 64 bit RAX
;
;    Input:    x0 address of input buffer
;
;    Output:   x0 contains 64 bit positive integer
;              x1 0 = no error else > 0 is error
;
;--------------------------------------------------------------*/
IntWordInput:
	sub	sp, sp, #80		// Reserve 20 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x9, [sp, #16]
	str	x10, [sp, #24]
	str	x11, [sp, #32]

	cbz	x0, IntWordInputError	// Error: Pointer is zero

	mov	x11, x0			// Address to input buffer
	mov	x10, #0			// Accumulate number here

	ldrb	w0, [x11]		// check for empty string
	cbz	w0, IntWordInputError	// Error: zero length string
10:
	ldrb	w0, [x11]		// Get next character from buffe4
	add	w11, w11, #1		// Point at next character
	cmp	w0, #0x3A		// Digit > ascii '9' + 1
        b.hs     20f			// Yes convert input
        cmp     w0, #0x30		// Digit < ascii '0'
        b.lo	20f			// Yes convert input
        and     x0, x0, #0x0F		// Mask to BCD bits
	mov	x9, x10, lsl #1		// x 2
	mov	x10, x10, lsl #3	// x 8
	add	x10, x10, x9		//  add X 2 value to X 8 value for X 10
	add	x10, x10, x0		// Add the digit
	b.al	10b			// Always taken
20:
	cmp	w0, #0			// expect null terminated string
	b.ne	IntWordInputError	// Error non numeric characters

	mov	x0, x10			// Exit X0 = value
	mov	x1, #0			// Exit X1 = error condition
	b.al	100f			// Go exit

IntWordInputError:
	ldr	x0, =Non_numeric_err	// Error message
	bl	StrOut
	mov	x0, #0			// Return 0 on error
	mov	x1, #1			// x1=1 --> error

100:	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x9,  [sp, #16]
	ldr	x10, [sp, #24]
	ldr	x11, [sp, #32]
	add	sp, sp, #80
	ret
Non_numeric_err:
	.asciz "\nInput Error:  Expect integer string.\n"

	.align 4

	.end
