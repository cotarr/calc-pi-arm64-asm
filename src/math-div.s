/* ----------------------------------------------------------------
	math-div.s

	Floating point division routines

	Created:   2021-02-15
	Last edit: 2021-02-25

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

	.global DivideVariable
	.global LongDivision

DivideVariable:
//	b	LongDivision

/*-----------------------------------------

  Long_Division

  This is a bitwise long division.
  It is a very slow method
  It is included as demonstration of
  this type of algorithm, but not
  useful to calculate pi.

  Perform full binary long division
  shift, subtract  --> borrow? --> CF

  Input:  OPR register is the Dividend
          ACC register is the Divisor

  Output  ACC register contains the Quotient

----------------------------------------- */

LongDivision:
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
	// Check Divisor for zero, if so, fatal division by zero error
	//
	mov	x1, HAND_ACC
	bl	TestIfZero
	cbz	x0, 100f
	ldr	x0, =MsgDivZero		// Error message pointer
	mov	x1, #1206		// 12 bit error code
	b	FatalError
100:
	//
	// Check Dividend for zero, if so, return 0
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
	//
	// Calculate number of bits-1 in number
	//
	bl	set_x10_to_Word_Size_Static
	lsl	x16, x10, X8SHIFT3BIT	// 8 bytes per word
	lsl	x16, x16, X8SHIFT3BIT	// 8 bits per byte
	sub	x16, x16, #1		// Don't use sign bit for data
	//
	// Additional shift for decimal point alignment
	mov	x1, HAND_ACC
	bl	Right1Bit
	bl	Right1Bit
//--------------------------------------------------------------------
// At this point, the number must be adjusted for the number of
// integer words to the left of the decimal point.
// For 2 words of 64 bit, an adjustment of 128 bits is needed
// This can bee OPR to Right, or ACC to Left
//
// TODO: this need to be optimized.
// Temporary, just shift OPR left 128 bits, overflowing into guard words.
// It will be fixed later.
//--------------------------------------------------------------------
	mov	x2, #128	// full inetger part word shift
	mov	x1, HAND_OPR
50:
	bl	Right1Bit
	sub	x2, x2,#1
	cbnz	x2, 50b
//--------------------------------------------------------------------
//	mov	x2, #0
//	mov	x1, HAND_ACC
// 51:
//	bl	Left1Bit
//	sub	x2, x2,#1
//	cbnz	x2, 51b
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

// =================================================================================
// start of main loop
//
//  Subtract WorkA[i] = OPR[i] - ACC[i]
//  If result negative (highest bit 1) then copy OPR = WorkA
//  Rotate OPR and WorkB left 1 bit at a time
//  For each cycle, if M.S.Bit of WorkA = 1 then Rotate 1 into L.S. Bit WorkB
//  When done all bits, result mantissa is in WorkB
// =================================================================================

loop55:
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static // Offset to LS Word
	bl	set_x10_to_Word_Size_Static // Count of words
	//
	//  Loop through words. For each Word
	//       WorkA[i] = OPR[i] - ACC[i]
	//
	mov	x0, #0
	subs	x0, x0, x0		// set carry C=1 (NOT carry needed)
210:
	ldr	x0, [x12, x9]		// word from OPR
	ldr	x1, [x11, x9]		// word from ACC
	sbcs	x0, x0, x1		// subtract OPR-ACC, carry flag effected
	str	x0, [x13, x9]		// store work-A
	add	x9, x9, BYTE_PER_WORD	// increment offset pointer
	sub	x10, x10, #1		// counter
	cbnz	x10, 210b		// loop again?
	//
	// If the result of the subtraction is positive
	//   then move mantissa of WorkA to OPR
	//  else skip
	//
	bl	set_x9_to_Int_MS_Word_Addr_Offset
	ldr	x1, [x13, x9]		// top 64 bit word WorkA
	ldr	x0, =Word8000
	ldr	x0, [x0]
	tst	x1, x0			// Is it negative?
	b.ne	skip65			// negative skip
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	bl	set_x10_to_Word_Size_Static
300:
	ldr	x0, [x13, x9]		// get 64 bit word from WORKA
	str	x0, [x12, x9]		// store in OPR
	add	x9, x9, BYTE_PER_WORD	// increment offset pointer
	sub	x10, x10, #1		// counter
	cbnz	x10, 300b		// loop again?
skip65:
	//
	// Rotate WorkB left 1 bit
	//
	mov	x1, HAND_WORKB
	bl	Left1Bit
	//
	// Recycle left most bit from rotation WORKA into right most bit WORKB (out left in right)
	//
	bl	set_x9_to_Int_MS_Word_Addr_Offset
	ldr	x1, [x13, x9]		// top word WORKA
	ldr	x0, =Word8000
	ldr	x0, [x0]
	tst	x1, x0			// Is it negative?
	b.ne	skip66			// negative skip

	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	ldr	x0, [x14, x9]		// get LS word from WORKB
	orr	x0, x0, #1		// set LS bit of LS Word
	str	x0, [x14, x9]		// Store WORKB
skip66:
	//
	// Rotate OPR left 1 bit left
	// Thus WORKB and OPR rotate together 1 bit at a time
	//
	mov	x1, HAND_OPR
	bl	Left1Bit		// Shift OPR left 1 bit
	//
	// Decrement bit counter, loop until all bits are rotated.
	sub	x16, x16, #1
	cbnz	x16, loop55
	//
	// Done main loop, result in work B
	//
	mov	x1, HAND_WORKB
	mov	x2, HAND_ACC
	bl	CopyVariable

	//
	tst	x17, #1			// check sign bit
	beq	400f
	mov	x1, HAND_ACC
	bl	TwosCompliment
400:

LongDivisionExit:
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

MsgDivZero:
	.asciz	"FP_Long_Divison: Error: Division by Zero"
	.align 4
