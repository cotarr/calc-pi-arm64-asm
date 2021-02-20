/* ----------------------------------------------------------------
	math-subr.s
	Include file for math.s

	Created:   2021-02-19
	Last edit: 2021-02-19

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
	AddMantissa
------------------------------------------------------------- */

	.global	ClearVariable
	.global SetToOne
	.global SetToTwo
	.global	CopyVariable
	.global	ExchangeVariable
	.global	TwosCompliment
	.global	AddMantissa

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
	str	x9,  [sp, #32]		// word index
	str	x10, [sp, #40]		// word counter
	str	x11, [sp, #48]		// source 1 address

	// setup offset index to address within variable
	mov	x9, #0			// offset applied to l.s. word

	// set x10 count number of words
	ldr	x10, =No_Word		// Word counter
	ldr	x10, [x10]		// Words in mantissa

	// set x11 address of variable m.s. word
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word
10:
	// Perform the fill using 64 bit words
	str	xzr, [x11, x9]
	sub	x9, x9, #BYTE_PER_WORD
	sub	x10, x10, #1		// Decrement counter
	cbnz	x10, 10b		// Done?

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x9,  [sp, #32]
	ldr	x10, [sp, #40]
	ldr	x11, [sp, #48]
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

	bl	ClearVariable		// Handle in x1 preserved

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word
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

	bl	ClearVariable		// Handle in x1 preserved

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word
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
	mov	x9, #0			// offset applied to l.s. word

	// x10 count number of words
	ldr	x10, =No_Word		// For word counter
	ldr	x10, [x10]		// Words in mantissa

	// x11 pointer to variable m.s. word
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// Handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word (exponent)

	// x12 pointer to variable m.s. word
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl #3	// Index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	add	x12, x12, #VAR_MSW_OFST	// x12 pointer at m.s, word (exponent)
10:
	// Perform the copy using 64 bit words
	ldr	x1, [x11, x9]
	str	x1, [x12, x9]
	sub	x9, x9, #BYTE_PER_WORD
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
	mov	x9, #0			// offset applied to l.s. word

	// x10 counter to number words
	ldr	x10, =No_Word		// For word counter
	ldr	x10, [x10]		// Words in mantissa
	// x11 pointer to source 1 variable
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// Handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word (exponent)
	// x12 pointer to source 2 variable
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl #3	// Index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	add	x12, x12, #VAR_MSW_OFST	// x12 pointer at m.s, word (exponent)
10:
	// Perform the word exchange using 64 bit words
	ldr	x1, [x11, x9]
	ldr	x2, [x12, x9]
	str	x1, [x12, x9]
	str	x2, [x11, x9]
	sub	x9, x9, #BYTE_PER_WORD
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
  Perform Floating Point 2's Compliment on Variable

  Input:    RSI = Handle Number of Variable

  Output:   none

  To get a 2's complement number do the following binary
  subtraction:

   000000000000
  -original num.
  ==============

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

	// setup offset index to address within variable
	mov	x9, #0

	// set x10 to count of words -1
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)

	// x11 pointer to variable
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// (handle * 8 bit)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer to m.s. word
	sub	x11, x11, x10, lsl #3	// X11 Pointer to l.s. word

	// First iteration does not subtract carry
	ldr	x0, [x11, x9]		// x0 is first word
	subs	x0, xzr, x0		// subtract register from zero (flags set)
	str	x0, [x11, x9]		// Store shifted word
	add	x9, x9, #BYTE_PER_WORD	// increment word pointer (no change in flags)
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x0, [x11, x9]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	str	x0, [x11, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, #BYTE_PER_WORD	// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x9,  [sp, #32]
	ldr	x10, [sp, #40]
	ldr	x11, [sp, #48]
	add	sp, sp, #64
	ret
/* --------------------------------------------------------------
  Perform Floating Point addition of 3 variables

  Input:    x1 = Handle Number of source 1 variable
            x2 = Handle number of source 2 variable
	    x3 = Handle number of destination variable
  Output:   none


---------------------------------------------------------------- */
AddMantissa:
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

	// setup offset index to address within variable
	mov	x9, #0			// offset applied to l.s. word

	// xet x10 to number of words - 1
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)

	// set variable pointers x11 souce 1
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// (handle * 8 bit)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer to m.s. word
	sub	x11, x11, x10, lsl #3	// X11 Pointer to l.s. word

	// set variable pointer x12 source 2
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl #3	// (handle * 8 bit)
	ldr	x12, [x12]		// x12 pointer to variable address
	add	x12, x12, #VAR_MSW_OFST	// x12 pointer to m.s. word
	sub	x12, x12, x10, lsl #3	// x12 Pointer to l.s. word

	// set variable pointer x13 destination
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl #3	// (handle * 8 bit)
	ldr	x13, [x13]		// x13 pointer to variable address
	add	x13, x13, #VAR_MSW_OFST	// x13 pointer to m.s. word
	sub	x13, x13, x10, lsl #3	// x13 Pointer to l.s. word

	// First iteration does not add carry
	ldr	x1, [x11, x9]		// Source 1 word
	ldr	x2, [x12, x9]		// source 2 word
	adds	x3, x1, x2		// add register from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	add	x9, x9, #BYTE_PER_WORD	// increment word pointer
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x1, [x11, x9]		// x0 is first word
	ldr	x2, [x12, x9]		// x0 is first word
	adcs	x3, x1, x2		// subtract register and NOT carry from zero (flags set)
	str	x3, [x13, x9]		// Store shifted word
	// increment and loop
	add	x9, x9, #BYTE_PER_WORD	// increment word offset pointer
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
