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
------------------------------------------------------------- */

	.global	Right1Bit

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
	str	x1,  [sp, #24]		// argument handle number
	str	x2,  [sp, #32]
//	str	x9,  [sp, #40]
	str	x10, [sp, #48]		// word counter
	str	x11, [sp, #56]		// pointer

	ldr	x10, =RegAddTable	// Pointer to vector table
	add	x10, x10, x1, lsl #3	// (handle * 8 bit)
	ldr	x11, [x10]		// X11 pointer to variable address
	add	x11, x11, #VAR_MSW_OFST	// x11 pointer at m.s. word
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Actual number words in mantissa
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)
	sub	x11, x11, x10, lsl #3	// Subtract (num words -1) * 8 --> l.s. word

	ldr	x0, [x11]		// x0 is first word to shift right
10:
	ldr	x1, [x11, #8]		// x1 is next (adjacent) word to shift
	lsr	x0, x0, #1		// Shift right 1 bit (0 into m.s. bit)
	add	x0, x0, x1, lsl #63	// Add l.s. bit next word as m.s. bit
	str	x0, [x11]
	// increment and loop
	mov	x0, x1			// No need fetch x0 from memory again
	add	x11, x11, #8		// increment word pointer
	subs	x10, x10, #1		// decrement word counter
	b.ne	10b			// non-zero, loop back
	// most significant word, sign bit copies into next bit when rotating right
	asr	x0, x0, #1		// Shift right 1 bit (sign bit into m.s. bit)
	str	x0, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
//	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	add	sp, sp, #80
	ret
