/* ----------------------------------------------------------------
	math-mult.s

	Floating point multiplicatoin routines

	Created:   2021-02-27
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
	.global MultiplyVariable
	.global WordMultiplication
	.global Reg64BitMultiplication
	.global _internal_matrix_multiply

// ----------------------------------------
// Multiply variable
//
// THis is a selector function to
// call proper multiplication child function.
//
// Input:  OPR register is the factor
//         ACC register is the factor
//
// Output  ACC register contains the Product
//
//-----------------------------------------


MultiplyVariable:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x8,  [sp, #40]
	str	x9,  [sp, #48]
	str	x10, [sp, #56]
	str	x11, [sp, #64]

	ldr	x0, =MathMode
	ldr	x0, [x0]
	tst	x0, #4			// disable resister mult
	b.ne	100f			// skip

	bl	set_x9_to_Int_LS_Word_Addr_Offset
	mov	x8, x9
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	bl	set_x10_to_Word_Size_Optimized

	mov	x1, HAND_ACC
	bl	set_x11_to_Var_LS_Word_Address

10:	cmp	x9, x8			// check if not Integer part MS word
	b.eq	20f			// this is int L.S word, special case
	ldr	x0, [x11, x9]
	cbnz	x0, 100f		// non-zero can't use 32 bit, do full
20:
	add	x9, x9, BYTE_PER_WORD
	sub	x10, x10, #1
	cbnz	x10, 10b
	//
	// Case of faster 64 bit processor word multiplication
	//
	// -------------------------
	ldr	x0, [x11, x8]		// L.S word integer part
	mov	x1, HAND_OPR		// Use main variable
	mov	x2, HAND_ACC		// Use main variable
	bl	Reg64BitMultiplication
	// -------------------------
	b.al	999f
100:
	//
	// Default, do full precision multiplication
	//
	// -------------------------
	bl	WordMultiplication
	// -------------------------

999:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	add	sp, sp, #96
	ret

/* --------------------------------------------------------------
   Multiply Variable by 64 bit word

   Input: x0 = 64 bit word with 64 bit factor, positive only
          x1 = Source factor Variable Handle (may be negtive)
	  x2 = Destination Product variable Handle

   Output:  none

   This will utilize 64 bit * 64 bit ARM64 to produce
   128 bit product (low word, high word)

-------------------------------------------------------------- */
Reg64BitMultiplication:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]	// <-- do not renumber (factor)
	str	x2,  [sp, #32]  // <-- do not renumber (product)
	str	x3,  [sp, #40]
	str	x4,  [sp, #48]
	str	x9,  [sp, #56]
	str	x10, [sp, #64]
	str	x11, [sp, #72]
	str	x12, [sp, #80]
	str	x17, [sp, #88]
	str	x18, [sp, #96]

	mov	x18, x0			// save x0 64 bit factor (register)
	//
	// Check 64 bit register for zero, if so return zero
	cmp	x18, #0			// zero?
	b.ne	10f			// no branch
	ldr	x1,  [sp, #32]		// Product (Destination) register handle
	bl	ClearVariable
	b.al	999f
10:
	//
	// Check factor for zero, if so, return 0
	//
	ldr	x1,  [sp, #24]		// Dividend (Source) register handle
	bl	TestIfZero
	cbz	x0, 40f
	// is zero, return zero value
	ldr	x1,  [sp, #32]		// Product (Destination) register handle
	bl	ClearVariable
	b.al	999f
40:
	// variable for negative sign
	mov	x17, #0			// default sign flag
	ldr	x1, [sp, #24]		// Factor (Source) register handle
	bl	TestIfNegative
	cbz	x0, 50f

	mov	x17, #1			// result sign flag

	ldr	x1, [sp, #24]
	ldr	x2, [sp, #24]
	bl	TwosCompliment
50:

//                           [hi ][low]
//                      [hi ][low]
//                 [hi ][low]
//            [hi ][low]
//       [hi ] <-- last word
//  [   ][   ][   ] <--- <--- <--- 1 extra for decial point align

	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	bl	set_x10_to_Word_Size_Optimized
	ldr	x1, [sp, #24]		// Source (factor) handle
	bl	set_x11_to_Var_LS_Word_Address
	ldr	x2, [sp, #32]		// Source (factor) handle
	bl	set_x12_to_Var_LS_Word_Address

	//
	// Adjust input 1 word left to high 128 bit result will fit
	//
	sub	x10, x10, #1
	add	x11, x11, BYTE_PER_WORD	// first word shifted
	//
	// Case of first multiplication
	ldr	x1, [x11, x9]
	mul	x3, x1, x18		// x3 is mult product bit 63-0
	umulh	x4, x1, x18		// x4 is mult product bit 127-64
	str	x3, [x12, x9]		// store lowest word
	add	x9, x9, BYTE_PER_WORD	// increment pointer
	sub	x10, x10, #1		// decrement counter
	//
	// Perform ARM64 Multiplication
	// low word bit 63-0 mul x3, x2, x1      -->  x3(63-0)   = X1 * x2
	// high word bit 127-64 umulh x4, x2, x1 -->  x4(127-64) = X1 * x2
	//
100:
	mov	x2, x4			// save last high word
	ldr	x1, [x11, x9]		// fetch next word from ACC
	mul	x3, x1, x18		// x3 is mult product bit 63-0
	umulh	x4, x1, x18		// x4 is mult product bit 127-64
	adds	x3, x3, x2		// add last high word (carry imapcted)
	adcs	x4, x4, xzr		// add carry flag to high word (carry impacted)
	b.cc	110f			// verify assumption no carry
	// Fatal error
	ldr	x0, =MsgRegMultCarry	// Error message pointer
	mov	x1, #677		// 12 bit error code
	b	FatalError
110:
	str	x3, [x12, x9]		// low word
	add	x9, x9, BYTE_PER_WORD
	sub	x10, x10, #1
	cbnz	x10, 100b
	//
	// Top word from multiplication needs store in top word variable
	str	x4, [x12, x9]
	//
	// Done

	//
	// Due to offset decimal point, we are shifted 1 word.
	// This is a potential loss of 64 bits on low end.
	//
	// TODO  ? option to shift input left before to save bits
	// although guard words should absorb them.
	//
	ldr	x1, [sp, #32]		// product destination variable handle
	bl	Left64Bits		// Bit alignment for decimal point
	//
	// Check for two's compliment
	//
	tst	x17, #1			// check sign bit
	beq	999f
	ldr	x1, [sp, #32]		// Product destination variable handle
	bl	TwosCompliment
999:
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
	ldr	x17, [sp, #88]
	ldr	x18, [sp, #96]
	add	sp, sp, #128
	ret

MsgRegMultCarry:	.asciz	"Reg64BitMultiplication: Error: (internal carry flag fault)"
MsgRegMultInvalid:	.asciz	"Reg64BitMultiplication: Error: Invalid input (Out of range)"
		.align 4

/*-----------------------------------------

  WordMultiplication

  Uses ARM process to multiply
  (factor-64bit) * (factor64bit) --> 128 bit Product
  Split number into words and matrix multiply

  Input:  OPR register is one factor
          ACC register is other factor

  Output  ACC register contains the Product

----------------------------------------- */

WordMultiplication:
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
	// Local variables on stack
	.set MultSignFlag,  168		// save sign flag during main compute
	.set PostMultShift1, 176	// save bit alignment Factor1 for end
	.set PostMultShift2, 184	// save bit alignment Factor2 for end
	.set PostMultShift3, 192	// save bit alignment Product for end

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
	b.al	WordMultiplicationExit
110:
	//
	// Check for negative, Exclusive OR to set sign flag
	//  + +   --> 0
	//  - +   --> 1
	//  + -   --> 1
	//  - -   --> 0
	//
	// Save sign in bit 0 of x8 for two's compliment later
	//
	//
	mov	x8, #0			// temporary sign flag
	// Check for negative sign
	mov	x1, HAND_OPR
	bl	TestIfNegative
	cbz	x0, 120f

	eor	x8, x8, #1		// result sign flag

	mov	x1, HAND_OPR
	mov	x2, HAND_OPR
	bl	TwosCompliment
120:
	// Check for negative sign
	mov	x1, HAND_ACC
	bl	TestIfNegative
	cbz	x0, 130f

	eor	x8, x8, #1		// result sign flag

	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	TwosCompliment
130:
	// save sign flag for end (two's compliment)
	str	x8, [sp, MultSignFlag]

	// WORKA and WORKB will be used in the multiplication
	//
	mov	x1, HAND_WORKA
	bl	ClearVariable

/*  --------------- NEW BIT ALIGNMENT CODE --- BROKEN !!! -------------
	//
	// Alignment for multiplicaiton
	//
	// 1 Shift Acc left until M.S. bit is 1
	// 2 Shift Opr left until M.S. bit is 1
	// 3 Save position of intended decimal separator after multiplication
	// 4 Range check integer part big enough to hold number
	// 5 Multiply
	// 6 Shift product to proper position of decimal separator

	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bit's needed for decimal separator alignment

	//
	// X3 is bits to shift ACC left, do the shift
	//
	mov	x1, HAND_ACC
	bl	CountLeftZerobits
	str	x0, [sp, PostMultShift1]
	bl	LeftNBits
	mov	x3, x0
	//
	// X2 is bits to shift OPR left, do the shift
	//
	mov	x1, HAND_OPR
	bl	CountLeftZerobits
	str	x0, [sp, PostMultShift2]
	bl	LeftNBits
	mov	x2, x0

	//
	// Determine alignment of decimal separator at end of the calculation.
	//
	// Subtract (Integer part bit size) - (leading zero count)
	sub	x0, x4, x3		// decimal separator alignment bits ACC
	sub	x1, x4, x2		// decimal deparator alignment bits OPR
	// Add values for both factors to get total post calculation position of decimal separator
	add	x0, x0, x1		// total decimal separator alignment bits
	str	x0, [sp, PostMultShift3]// Save for later

//TODO reange check need accommodate positive and negative
	//
	// Range Check, Does ineger part have enough bits to hold the result?
	//
	add	x0, x0, #2		// 2 bits for safety
	subs	x0, x4, x0		// Is integer part big enough to hold this variable?
	// Positive right, Negative Left
	b.hs	140f			// case of positive lots of room to right,
	// Fatal error
	ldr	x0, =MultErrMsg1	// Error message pointer
	mov	x1, #641		// 12 bit error code
	b	FatalError
140:
*/

// -------------- TEMPORARILY RESTORE OLD BIT ALIGNMENT CODE -------------------
	//
	// Check for multiply overflow (exceed integer part)
	//
	//
	// x4 contains bit shift needed to stay in range
	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bit's needed for decimal separator alignment
	//
	// X3 is space to shift ACC left
	//
	mov	x1, HAND_ACC
	bl	CountLeftZerobits
	mov	x3, x0
	//
	// X2 is space to shift OPR left
	//
	mov	x1, HAND_OPR
	bl	CountLeftZerobits
	mov	x2, x0

	sub	x5, x4, #2		// Safety bits for overflow
	add	x0, x2, x3		// Total left shift available
	cmp	x5, x0			// Check for multiplication overflow
	// -------------------------
	// Check for overflow
	// -------------------------
	b.lo	150f			// If negative, overlow error
	// Fatal error
	ldr	x0, =MultErrMsg1	// Error message pointer
	mov	x1, #603		// 12 bit error code
	b	FatalError
150:
	// ----------------------------------------------------------
	// By experimenting, with integer part size set to two 64-bit words,
	// a post multiplication shift left of 128 bits left is needed.
	// This is assumed to be related to the size of the integer part.
	// Pre-multiplication rotation left accomplishes the same thing
	// but has the advantage of reducing risk of loss of significant
	// bits on L.S side of variable.
	// The approach here is to shift OPR, then ACC left as needed
	// to get 128 bits total while leaving 64 bit safety margin.
	// Remaining bits (not shifted before mult) will be
	// shifted left after multiplication is complete.
	//
	// If already left at limit, no right shift is done (should?)
	//---------------------------------------------------
	//
	// TODO test bit alignment with size of integer part
	//      set other than two words
	//
	// --------------------------------------------------
	// Shift OPR, then ACC left
	//
	// OPR
	//
	// Check OPP zero bits > 64 bit word size
	subs	x5, x2, BIT_PER_WORD	// OPR available bits - safety word
	b.lo	170f			// Less than safety word, skip, try ACC
	cmp	x4, x5			// Requested bits - OPR available
	b.lo	160f
	// Case Requested >= OPR availble bits, shift available, then do ACC
	mov	x0, x5			// available bits is argument
	mov	x1, HAND_OPR
	bl	LeftNBits		// shift bits
	sub	x4, x4, x5		// bits needed by ACC afterwards
	b.al	170f			// Next shift ACC remaining
160:
	// Case Requested < available, shift requested, then done...
	mov	x0, x4			// requested bits is argument
	mov	x1, HAND_OPR
	bl	LeftNBits		// shift bits
	mov	x4, #0			// requested now zero
	b.al	190f			// done shifting bits
170:
	//
	// ACC
	//
	// Check ACC zero bits > 64 bit word size
	subs	x5, x3, BIT_PER_WORD	// ACC available bits - safety word
	b.lo	190f			// Less than safety word, skip,
	cmp	x4, x5			// Requested bits - ACC available
	b.lo	180f
	// Case Requested >= ACC availble bits, shift available
	mov	x0, x5			// available bits is argument
	mov	x1, HAND_ACC
	bl	LeftNBits		// shift bits
	sub	x4, x4, x5		// bits needed Post multiplication
	b.al	190f			// Next shift ACC remaining
180:
	// Case Requested < available, shift requested, then done...
	mov	x0, x4			// requested bits is argument
	mov	x1, HAND_ACC
	bl	LeftNBits		// shift bits
	mov	x4, #0			// requested now zero
	b.al	190f			// done shifting bits
190:
	cmp	x4, xzr			// post mult shift must be >= 0
	b.pl	195f
	// Fatal error
	ldr	x0, =MultErrMsg4	// Error message pointer
	mov	x1, #677		// 12 bit error code
	b	FatalError
195:

	// any remiaining bits to shift do after multiplicaiton done
	str	x4, [sp, PostMultShift3]
// ------------- END OLD WAY ----------------

//--------------------------------------------------------------------
// Internal function for matrix multiplication
//--------------------------------------------------------------------
	//
	// Setup address pointers x11,x12,x13,x14(these will not change)
	//
	mov	x1, HAND_ACC	// (Factor1)
	mov	x2, HAND_OPR	// (Factor2)
	mov	x3, HAND_WORKA	// (Product)
	bl	set_x11_to_Var_LS_Word_Address // (Factor1)
	bl	set_x12_to_Var_LS_Word_Address // (Factor2)
	bl	set_x13_to_Var_LS_Word_Address // (Product)

	//
	// Setup x17 LSW and x18 MSW as constant value address offset
	//
	bl set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	mov	x17, x9			// save LSW offset in x17
	bl set_x9_to_Int_MS_Word_Addr_Offset
	mov	x18, x9			// save MSW offset in x18
	mov	x9, #0			// x9 value was temporary

	// ==============================================
	// Internal function for matrix multiplicaiton
	// using processor 64bit x 64 bit --> 128 bit
	//
	// Assume registers x0 to x18 are NOT preserved
	//
	bl	_internal_matrix_multiply
	//
	// ===============================================

	//
	// Move result back to ACC
	//
	mov	x1, HAND_WORKA
	mov	x2, HAND_ACC
	bl	CopyVariable

/* ------------------ NEW BIT ALIGNMENT --- BROKEN!!! ---------
	//
	// Restore Factor1 and Factor2 to correct position
	// This may not be necessary and possibly removed.
	//
	mov	x1, HAND_ACC
	ldr	x0, [sp, PostMultShift1]
	bl	RightNBits
	mov	x1, HAND_OPR
	ldr	x0, [sp, PostMultShift2]
	bl	RightNBits

	//
	// Align bits for proper decimal point
	//

	ldr	x4, =IntWSize
	ldr	x4, [x4]
	lsl	x4, x4, X64SHIFT4BIT	// Bit's needed for decimal separator alignment
	ldr	x0, [sp, PostMultShift3]
	subs	x0, x4, x0
	// Positive Right, negative left
	b.eq	360f
	b.mi	350f
	mov	x1, HAND_ACC
	bl	RightNBits
	b.al	360f
350:
	sub	x0, xzr, x0		// 2's TwosCompliment
	mov	x1, HAND_ACC
	bl	LeftNBits
360:
*/

// ------ RESTORE OLD WAY TEMPORARILY ---------
	// Align bits for proper decimal point
	ldr	x0, [sp, PostMultShift3]
	mov	x1, HAND_ACC
	bl	LeftNBits
// ----------END OLD WAY ----------------------


	//
	// Check sign flag and 2's compliment if needed
	//
	ldr	x0, [sp, MultSignFlag]
	tst	x0, #1			// check sign bit
	b.eq	400f
	mov	x1, HAND_ACC
	mov	x2, HAND_ACC
	bl	TwosCompliment
400:
WordMultiplicationExit:
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


MultErrMsg1:	.asciz	"WordMultiplication: Error: Overlow (number too big)"
MultErrMsg4:	.asciz	"WordMultiplication: Error: Bit alignment error"
	.align 4

// -------------------------------------------------------
// Note: Used by WordMultiplication and Reciprocal
// -------------------------------------------------------
//
// DO NOT CALL DIRECTLY This is an internal function.
//
//     * * * * * * *
//   * * * The product variable MUST be set to zero before calling this procedure
// * * * * * * *
//
// If one of the factors is a small integer, it should be Factor1 at x11 address.
//
// Registers are NOT preserved.
//
// On entry, these are treated as constants
//	x11 - Factor1 LS Word Address
//	x12 - Factor2 LS Word Address
//	x13 - Product LS Word Address
//      x17 - L.S. word address offset
//	x18 - M.S. word address offset
//
// Local variables:
//	x5  - Holds under range word
//	x6  - Under range pseudo variable (for migrate carry)
//	x7  - (Factor1) Loop-1 Index
//      x14 - (Factor2) Loop-1 Index
//      x8  - (Factor2) Loop-2 Index
//	x15 - (Product) Loop-2 Index
//	x10 - (Product) Loop-3 Index
//	x9  - (Product-1W) This is X10 - 1 word (8 byte)
//
// Scratch variables
//	x0 argument
//	x1 multiply argument
//	x2 multiply argument
//	x3 multiply argument
//	x4 multiply argument

// ----------------------------------------
// Setup for 64 bit word multiplication
//
//  Pseudo Code showing indexing loops
//
//  x17(LSWOfst)-->x7
//  x18(MSWOfst) -->x14
//  Loop1
//      x14->x8
//      x17(LSWOfst) + (1word)->x15
//      Loop2
//          x15         -> x9  (low result)
//	    x15 + 1Word -> x10 (high result)
//           Multiply [x7]*[x8]
//           Add LSW --> [x9] and save CF
//             or LSW --> x5 if under range, and save CF
//           Add MSW --> [x10]
//             Loop3B
//		INC x10 (Exit loop 3?)
//		Add Carry Flag --> [x10]
//             End-Loop3B
//           Inc x15
//           Inc x8 (Exit Loop2?)
//      End-Loop2
//      DEC x14
//      INC x7 (Exit Loop1?)
//  End-Loop1
//
//
//
//  Trace 8 word loop index values
// .set	INT_WSIZE, 	0x2
// .set	FCT_WSIZE, 	0x10
// .set	GUARDWORDS,	4

//
// Int MS Word Addr Ofst: 0x0000000000000088 136
// Int LS Word Addr Ofst: 0x0000000000000080 128
// Fct MS Word Addr Ofst: 0x0000000000000078 120
// Fct LS Word Addr Ofst: 0x0000000000000040 64 (Static)
// Fct LS Word Addr Ofst: 0x0000000000000040 64 (Optimized)
// Var LS Word Addr Ofst: 0x0000000000000000 0

//
// Trace:  (1/7) * (1/7)
//
// x7=72
// x8=128 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136

// x7=80
// x8=120 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136

// x7=88
// x8=112 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136

// x7=96
// x8=104 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136

// x7=104
// x8=96 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136

// x7=112
// x8=88 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=104 x10=112 cf=120 cf=128 cf=136

// x7=120
// x8=80 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=88 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=104 x10=112 cf=120 cf=128 cf=136
// x8=136 x9=112 x10=120 cf=128 cf=136

// x7=128
// x8=72 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=80 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=88 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=104 x10=112 cf=120 cf=128 cf=136
// x8=128 x9=112 x10=120 cf=128 cf=136
// x8=136 x9=120 x10=128 cf=136

// x7=136
// x8=64 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=72 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=80 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=88 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=104 x10=112 cf=120 cf=128 cf=136
// x8=120 x9=112 x10=120 cf=128 cf=136
// x8=128 x9=120 x10=128 cf=136
// x8=136 x9=128 x10=136

//
//---------------------------------------------------------------------------------------------------------
//

// .set MULTTRACE, 1
_internal_matrix_multiply:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]

	cmp	x11, x13		// Product variable must not be same as factor variable
	beq	10f
	cmp	x12, x13		// Product variable must not be same as factor variable
	beq	10f
	b.al	20f

	// Fatal error
10:
	ldr	x0, =MatMultErrMsg1	// Error message pointer
	mov	x1, #834		// 12 bit error code
	b	FatalError
20:
	mov	x6, #0			// Under range pseudo variable
	//
	// Init for preloop
	//
	mov	x7, x17			// (Factor1 Loop-1 Index), init to LSW Address Offset
	mov	x14, x18		// (Factor2 Loop-1 Index), init to MSW address pointer

//---------------
//  Pre-Loop 0
//---------------
	//
	// The purpose of the pre-loop is to save time in the case where Factor1
	// contains many zero words on the right (least significant) side of the
	// variable. When these are multiplied, the result would be zero, so
	// the range of valid index values can be reduced.
	// The index pointer for Factor1 is incremented left until a zon-zero word is found.
	// For each increment of the Factor1 index, the Factor2 index is
	// decremented in the opposite direcction.
	//
pre_loop_0:
	ldr	x0, [x11,x7]		// (Factor1) Check word for non-zero value
	cbnz	x0, mult_loop_1		// Non-zero? exit loop, begin multipications
	//
	// Decrement index and loop
	//
	sub	x14, x14, BYTE_PER_WORD	// (Factor2 loop-1 index) decrement (MS-->LS) ( will init --> x8 loop 2)
	add	x7, x7, BYTE_PER_WORD	// (Factor1 loop-1 index) inc (LS-->MS)
	cmp	x18, x7 		// x7 above top word? (MSW - x7)
	b.hs	pre_loop_0		// higher or same (C==1)

	// Should not have fallen through if parent function performed zero check.
	// Fatal error
	ldr	x0, =MatMultErrMsg1	// Error message pointer
	mov	x1, #834		// 12 bit error code
	b	FatalError

//---------------
//  L O O P - 1
//---------------
mult_loop_1:

.ifdef MULTTRACE
// - - - - Trace Code  - - - -
	bl	CROut
	mov	x0, #'x'
	bl	CharOut
	mov	x0, #'7'
	bl	CharOut
	mov	x0, #'='
	bl	CharOut
	mov	x0, x7
	bl	PrintWordB10
	mov	x0, #' '
	bl	CharOut
.endif
// - - - - - - - - - - - - - -
	//
	// Setup x8 to index input words from (Factor2) for multiplicatioon
	//
	mov	x8, x14			// (Factor2 Loop-2 index), init x8 (from loop-1 x14)
	mov	x15, x17		// (Product Loop-2 index), init x15 (from LSWOfset for --> init x10)

	// options to align
//	add	x15, x15, BYTE_PER_WORD
 	sub	x15, x15, BYTE_PER_WORD
//
//---------------
//  L O O P - 2
//---------------
mult_loop_2:
	//
	// Initialize x10 index to store output of multiplication into WorkA
	//
	add	x10, x15, BYTE_PER_WORD	// (Product Loop 3 Index) init from loop-2 index (for loop 3 too)
	mov	x9, x15		 	// x9 is x10 - 1 word (8 byte)

// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	bl	CROut
	mov	x0, 'x'
	bl	CharOut
	mov	x0, '8'
	bl	CharOut
	mov	x0, '='
	bl	CharOut
	mov	x0, x8
	bl	PrintWordB10
	mov	x0, ' '
	bl	CharOut
.endif
// - - - - - - - - - - - - - -
	//
	//      M U L T I P L Y
	//
	// Perform ARM64 Multiplication
	// low word bit 63-0 mul x3, x2, x1      -->  x3(63-0)   = X1 * x2
	// high word bit 127-64 umulh x4, x2, x1 -->  x4(127-64) = X1 * x2
	//
	ldr	x1, [x11, x7]		// fetch next word from Factor1
	ldr	x2, [x12, x8]		// fetch next word from Factor2
	mul	x3, x1, x2		// x3 is mult product bit 63-0
	umulh	x4, x1, x2		// x4 is mult product bit 127-64
	//
	//  Save Result of multiplication
	//
	cmp	x17, x9			// Is loop-3 index (save product) below LSWord?
	b.hs	index_under_range	// LOwer than (C=0), branch
	//
	// Add Low Word to (Product)
	//
	// need shift tremporarily 1 word (TBD: better way)
	ldr	x0, [x13, x9]		// get word
	// Add LSW of multiplication (bit 63-0)
	adds	x0, x0, x3		// add mult result, carry flag impacted
	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr
	and	x6, x6, 1		// x6 = bit 0 = carry flag inverted
	str	x0, [x13, x9]		// store result
//
// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	mov	x0, 'x'
	bl	CharOut
	mov	x0, '9'
	bl	CharOut
	mov	x0, '='
	bl	CharOut
	mov	x0, x9
	bl	PrintWordB10
	mov	x0, ' '
	bl	CharOut
.endif
// - - - - - - - - - - - - - -
	b.al	index_in_range
index_under_range:
	//
	// Out of range of variable size, but need to ripple carry flag into range
	// This of x5 as pseudo varaible
	//
	adds	x5, x5, x3		// x5 holds under range word
	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr		// x0 bit 0 = inverted carry flag
	and	x6, x6, 1

// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	mov	x0, 'u'
	bl	CharOut
	mov	x0, 'r'
	bl	CharOut
	mov	x0, ' '
	bl	CharOut
.endif
// - - - - - - - - - - - - - -

index_in_range:
	//
	// Add High word
	//
	ldr	x0, [x13, x10]		// get word from (Product)
	// restore (inverted) carry
	subs	xzr, xzr, x6
	// addition
	adcs	x0, x0, x4		// Add and MSW from mult
	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr		// x6 bit 1 is inverted carry flag
	and	x6, x6, 1

	str	x0, [x13, x10]		// store result word in (Product)

// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	mov	x0, 'x'
	bl	CharOut
	mov	x0, '1'
	bl	CharOut
	mov	x0, '0'
	bl	CharOut
	mov	x0, '='
	bl	CharOut
	mov	x0, x10
	bl	PrintWordB10
	mov	x0, ' '
	bl	CharOut
.endif
// - - - - - - - - - - - - - -

//-----------------
//  L O O P - 3
//-----------------
mult_loop_3:
//
// Loop 3 is to add carry flag to higher words
//
//   Increment pointer to next work, check if done
//
	tst	x6, #1			// see if (inverted) carry flag
.ifndef MULTTRACE
	b.ne	exit_loop_3		// no carry to add (x6==1), exit loop
.endif
	add	x10, x10, BYTE_PER_WORD	// (Product Loop-3 index) increment (LS-->MS)
	cmp	x18, x10		// x18 MSW address offset
					// Check if above M.S.Word
	b.hs	100f			// Higher Same (C=1), go add carry flag
	tst	x6, #1			// Check Carry, expect C = 0 (x6 == 1)
	b.ne	exit_loop_3		// CD was not set, expected, exit loop

	// Fatal error
	ldr	x0, =MatMultErrMsg2	// Error message pointer
	mov	x1, #835		// 12 bit error code
	b	FatalError
100:
	ldr	x0, [x13, x10]		// Get word from (Product)

	// restore (inverted) carry
	subs	xzr, xzr, x6		// x6 bit 0 inverted carry flag

	// add the carry
	adcs	x0, x0, xzr

	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr
	and	x6, x6, 1		// x6 bit0 = inverted carry flag

	str	x0, [x13, x10]		// store word in (Product)

//
// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	mov	x0, 'c'
	bl	CharOut
	mov	x0, 'f'
	bl	CharOut
	mov	x0, '='
	bl	CharOut
	mov	x0, x10
	bl	PrintWordB10
	mov	x0, ' '
	bl	CharOut

.endif
// - - - - - - - - - - - - - -
//
//  Loop until add of carry not needed
//
	b.al	mult_loop_3
//---------------
//  E N D - 3
//---------------
exit_loop_3:
//
// Increment/Decrement index, check done, else loop
//
	add	x15, x15, BYTE_PER_WORD	// (Product Loop-2 index) increment (LS --> MS)
	add	x8, x8, BYTE_PER_WORD	// (Factor2 Loop-2 index) increment (LS --> MS)
	cmp	x18, x8			// x18 MSW address offset
	b.hs	mult_loop_2		// higher same (C=1)
//---------------
//  E N D - 2
//---------------

//
// Check that no CF = 1 condition is left, zero is expected
//
	tst	x6, #1			// What is the CF value?
	b.ne	110f			// CF = 0, (x6 = 1)
	// Fatal error
	ldr	x0, =MatMultErrMsg2	// Error message pointer
	mov	x1, #836		// 12 bit error code
	b	FatalError

110:
// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	bl	CROut
.endif
// - - - - - - - - - - - - - -
//
// Increment/Decrement index, check done, else loop
//
	sub	x14, x14, BYTE_PER_WORD	// (Factor2 Loop-1 Index) decrement (LS --> MS)
	add	x7, x7, BYTE_PER_WORD   // (Factor1 Loop-1 Index) increment (LS --> MS)
	cmp	x18, x7			// x18 MSW address offset
					// Is Factor1 index above MSW? if so, done looping
	b.hs	mult_loop_1		// Higher same (C=1) loop again
//---------------
//  E N D - 1
//---------------
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	add	sp, sp, #32
	ret

MatMultErrMsg1:	.asciz	"WordMultiplication: Error, pre-loop exit without non-zero word"
MatMultErrMsg2:	.asciz	"WordMultiplication: Error, CF not zero above M.S.Word"
MatMultErrMsg3:	.asciz	"WordMultiplication: Error, Product variable may not be same as any factor variable"
	.align 4
