/* ----------------------------------------------------------------
	math-mult.s

	Floating point multiplicatoin routines

	Created:   2021-02-27
	Last edit: 2021-03-01

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
	b	WordMultiplication

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
	sub	sp, sp, #192		// Reserve 24 words
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
	.set MultSignFlag,  168		// save sign flag during main compute
	.set PostMultShift, 176		// save bit alignment for end

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
	// Save sign in bit 0 of x8 for two's compliment later
	//
	//
	mov	x8, #0			// temporary sign flag
	// Check Dividend for negative sign
	mov	x1, HAND_OPR
	bl	TestIfNegative
	cbz	x0, 120f

	eor	x8, x8, #1		// result sign flag

	mov	x1, HAND_OPR
	mov	x2, HAND_OPR
	bl	TwosCompliment
120:
	// Check divisor for negative sign
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

	// WORKA and WORKB will be used in the long division
	//
	mov	x1, HAND_WORKA
	bl	ClearVariable


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
	ldr	x0, =Mult_Err_Msg3	// Error message pointer
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
	ldr	x0, =Mult_Err_Msg4	// Error message pointer
	mov	x1, #677		// 12 bit error code
	b	FatalError
195:

// any remiaining bits to shift do after multiplicaiton done
str	x4, [sp, PostMultShift]



//--------------------------------------------------------------------
	//
	// Setup address pointers x11,x12,x13,x14(these will not change)
	//
	mov	x1, HAND_ACC
	mov	x2, HAND_OPR
	mov	x3, HAND_WORKA
	bl	set_x11_to_Var_LS_Word_Address
	bl	set_x12_to_Var_LS_Word_Address
	bl	set_x13_to_Var_LS_Word_Address

//
//----------------------------------------
// Setup for 64 bit word multiplication
//
//  Pseudo Code showing indexing loops
//
//  L.S. Word Address Offset --> x17
//  M.S. Word Address Offset --> x18

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
//
// Int MS Word Addr Ofst: 0x0000000000000088 136
// Int LS Word Addr Ofst: 0x0000000000000080 128
// Fct LS Word Addr Ofst: 0x0000000000000078 120
// Fct LS Word Addr Ofst: 0x0000000000000040 64 (Static)
//
// Trace:  (1/7) * (1/7)
//
// x7=64
// x8=136 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
//
// x7=72
// x8=128 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
//
// x7=80
// x8=120 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
//
// x7=88
// x8=112 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
//
// x7=96
// x8=104 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
//
// x7=104
// x8=96 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
//
// x7=112
// x8=88 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=136 x9=104 x10=112 cf=120 cf=128 cf=136
//
// x7=120
// x8=80 ur x10=64 cf=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=88 ur x10=72 cf=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=96 x9=72 x10=80 cf=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=104 x9=80 x10=88 cf=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=112 x9=88 x10=96 cf=104 cf=112 cf=120 cf=128 cf=136
// x8=120 x9=96 x10=104 cf=112 cf=120 cf=128 cf=136
// x8=128 x9=104 x10=112 cf=120 cf=128 cf=136
// x8=136 x9=112 x10=120 cf=128 cf=136
//
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
//
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
//www
	//
	// Setup X18 LSW and X18 MSW as constant value address offset
	//
	bl set_x9_to_Fct_LS_Word_Addr_Offset_Static
	mov	x17, x9			// save LSW offset in x17
	bl set_x9_to_Int_MS_Word_Addr_Offset
	mov	x18, x9			// save MSW offset in x18
	mov	x9, #0			// x9 value was temporary

	mov	x6, #0			// Under range pseudo variable
	//
	// Init for preloop
	//
	mov	x7, x17			// (ACC Loop-1 Index), init to LSW Address Offset
	mov	x14, x18		// (OPR Loop-1 Index), init to MSW address pointer

//---------------
//  Pre-Loop 0
//---------------

pre_loop_0:
	ldr	x0, [x11,x7]		// (ACC) Check word
	cbnz	x0, mult_loop_1		// Non-zero? exit loop, begin multipications
//
// Decrement index and loop
//
	sub	x14, x14, BYTE_PER_WORD	// (OPR loop-1 index) decrement (MS-->LS) ( will init --> x8 loop 2)
	add	x7, x7, BYTE_PER_WORD	// (ACC loop-1 index) inc (LS-->MS)
	cmp	x18, x7 		// x7 above top word? (MSW - x7)
	b.hs	pre_loop_0		// higher or same (C==1)

// Should not have fallen through
	// Fatal error
	ldr	x0, =Mult_Err_Msg1		// Error message pointer
	mov	x1, #834		// 12 bit error code
	b	FatalError

//---------------
//  L O O P - 1
//---------------
mult_loop_1:
//
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
// Setup x8 to index input words from OPr for multiplicatioon
//
	mov	x8, x14			// (OPR   Loop-2 index), init x8 (from loop-1 x14)
	mov	x15, x17		// (WORKA Loop-2 index), init x15 (from LSWOfset for --> init x10)

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
	add	x10, x15, BYTE_PER_WORD			// (WORKA Loop 3 Index) init from loop-2 index (for loop 3 too)
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
// Perform ARM64 Multiplication
// low word bit 63-0 mul x3, x2, x1      -->  x3(63-0)   = X1 * x2
// high word bit 127-64 umulh x4, x2, x1 -->  x4(127-64) = X1 * x2
//
	ldr	x1, [x11, x7]		// fetch next word from ACC
	ldr	x2, [x12, x8]		// fetch next word from OPR
	mul	x3, x1, x2		// x3 is mult product bit 63-0
	umulh	x4, x1, x2		// x4 is mult product bit 127-64

//	mov	rbx, [x11+x7]
//	mov	rax, [x12+x8]
//	mov	rdx, 0
//	mul	rbx	; Multiply RAX * RBX = RDX:RAX
//
//  Save Result of multiplication
//

//	mov	x0, x10
//	bl	CROut
//	bl	PrintWordB10
//	bl	CROut

	cmp	x17, x9			// Is loop-3 index (save product) below LSWord?
	b.hs	index_under_range	// LOwer than (C=0), branch
	//
	// Add Low Word to Work A
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
	ldr	x0, [x13, x10]		// get word from workA
	// restore (inverted) carry
	subs	xzr, xzr, x6
	// addition
	adcs	x0, x0, x4		// Add and MSW from mult
	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr		// x6 bit 1 is inverted carry flag
	and	x6, x6, 1

	str	x0, [x13, x10]		// store result word in workA

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
	add	x10, x10, BYTE_PER_WORD	// (WORKA Loop-3 index) increment (LS-->MS)
	cmp	x18, x10		// x18 MSW address offset
					// Check if above M.S.Word
	b.hs	mult_go_add		// Higher Same (C=1), go add carry flag
	tst	x6, #1			// Check Carry, expect C = 0 (x6 == 1)
	b.ne	exit_loop_3		// CD was not set, expected, exit loop

	// Fatal error
	ldr	x0, =Mult_Err_Msg2		// Error message pointer
	mov	x1, #835		// 12 bit error code
	b	FatalError

mult_go_add:
	ldr	x0, [x13, x10]		// Get word from workA

	// restore (inverted) carry
	subs	xzr, xzr, x6		// x6 bit 0 inverted carry flag

	// add the carry
	adcs	x0, x0, xzr

	// Save (inverted) carry flag in x6
	sbc	x6, xzr, xzr
	and	x6, x6, 1		// x6 bit0 = inverted carry flag

	str	x0, [x13, x10]		// store word in WORKA

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
	add	x15, x15, BYTE_PER_WORD	// (WORKA Loop-2 index) increment (LS --> MS)
	add	x8, x8, BYTE_PER_WORD	// (OPR   Loop-2 index) increment (LS --> MS)
	cmp	x18, x8			// x18 MSW address offset
	b.hs	mult_loop_2		// higher same (C=1)
//---------------
//  E N D - 2
//---------------

//
// Check that no CF = 1 condition is left, zero is expected
//
	tst	x6, #1				// What is the CF value?
	b.ne	no_carry			// CF = 0, (x6 = 1)

	// Fatal error
	ldr	x0, =Mult_Err_Msg2		// Error message pointer
	mov	x1, #836		// 12 bit error code
	b	FatalError

no_carry:
// - - - - Trace Code  - - - -
.ifdef MULTTRACE
	bl	CROut
.endif
// - - - - - - - - - - - - - -
//
// Increment/Decrement index, check done, else loop
//
	sub	x14, x14, BYTE_PER_WORD	// (OPR Loop-1 Index) decrement (LS --> MS)
	add	x7, x7, BYTE_PER_WORD   // (ACC Loop-1 Index) increment (LS --> MS)
	cmp	x18, x7			// x18 MSW address offset
					// Is ACC index above MSW? if so, done looping
	b.hs	mult_loop_1		// Higher same (C=1) loop again
//---------------
//  E N D - 1
//---------------
//
// Move result back to ACC
//
	mov	x1, HAND_WORKA
	mov	x2, HAND_ACC
	bl	CopyVariable

	//
	// Align bits for proper decimal point
	ldr	x0, [sp, PostMultShift]
	mov	x1, HAND_ACC
	bl	LeftNBits
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
	add	sp, sp, #192
	ret

Mult_Err_Msg1:	.asciz	"WordMultiplication: Error, pre-loop exit without non-zero word"
Mult_Err_Msg2:	.asciz	"WordMultiplication: Error, CF not zero above M.S.Word"
Mult_Err_Msg3:	.asciz	"WordMultiplication: Error: Overlow (number too big)"
Mult_Err_Msg4:	.asciz	"WordMultiplication: Error: Bit alignment error"
	.align 4
