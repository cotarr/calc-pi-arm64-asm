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
	SetToTwo
	CopyVariable
------------------------------------------------------------- */

	.global	ClearVariable
	.global SetToOne
	.global SetToTwo
	.global	CopyVariable

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
	str	x12,  [sp, #48]		// Destination Address Pointer

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
