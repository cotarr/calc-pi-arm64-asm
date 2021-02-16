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
	.global ClearRegisters
	.global PrintRegisters


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

//
// get status of flags before they are changed
//
	mov	x9, xzr			// x9 = 0
	b.ne	10f			// zero flag 1 = zero
	and	x9, x9, #1
10:	b.lo	20f			// carry flag
	and	x9, x9, #2
20:	b.pl	30f			// sign flag 1 = negative
	and	x9, x9, #4
30:	b.vc	40f			// overflow flag
	and	x9, x9, #8
//
// Display status flags
//

40:	bl	CROut
	mov	x0, #0x20		// ascii space
	bl	CharOut
	ldr	x0, =.LTR_FlagNames
	bl	StrOut
	mov	x0, #0x30
	tst	x9, #1			// Zero
	b.eq	50f
	mov	x0, #0x31
50: 	bl	CharOut

	ldr	x0, =.LTR_FlagNames
	add	x0, x0, #FlagNameLen
	bl	StrOut
	mov	x0, #0x30
	tst	x9, #2			// Carry
	b.eq	60f
	mov	x0, #0x31
60: 	bl	CharOut

	ldr	x0, =.LTR_FlagNames
	add	x0, x0, #FlagNameLen
	add	x0, x0, #FlagNameLen
	bl	StrOut
	mov	x0, #0x30
	tst	x9, #4			// Minus
	b.eq	70f
	mov	x0, #0x31
70: 	bl	CharOut

	ldr	x0, =.LTR_FlagNames
	add	x0, x0, #FlagNameLen
	add	x0, x0, #FlagNameLen
	add	x0, x0, #FlagNameLen
	bl	StrOut
	mov	x0, #0x30
	tst	x9, #8			// Overflow
	b.eq	80f
	mov	x0, #0x31
80: 	bl	CharOut
	bl	CROut

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

	.set	FlagNameLen, 5
.LTR_FlagNames:
	.asciz	" ZF="
	.asciz	" CF="
	.asciz	" SF="
	.asciz	" VF="

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

	.align 2

	.end
