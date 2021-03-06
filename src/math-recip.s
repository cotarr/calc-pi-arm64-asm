/* ----------------------------------------------------------------
	math-div.s

	Calculate Reciprocal

	Created:   2021-03-05
	Last edit: 2021-03-06

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
	.global Reciprocal
//------------------------------------------------
//
//  FP Reciprocal (1/X)
//
//  Input  Variable in ACC
//
//  Working Reg
//     ACC, WORKA, WORKB, WORKC
//
//     Variable OPR not used so division can preserve
//
//  Result   Variable in ACC
//
//  Use Newton Raphson method
//
//  D = Demonimator
//
//  x = 1/D ,  make guesses for next Xn
//
//  Xn+1 =  Xn + (Xn*(1-Xn*D))
//
//       Note: according to Wikipedia, alternate
//       Xn+1 = Xn(2-XnD) is simpler, but requires
//       double precision compare to formula used.
//
//
//  ACC      WorkC    WorkA     WorkB
//   D                                 ACC contains original denominator
//                               D     WorkB - move D to work B (Move)
//                     Xn        D     WorkA - has next guess   (Set)
// loop:
//  Xn*D               Xn        D     ACC   = Xn*D             (Multiply)
//  Xn*D       1       Xn        D     WorkC = 1                (Set)
//           1-(Xn*D)  Xn        D     WorkC = 1-(Xn*D)         (Subtract)
// Xn(1-Xn*D)          Xn        D     ACC   = Xn(1-Xn*D)       (Multiply)
// Xn+Xn( )            Xn        D     ACC   = Xn+Xn(1-XnD)     (Add)
// Xn+Xn( )            Xn        D     Compare ACC and WorkA    (Compare)
//                     Xn+1      D     WorkA next Xn+1 = P      (Move)
//                     Xn+1      D     WorkA next Xn+1 = P      (Loop back)
//
//------------------------------------------------
Reciprocal:

	sub	sp, sp, #224		// Reserve 28 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// var handle / mult factor
	str	x2,  [sp, #32]		// var handle / mult factor
	str	x3,  [sp, #40]		// var handle / mult product low bit 63-0
	str	x4,  [sp, #48]		//              mult product hi  bit 127-64
	str	x5,  [sp, #56]		// under range sum (pseudo variable)
	str	x6,  [sp, #64]		// preserved carry flag
	str	x7,  [sp, #72]		// ACC offset Loop 1 index
	str	x8,  [sp, #80]		// OPR offset
	str	x9,  [sp, #88]		// WORKA offset
	str	x10, [sp, #96]
	str	x11, [sp, #104]		// ACC variable address
	str	x12, [sp, #112]		// OPR variable address
	str	x13, [sp, #120]		// WORKA variable address
	str	x14, [sp, #128]		// OPR Loop-1 index
	str	x15, [sp, #136]		// WORKA Loop-2 index
	str	x16, [sp, #144]
	str	x17, [sp, #152]		// LSW Offset address (constant)
	str	x18, [sp, #160]		// MSW Offset address
	// local variables on stack
	.set SignFlag,         168	// save sign flag during main compute
	.set ReciprocalShift,  176	// save bit alignment for end
	.set RecipWorkCSign,   184	// Scratch sign flag
	.set RecipLoopCounter, 192	// Counter

	//
	// Check Number for zero, if so, fatal division by zero error
	//
	mov	x1, HAND_ACC
	bl	TestIfZero
	cbz	x0, 100f
	ldr	x0, =RecipMsgDivZero	// Error message pointer
	mov	x1, #1126		// 12 bit error code
	b	FatalError
100:
	//
	// Check sign, save flag for end, two's compliment if negative
	//
	mov	x0, #0
	str	x0, [sp, SignFlag]
	mov	x1, HAND_ACC
	bl	TestIfNegative		// x0 == 1 if negative
	cbz	x0, 120f

	mov	x0, #1
	str	x0, [sp, SignFlag]

	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	TwosCompliment
120:
	//
	// Range check reciprocal value before calculation
	//
	// size is 2x integer size (left of dec pt + right of dec pt
	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bits in integer part
	add	x4, x4, x4
	//
	// X3 is space to shift ACC left (preferred ACC)
	//
	mov	x1, HAND_ACC
	bl	CountLeftZerobits
	mov	x3, x0			// x0 is M.S. zero bit count
	add	x3, x3, #2		// 2 bits for safety
	subs	x0, x4, x3		// (int size) - (zero bits)
	b.hs	130f
	// Fatal error
	ldr	x0, =RecipMsgDivOverflow // Error message pointer
	mov	x1, #1222		// 12 bit error code
	b	FatalError
130:
	//
	// ACC is saved in WORKB for use during calculation
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_WORKB
	bl	CopyVariable

// -----------------------------------------
// For reciprocal to work properly,
// Number must be in range 0.5 to 1.0
// Shift to this position and remember
// amount of shift to adjust at the end.
// ------------------------------------------

	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bits in integer part

	mov	x1, HAND_WORKB
	bl	CountLeftZerobits
	mov	x3, x0

	subs	x0, x4, x3		// x0 bits to shift
	str	x0, [sp, ReciprocalShift] // Save for restore post calculation
	b.eq	160f			// already in range 0.5 to 1.0
	b.mi	150f			// Need shift left
	// right shift
	// x0 contains requrest shift argument
	mov	x1, HAND_WORKB
	bl	RightNBits
	b.al	160f
150:	// left shift
	sub	x0, xzr, x0		// two's compliment to positive
	mov	x1, HAND_WORKB
	bl	LeftNBits
160:
	mov	x1, HAND_ACC
	bl	ClearVariable
	mov	x1, HAND_WORKA
	bl	ClearVariable
	mov	x1, HAND_WORKC
	bl	ClearVariable
	//
	// Make first guess 0.75
	//
	mov	x1, HAND_WORKA
	bl	set_x11_to_Fct_MS_Word_Address
	movz	x0, #0xc000, lsl 48	// 0xc000000000000000
	str	x0, [x11]		// Store MSW Work Fractin Part

// =====================================
// Place holder for variable accuracy
// =====================================
	//
	// Setup x17 LSW and x18 MSW as constant value address offset
	//
	bl set_x9_to_Fct_LS_Word_Addr_Offset_Static
	mov	x17, x9			// save LSW offset in x17
	bl set_x9_to_Int_MS_Word_Addr_Offset
	mov	x18, x9			// save MSW offset in x18
	mov	x9, #0			// x9 value was temporary
	//
	// Initialize loop counter
	//
	mov	x0, #0
	str	x0, [sp, RecipLoopCounter]

RecipMainLoop:
	//------------------------------------------
	// Main iteration loop for making guesses
	//------------------------------------------
	//
	//  Formula :   Xn+1 = Xn + Xn(1-DXn)
	//
	// ---- start clip formula -----
	//
	// Multiply ACC = WORKA * WORKB
	// ACC = Xn*D
	//
	mov	x1, HAND_WORKA		//   Xn Next guess
	mov	x2, HAND_WORKB		// * D (Original denominator)
	mov	x3, HAND_ACC		// Xn*D --> ACC
	bl	_RecipMultiplyWrapper

	//
	// Load WorkC with properly aligned fixed point integer value 1
	// WorkC=1
	//
	mov	x1, HAND_WORKC		//
	bl	SetToOne		// 1.0 --> WorkC

	//
	//  Subtract WorkC = WorkC - ACC
	//  WorkC=1-(Xn*D)
	//
	mov	x1, HAND_WORKC		// 1.0
	mov	x2, HAND_ACC		// - (Xn*D)
	mov	x3, HAND_WORKC		// --> 1.0 - (Xn*D)
	bl	SubtractVariable

	//
	// If negative Twos Compliment
	// (Temporary for multiplication)
	//
	mov	x1, HAND_WORKC
	bl	TestIfNegative		// x0 == 1 if negative
	str	x0, [sp, RecipWorkCSign] // Save sign flag 1 if Negative
	cbz	x0, 180f		// x0==0, was positive
	mov	x1, HAND_WORKC
	mov	x2, HAND_WORKC
	bl	TwosCompliment		// WorkC = (0) - (1-(Xn*D))
180:

	//
	// Multiply ACC = WORKA * WORKC
	// ACC = Xn(1-(Xn*D))
	//
	mov	x1, HAND_WORKA		// Xn
	mov	x2, HAND_WORKC		// (1-(Xn*D))
	mov	x3, HAND_ACC		// Xn*(1-(Xn*D)) --> ACC
	bl	_RecipMultiplyWrapper

	//
	// Add or subtract depending on if 2's compliment was done
	// ACC = Xn+(Xn*(1-Xn*D))
	//
	ldr	x0, [sp, RecipWorkCSign] // get sign flag
	cbz	x0, 200f // case of positive, branch
	// ACC = WorkC - ACC
	mov	x1, HAND_WORKA		// Xn
	mov	x2, HAND_ACC		// - (0-(Xn*(1-(Xn*D))))  [double negative]
	mov	x3, HAND_ACC		// --> ACC = Xn+(Xn(...))
	bl	SubtractVariable
	b.al	210f
200:
	// ACC = WorkC + ACC
	mov	x1, HAND_WORKA		// Xn
	mov	x2, HAND_ACC		// - (Xn*((1-(Xn*D))))
	mov	x3, HAND_ACC		// --> ACC = Xn+(Xn(...))
	bl	AddVariable
210:
	ldr	x0, [sp, RecipLoopCounter]
	add	x0, x0, #1
	str	x0, [sp, RecipLoopCounter]

	// Skip check for first few cycles
	cmp	x0, #4
	b.lo	400f

	mov	x1, HAND_ACC		// new guess
	mov	x2, HAND_WORKA
	bl	CountAbsValDifferenceBits
	// bl	PrintWordB10
	// bl	CROut
	cmp	x0, #64
	b.lo	ExitRecipLoop

400:

	// Debug option to exit loop at this count
	// ldr	x0, [sp, RecipLoopCounter]
	// cmp	x0, #5
	// b.hs	ExitRecipLoop

	//
	// Keep going, ACC becomes new guess
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_WORKA
	bl	CopyVariable
	b.al	RecipMainLoop

ExitRecipLoop:

	//
	// Align bits for proper decimal separator after reciprocal
	//
	ldr	x0, [sp, ReciprocalShift]	// get shift count from earlier
	adds	x0, xzr, x0		// is it zero?
	b.eq	940f			// zero, no shift
	b.mi	930f
	// x0 is shift count argument
	mov	x1, HAND_ACC
	bl	RightNBits
	b.al	940f
930:
	// x0 is shift count argument
	sub	x0, xzr, x0		// Two's compliment to positive
	mov	x1, HAND_ACC
	bl	LeftNBits
940:

	//
	// Check sign flag and 2's compliment if needed
	//
	ldr	x0, [sp, SignFlag]
	tst	x0, #1			// check sign bit
	b.eq	960f
	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	TwosCompliment
960:

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x4,  [sp, #48]
	ldr	x5,  [sp, #56]
	ldr	x6,  [sp, #64]
	ldr	x7,  [sp, #72]
	ldr	x8,  [sp, #80]
	ldr	x9,  [sp, #88]
	ldr	x10, [sp, #96]
	ldr	x11, [sp, #104]
	ldr	x12, [sp, #112]
	ldr	x13, [sp, #120]
	ldr	x14, [sp, #128]
	ldr	x15, [sp, #136]
	ldr	x16, [sp, #144]
	ldr	x17, [sp, #152]
	ldr	x18, [sp, #160]
	add	sp, sp, #224
	ret

RecipMsgDivZero:	.asciz	"Reciprocal: Error: Division by Zero"
RecipMsgDivOverflow:	.asciz	"Reciprocal: Error: Overlow (number too big)"
	.align 4
// ----------------------------------------------------
//
//      DO NOT CALL DIRECTLY
// Multiply ACC = WORKA * WORKC
//
// Assumes positive input
//
// x1, x2, x3 saved for resuse within, REGISTERS NOT PRESERVED
//
// On entry:
//      X1  - Factor1 Variable Handle
//      X2  - Factor2 Variable Handle
//      X3  - Product Variable Handle
//      x17 - L.S. word address offset
//	x18 - M.S. word address offset
// -----------------------------------------------------
_RecipMultiplyWrapper:
	sub	sp  , sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x1,  [sp, #16]		// Factor1 handle
	str	x2,  [sp, #24]		// Factor2 handle
	str	x3,  [sp, #32]		// Product handle
	// Local variables on stack
	.set	RMShift1, 40
	.set	RMShift2, 48
	.set	RMShift3, 56

	//
	// Alignment for multiplicaiton
	//
	// 1 Shift Factor1 left until M.S. bit is 1
	// 2 Shift Factor2 left until M.S. bit is 1
	// 3 Save position of intended decimal separator after multiplication
	// 4 (TBD) Range check integer part big enough to hold number
	// 5 Multiply
	// 6 Shift product to proper position of decimal separator

	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bit's needed for decimal separator alignment

	//
	// X3 is bits to shift Factor1 left, do the shift
	//
	ldr	x1, [sp, #16]
	bl	CountLeftZerobits
	str	x0, [sp, RMShift1]	// save to restore at end
	bl	LeftNBits
	mov	x3, x0
	//
	// X2 is bits to shift Factor2 left, do the shift
	//

	ldr	x1, [sp, #24]
	bl	CountLeftZerobits
	str	x0, [sp, RMShift2]	// save to restore at end
	bl	LeftNBits
	mov	x2, x0

	//
	// Determine alignment of decimal separator at end of the calculation.
	//
	// Subtract (Integer part bit size) - (leading zero count)
	sub	x0, x4, x3		// decimal separator alignment bits Factor1
	sub	x1, x4, x2		// decimal deparator alignment bits Factor2
	// Add values for both factors to get total post calculation position of decimal separator
	add	x0, x0, x1		// total decimal separator alignment bits
	str	x0, [sp, RMShift3]	// Save for post multiplication shift

/* TODO reange check need accommodate positive and negative
	//
	// Range Check, Does ineger part have enough bits to hold the result?
	//
	add	x0, x0, #2		// 2 bits for safety
	subs	x0, x4, x0		// Is integer part big enough to hold this variable?
	b.hs	140f			// Yes enought space, branch ahead and continue
	// Fatal error
	ldr	x0, =WrapMultErrMsg1	// Error message pointer
	mov	x1, #641		// 12 bit error code
	b	FatalError
140:
*/
	//
	// Setup address pointers x11,x12,x13,x14(these will not change)
	//
	ldr	x1, [sp, #16]		// Factor1
	ldr	x2, [sp, #24]		// Factor2
	ldr	x3, [sp, #32]		// Product
	bl	set_x11_to_Var_LS_Word_Address
	bl	set_x12_to_Var_LS_Word_Address
	bl	set_x13_to_Var_LS_Word_Address
	//
	// Clear of product variable is required before calling internal procedure
	//
	ldr	x1, [sp, #32]		// Variable Handle
	bl	ClearVariable
	// ==============================================
	// Internal function for matrix multiplicaiton
	// using processor 64bit x 64 bit --> 128 bit
	//
	// Assume registers x0 to x18 are NOT preserved
	// this function located in math-mult.s

	bl	_internal_matrix_multiply

	// ===============================================
	//
	// Restore Factor1 and Factor2 to correct shift position
	// This may not be necessary, but included for now.
	//
	ldr	x1, [sp, 16]
	ldr	x0, [sp, RMShift1]
	bl	RightNBits
	ldr	x1, [sp, 24]
	ldr	x0, [sp, RMShift2]
	bl	RightNBits
	//
	// Align Product bits for proper decimal separator after multiplication
	//
	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bit's needed for decimal separator alignment
	ldr	x0, [sp, RMShift3]
	subs	x0, x4, x0
	b.eq	360f
	b.mi	350f
	ldr	x1, [sp, #32]		// Product
	bl	RightNBits
	b.al	360f
350:
	sub	x0, xzr, x0		// 2's TwosCompliment of x0
	ldr	x3, [sp, #32]		// Product
	bl	LeftNBits
360:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x1,  [sp, #16]
	ldr	x2,  [sp, #24]
	ldr	x3,  [sp, #32]
	add	sp, sp, #80
	ret

WrapMultErrMsg1:	.asciz	"_RecipMultiplyWrapper: Error: Overlow (number too big)"
	.align 4
