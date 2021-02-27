/* ----------------------------------------------------------------
	math-mult.s

	Floating point multiplicatoin routines

	Created:   2021-02-27
	Last edit: 2021-02-27

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

	.global MultiplyVariable
	.global WordMultiplication

MultiplyVariable:
//	b	Multiplication

/*-----------------------------------------

  Long_Division

  This is a bitwise long division.
  It is a very slow method
  It is included as demonstration of
  this type of algorithm, but not
  useful to calculate pi.

  Perform full binary long division
  shift, subtract  --> borrow? --> CF

  Input:  OPR register is one factor
          ACC register is other factor

  Output  ACC register contains the Product

----------------------------------------- */

WordMultiplication:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x4,  [sp, #49]
	str	x9,  [sp, #56]
	str	x10, [sp, #64]
	str	x11, [sp, #72]
	str	x12, [sp, #80]
	str	x13, [sp, #88]
	str	x14, [sp, #96]
	str	x16, [sp, #104]
	str	x17, [sp, #112]

	mov	x17, 0			// initialize flag register
					// bit 0 is sign flag
	//
	// Check ACC for zero, if so return zero result
	//
	mov	x1, HAND_ACC
	bl	TestIfZero
	cbz	x0, 100f
	// is zero, return zero value
	mov	x1, HAND_ACC
	bl	ClearVariable
	b.al	WordMultiplicationExit
100:
	//
	// Check OPR, if so, return 0
	//
	mov	x1, HAND_OPR
	bl	TestIfZero
	cbz	x0, 110f
	// is zero, return zero value
	mov	x1, HAND_ACC
	bl	ClearVariable
	b.al	LongDivisionExit
110:
	//
	// Check for negative, Exclusive OR to set sign flag
	//  + +   --> 0
	//  - +   --> 1
	//  + -   --> 1
	//  - -   --> 0
	//
	// Save sign in bit 0 of x17 for two's compliment later
	//
	//
	// Check Dividend for negative sign
	mov	x1, HAND_OPR
	bl	TestIfNegative
	cbz	x0, 120f

	eor	x17, x17, #1		// result sign flag

	mov	x1, HAND_OPR
	mov	x2, HAND_OPR
	bl	TwosCompliment
120:
	// Check divisor for negative sign
	mov	x1, HAND_ACC
	bl	TestIfNegative
	cbz	x0, 130f

	eor	x17, x17, #1		// result sign flag

	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	TwosCompliment
130:
	// WORKA and WORKB will be used in the long division
	//
	mov	x1, HAND_WORKA
	bl	ClearVariable
	mov	x1, HAND_WORKB
	bl	ClearVariable
/*
// %%%%%%%%%%%%%%%%%%%%%%%
//    PLACEHOLDER CODE
//    From division bit shifts
// %%%%%%%%%%%%%%%%%%%%%%%

	//
	// Calculate number of bits-1 in number
	//
	bl	set_x10_to_Word_Size_Static
	lsl	x16, x10, X8SHIFT3BIT	// 8 bytes per word
	lsl	x16, x16, X8SHIFT3BIT	// 8 bits per byte
	sub	x16, x16, #1		// Don't use sign bit for data

	//   Gather Data
	// -------------------
	//
	// x4 contains bit shift needed for decimal point alignment
	//
	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT
	sub	x4, x4, #2 		// for alignment
	//
	// X3 is space to shift ACC left (preferred ACC)
	//
	mov	x1, HAND_ACC
	bl	CountLeftZerobits
	mov	x3, x0
	//
	// X2 is space to shift OPR right (remaining bits)
	//
	mov	x1, HAND_OPR
	bl	CountLeftZerobits
	mov	x2, x0
	//
	// Check for long division overflow (number too big)
	//
	mov	x0, x4			// Available bits
	add	x0, x0, x2		// OPR alignment
	sub	x0, x0, #3		// safety bits
	subs	x0, x0, x3		// ACC alignment
	b.pl	10f			// If negative, overlow error
	// Fatal error
	ldr	x0, =MsgDivOverflow	// Error message pointer
	mov	x1, #1222		// 12 bit error code
	b	FatalError
10:
	//
	// count of available bit to shift in ACC
	//
	subs	x3, x3, #2		// safety bits on high end
	b.eq	10f			// If zero skip to ship OPR
	b.mi	10f			// If negative skip to OPR

	cmp	x4, x3			// Area available bit more than needed?
	b.cs	5f			// Too big, use required number instead
	b.eq	5f			// equal, use it
	mov	x3, x4			// Replace available shift with required shift
5:
	mov	x0, x3			// Argument bits to shift
	mov	x1, HAND_ACC		// Variable handle number
	bl	LeftNBits		// Shift variable bits
10:
	subs	x2, x4, x3		// Subtract ot get remaining bits to shift
	b.mi	20f			// negative, not needed skip
	b.eq	20f			// zero, not needed, skip

	mov	x0, x2
	mov	x1, HAND_OPR
	bl	RightNBits
20:

// %%%%%%%%%%%%%%%%%%%%%%%
//    END PLACEHOLDER CODE
// %%%%%%%%%%%%%%%%%%%%%%%
*/

//--------------------------------------------------------------------
	//
	// Setup address pointers x11,x12,x13,x14(these will not change)
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_OPR
	mov	x3, HAND_WORKA
	mov	x4, HAND_WORKB
	bl	set_x11_to_Var_LS_Word_Address
	bl	set_x12_to_Var_LS_Word_Address
	bl	set_x13_to_Var_LS_Word_Address
	bl	set_x14_to_Var_LS_Word_Address

// %%%%%%%%%%%%%%% PLACE HOLDER STRING OUTPUT %%%%%%%%%%
	ldr	x0, =123f
	bl	StrOut
	b.al	124f
123:	.asciz	"\nPlace Holder Multiplication\n\n"
	.align	4
124:
// %%%%%%%%%%%%%%  END PLACEHOLDER %%%%%%%%%%%%%%%%%%%%%%%%%%
	tst	x17, #1			// check sign bit
	beq	400f
	mov	x1, HAND_ACC
	bl	TwosCompliment

WordMultiplicationExit:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x4,  [sp, #48]
	ldr	x9,  [sp, #56]
	ldr	x10, [sp, #64]
	ldr	x11, [sp, #72]
	ldr	x12, [sp, #80]
	ldr	x13, [sp, #88]
	ldr	x14, [sp, #96]
	ldr	x16, [sp, #104]
	ldr	x17, [sp, #112]
	add	sp, sp, #128
	ret
