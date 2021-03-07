/* ----------------------------------------------------------------
	calc-sqrt.s

	Calculation of square root of ACC

	Created:   2021-03-07
	Last edit: 2021-03-07

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
	.global	SquareRoot
// ---------------------------------------------------------

// -------------------------------------------------------------
//
// for Square root root of ACC
//
//  INPUT: X-Reg = Floating point number A
//
// During calculation:
//    XREG - Original A
//    REG0 - holds next/last guess (not preserved)
//
// After calculation:
//    ACC - nth root of A
//    REG0 - not preserved.
//
//-----------------------------------------
//
//  Method: Iterative approximations
//
//  X(i) = last guess   X(i+1) = next guess  A = input number
//
//  X(i+1) =  [  (A / X(i))  + (X(i) ] / 2
//
//-----------------------------------------
//
SquareRoot:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]

	//
	// Check and make error if input not positive non-zero number.
	//
	mov	x1, HAND_XREG
	bl	TestIfZero
	cbnz	x0, 20f
	mov	x1, HAND_XREG
	bl	TestIfZero
	cbnz	x0, 20f
	b.al	30f
20:
	// Fatal error
	ldr	x0, =SqrtRangeError
	mov	x1, #1230		// 12 bit error code
	b	FatalError
30:
	//
	// First guess is 1.0
	//
	mov	x1, HAND_REG0
	bl	SetToOne

Sqrt_Loop:
	//
	// Divide ACC = XREG / REG0
	//
	mov	x1, HAND_XREG
	mov	x2, HAND_OPR
	bl	CopyVariable

	mov	x1, HAND_REG0
	mov	x2, HAND_ACC
	bl	CopyVariable

	bl	DivideVariable

	// Add ACC = ACC + REG0 (two times)
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_REG0
	mov	x3, HAND_ACC

	bl	AddVariable

	//
	// Move Divide ACC by 2
	//
	mov	x1, HAND_ACC
	bl	Right1Bit
	//
	// Check difference guess verses this result

	mov	x1, HAND_REG0
	mov	x2, HAND_ACC
	bl	CountAbsValDifferenceBits
	bl	PrintWordB10
	bl	CROut
	cmp	x0, #96
	b.lo	999f
	//
	// Save result as next guess
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_REG0
	bl	CopyVariable

	b.al	Sqrt_Loop		// Loop back (Always taken)

999:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	add	sp, sp, #96
	ret
SqrtRangeError:
	.asciz	"\nError: Square Root input must be positive non-zero number.\n"
	.align 4
