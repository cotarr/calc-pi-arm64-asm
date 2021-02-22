/* ----------------------------------------------------------------
	math-output.s

	Print binary variable in base 10
	Input binary variable from base 10

	Created:   2021-02-22
	Last edit: 2021-02-22

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
	PrintVariable
	InputVariable
	MultiplyByTen
	DivideByTen
------------------------------------------------------------- */

	.global	PrintVariable
	.global InputVariable

// -------------------------------------------------------------

/* --------------------------------------------------------------

  Print Variable

  Subroutine performs radix conversion to base 10.

  Input: ACC variable (handle 0) contains floating point word to print.

  Output: none

  Output formatting performed in CharOutFmt

-------------------------------------------------------------- */
PrintVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x9,  [sp, #40]
	str	x10, [sp, #48]
	str	x11, [sp, #56]
	str	x12, [sp, #64]
	str	x13, [sp, #72]

	mov	x0, #'X'
	bl	CharOutFmt
	bl	CharOutFmt
	bl	CharOutFmt
	bl	CROut

	// TEMPORARY FOR TEST  MULT 10 AND  DIVIDE 10
	mov	x1, HAND_ACC
	bl	SetToOne
	bl	DivideByTen
	bl	DivideByTen
	bl	DivideByTen
	bl	DivideByTen
	bl	MultiplyByTen
	bl	MultiplyByTen
	bl	MultiplyByTen
	bl	MultiplyByTen

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	ldr	x13, [sp, #72]
	add	sp, sp, #80
	ret


/* ----------------------------------------------------
 Floating Point Input

 Convert ASCII string to floating point number

    Input:    x0 = Address of null terminated character buffer

    Output:   (none)

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

  InFlags bits
  0x0001 0 = Accepting leading + or - in mantissa, 1=done
  0x0002 0 = positive sign 1 = negative sign need 2's compliment
  0x0004 0 = Accepting integer part before decimal point, 1=done
  0x0008 0 = Accepting fraction part after dcimal point, 1=done
  0x0080 1 = Not Zero
  0x0100 1 = mantissa integer part has digits
  0x0200 1 = mantissa fraction part has digits

 ------------------------------------------------------- */

InputVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x9,  [sp, #40]
	str	x10, [sp, #48]
	str	x11, [sp, #56]
	str	x12, [sp, #64]
	str	x13, [sp, #72]

	mov	x1, #1

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
//	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	ldr	x13, [sp, #72]
	add	sp, sp, #80
	ret

/* --------------------------------------------------------------
   Multiply Variable by 10

   Input:   x1 = Variablel Handle

   Output:  none

   This will use multiplication with 32 bit factors to give
   a 64 bit product. It is split into data32:data32.
   The high 32 bit word is saved for next loop and added

   Memory is loaded and stored in 32 bit word size in a loop.

-------------------------------------------------------------- */
MultiplyByTen:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x9,  [sp, #48]
	str	x10, [sp, #56]
	str	x11, [sp, #64]
	str	x12, [sp, #72]
	str	x17, [sp, #80]		// VAR_MSW_OFST

	ldr	x17, =VarMswOfst	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value

	// setup offset index to address within variable
	mov	x9, #0

	// set x10 to count of words -1
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	sub	x10, x10, #1		// count - 1 ( address calculation nexxt)

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl WORDSIZEBITS // Add (handle * bit size)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, x17		// add VAR_MSW_OFST, point to M.S.Word
	sub	x11, x11, x10, lsl WORDSIZEBITS	// X11 Point at L.S. word64

	add	x10, x10, #1		// add back in, x10 = count 64 bit words
	lsl	x10, x10, #2		// Multiply * 2 to address 32 bit word size

	mov	x12, #10		// constant value, (multiply by 10 from register)
	//
	// Loop back to here
	//
10:
	ldr	w1, [x11, x9]		// Load data32 (upper bit 63-32 are zero by op)
	mul	x2, x1, x12		// multiply data32 x 10 = result64
	lsr	x4, x2, #32		// save remainder shifted to lower half
	adds	w2, w2, w3		// add previous remainder, carry flag is changed
	mov	w3, #0			// Need a zero word to add carry flag
	adc	w3, w4, w3		// Add carry to remainder
	str	w2, [x11, x9]		// Store 32 bit result
	add	x9, x9, #4		// decrement index to next 32 bit word
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 10b		// loop until all 32 bit word are processed
	//
	// Done
	//
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
	ldr	x17, [sp, #80]
	add	sp, sp, #96
	ret



/* --------------------------------------------------------------
   Divide Variable by 10

   Input:   x1 = Variablel Handle

   Output:  none

   Note:    Variable must be >= 0

   This will utilize 64 bit divident by 32 bit divisor
   to get 32 bit quotient and 32 bit remiander

   The each loop 32 bit remainder and 32 bit data
   is used to form the 64 bit divisor.

   Memory is loaded and stored in 32 bit word size in a loop.

-------------------------------------------------------------- */
DivideByTen:
	sub	sp, sp, #96		// Reserve 12 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x9,  [sp, #48]
	str	x10, [sp, #56]
	str	x11, [sp, #64]
	str	x12, [sp, #72]
	str	x17, [sp, #80]		// VAR_MSW_OFST

	ldr	x17, =VarMswOfst	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value

	// setup offset index to address within variable
	mov	x9, #0

	// set x10 to count of words -1
	ldr	x10, =No_Word		// Pointer to of words in mantissa
	ldr	x10, [x10]		// Number words in mantissa
	lsl	x10, x10, #2		// Multiply two word32 per word64
	sub	x10, x10, #1		// Count - 1

	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl WORDSIZEBITS // Add (handle * bit size)
	ldr	x11, [x11]		// X11 pointer to variable address
	add	x11, x11, x17		// add VAR_MSW_OFST, point to M.S.Word

	mov	x12, #10		// constant value, (divide by 10 from register)

	//
	// first division is special case, no previous remainder
	//
	ldr	w1, [x11, #4]		// Special case, get top 32 bit word into 64 bit reg
	udiv	x2, x1, x12		// x2 quot = (zero32:data32) / 10
	msub	x3, x2, x12, x1		// x3 rem  = (zero32:data32) - (quot64 * 10)
	str	w2, [x11, #4]		// save top 32 bit of top word
	//
	// Loop back to here for each operation
	//
10:
	ldr	w1, [x11, x9]		// Load data32 (upper bit 63-32 are zero by op)
	orr	x1, x1, x3, lsl #32	// Combine remainder32:data32 with shifted OR
	udiv	x2, x1, x12		// x2 quot = (lastrem:data] / 10
	msub	x3, x2, x12, x1 	// x3 rem  = (lastrem:data) - (quot * 10)
	str	w2, [x11, x9]		// store 32 bit result
	sub	x9, x9, #4		// decrement index to next 32 bit word
	sub	x10, x10, #1		// decrement counter
	cbnz	x10, 10b		// loop until all 32 bit words are processed
	//
	// Done
	//
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
	ldr	x17, [sp, #80]
	add	sp, sp, #96
	ret
