/* ----------------------------------------------------------------
	calc-e.s

	Calculation of e

	Created:   2021-03-04
	Last edit: 2021-03-04

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

	.global	Function_calc_e

//====================================
//
//   Calculate e
//
// Infinite sum of  1 + (1/1) + (1/2) + (1/6) + (1/24) + ... + (1/n!)
//
// Where n factorial is n! = 1 * 2 * 3 * 4 * 5 * ... * (n)
//
//===============================
//
//  ACC = Current n-factorial term
//  OPR = Running Sum
//  x8 = Runnning value of n
//
//  Result: XReg = SUM
//          YReg = Final value of n (from 1/n)
//
//  Loop exit criteria, number of left zero bits >= (variableBits - 1Bit)
//

Function_calc_e:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// scratch
	str	x1,  [sp, #24]		// Internal variable handle argument
	str	x2,  [sp, #32]		// Internal variable handle argument
	str	x3,  [sp, #40]		// Internal variable handle argument
	str	x8,  [sp, #48]		// Holds incremental value of n during summation
	str	x10, [sp, #56]		// Constant value, bits to stop summation
	str	x11, [sp, #64]		// Internal address pointer
	str	x17, [sp, #72]		// Division overflow mask to check errors

	//
	// Print description
	//
	ldr	x0, =calc_e_description
	bl	StrOut

	//
	// Clear variables to make room for result
	//
	mov	x1, HAND_YREG
	mov	x2, HAND_TREG
	bl	CopyVariable

	mov	x1, HAND_XREG
	mov	x2, HAND_ZREG
	bl	CopyVariable

	//
	// Initialize summation variables
	//
	mov	x1, HAND_ACC
	bl	SetToOne		// ACC Holds 1/n! term

	mov	x1, HAND_OPR
	bl	SetToOne		// OPR Holds sum

	mov	x8, #0			// x8 holds n

	ldr	x17, =calc_e_overflow_mask
	ldr	x17, [x17]		// Constant value for error checking

	bl	set_x10_to_Word_Size_Static	// number words in variable
	lsl	x10, x10, X64SHIFT4BIT	// bits in number
	sub	x10, x10, #1		// end loop criteria (trial and error)

//	mov	x0, x10			// debug, print zero bit limit (used to end loop)
//	bl	PrintWordB10
//	bl	CROut
//	bl	CROut

calc_e_loop:
	// -----------------------
	// Increment n = n + 1
	// -----------------------
	add	x8, x8, #1		// Increment n

	tst	x8, x17			// test for division overflow
	b.eq	10f
	// Fatal error
	ldr	x0, =calc_e_overflow_message // Error message pointer
	mov	x1, #741		// 12 bit error code
	b	FatalError
10:
	// ---------------------------
	// Divide  ACC = ACC / n
	// ---------------------------

	mov	x0, x8			// get divisor n from x8
	mov	x1, HAND_ACC		// Dividend (source)
	mov	x2, HAND_ACC		// Quotient
	bl	Reg32BitDivision	// Division by 32 bit register value

	mov	x1, HAND_ACC
	mov	x2, HAND_OPR
	mov	x3, HAND_OPR
	bl	AddVariable

	mov	x1, HAND_ACC
	bl	CountLeftZerobits

//	bl	PrintWordB10
//	bl	CROut

//	cmp	x8, #4			// DEBUG - exit loop at this many divisions
//	b.HS	20f			// DEBUG

	cmp	x10, x0			// Done? (variable_bits) - (zero_bits)
	b.hs	calc_e_loop
20:
	//
	// XReg holds calculation result
	//
	mov	x1, HAND_OPR
	mov	x2, HAND_XREG
	bl	CopyVariable
	//
	// YReg holds last n
	//
	mov	x1, HAND_YREG
	bl	ClearVariable
	bl	set_x11_to_Int_LS_Word_Address
	str	x8, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x8,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x17, [sp, #72]
	add	sp, sp, #96
	ret

calc_e_overflow_message:
	.asciz	"Error: Summation error, n overflow"
calc_e_description:
	.asciz	"\nFunction_calc_e: Calculating e using sum 1/n!\n"
	.align 4
calc_e_overflow_mask:
	.quad	0xffffffff00000000
//      Ruler --> 1234567812345678
	.align 4
