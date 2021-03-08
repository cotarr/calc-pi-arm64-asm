/* ----------------------------------------------------------------
	calc-e.s

	Calculation of pi by Chudnovsky Formula

	Created:   2021-03-08
	Last edit: 2021-03-08

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

	.global	Function_calc_pi_ch

// ---------------------------------------------------------------
//  Calculation of pi using Chudnovsky Formula
//
// Calculations requires square root of 10005 to full accuracy
// XReg must contain sqrt(10005) at start calculated externally
//
// Summation Term A:  [(6n)!(13591409)] / [(n!^3)(3n!)(-640320^3n)]
//
// Summation Term B:  [(6n)!(545140134)(n)] / [(n!^3)(3n!)(-640320^3n)]
//
// Final Divisions pi = (426880(sqrt(10005)) / summations
//
//  ACC = Sum
//  Reg0 = Square root of 10005 (for now from XREG)
//  Reg1 = Term-A [(6n)!(13591409)] / [(n!^3)(3n!)(-640320^3n)]
//  Reg2 = Term-B [(6n)!(545140134)(n)] / [(n!^3)(3n!)(-640320^3n)]
//
//  Stack Variables (64 bit)
// value_n           = n
// termA_3n          = 3n for running 3n! calculation
// termA_3n          = 3n for running 3n! calculation
// termB_6n          = 6n for running 6n! calculation
// termB_6n          = 6n for running 6n! calculation
// flag_term_A_done  = Flag, term A done ( 0 = Not done)
// flag_term_B_done  = Flag, term B done ( 0 = Not done)
//
// Defined constants
// pi_ch_value_426880   = 426880 Used for final multiply
// pi_ch_value_640320	= 640320 Used for (640320^3)
// pi_ch_value_640320E3 = 640320^3 = 262537412640768000
// pi_ch_init_sum       = 13591409
// pi_ch_init_term_A    = 13591409
// pi_ch_init_term_B    = 545140134
//
//  ACC contains result
// ------------------------------------------------------------

Function_calc_pi_ch:
	sub	sp, sp, #192		// Reserve 24 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// scratch
	str	x1,  [sp, #24]		// Internal variable handle argument
	str	x2,  [sp, #32]		// Internal variable handle argument
	str	x3,  [sp, #40]		// Internal variable handle argument
	str	x8,  [sp, #48]
	str	x10, [sp, #56]		// Constant value, bits to stop summation
	str	x11, [sp, #64]		// Internal address pointer
	// Stack Variables
	.set value_n, 120
	.set termA_3n, 128
	.set termB_3n, 136
	.set termA_6n, 144
	.set termB_6n, 152
	.set flag_term_A_done, 160
	.set flag_term_B_done, 168

	//
	// Print description
	//
	ldr	x0, =calc_pi_ch_description
	bl	StrOut

	// ----------------------------
	// Initialize Number Variables
	// ----------------------------

	//
	// At program start, square root of 10005 is expected in XREG
	// Move sqrt(10005) to REG0 for use at the end of calculation
	//
	mov	x1, HAND_XREG		// XREG must contain Sqrt(10005)
	mov	x2, HAND_REG0
	bl	CopyVariable		// REG0 = SQRT(10005)

	//
	// XREG: (Sum) Initialize to hold 13591409 for term #0
	//              The sum will start with this term
	//
	ldr	x0, =pi_ch_init_sum
	ldr	x0, [x0]
	mov	x1, HAND_XREG
	bl	Load64BitNumber
	//
	// Reg1 (Term A) Initialize to 13591409  n=0 in Term-A
	//
	ldr	x0, =pi_ch_init_term_A
	ldr	x0, [x0]
	mov	x1, HAND_REG1
	bl	Load64BitNumber

	//
	// Reg2 (Term B) Initialize to 545140134 n=0 in Term-B
	//
	ldr	x0, =pi_ch_init_term_B
	ldr	x0, [x0]
	mov	x1, HAND_REG2
	bl	Load64BitNumber

	//
	// Initialize stack variables
	//
	mov	x0, #0
	str	x0, [sp, value_n]
	str	x0, [sp, termA_3n]
	str	x0, [sp, termB_3n]
	str	x0, [sp, termA_6n]
	str	x0, [sp, termB_6n]
	str	x0, [sp, flag_term_A_done]
	str	x0, [sp, flag_term_B_done]

// * * * * * * * * * * * * * * * *
//
//    M A I N    L O O P
//
// * * * * * * * * * * * * * * * *
pi_ch_loop:
	//
	// Increment n
	//
	ldr	x0, [sp, value_n]
	add	x0, x0, #1		// n = n + 1
	str	x0, [sp, value_n]

	// ---------------------------
	// F I R S T   T E R M   A
	// ---------------------------

	// Skip if previous term zero
	ldr	x0, [sp, flag_term_A_done]
	cbnz	x0, pi_ch_termB

	//
	// Build (6n)! in numerator
	//
	mov	x1, HAND_REG1		// Factor2
	mov	x2, HAND_REG1		// Product
	mov	x10, #6			// Counter
100:
	ldr	x0, [sp, termA_6n]
	add	x0, x0, #1
	str	x0, [sp, termA_6n]	// x0 Factor1 input for multiplication

	// Check for out of range
	ldr	x11, =Word8000
	ldr	x11, [x11]		// x1 = 0x08000000000000000
	tst	x11, x0
	b.eq	105f
	// Fatal error
	ldr	x0, =calc_pi_ch_overflow_message
	mov	x1, #348		// 12 bit error code
	b	FatalError
105:
	bl	Reg64BitMultiplication	// REG1 = REG1 * x0
	sub	x10, x10, #1
	cbnz	x10, 100b

	//
	// Build (3n)! in denominator
	//
	mov	x1, HAND_REG1		// Dividnend
	mov	x2, HAND_REG1		// Quotient
	mov	x10, #3			// Counter
110:
	ldr	x0, [sp, termA_3n]
	add	x0, x0, #1		// Increment variable
	str	x0, [sp, termA_3n]	// x0 divisor input for division

	// Check for out of range
	ldr	x11, =calc_pi_ch_overflow_mask
	ldr	x11, [x11]		// x1 = 0x0ffffffff00000000
	tst	x11, x0
	b.eq	115f
	// Fatal error
	ldr	x0, =calc_pi_ch_overflow_message
	mov	x1, #347		// 12 bit error code
	b	FatalError
115:
	bl	Reg32BitDivision	// REG1 = REG1 / x0
	sub	x10, x10, #1
	cbnz	x10, 110b

	//
	// Using n, build (n!)^3 in denominator
	//
	mov	x1, HAND_REG1		// Dividnend
	mov	x2, HAND_REG1		// Quotient
	mov	x10, #3			// Counter
120:
	ldr	x0, [sp, value_n]
	bl	Reg32BitDivision	// Reg1 = Reg1 / x0
	sub	x10, x10, #1
	cbnz	x10, 120b

	//
	// Build (640320)^(3n) in denominator
	//
	// TODO: can upgrade to 64 bit single division without loop
	mov	x1, HAND_REG1		// Dividnend
	mov	x2, HAND_REG1		// Quotient
	mov	x10, #3			// Counter
120:
	ldr	x0, =pi_ch_value_640320
	ldr	x0, [x0]
	bl	Reg32BitDivision	// REG1 = REG1 / x0
	sub	x10, x10, #1
	cbnz	x10, 120b

	//
	// At this point term A is complete
	//

	// ---------------------------
	// S E C O N D  T E R M   B
	// ---------------------------
pi_ch_termB:
	// Skip if previous term zero
	ldr	x0, [sp, flag_term_B_done]
	cbnz	x0, pi_ch_sum

	//
	// Build (6n)! in numerator
	//
	mov	x1, HAND_REG2		// Factor2
	mov	x2, HAND_REG2		// Product
	mov	x10, #6			// Counter
200:
	ldr	x0, [sp, termB_6n]
	add	x0, x0, #1
	str	x0, [sp, termB_6n]	// x0 Factor1 input for multiplication
	bl	Reg64BitMultiplication	// REG2 = REG2 * x0
	sub	x10, x10, #1
	cbnz	x10, 200b

	//
	// Build (3n)! in denominator
	//
	mov	x1, HAND_REG2		// Dividnend
	mov	x2, HAND_REG2		// Quotient
	mov	x10, #3			// Counter
210:
	ldr	x0, [sp, termB_3n]
	add	x0, x0, #1
	str	x0, [sp, termB_3n]	// x0 divisor input for division
	bl	Reg32BitDivision	// result in REG2
	sub	x10, x10, #1
	cbnz	x10, 210b

	//
	// Divide by previous n-1 in numerator
	//
	mov	x1, HAND_REG2		// Dividnend
	mov	x2, HAND_REG2		// Quotient
	ldr	x0, [sp, value_n]
	sub	x0, x0, #1		// x0 = n-1 to cancel previous term n
	cbz	x0, 220f		// Skip term n=1 --> n=0 division by zero
	bl	Reg32BitDivision 	// REG2 = REG2 / x0
220:
	//
	// Multiply by n in numerator, this will be reversed next loop by division
	//
	mov	x1, HAND_REG2		// Factor2
	mov	x2, HAND_REG2		// Producct
	ldr	x0, [sp, value_n]	// Factor1
	bl	Reg64BitMultiplication	//REG2 = REG2 / x0

	//
	// Using n, build (n!)^3 in denominator
	//
	mov	x1, HAND_REG2		// Dividnend
	mov	x2, HAND_REG2		// Quotient
	mov	x10, #3			// Counter
230:
	ldr	x0, [sp, value_n]	// Divisor
	bl	Reg32BitDivision	// REG2 = REG2 / x0
	sub	x10, x10, #1
	cbnz	x10, 230b

	//
	// Build (640320)^(3n) in denominator
	//
	// TODO: can upgrade to 64 bit single division without loop
	mov	x1, HAND_REG2		// Dividnend
	mov	x2, HAND_REG2		// Quotient
	mov	x10, #3			// Counter
240:
	ldr	x0, =pi_ch_value_640320
	ldr	x0, [x0]
	bl	Reg32BitDivision	// REG2 = REG2 / x0
	sub	x10, x10, #1
	cbnz	x10, 240b

	//
	// At this point TermB is complete
	//

pi_ch_sum:
	// --------------------
	// Perform summation
	// --------------------

	//
	// Add term A to sum
	//
	ldr	x0, [sp, flag_term_A_done]
	cbnz	x0, 340f		// skip if not calculated

	mov	x1, HAND_XREG
	mov	x2, HAND_REG1
	mov	x3, HAND_XREG

	ldr	x0, [sp, value_n]	// check even or odd
	tst	x0, #1
	b.ne	330f
	bl	AddVariable
	b.al	340f
330:
	bl	SubtractVariable
340:
	//
	// Add term B to sum
	//
	ldr	x0, [sp, flag_term_B_done]
	cbnz	x0, 380f		// skip if not calculated

	mov	x1, HAND_XREG
	mov	x2, HAND_REG2
	mov	x3, HAND_XREG

	ldr	x0, [sp, value_n]	// check even or odd
	tst	x0, #1
	b.ne	370f
	bl	AddVariable
	b.al	380f
370:
	bl	SubtractVariable
380:
	// done summation

	ldr	x8, =Word_Size_Static
	ldr	x8, [x8]
	lsl	x8, x8, X64SHIFT4BIT	// Available bits in variable

	ldr	x2, [sp, flag_term_A_done]
	cbnz	x2, 410f
	mov	x1, HAND_REG1
	bl	CountLeftZerobits
	sub	x0, x8, x0
	b.ne	410f
	mov	x2, #1
	str	x2, [sp, flag_term_A_done]
410:
	ldr	x3, [sp, flag_term_B_done]
	cbnz	x3, 420f
	mov	x1, HAND_REG2
	bl	CountLeftZerobits
	sub	x0, x8, x0
	b.ne	420f
	mov	x3, #1
	str	x3, [sp, flag_term_A_done]
420:

	// Loop exit check
	and	x0, x2, x3		// termA Done || termB Done
	cbnz	x0, 500f		// 1 && 1 == 1 then done

	// DEBUG, stop loop at a fixed value
	//ldr	x0, [sp, value_n]
	//cmp	x0, #20
	//b.eq	500f

	b.al	pi_ch_loop	// loop gain, always taken
500:
	//
	// Calculate 1/Sum using reciprocal
	//
	mov	x1, HAND_XREG
	mov	x2, HAND_ACC
	bl	CopyVariable
	// First time +13591408.999999744616

	bl	Reciprocal
	// First time +0.00000007357588900459

	mov	x1, HAND_ACC
	mov	x2, HAND_OPR
	bl	CopyVariable

	mov	x1, HAND_REG0		// Squre root 10005
	mov	x2, HAND_ACC
	bl	CopyVariable
	//
	bl	MultiplyVariable	// ACC = OPR * ACC

	mov	x1, HAND_ACC
	mov	x2, HAND_OPR
	bl	CopyVariable

	ldr	x0, =pi_ch_value_426880
	ldr	x0, [x0]		// 426880
	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	Reg64BitMultiplication

	mov	x1, HAND_ACC
	mov	x2, HAND_XREG
	bl	CopyVariable

999:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x8,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	add	sp, sp, #192
	ret

calc_pi_ch_overflow_message:
	.asciz	"Error: Summation error, n overflow"
calc_pi_ch_description:
	.asciz	"\nFunction_calc_e: Calculating pi using Chudnovsky Formul\n"
	.align 4
calc_pi_ch_overflow_mask:
			.quad	0xffffffff00000000
//                      Ruler --> 1234567812345678

pi_ch_value_426880:	.quad 426880
pi_ch_value_640320:	.quad 640320
pi_ch_value_640320E3:	.quad (640320 * 640320 * 64320)
pi_ch_init_sum:       	.quad 13591409
pi_ch_init_term_A:    	.quad 13591409
pi_ch_init_term_B:    	.quad 545140134

	.align 4
