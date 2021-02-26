/* ----------------------------------------------------------------
	math-rotate.s

	Logical shift bit, bytes and words

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

	.global CountLeftZerobits
	.global	Right1Bit
	.global	Left1Bit
	.global	Right64Bit
	.global	Left64Bit

/* --------------------------------------------------------------
  Count number of zero bits to the left of the first non-zero bit
  in the specified variable. If the variable is zero, it will
  return number of bits in variable (world_size * 64).
  If the top bit is non-zero, it will return zero

  Input:   x1 = Handle Number of Variable

  Output:  x0 = Number of zero bits

;--------------------------------------------------------------*/
CountLeftZerobits:
	sub	sp, sp, #64		// Preserve words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x1,  [sp, #16]		// Input argument
	str	x10, [sp, #24]		// Counter
	str	x11, [sp, #32]		// Address pointer
	str	x16, [sp, #40]		// Constant 0x8000000000000000
	str	x17, [sp, #48]		// Bit counter

	ldr	x16, =Word8000		// use as constant
	ldr	x16, [x16]		// 0x8000000000000000
	mov	x17, #0			// bit counter

	bl	set_x10_to_Word_Size_Static	// Word counter

	// Argument in x1 variable handle number
	bl	set_x11_to_Int_MS_Word_Address	// Top word address

10:
	ldr	x0, [x11], -BYTE_PER_WORD // get word, then decrement address
	cbnz	x0, 20f			// non-zero? yes branch
	add	x17, x17, #64		// add 64 bits (1 word)
	sub	x10, x10, #1		// last word?
	cbnz	x10, 10b		// no loop again
	b.al	99f			// no words were found, it equal zero
20:
	mov	x10, #64
30:
	tst	x0, x16			// AND 0x8000000000000000
	b.ne	99f
	lsl	x0, x0, #1		// shift next bit left to test
	add	x17, x17, #1		// add 1 bit
	sub	x10, x10, #1		// loop counter
	cbnz	x10, 30b		// again?
	b.al	99f			// done
99:
	mov	x0, x17			// return value x0 is number zero bits

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x1,  [sp, #16]
	ldr	x10, [sp, #24]
	ldr	x11,  [sp, #32]
	ldr	x16,  [sp, #40]
	ldr	x17,  [sp, #48]
	add	sp, sp, #64
	ret

/* --------------------------------------------------------------
  Rotate Right 1 bit (copy sign bit)

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
  Rotate Left 1 bit (zero fill l.s. bit)

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


/* --------------------------------------------------------------
  Rotate Right 1 word (64 bits) (zero fill l.s. word)

  Input:   x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
Right64Bit:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x10, [sp, #32]		// word counter
	str	x11, [sp, #40]		// pointer address

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 is variable handle number
	bl	set_x11_to_Fct_LS_Word_Address_Static
10:
	ldr	x0, [x11, BYTE_PER_WORD] // Load adjacent word on left
	str	x0, [x11], BYTE_PER_WORD // Save at pointer location, then inc pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	mov	x0, #0			// lowest word is zero fill
	str	x0, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	add	sp, sp, #64
	ret

/* --------------------------------------------------------------
  Rotate Left 1 word (64 bits) (zero fill l.s. word)

  Input:   x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
Left64Bit:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]		// input argument / scratch
	str	x10, [sp, #32]		// word counter
	str	x11, [sp, #40]		// pointer address

	bl	set_x10_to_Word_Size_Static_Minus_1

	// Argument x1 is variable handle number
	bl	set_x11_to_Int_MS_Word_Address
10:
	ldr	x0, [x11, -BYTE_PER_WORD] // Load adjacent word on right
	str	x0, [x11], -BYTE_PER_WORD // Save at pointer location, then decrement pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back

	mov	x0, #0			// lowest word is zero fill
	str	x0, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10, [sp, #32]
	ldr	x11, [sp, #40]
	add	sp, sp, #64
	ret
