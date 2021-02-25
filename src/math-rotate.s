/* ----------------------------------------------------------------
	math-rotate.s

	Logical shift bit, btyes and words

	Created:   2021-02-10
	Last edit: 2021-02-25

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

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 contains variable handle number
	bl	set_x11_to_Fct_LS_Word_Address_Static

	// fetch word to setup loop entry
	ldr	x1, [x11]		// x1 is first word to shift right
10:
	ldr	x2, [x11, BYTE_PER_WORD] // x2 is next (adjacent left) word to shift
	lsr	x1, x1, #1		// Shift right 1 bit (0 into m.s. bit)
	add	x1, x1, x2, lsl #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11], BYTE_PER_WORD // Store shifted word
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// most significant word, sign bit copies into next bit when rotating right
	asr	x1, x1, #1		// Shift right 1 bit (sign bit into m.s. bit)
	str	x1, [x11]		// and store most significant word

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
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

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 is variable handle number
	bl	set_x11_to_Int_MS_Word_Address

	ldr	x1, [x11]
10:
	ldr	x2, [x11, -BYTE_PER_WORD] // x1 is next (adjacent right) word to shift
	lsl	x1, x1, #1		// Shift left 1 bit (0 into m.s. bit)
	add	x1, x1, x2, lsr #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11], -BYTE_PER_WORD
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back
	//
	// Last word is special case, no adjacent word on right
	//
	lsl	x1, x1, #1
	str	x1, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	add	sp, sp, #80
	ret
