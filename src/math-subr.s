/* ----------------------------------------------------------------
	math-subr.s
	Include file for math.s

	Created:   2021-02-19
	Last edit: 2021-02-23

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
----------------------------------------------------------------
	ClearVariable
	SetToOne
	SetToTwo
	CopyVariable
	ExchangeVariable
	TwosCompliment
	TestIfNegative
	TestIfZero
	AddVariable
	SubtractVariable
	MultiplyByTen
	DivideByTen
------------------------------------------------------------- */

	.global	ClearVariable
	.global SetToOne
	.global SetToTwo
	.global	CopyVariable
	.global	ExchangeVariable
	.global TestIfNegative
	.global TestIfZero
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

	// set x10 count number of words
	ldr	x10, =Word_Size_Static		// Word counter
	ldr	x10, [x10]		// Words in mantissa

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
	str	x17, [sp, #72]		// VAR_MSW_OFST

	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
	lsl	x17, x17, X8SHIFT3BIT

	// setup offset index to address within variable
	mov	x9, #0			// offset applied address

	// x10 count number of words
	ldr	x10, =Word_Size_Static		// For word counter
	ldr	x10, [x10]		// Words in mantissa

	// x11 pointer to variable m.s. word
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // Handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, x17	// x11 pointer at m.s. word (exponent)

	// x12 pointer to variable m.s. word
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // Index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	add	x12, x12, x17	// x12 pointer at m.s, word (exponent)
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
	ldr	x17, [sp, #72]
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
	str	x17, [sp, #72]		// VAR_MSW_OFST

	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
	lsl	x17, x17, X8SHIFT3BIT

	// setup offset index to address within variable
	mov	x9, #0			// offset applied address

	// x10 counter to number words
	ldr	x10, =Word_Size_Static		// For word counter
	ldr	x10, [x10]		// Words in mantissa
	// x11 pointer to source 1 variable
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // Handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, x17	// x11 pointer at m.s. word (exponent)
	// x12 pointer to source 2 variable
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // Index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	add	x12, x12, x17	// x12 pointer at m.s, word (exponent)
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
	ldr	x17, [sp, #72]
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
	str	x17, [sp, #32]		// VAR_MSW_OFST

	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
	lsl	x17, x17, X8SHIFT3BIT
	//
	// First check if negative, if so perform 2's compliment
	//
	// set x11 address of variable m.s. word
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, x17		// x11 pointer at m.s. word

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
	ldr	x17, [sp, #32]
	add	sp, sp, #48
	ret

/* --------------------------------------------------------------
  Test function to see if zero

  Input:    x1 = Handle Number of source 1 variable

  Output:   x0  1 if zero, 0 in non-zero

---------------------------------------------------------------- */
TestIfZero:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x1,  [sp, #16]		// input argument / scratch
	str	x9,  [sp, #24]		// word index
	str	x10, [sp, #32]		// word counter
	str	x11, [sp, #40]		// source 1 address
	str	x17, [sp, #48]		// VAR_MSW_OFST

	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
	lsl	x17, x17, X8SHIFT3BIT

	// setup offset index to address within variable
	mov	x9, #0			// offset applied to address

	// set x10 count number of words
	ldr	x10, =Word_Size_Static		// Word counter
	ldr	x10, [x10]		// Words in mantissa
	sub	x10, x10, #1		// Count - 1

	// set x11 address of variable m.s. word
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, x17	// x11 pointer at m.s. word

	bl	TestIfNegative		// test if negative using handle in x1
	cbz	x0, 50f			// Positive number from previous test
// ------------------
// Case of negative
// ------------------
	sub	x11, x11, x10, lsl X8SHIFT3BIT // X11 Pointer to l.s. word

	mov	x1, #1			// sign flag, default 1 for zero

	mov	x0, #0
	subs	x0, x0, x0		// set carry C=1  (NOT carry)

	mov	x10, GUARDWORDS		// first loop guard words
	cbz	x10, 15f		// skip if no guardwords
10:
	// loop ignoring guard words
	ldr	x0, [x11, x9]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// Done Guard words?
15:
	// set x10 count number of other (non-guard) words
	ldr	x10, =Word_Size_Static		// Word counter
	ldr	x10, [x10]		// Words in mantissa
	sub	x10, x10, GUARDWORDS	// Subtract guard words, already checked
20:
	ldr	x0, [x11, x9]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	cbz	x0, 15f			// test if word is zero
	mov	x1, #0			// clear zero flag if non zero
15:
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 20b		// Done?
	b.al	100f			// yes done exit
//
// Case of Positive
//
50:
	add	x10, x10, #1		// x10 word count  ( (count-1) + 1)
	sub	x10, x10, GUARDWORDS	// less guard words

	mov	x1, #1			// default flag 1 = zero
60:
	ldr	x0, [x11, x9]		// get word
	cbz	x0, 70f
	mov	x1, #0			// set flag for non-zero found
70:
	sub	x9, x9, BYTE_PER_WORD
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
	ldr	x9,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	ldr	x17, [sp, #48]
	add	sp, sp, #64
	ret

/* --------------------------------------------------------------
  Perform Floating Point 2's Compliment on Variable

  Input:    RSI = Handle Number of Variable

  Output:   none

  To get a 2's complement number do the following binary
  subtraction:

   000000000000
  -original num.
  ==============

TODO: Make 3 argument, S1 s2 D1

---------------------------------------------------------------- */
TwosCompliment:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x9,  [sp, #32]		// word index
	str	x10, [sp, #40]		// word counter
	str	x11, [sp, #48]		// source 1 address
	str	x17, [sp, #56]		// VAR_MSW_OFST

	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
	lsl	x17, x17, X8SHIFT3BIT

	// setup offset index to address within variable
	mov	x9, #0

	// set x10 to count of words -1
	ldr	x10, =Word_Size_Static		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)

	// x11 pointer to variable
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // (handle * 8 bit)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, x17	// x11 pointer to m.s. word
	sub	x11, x11, x10, lsl X8SHIFT3BIT // X11 Pointer to l.s. word

	// First iteration does not subtract carry
	ldr	x0, [x11, x9]		// x0 is first word
	subs	x0, xzr, x0		// subtract register from zero (flags set)
	str	x0, [x11, x9]		// Store shifted word
	add	x9, x9, BYTE_PER_WORD	// increment word pointer (no change in flags)
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x0, [x11, x9]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	str	x0, [x11, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, BYTE_PER_WORD	// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x9,  [sp, #32]
	ldr	x10, [sp, #40]
	ldr	x11, [sp, #48]
	ldr	x17, [sp, #56]
	add	sp, sp, #64
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

	// set x10 to count of words -1
	ldr	x10, =Word_Size_Static	// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	lsl	x10, x10, #2		// Multiply * 2 to address 32 bit word size

	mov	x12, #10		// constant value, (multiply by 10 from register)
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

   Input:   x1 = Variablel Handle

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
	lsl	x10, x10, #2		// Multiply two word32 per word64
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
