/* ----------------------------------------------------------------
	math-output.s

	Input binary variable from base 10

	Created:   2021-02-23
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
	InputVariable

------------------------------------------------------------- */

	.global	InputVariable

/* ----------------------------------------------------
 Floating Point Input

 Convert ASCII string to floating point number

    Input:    x0 = Address of null terminated character buffer

    Output:   x1 = Error code, 0=no error

    Valid number syntax

    Leading +, -
      12
      +12
      -12
    Decimal Point
      .12
      1.2
      12.
      0.12
      12.34
 ------------------------------------------------------

  InFlags bits - Use x16 register for this

  0x0001 0 = Accepting leading + or - in mantissa, 1=done
  0x0002 0 = positive, 1 = negative  need 2's compliment
  0x0004 0 = Accepting integer part before decimal point, 1=done

 ------------------------------------------------------- */

	.align 4

InputVariable:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x9,  [sp, #48]		// Offset pointer relative M.S. Word
	str	x10, [sp, #56]		// fraction power of 10 counter
	str	x11, [sp, #64]		// Point ACC M.S. Word
	str	x12, [sp, #72]		// Point OPR M.S. Word
	str	x15, [sp, #80]		// Pointer to input string
	str	x16, [sp, #88]		// Input status flag showing state bits
	str	x17, [sp, #96]		// VAR_MSW_OFST
	//
	// Set x15 pointer to input string
	//
	mov	x15, x0
	//
	// x17 is constant (Offset to M.S. word of variable)
	//
	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Treat this as a constant in this function
	//
	// x11 is constant (address of ACC M.S. World)
	//
	mov	x1, HAND_ACC		// Variable handle number
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x12 is address of variable
	add	x11, x11, x17		// x12 pointer at m.s. word
	//
	// x12 is constant (address of OPR M.S. World)
	//
	mov	x2, HAND_OPR		// Variable handle number
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 is address of variable
	add	x12, x12, x17		// x12 pointer at m.s. word

	// x9 is constant address of Integer Part L.S.word
	ldr	x9, =IntWSize
	ldr	x9, [x9]		// x11 is count integer words
	sub	x9, x9, #1		// Subtract 1 now x9 = (words -1)
	sub	x9, xzr, x9, lsl X8SHIFT3BIT // (0 - (x9 * 8) = Neg offset to L.S. word

	mov	x16, #0x00		// State of input process
	sub	x15, x15, #1		// Decrement so it can increment start of loop
	mov	x10, #0			// counter for power of 10 fractions

	// we are going to build number in ACC
	mov	x1, HAND_ACC		// Variable handle number
	bl	ClearVariable

	// opr will be used to scale fraction part of number when digit added.
	mov	x1, HAND_OPR		// Variable handle number
	bl	ClearVariable

	// Input character from buffer
next_character:
	add	x15, x15, #1			// Point to next character
	ldrb	w0, [x15]		// get character
	cmp	w0, #0			// end of string?
	b.eq	end_of_string		// yes

	//
	// Check plus sign +
	//
100:	cmp	w0, #'+'
	b.ne	200f
	tst	x16, #0x01		// Accepting leading +/- ?
	b.ne	conversion_error
	orr	x16, x16, #0x01		// Mark sign as received
	b.al	next_character
	//
	// Check minus sign -
	//
200:	cmp	w0, #'-'
	b.ne	300f
	tst	X16, 0x01		// Accepting leading +/- ?
	b.ne	conversion_error
	orr	x16, x16, #0x01		// Mark sign as received
	orr	x16, x16, #0x02		// Mark 2's compliment required
	b.al	next_character
	//
	// Check decimal point
	//
300:	cmp	w0, #'.'
	b.ne	400f
	tst	x16, #0x04		// already decimal point?
	b.ne	conversion_error
	orr	x16, x16, #0x04
	b.al	next_character
	//
	// Check if digit 0 to 9
400:
	cmp	w0, #'0'
	b.lt	conversion_error
	cmp	w0, #'9'
	b.gt	conversion_error

	// -----------------------------------------------
	// At this point the numeric digits must be processed.
	//
	// There are two options:
	//     1) accepting integer part (left of decimal separator)
	//     2) accepting fraction part (right of decimal separator)
	//
	// Case of ingteger part:
	//    Multiply number in ACC by 10
	//    Convert ascii to bcd and store in OPR
	//    Add ACC = ACC + OPR
	//
	// Case of fraction part
	//    Increment power of 10 counter
	//    Convert ascii to bcd and store in OPR
	//    In loop for count of fraction digits
	//       Divide OPR by 10
	//    Add ACC = ACC + OPR
	// -------------------------------------------------------
	//
	tst	x16, #0x04		// Integer part, or fraction part?
	b.ne	700f			// bit set, process as fraction digit

					// else process as integer part digit
	mov	x1, HAND_ACC		// Variable handle number
	bl	MultiplyByTen

	// this places character in OPR
	mov	x0, #0
	str	x0, [x12, x9]		// [address, offset] L.S Word on integer part
	ldrb	w0, [x15]		// get character
	and	w0, w0, 0x0f		// ASCII --> BCD
	strb	w0, [x12, x9]		// save digit as BCD number in OPR
	// This is addition of variables
	mov	x1, HAND_ACC		// Variable handle number
	mov	x2, HAND_OPR
	mov	x3, HAND_ACC
	bl	AddVariable		// ACC = ACC = OPR
	b.al	next_character

700:
	add	x10, x10, #1		// increment power of 10 counter

	mov	x1, HAND_OPR		// Variable handle number
	bl	ClearVariable
	// this places character in OPR
	ldrb	w0, [x15]		// get character
	and	w0, w0, 0x0f		// ASCII --> BCD
	strb	w0, [x12, x9]		// save digit as BCD number in OPR
	// Multiplication loop
	mov	x2, x10			// division counter
710:	mov	x1, HAND_OPR
	bl	DivideByTen
	sub	x2, x2, #1
	cbnz	x2, 710b
	// Addition of divided digit
	mov	x1, HAND_ACC		// Variable handle number
	mov	x2, HAND_OPR
	mov	x3, HAND_ACC
	bl	AddVariable		// ACC = ACC + OPR
	b.al	next_character

conversion_error:
	mov	x1, HAND_ACC		// Variable handle number
	bl	ClearVariable
	mov	x1, #1			// error flag
	b.al	999f

end_of_string:
	tst	x16, 0x02		// Check if 2's compliment needed for negate?
	b.eq	900f
	mov	x1, HAND_ACC		// Variable handle number
	bl	TwosCompliment
900:
	mov	x1, #0			// no error

999:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	// ldr	x1,  [sp, #24]		// return error code
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x9,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	ldr	x12, [sp, #72]
	ldr	x15, [sp, #80]
	ldr	x16, [sp, #88]
	ldr	x17, [sp, #96]
	add	sp, sp, #128
	ret
