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
	.global	RightNBits
	.global	LeftNBits

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
	orr	x1, x1, x2, lsl #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11], BYTE_PER_WORD // Store shifted word
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// most significant word, sign bit copies into next bit when rotating right
	lsr	x1, x1, #1		// Shift right 1 bit (zero fill)
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
	orr	x1, x1, x2, lsr #63	// Add l.s. bit next word as m.s. bit
	str	x1, [x11], -BYTE_PER_WORD
	// increment and loop
	mov	x1, x2			// No need fetch from memory again
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 10b		// non-zero, loop back
	//
	// Last word is special case, no adjacent word on right
	//
	lsl	x1, x1, #1		// zero fill
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

/* --------------------------------------------------------------
  Rotate Right (n) bits with zero fill

  Input:  x0 = Number of bits to rotate
          x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
RightNBits:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// input argument (bits to shift)
	str	x1,  [sp, #24]		// input argument (variable handle)
	str	x2,  [sp, #32]		// input argument (variable handle)

	str	x8,  [sp, #40]		// Counter zero fill words
	str	x9,  [sp, #48]		// Address offset
	str	x10, [sp, #56]		// Counter shifting words

	str	x11, [sp, #64]		// Destinatin base address
	str	x12, [sp, #72]		// Source low word address
	str	x13, [sp, #80]		// source high word address

	str	x15, [sp, #88]		// Input argument x0: total bits to rotate
	str	x16, [sp, #96]		// count of words to rotate
	str	x17, [sp, #104]		// count of bits from high word
	str	x18, [sp, #112]		// count of bits from low word

	mov	x15, x0			// save N bits to shift in X15
	cbz	x0, 99f			// if zero skip

	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Fct_LS_Word_Address_Static

	//
	// Divide to get words and bits
	//
	mov	x0, #64			// Use as temporary constant value
	udiv	x16, x15, x0		// x16 words to shift
	msub	x17, x16, x0, x15	// x17 bits within word to shift
	sub	x18, x0, x17		// x18 fill in bits in adjacent word (64 - N)

	// At zero word shift, offset is 1 word (like shift 1 bit above)
	// Number of words shift is added to offset of 1
	add	x12, x11, x16, lsl X8SHIFT3BIT // low source word address
	add	x13, x12, BYTE_PER_WORD // high source word address

	sub	x10, x10, #1		// Adjust one time case outside loop
	mov	x8, x10			// copy (temp)
	sub	x10, x10, x16		// counter adjusted word shift
	sub	x8, x8, x10		// fill words after shifted words
	//
	// check in range
	//
	cmp	x10, x16
	b.hs	10f
	ldr	x0, =RotateNRangeMsgRight // Error message pointer
	mov	x1, #372		// 12 bit error code
	b	FatalError
10:
	mov	x9, #0			// offset pointer

	// fetch word to setup loop entry
	ldr	x1, [x12, x9]		// x1 contains Low source word
20:
	ldr	x2, [x13, X9]		// x2 contains High source word
	lsr	x1, x1, x17		// Shift right [x17] bits, zero fill
	lsl	x0, x2, x18		// temp shifted value to x0
	orr	x1, x1, x0		// OR shifted bits
	// Store shifted word
	str	x1, [x11, x9]		// save in destination word
	// increment and loop
	add	x9, x9, BYTE_PER_WORD
	mov	x1, x2			// High word --> Low word
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 20b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// most significant word
	lsr	x1, x1, x17		// Shift right 1 bit (zero fill)
	str	x1, [x11, x9]		// and store most significant word
	//
	// Fill shifted words
	//
	cbz	x8, 99f
	mov	x0, #0			// fill value
	add	x9, x9, BYTE_PER_WORD	// for alignment of words
30:
	str	x0, [x11, x9]
	add	x9, x9, BYTE_PER_WORD
	sub	x8, x8, #1
	cbnz	x8, 30b
99:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x13, [sp, #80]
	ldr	x15, [sp, #88]
	ldr	x16, [sp, #96]
	ldr	x17, [sp, #104]
	ldr	x18, [sp, #116]
	add	sp, sp, #128
	ret

/* --------------------------------------------------------------
  Rotate left (n) bits with zero fill

  Input:  x0 = Number of bits to rotate
          x1 = Handle Number of Variable

  Output:  none

;--------------------------------------------------------------*/
LeftNBits:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// input argument (bits to shift)
	str	x1,  [sp, #24]		// input argument (variable handle)
	str	x2,  [sp, #32]		// input argument (variable handle)

	str	x8,  [sp, #40]		// Counter zero fill words
	str	x9,  [sp, #48]		// Address offset
	str	x10, [sp, #56]		// Counter shifting words

	str	x11, [sp, #64]		// Destinatin base address
	str	x12, [sp, #72]		// Source high word address
	str	x13, [sp, #80]		// source low word address

	str	x15, [sp, #88]		// Input argument x0: total bits to rotate
	str	x16, [sp, #96]		// count of words to rotate
	str	x17, [sp, #104]		// count of bits from low word
	str	x18, [sp, #112]		// count of bits from high word

	mov	x15, x0			// save N bits to shift in X15
	cbz	x0, 99f			// if zero skip

	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Int_MS_Word_Address

	//
	// Divide to get words and bits
	//
	mov	x0, #64			// Use as temporary constant value
	udiv	x16, x15, x0		// x16 words to shift
	msub	x17, x16, x0, x15	// x17 bits within word to shift
	sub	x18, x0, x17		// x18 fill in bits in adjacent word (64 - N)

	// At zero word shift, offset is 1 word (like shift 1 bit above)
	// Number of words shift is added to offset of 1
	sub	x12, x11, x16, lsl X8SHIFT3BIT // high source word address
	sub	x13, x12, BYTE_PER_WORD // low source word address

	sub	x10, x10, #1		// Adjust one time case outside loop
	mov	x8, x10			// copy (temp)
	sub	x10, x10, x16		// counter adjusted word shift
	sub	x8, x8, x10		// fill words after shifted words
	//
	// check in range
	//
	cmp	x10, x16
	b.hs	10f
	ldr	x0, =RotateNRangeMsgLeft // Error message pointer
	mov	x1, #373		// 12 bit error code
	b	FatalError
10:
	mov	x9, #0			// offset pointer

	// fetch word to setup loop entry
	ldr	x1, [x12, x9]		// x1 contains high source word
20:
	ldr	x2, [x13, X9]		// x2 contains Low source word
	lsl	x1, x1, x17		// Shift right [x17] bits, zero fill
	lsr	x0, x2, x18		// temp shifted value to x0
	orr	x1, x1, x0		// OR shifted bits
	// Store shifted word
	str	x1, [x11, x9]
	// increment and loop
	sub	x9, x9, BYTE_PER_WORD
	mov	x1, x2			// Low word --> High word
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 20b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// least significant word
	lsl	x1, x1, x17		// Shift right 1 bit (zero fill)
	str	x1, [x11, x9]		// and store most significant word
	//
	// Fill shifted words
	//
	cbz	x8, 99f
	mov	x0, #0			// fill value
	sub	x9, x9, BYTE_PER_WORD	// for alignment of words
30:
	str	x0, [x11, x9]
	sub	x9, x9, BYTE_PER_WORD
	sub	x8, x8, #1
	cbnz	x8, 30b
99:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x13, [sp, #80]
	ldr	x15, [sp, #88]
	ldr	x16, [sp, #96]
	ldr	x17, [sp, #104]
	ldr	x18, [sp, #116]
	add	sp, sp, #128
	ret


RotateNRangeMsgRight:
	.asciz	"RightNBits argument too large"
RotateNRangeMsgLeft:
	.asciz	"LeftNBits argument too large"
	.align 4
