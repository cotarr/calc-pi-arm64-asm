/* ----------------------------------------------------------------
	math-rotate.s

	Logical shift bit, btyes and words

	Created:   2021-02-10
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
	Right1Bit
	Left1Bit
------------------------------------------------------------- */

	.global	Right1Bit
	.global	Left1Bit

/* --------------------------------------------------------------
  Rotate Mantissa Right 1 bit (copy sign bit)

  Input:   x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
Right1Bit:
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
	mov	x9, #0

	// set x10 to count of words -1
	ldr	x10, =Word_Size_Static		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // Add (handle * bit size)
	ldr	x11, [x11]		// X11 pointer to variable address
		// get VAR_MSW_OFST (too big for immediate value)
	add	x11, x11, x17		// add VAR_MSW_OFST, point to M.S.Word
	sub	x11, x11, x10, lsl X8SHIFT3BIT // X11 Pointer to l.s. word


	// Setup x12 to point 1 word higher than x11
	add	x12, x11, BYTE_PER_WORD // x12 pointer l.s. word + 1 word

	// fetch word to setup loop entry
	ldr	x1, [x11, x9]		// x1 is first word to shift right
10:
	ldr	x2, [x12, x9]		// x2 is next (adjacent) word to shift
	lsr	x1, x1, #1		// Shift right 1 bit (0 into m.s. bit)
	add	x1, x1, x2, lsl #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11, x9]		// Store shifted word
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	add	x9, x9, #8		// increment word pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	// most significant word, sign bit copies into next bit when rotating right
	asr	x1, x1, #1		// Shift right 1 bit (sign bit into m.s. bit)
	str	x1, [x11, x9]		// and store most significant word

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
  Rotate Mantissa Left 1 bit (zero fill l.s. bit)

  Input:   x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
Left1Bit:
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
	mov	x9, #0			// offset applied to address

	// x10 counter to number words
	ldr	x10, =Word_Size_Static		// For word counter
	ldr	x10, [x10]		// Words in mantissa

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl #3	// (handle * 8 bit)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, x17		// add VAR_MSW_OFST, point to M.S. Word

	// Setup x12 to point 1 word lower than x11
	sub	x12, x11, BYTE_PER_WORD // x12 pointer l.s. word - 1 word

	ldr	x1, [x11, x9]		// x0 is first word to shift left
10:
	ldr	x2, [x12, x9]		// x1 is next (adjacent) word to shift
	lsl	x1, x1, #1		// Shift right 1 bit (0 into m.s. bit)
	add	x1, x1, x2, lsr #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11, x9]
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	sub	x9, x9, BYTE_PER_WORD	// increment word pointer
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
	ldr	x17, [sp, #72]
	add	sp, sp, #80
	ret
