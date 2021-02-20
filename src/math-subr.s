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
------------------------------------------------------------- */

	.global	ClearVariable
	.global SetToOne
	.global SetToTwo
	.global	CopyVariable
	.global	ExchangeVariable
	.global	TwosCompliment

/*--------------------------------------------------------------
  Clear F.P. Variable to all zero's,

  Input:   x1 = handle number of variable

  Output:  none

--------------------------------------------------------------*/
ClearVariable:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// Handle number of variable (Argument)
	str	x10,  [sp, #32]		// Counter
	str	x11,  [sp, #40]		// Address Pointer

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x1, lsl #3	// handle --> index into table
	ldr	x11, [x10]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word
	ldr	x10, =No_Word		// Word counter
	ldr	x10, [x10]		// Words in mantissa
10:
	// Perform the fill using 64 bit words
	str	xzr, [x11], #-BYTE_PER_WORD
	subs	x10, x10, #1		// Decrement counter
	b.ne	10b			// Done?

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10,  [sp, #32]
	ldr	x11,  [sp, #40]
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
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// Handle number of source variable (Argument)
	str	x2,  [sp, #32]		// Handle number of destination variable (Argument)
	str	x10,  [sp, #40]		// Counter
	str	x11,  [sp, #48]		// Source Address Pointer
	str	x12,  [sp, #56]		// Destination Address Pointer

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x1, lsl #3	// Handle --> index into table
	ldr	x11, [x10]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word (exponent)

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x2, lsl #3	// Index into table
	ldr	x12, [x10]		// x12 pointer to variable address
	add	x12, x12, #VAR_MSW_OFST	// x12 pointer at n.s, word (exponent)

	ldr	x10, =No_Word		// For word counter
	ldr	x10, [x10]		// Words in mantissa
10:
	// Perform the copy using 64 bit words
	ldr	x0, [x11], #-BYTE_PER_WORD
	str	x0, [x12], #-BYTE_PER_WORD
	subs	x10, x10, #1
	bne	10b

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x10,  [sp, #40]
	ldr	x11,  [sp, #48]
	ldr	x11,  [sp, #56]
	add	sp, sp, #64
	ret

/*--------------------------------------------------------------
  Exchange F.P. Variable

  Input:   x1 = Source - handle number of variable
           x2 = Destination - handle number of variable

  Output:  none

--------------------------------------------------------------*/
ExchangeVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// Handle number of source variable (Argument)
	str	x2,  [sp, #32]		// Handle number of destination variable (Argument)
	str	x9,  [sp, #40]		// Counter
	str	x10, [sp, #48]		// Counter
	str	x11, [sp, #56]		// Source Address Pointer
	str	x12, [sp, #64]		// Destination Address Pointer

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x1, lsl #3	// Handle --> index into table
	ldr	x11, [x10]		// x11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word (exponent)

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x2, lsl #3	// Index into table
	ldr	x12, [x10]		// x12 pointer to variable address
	add	x12, x12, #VAR_MSW_OFST	// x12 pointer at n.s, word (exponent)

	ldr	x10, =No_Word		// For word counter
	ldr	x10, [x10]		// Words in mantissa
10:
	// Perform the word exchange using 64 bit words
	ldr	x0, [x11]
	ldr	x9, [x12]
	str	x0, [x12], #-BYTE_PER_WORD
	str	x9, [x11], #-BYTE_PER_WORD
	subs	x10, x10, #1
	bne	10b

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10,  [sp, #48]
	ldr	x11,  [sp, #56]
	ldr	x11,  [sp, #64]
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
	str	x1,  [sp, #24]		// argument handle number
	str	x2,  [sp, #32]
	str	x10, [sp, #40]		// word counter
	str	x11, [sp, #48]		// pointer
//
// Note about entry with variable equal to zero.
// In scientific notation variables, i usually test the top word
// of a normalized mantissa for zero, then skip the 2's compliment if
// the variable is zero when 2's complment is called.
// Since this is fixed point format, there is no normalized word to check.
// ALso, I have not provided a zero flag for the variable.
// Executing this function with a zero value returns all words zero.
// I have left it at this point, but may revist a zero check in the future (TODO)
//
	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x1, lsl #3	// (handle * 8 bit)
	ldr	x11, [x10]		// X11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer to m.s. word
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)
	sub	x11, x11, x10, lsl #3	// X11 Pointer to l.s. word
	// First iteration does not subtract carry
	ldr	x0, [x11]		// x0 is first word
	subs	x0, xzr, x0		// subtract register from zero (flags set)
	str	x0, [x11]		// Store shifted word
	add	x11, x11, #8		// increment word pointer
	// decrement counter not needed because already count-1 for pointer arithmetic
10:
	ldr	x0, [x11]		// x0 is first word
	sbcs	x0, xzr, x0		// subtract register and NOT carry from zero (flags set)
	str	x0, [x11]		// Store shifted word
	// increment and loop
	add	x11, x11, #8		// increment word pointer
	subs	x10, x10, #1		// decrement word counter
	b.ne	10b			// non-zero, loop back

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x10, [sp, #40]
	ldr	x11, [sp, #48]
	add	sp, sp, #64
	ret
