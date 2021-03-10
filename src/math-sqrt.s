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
	str	x4,  [sp, #48]


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

	//
	// Redice Accuracy for early calculation loops
	//
	ldr	x0, =MinimumWord
	ldr	x0, [x0]

	bl	Set_Temporary_Word_Size

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
	// Check difference between guess verses this result
	//
	// Continue in loop until half of bits match
	// then double accuracy and continue util half of those match
	//
	bl	Grab_Reduced_Accuracy	// x1 = static x2 = optimized
	cmp	x1, x2			// full accuracy?
	b.ne	40f
	mov	x4, #96			// Final end, full accuracy, 96 ls bits allow different
	b.al	50f
40:
	mov	x4, x2			// static words in variable
	lsl	x4, x4, X64SHIFT4BIT	// multiply 64 bit per word
	lsr	x4, x4, #1		// divide by 2, limit bits match
	cmp	x4, #96
	b.hs	50f
	mov	x4, #96
50:
	// mov	x0, x4
	// bl	PrintWordB10
	// mov	x0, #0x09		// tab
	// bl	CharOut

	mov	x1, HAND_REG0
	mov	x2, HAND_ACC
	bl	CountAbsValDifferenceBits
	// bl	PrintWordB10
	cmp	x0, x4			// Is difference significant?
	b.hs	80f			// Yes loop again
	//
	// If no, then see if accuracy can be increased?
	//
	bl	Grab_Reduced_Accuracy	// x1 = static x2 = optimized
	cmp	x1, x2			// Full accuracy now?
	b.eq	999f			// yes, done

	lsl	x0, x2, #1		// Double words
	cmp	x1, x0			// new value below maximum?
	b.hs	70f			// yes, below keep
	mov	x0, x1			// no, use maximum instead
70:
	bl	Set_Temporary_Word_Size
80:

	// mov	x0, #0x09		// ascii tab
	// bl	CharOut
	// bl	Grab_Reduced_Accuracy
	// mov	x0, x2
	// bl	PrintWordB10
	// bl	CROut
	//
	// Save result as next guess
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_REG0
	bl	CopyVariable

	b.al	Sqrt_Loop		// Loop back (Always taken)

999:
	bl	Restore_Full_Accuracy

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x4,  [sp, #48]
	add	sp, sp, #96
	ret
SqrtRangeError:
	.asciz	"\nError: Square Root input must be positive non-zero number.\n"
	.align 4
