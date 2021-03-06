/* ----------------------------------------------------------------
	math-subr.s
	Include file for math.s

	Created:   2021-02-19
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

	.global	ClearVariable
	.global SetToOne
	.global SetToTwo
	.global	CopyVariable
	.global	ExchangeVariable
	.global TestIfNegative
	.global TestIfZero
	.global CountLSBitsDifferent
	.global CountAbsValDifferenceBits
	.global	TwosCompliment
	.global	AddVariable
	.global	SubtractVariable
	.global	MultiplyByTen
	.global	DivideByTen

/*--------------------------------------------------------------
  Clear F.P. Variable to all zero's,

  Input:   x1 = handle number of variable

  Output:  none

--------------------------------------------------------------*/
ClearVariable:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x10, [sp, #32]		// word counter
	str	x11, [sp, #40]		// source 1 address

	bl	set_x10_to_Word_Size_Static

	// Argument in x1 is variable handle (preserved)
	bl	set_x11_to_Fct_LS_Word_Address_Static
10:
	// Perform the fill using 64 bit words
	str	xzr, [x11], BYTE_PER_WORD
	sub	x10, x10, #1		// Decrement counter
	cbnz	x10, 10b		// Done?

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	add	sp, sp, #64
	ret

/* --------------------------------------------------------------
  Set Variable to 1.0 (integer value)

  Input:   x1 = handle number of variable

  Output:  none

------------------------------------------------------------- */
SetToOne:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// Handle number of variable (Argument)
	str	x11,  [sp, #32]		// Address Pointer

	// Argument in x1 is variable handle (preserved)
	bl	ClearVariable
	bl	set_x11_to_Int_LS_Word_Address

	mov	x0, #1
	str	x0, [x11]		// Place 1 in top word

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x11,  [sp, #32]
	add	sp, sp, #64
	ret

/* --------------------------------------------------------------
  Set Variable to 2.0 (integer value)

  Input:   x1 = handle number of variable

  Output:  none

------------------------------------------------------------- */
SetToTwo:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// Handle number of variable (Argument)
	str	x11,  [sp, #32]		// Address Pointer

	// Argument in x1 is variable handle (preserved)
	bl	ClearVariable
	bl	set_x11_to_Int_LS_Word_Address

	mov	x0, #2
	str	x0, [x11]		// Place 2 in top word

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x11,  [sp, #32]
	add	sp, sp, #64
	ret

/*--------------------------------------------------------------
  Copy F.P. Variable

  Input:   x1 = Source - handle number of variable
           x2 = Destination - handle number of variable

  Output:  none

--------------------------------------------------------------*/
CopyVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x9,  [sp, #40]		// word index
	str	x10, [sp, #48]		// word counter
	str	x11, [sp, #56]		// source 1 address
	str	x12, [sp, #64]		// source 2 address

	// setup offset index to address within variable
	bl	set_x9_to_Int_MS_Word_Addr_Offset

	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Var_LS_Word_Address

	// Argument x2 contains variable handle number
	bl	set_x12_to_Var_LS_Word_Address
10:
	// Perform the copy using 64 bit words
	ldr	x1, [x11, x9]
	str	x1, [x12, x9]
	sub	x9, x9, BYTE_PER_WORD
	sub	x10, x10, #1
	cbnz	x10, 10b

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	add	sp, sp, #80
	ret

/*--------------------------------------------------------------
  Exchange F.P. Variable

  Input:   x1 = Source - handle number of variable
           x2 = Destination - handle number of variable

  Output:  none

--------------------------------------------------------------*/
ExchangeVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x9,  [sp, #40]		// word index
	str	x10, [sp, #48]		// word counter
	str	x11, [sp, #56]		// source 1 address
	str	x12, [sp, #64]		// source 2 address

	// setup offset index to address within variable
	bl	set_x9_to_Int_MS_Word_Addr_Offset

	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Var_LS_Word_Address

	// Argument x2 contains variable handle number
	bl	set_x12_to_Var_LS_Word_Address

10:
	// Perform the word exchange using 64 bit words
	ldr	x1, [x11, x9]
	ldr	x2, [x12, x9]
	str	x1, [x12, x9]
	str	x2, [x11, x9]
	sub	x9, x9, BYTE_PER_WORD
	sub	x10, x10, #1
	cbnz	x10, 10b

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]

	add	sp, sp, #80
	ret


/* --------------------------------------------------------------
  Test function to see if negative (top bit = 1)

  Input:    x1 = Handle Number of source 1 variable

  Output:   x0 = 0 if positive, 1 if negative

---------------------------------------------------------------- */
TestIfNegative:
	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x1,  [sp, #16]		// input argument / scratch
	str	x11, [sp, #24]		// source 1 address

	// Argument x1 variable handle number
	bl	set_x11_to_Int_MS_Word_Address

	ldr	x1, =Word8000
	ldr	x1, [x1]
	ldr	x0, [x11]		// get M.S. word
	tst	x0, x1			// text with AND 0x8000000000000

	// Set return values
	mov	x0, #0			// Default 0 for positive
	b.eq	10f			// is it positive, skip?
	mov	x0, #1			// No, set 1 for negative
10:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x1,  [sp, #16]
	ldr	x11, [sp, #24]
	add	sp, sp, #48
	ret


// --------------------------------------------------------------
//  Test function to see if zero
//
//  Input:    x1 = Handle Number of source 1 variable
//
//  Output:   x0  1 if zero, 0 in non-zero
//
// TODO: create function for "nearly zero" to ignore roundoff bits
//----------------------------------------------------------------
TestIfZero:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x1,  [sp, #16]		// input argument / scratch
	str	x10, [sp, #24]		// word counter
	str	x11, [sp, #32]		// source 1 address

	// Argument x1 Variable handle number
	bl	TestIfNegative		// test if negative using handle in x1
	cbz	x0, 50f			// Positive number from previous test
// ------------------
// Case of negative
// ------------------
	//
	// This does an "on the fly" 2's compliment
	//
	// Argument x1 contains variable handle
	bl	set_x11_to_Fct_LS_Word_Address_Static

	bl	set_x10_to_Word_Size_Static

	mov	x1, #1			// sign flag, default 1 for zero

	mov	x0, #0
	subs	x0, x0, x0		// set carry C=1  (NOT carry)

20:
	ldr	x0, [x11], BYTE_PER_WORD // x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	cbz	x0, 25f			// test if word is zero
	mov	x1, #0			// clear zero flag if non zero
25:
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 20b		// Done?
	b.al	100f			// yes done exit
// --------------------
// Case of Positive
// --------------------
50:
	bl	set_x10_to_Word_Size_Static

	// Argument x1 variable handl enumber
	bl	set_x11_to_Fct_LS_Word_Address_Static

	mov	x1, #1			// default flag 1 = zero
60:
	ldr	x0, [x11], BYTE_PER_WORD // get word
	cbz	x0, 70f
	mov	x1, #0			// set flag for non-zero found
70:
	sub	x10, x10, #1		// Decrement counter
	cbnz	x10, 60b		// Done?
//
// Done
//
100:
	mov	x0, x1			// return x0 result 0=positive 1=negative

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x1,  [sp, #16]
	ldr	x10, [sp, #24]
	ldr	x11, [sp, #32]
	add	sp, sp, #64
	ret

// --------------------------------------------------------------
//  Count number of bits that are different on the
//       least significant side of the word
//
//  Input:    x1 = Handle Number of source1 variable
//  Input:    x2 = Handle Number of source2 variable
//
//  Output:   x0  Count of bits different
//
//  Note: this is literal so the following round off would be issue
//  as they are really only different 1 bit
//  0000200000000000000000
//  00001FFFFFFFFFFFFFFFFF
//----------------------------------------------------------------

CountLSBitsDifferent:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x9,  [sp, #40]		// word index
	str	x10, [sp, #48]		// word counter
	str	x11, [sp, #56]		// source 1 address
	str	x12, [sp, #64]		// source 1 address
	str	x17, [sp, #72]		// source 1 address
	str	x18, [sp, #80]		// source 1 address

	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle
	bl	set_x11_to_Int_MS_Word_Address

	// Argument x2 contains variable handle
	bl	set_x12_to_Int_MS_Word_Address

	mov	x18, BIT_PER_WORD
	mov	x17, #0			// initialize bit counter
	//
	// Part 1, check 64 bit words the same
	//
10:
	ldr	x0, [x11], -BYTE_PER_WORD
	ldr	x2, [x12], -BYTE_PER_WORD
	cmp	x0, x2
	b.ne	100f
	add	x17, x17, x18		// add bits per word (64)
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 10b
	b.al	200f
100:
	//
	// Part 2 check bits the same
	//
	mov	x10, BIT_PER_WORD	// loop counter <-- number of bits
	add	x17, x17, BIT_PER_WORD	// (assume all bits same then subtract each)
110:
	sub	x17, x17, #1		// subtract 1 bit as same
	lsr	x0, x0, #1
	lsr	x1, x1, #1
	cmp	x0, x1
	b.eq	200f
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 110b
200:
	//
	// Subtract (total bits) - (same bits) to get different bits
	//
	bl	set_x10_to_Word_Size_Static
	lsl	x10, x10, X64SHIFT4BIT	// bits per variable
	sub	x0, x10, x17		// x0 = bits different
	//
	// Return with result in x0
	//

999:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	// x0 is return value  <-- return
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	ldr	x17, [sp, #72]
	ldr	x18, [sp, #80]
	add	sp, sp, #96
	ret


// --------------------------------------------------------------
//  Count LS difference bits after absolute value subtraction
//
//  Input:    x1 = Handle Number of source1 variable
//  Input:    x2 = Handle Number of source2 variable
//
//  Output:   x0  Count of bits different
//
// Subtract Source1 - Source2
// If negative, then
// Subtract Source2 - Source1
//
// Then counts bits non-zero on right (L.S. side)
//----------------------------------------------------------------
CountAbsValDifferenceBits:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x8,  [sp, #40]		// saved offset index
	str	x9,  [sp, #48]		// offset index
	str	x10, [sp, #56]		// wcounter
	str	x11, [sp, #64]		// source 1 address
	str	x12, [sp, #72]		// source 2 address
	str	x17, [sp, #80]		// bit counter
	str	x18, [sp, #88]		// bit counter remembered


	// Argument x1 contains variable handle
	bl	set_x11_to_Var_LS_Word_Address

	// Argument x2 contains variable handle
	bl	set_x12_to_Var_LS_Word_Address

	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	bl	set_x10_to_Word_Size_Static
	mov	x17, #0			// init counters
	mov	x18, #0			// init counters

	// set carry C=1  (NOT carry) for subtraction
	mov	x0, #0
	subs	x0, x0, x0
10:
	ldr	x1, [x11, x9]		// Source 1
	ldr	x2, [x12, x9]		// source 2
	sbcs	x0, x1, x2		// subtract register and NOT carry from zero (flags set)
	b.eq	20f			// This is flag from "sbcs"
	mov	x18, x17		// Total difference bits
	mov	x8, x0			// save highest difference word
20:
	// increment and loop
	add	x17, x17, BIT_PER_WORD	// running total of bits checked
	add	x9, x9, BYTE_PER_WORD	// increment word offset pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back
	//
	// was result negative, then reverse order of subtraction
	//
	add	x0, xzr, x0		// was it negative?
	b.mi	500f

	b.al	800f

500:
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	bl	set_x10_to_Word_Size_Static
	mov	x17, #0			// init counters
	mov	x18, #0			// init counters

	// set carry C=1  (NOT carry) for subtraction
	mov	x0, #0
	subs	x0, x0, x0
510:
	ldr	x1, [x12, x9]		// source 2
	ldr	x2, [x11, x9]		// Source 1
	sbcs	x0, x1, x2		// subtract register and NOT carry from zero (flags set)
	b.eq	520f			// This is flag from "sbcs"
	mov	x18, x17		// Total difference bits
	mov	x8, x0			// save highest difference word
520:
	// increment and loop
	add	x17, x17, BIT_PER_WORD	// running total of bits checked
	add	x9, x9, BYTE_PER_WORD	// increment word offset pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 510b		// non-zero, loop back
	//
	// Flag shoud still be set from subtraction
	// was result negative, then reverse order of subtraction
	//
800:
	//
	// x8 contains last difference word (non-zero)
	//
	mov	x10, BIT_PER_WORD	// counter
810:
	add	x18, x18, #1		// add diffrent bit
	lsr	x8, x8, #1		// shift 1 bit
	cbz	x8, 850f		// all bits now zero, leave with count
	sub	x10, x10, #1
	cbnz	x10, 810b
850:

999:
	mov	x0, x18			// return result

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	// x0 returns result
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x17, [sp, #80]
	ldr	x18, [sp, #88]
	add	sp, sp, #128
	ret

/* --------------------------------------------------------------
  Perform Floating Point 2's Compliment on Variable

  Input:    x1 = Source Handle Number of Variable
            x2 = Destination Handle Number ff Varaible

  Output:   none

  To get a 2's complement number do the following binary
  subtraction:

   000000000000
  -original num.
  ==============

TODO: Make 3 argument, S1 s2 D1

---------------------------------------------------------------- */
TwosCompliment:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x9,  [sp, #40]		// word index
	str	x10, [sp, #48]		// word counter
	str	x11, [sp, #56]		// source 1 address
	str	x12, [sp, #64]		// source 1 address

	bl	set_x9_to_Var_LS_Word_Addr_Offset

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 contains variable handle
	bl	set_x11_to_Fct_LS_Word_Address_Static

	// Argument x2 contains variable handle
	bl	set_x12_to_Fct_LS_Word_Address_Static

	// First iteration does not subtract carry
	ldr	x0, [x11, x9]		// x0 is first word
	subs	x0, xzr, x0		// subtract register from zero (flags set)
	str	x0, [x12, x9]		// Store shifted word
	add	x9, x9, BYTE_PER_WORD	// increment word pointer (no change in flags)
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x0, [x11, x9]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	str	x0, [x12, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	add	sp, sp, #80
	ret
/* --------------------------------------------------------------
  Perform Floating Point addition of 3 variables

  Input:    x1 = Handle Number of source 1 variable
            x2 = Handle number of source 2 variable
	    x3 = Handle number of destination variable
  Output:   none
---------------------------------------------------------------- */
AddVariable:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x3,  [sp, #40]		// input argument / scratch
	str	x9,  [sp, #48]		// word index
	str	x10, [sp, #56]		// word counter
	str	x11, [sp, #64]		// source 1 address
	str	x12, [sp, #72]		// source 2 address
	str	x13, [sp, #80]		// desitination address

	bl	set_x9_to_Var_LS_Word_Addr_Offset

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 contains variable handle
	bl	set_x11_to_Fct_LS_Word_Address_Static

	// Argument x2 contains variable handle
	bl	set_x12_to_Fct_LS_Word_Address_Static

	// Argument x3 contains variable handle
	bl	set_x13_to_Fct_LS_Word_Address_Static

	// First iteration does not add carry
	ldr	x1, [x11, x9]		// Source 1 word
	ldr	x2, [x12, x9]		// source 2 word
	adds	x3, x1, x2		// add register from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x1, [x11, x9]		// x0 is first word
	ldr	x2, [x12, x9]		// x0 is first word
	adcs	x3, x1, x2		// subtract register and NOT carry from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, BYTE_PER_WORD	// increment word offset pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x13, [sp, #80]
	add	sp, sp, #96
	ret

/* --------------------------------------------------------------
  Perform Floating Point subtraction of 3 variables

  Input:    x1 = Handle Number of source 1 variable
            x2 = Handle number of source 2 variable
	    x3 = Handle number of destination variable

  Output:   none

  (3) = (1) - (2)
 ---------------------------------------------------------------- */
SubtractVariable:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x2,  [sp, #32]		// input argument / scratch
	str	x3,  [sp, #40]		// input argument / scratch
	str	x9,  [sp, #48]		// word index
	str	x10, [sp, #56]		// word counter
	str	x11, [sp, #64]		// source 1 address
	str	x12, [sp, #72]		// source 2 address
	str	x13, [sp, #80]		// desitination address

	// This is a zero value
	bl	set_x9_to_Var_LS_Word_Addr_Offset

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 contains variable handle
	bl	set_x11_to_Fct_LS_Word_Address_Static

	// Argument x2 contains variable handle
	bl	set_x12_to_Fct_LS_Word_Address_Static

	// Argument x3 contains variable handle
	bl	set_x13_to_Fct_LS_Word_Address_Static

	// First iteration does not add carry
	ldr	x1, [x11, x9]		// Source 1 word
	ldr	x2, [x12, x9]		// source 2 word
	subs	x3, x1, x2		// add register from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x1, [x11, x9]		// x0 is first word
	ldr	x2, [x12, x9]		// x0 is first word
	sbcs	x3, x1, x2		// subtract register and NOT carry from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, BYTE_PER_WORD	// increment word offset pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x13, [sp, #80]
	add	sp, sp, #96
	ret

/* --------------------------------------------------------------
   Multiply Variable by 10

   Input:   x1 = Variablel Handle

   Output:  none

   This will use multiplication with 32 bit factors to give
   a 64 bit product. It is split into data32:data32.
   The high 32 bit word is saved for next loop and added

   Memory is loaded and stored in 32 bit word size in a loop.

-------------------------------------------------------------- */
MultiplyByTen:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x4,  [sp, #48]
	str	x10, [sp, #56]
	str	x11, [sp, #64]
	str	x12, [sp, #72]

	// Argument x1 contains variable handle number
	bl	set_x11_to_Fct_LS_Word_Address_Static
	add	x11, x11, #4		// offset for half word

	// set x10 to count of words -1
	ldr	x10, =Word_Size_Static	// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	lsl	x10, x10, #1		// Multiply * 2 to address 32 bit word size

	mov	x12, #10		// constant value, (multiply by 10 from register)
	mov	x1, #0
	mov	x2, #0
	mov	x3, #0
	mov	x4, #0
	//
	// Loop back to here
	//
10:
	ldr	w1, [x11]		// Load data32 (upper bit 63-32 are zero by op)
	mul	x2, x1, x12		// multiply data32 x 10 = result64
	lsr	x4, x2, #32		// save remainder shifted to lower half
	adds	w2, w2, w3		// add previous remainder, carry flag is changed
	mov	w3, #0			// Need a zero word to add carry flag
	adc	w3, w4, w3		// Add carry to remainder
	str	w2, [x11], #4		// Store 32 bit result, increment half (32 bit) word
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 10b		// loop until all 32 bit word are processed
	//
	// Done
	//
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x4,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	add	sp, sp, #96
	ret

/* --------------------------------------------------------------
   Divide Variable by 10

   Input:   x1 = Variable Handle

   Output:  none

   Note:    Variable must be >= 0

   This will utilize 64 bit divident by 32 bit divisor
   to get 32 bit quotient and 32 bit remiander

   The each loop 32 bit remainder and 32 bit data
   is used to form the 64 bit divisor.

   Memory is loaded and stored in 32 bit word size in a loop.

-------------------------------------------------------------- */
DivideByTen:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x10, [sp, #48]
	str	x11, [sp, #56]
	str	x12, [sp, #64]

	// set x10 to (count of 32 bit half-words) -1
	ldr	x10, =Word_Size_Static	// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	lsl	x10, x10, #1		// Multiply two word32 per word64
	sub	x10, x10, #1		// Count - 1
	// Argument x1 is variable handle number
	bl	set_x11_to_Int_MS_Word_Address

	mov	x12, #10		// constant value, (divide by 10 from register)

	//
	// first division is special case, no previous remainder
	//
	ldr	w1, [x11, #4]		// Special case, get top 32 bit word into 64 bit reg
	udiv	x2, x1, x12		// x2 quot = (zero32:data32) / 10
	msub	x3, x2, x12, x1		// x3 rem  = (zero32:data32) - (quot64 * 10)
	str	w2, [x11, #4]		// save top 32 bit of top word
	//
	// Loop back to here for each operation
	//
10:
	ldr	w1, [x11]		// Load data32 (upper bit 63-32 are zero by op)
	orr	x1, x1, x3, lsl #32	// Combine remainder32:data32 with shifted OR
	udiv	x2, x1, x12		// x2 quot = (lastrem:data] / 10
	msub	x3, x2, x12, x1 	// x3 rem  = (lastrem:data) - (quot * 10)
	str	w2, [x11], #-4		// store 32 bit result, decrement address by half word (32 bit)
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 10b		// loop until all 32 bit words are processed
	//
	// Done
	//
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	add	sp, sp, #80
	ret
