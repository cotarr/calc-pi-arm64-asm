/* ----------------------------------------------------------------
	math-rotate.s

	Logical shift bit, bytes and words

	Created:   2021-02-10
	Last edit: 2021-03-05

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
	.global	Right64Bits
	.global	Left64Bits
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
Right64Bits:
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
Left64Bits:
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

	// -------------------------------------------------------
	// Save input argument
	// -------------------------------------------------------
	mov	x15, x0			// save N bits to shift in X15

	// -------------------------------------------------------
	// Setup word size counter and varaible address pointer
	// -------------------------------------------------------
	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Fct_LS_Word_Address_Static

	// -------------------------------------------------
	// Case #1 - Zero bit shift requested (x15 = 0)
	// In this care return the original result unchanged.
	// -------------------------------------------------
	cbz	x15, 999f			// if zero skip

	// -------------------------------------------------
	// check shift size range, else fatal error
	// -------------------------------------------------
	mov	x0, x10
	lsl	x0, x0, X64SHIFT4BIT	// mult * 8 for 64 bits
	cmp	x0, x15
	b.gt	10f
//	ldr	x0, =RotateNRangeMsgRight // Error message pointer
//	mov	x1, #372		// 12 bit error code
//	b	FatalError
	//
	// Instead of error, clear to zero, all bits rotated
	//
	ldr	x1, [sp, #24]		// variable handle
	bl	ClearVariable
	b.al	999f
10:
	// ------------------------------------------------
	// Divide to get words and bits
	// x15 = Iriginal word size
	// x16 = Number of 64 bit words to shift
	// x17 = Number of bits to shift
	// x18 = Number of bits to fill after shift (64 - x17)
	// ------------------------------------------------
	mov	x0, #64			// Use as temporary constant value
	udiv	x16, x15, x0		// x16 words to shift
	msub	x17, x16, x0, x15	// x17 bits within word to shift
	sub	x18, x0, x17		// x18 fill in bits in adjacent word (64 - N)

	// -------------------------------------------------
	// Case #2 request shift of even word (x16 != 0, x17 == 0)
	// -------------------------------------------------
	cbnz	x17, 140f
	// setup x12 to point to destination word address
	add	x12, x11, x16, lsl X8SHIFT3BIT
	mov	x8, x10			// temp save
	sub	x10, x10, x16		// counter words to shift
	sub	x8, x8, x10		// zero words needed
120:	ldr	x0, [x12], BYTE_PER_WORD // Load adjacent word on left
	str	x0, [x11], BYTE_PER_WORD // Save at pointer location, then inc pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 120b		// non-zero, loop back
	// fill remaining words with zero
130:	mov	x0, #0			// fill value
	str	x0, [x11], BYTE_PER_WORD // store zero word
	sub	x8, x8, #1		// counter
	cbnz	x8, 130b
	b.al	999f			// no more, return
140:
	// -------------------------------------------------
	// Case #3 Shift End to End
	//
	// Some bits from first words are shifted to the
	// last word. In this case bits from two different
	// words are not combined.
	// -------------------------------------------------
	// Note, register x17 (bit count) has already been checked for zero
	mov	x0, x10			// count of number of words
	sub	x0, x0, 1		// Count -1
	cmp	x16, x0
	b.ne	240f

	// setup x12 to point to destination word address
	add	x12, x11, x16, lsl X8SHIFT3BIT
	// Single word move with shift of bits
	sub	x8, x10, #1		// zero words needed
	ldr	x0, [x12]		// Word from one end of variable
	lsr	x0, x0, x17		// shift bits by requested bit count
	str	x0, [x11], BYTE_PER_WORD // Save at pointer location, then inc pointer

	// fill remaining words with zero
230:	mov	x0, #0			// fill value
	str	x0, [x11], BYTE_PER_WORD // store zero word
	sub	x8, x8, #1		// counter
	cbnz	x8, 230b

	b.al	999f			// no more, return
240:
	// ---------------------------------------------------------------
	//      M A I N   S H I F T   C O D E
	//
	// All special cases are complete.
	//
	// This is the main bit shift function
	// This is the main bit shift function
	//    Load 2 adjacent words
	//    Shift bits in one word
	//    Shift bits in other word opposite direction
	//    Combine two words with bitwise OR
	//    Store single word (combined from two words)
	//    Loop until done
	// ---------------------------------------------------------------

	// At zero word shift, offset is 1 word (like shift 1 bit above)
	// Number of words shift is added to offset of 1
	add	x12, x11, x16, lsl X8SHIFT3BIT // low source word address
	add	x13, x12, BYTE_PER_WORD // high source word address

	sub	x10, x10, #1		// Adjust one time case outside loop
	mov	x8, x10			// copy (temp)
	sub	x10, x10, x16		// counter adjusted word shift
	sub	x8, x8, x10		// fill words after shifted words

	mov	x9, #0			// offset pointer

	// fetch word to setup loop entry
	ldr	x1, [x12, x9]		// x1 contains Low source word
350:
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
	cbnz	x10, 350b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// most significant word
	lsr	x1, x1, x17		// Shift right 1 bit (zero fill)
	str	x1, [x11, x9]		// and store most significant word
	//
	// Fill shifted words
	//
	cbz	x8, 999f
	mov	x0, #0			// fill value
	add	x9, x9, BYTE_PER_WORD	// for alignment of words
360:
	str	x0, [x11, x9]
	add	x9, x9, BYTE_PER_WORD
	sub	x8, x8, #1
	cbnz	x8, 360b
999:
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
	ldr	x18, [sp, #112]
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

	// -------------------------------------------------------
	// Save input argument
	// -------------------------------------------------------
	mov	x15, x0			// save N bits to shift in X15

	// -------------------------------------------------------
	// Setup word size counter and varaible address pointer
	// -------------------------------------------------------
	bl	set_x10_to_Word_Size_Static

	// Argument x1 contains variable handle number
	bl	set_x11_to_Int_MS_Word_Address

	// -------------------------------------------------
	// Case #1 - Zero bit shift requested (x15 = 0)
	// In this care return the original result unchanged.
	// -------------------------------------------------
	cbz	x15, 999f		// if zero skip

	// -------------------------------------------------
	// check shift size range, else fatal error
	// -------------------------------------------------
	mov	x0, x10
	lsl	x0, x0, X64SHIFT4BIT	// mult * 8 for 64 bits
	cmp	x0, x15
	b.gt	10f
//	ldr	x0, =RotateNRangeMsgLeft // Error message pointer
//	mov	x1, #374		// 12 bit error code
//	b	FatalError
	//
	// Instead of error, clear to zero, all bits rotated
	//
	ldr	x1, [sp, #24]		// variable handle
	bl	ClearVariable
	b.al	999f
10:
	// ------------------------------------------------
	// Divide to get words and bits
	// x15 = Iriginal word size
	// x16 = Number of 64 bit words to shift
	// x17 = Number of bits to shift
	// x18 = Number of bits to fill after shift (64 - x17)
	// ------------------------------------------------
	mov	x0, #64			// Use as temporary constant value
	udiv	x16, x15, x0		// x16 words to shift
	msub	x17, x16, x0, x15	// x17 bits within word to shift
	sub	x18, x0, x17		// x18 fill in bits in adjacent word (64 - N)

	// -------------------------------------------------
	// Case #2 request shift of even word (x16 != 0, x17 == 0)
	// -------------------------------------------------
	cbnz	x17, 140f
	// setup x12 to point to destination word address
	sub	x12, x11, x16, lsl X8SHIFT3BIT
	mov	x8, x10			// temp save
	sub	x10, x10, x16		// counter words to shift
	sub	x8, x8, x10		// zero words needed
120:	ldr	x0, [x12], -BYTE_PER_WORD // Load adjacent word on left
	str	x0, [x11], -BYTE_PER_WORD // Save at pointer location, then inc pointer
	sub	x10, x10, #1		// decrement word counter
	cbnz	x10, 120b		// non-zero, loop back
	// fill remaining words with zero
130:	mov	x0, #0			// fill value
	str	x0, [x11], -BYTE_PER_WORD // store zero word
	sub	x8, x8, #1		// counter
	cbnz	x8, 130b
	b.al	999f			// no more, return
140:
	// -------------------------------------------------
	// Case #3 Shift End to End
	//
	// Some bits from first words are shifted to the
	// last word. In this case bits from two different
	// words are not combined.
	// -------------------------------------------------
	// Note, register x17 (bit count) has already been checked for zero
	mov	x0, x10			// count of number of words
	sub	x0, x0, 1		// Count -1
	cmp	x16, x0
	b.ne	240f

	// setup x12 to point to destination word address
	sub	x12, x11, x16, lsl X8SHIFT3BIT
	// Single word move with shift of bits
	sub	x8, x10, #1		// zero words needed
	ldr	x0, [x12]		// Word from one end of variable
	lsl	x0, x0, x17		// shift bits by requested bit count
	str	x0, [x11], -BYTE_PER_WORD // Save at pointer location, then inc pointer

	// fill remaining words with zero
230:	mov	x0, #0			// fill value
	str	x0, [x11], -BYTE_PER_WORD // store zero word
	sub	x8, x8, #1		// counter
	cbnz	x8, 230b

	b.al	999f			// no more, return
240:
	// ---------------------------------------------------------------
	//      M A I N   S H I F T   C O D E
	//
	// All special cases are complete.
	//
	// This is the main bit shift function
	//    Load 2 adjacent words
	//    Shift bits in one word
	//    Shift bits in other word opposite direction
	//    Combine two words with bitwise OR
	//    Store single word (combined from two words)
	//    Loop until done
	// ---------------------------------------------------------------

	// At zero word shift, offset is 1 word (like shift 1 bit above)
	// Number of words shift is added to offset of 1
	sub	x12, x11, x16, lsl X8SHIFT3BIT // high source word address
	sub	x13, x12, BYTE_PER_WORD // low source word address

	sub	x10, x10, #1		// Adjust one time case outside loop
	mov	x8, x10			// copy (temp)
	sub	x10, x10, x16		// counter adjusted word shift
	sub	x8, x8, x10		// fill words after shifted words

	mov	x9, #0			// offset pointer

	// fetch word to setup loop entry
	ldr	x1, [x12, x9]		// x1 contains high source word
350:
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
	cbnz	x10, 350b		// non-zero, loop back
	//
	// last word is special case of end word
	//
	// least significant word
	lsl	x1, x1, x17		// Shift right 1 bit (zero fill)
	str	x1, [x11, x9]		// and store most significant word
	//
	// Fill shifted words
	//
	cbz	x8, 999f
	mov	x0, #0			// fill value
	sub	x9, x9, BYTE_PER_WORD	// for alignment of words
360:
	str	x0, [x11, x9]
	sub	x9, x9, BYTE_PER_WORD
	sub	x8, x8, #1
	cbnz	x8, 360b
999:
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
	ldr	x18, [sp, #112]
	add	sp, sp, #128
	ret

RotateNRangeMsgRight:
	.asciz	"RightNBits argument too large"
RotateNRangeMsgLeft:
	.asciz	"LeftNBits argument too large"
	.align 4
/*
// -------  Begin test code -----------
//
// RightNBits and LeftNBits are critical
// functions that must work correctly.
// This is some temporary debug code to test.
//
// Insert furnction "DEBUG_test_N_shift" into
// command parser "test" Function as follows:
//
///		cbz	x0, 10f
//		bl	IntWordInput
//		mov	x9, x0
//		bl	DEBUG_test_N_shift
//	10:	b	ParseCmd
//
// Comment lines for left or right (two places)
//
// Command:  test <bits to shift>
// ---------------------------------------
	.align 4
	.global	DEBUG_test_N_shift
//
// Bits to shift argument in x9
//
DEBUG_test_N_shift:
	stp	x29, x30, [sp, -16]!	// preserve return address

	mov	x0, x9
	bl	Print0xWordHex
	mov	x0, #' '
	bl	CharOut
	mov	x0, x9
	bl	PrintWordB10
	bl	CROut

	// 1) fill test data

	mov	x1, 3
	bl DebugFillVariable
	mov	x1, 5
	bl DebugFillVariable
	mov	x1, 7
	bl DebugFillVariable

	// 2) Shift specified number of bits in single function test

	mov	x0, x9
	mov	x1, #5
//	bl	RightNBits
	bl	LeftNBits

	// 3) Shift bits manually bit by bit

	mov	x2, x9
	cbz	x2, 20f		// skip if zero

	mov	x1, #3
10:
//	bl	Right1Bit
	bl	Left1Bit
	sub	x2, x2, #1
	cbnz	x2, 10b
20:
	// 4) Print resutls to compare

	mov	x1, #3
	bl	PrintVar
	mov	x1, #5
	bl	PrintVar
	mov	x1, #7
	bl	PrintVar
99:
	ldp	x29, x30, [sp], 16	// restore return address
	ret
// -------------- end test code --------------
*/
