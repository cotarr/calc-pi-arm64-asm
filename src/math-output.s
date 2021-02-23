/* ----------------------------------------------------------------
	math-output.s

	Print binary variable in base 10
	Input binary variable from base 10

	Created:   2021-02-22
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
	PrintVariable
------------------------------------------------------------- */

	.global	PrintVariable

// -------------------------------------------------------------

/* --------------------------------------------------------------

  Print Variable

  Subroutine performs radix conversion to base 10.

  Input: ACC variable (handle 0) contains floating point word to print.

  Output: none

  Output formatting performed in CharOutFmt

-------------------------------------------------------------- */
PrintVariable:
	sub	sp, sp, #128		// Reserve 16 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]
	str	x9,  [sp, #48]		// Offset pointer relative M.S. Word
	str	x10, [sp, #56]
	str	x11, [sp, #64]		// Point ACC M.S. Word
	str	x12, [sp, #72]		// Point OPR M.S. Word
	str	x15, [sp, #80]		// Decimal point counter
	str	x16, [sp, #88]		// Print digit counter
	str	x17, [sp, #96]		// VAR_MSW_OFST

	//
	// x17 is constant (Offset to M.S. word of variable)
	//
	ldr	x17, =VarMswOfst	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Treat this as a constant in this function
	//
	// x11 is constant (address of ACC M.S. World)
	//
	ldr	x11, =RegAddTable	// Pointer to vector table
	ldr	x11, [x11]		// x12 is address of variable
	add	x11, x11, x17		// x12 pointer at m.s. word
	//
	// x12 is constant (address of OPR M.S. World)
	//
	mov	x1, HAND_OPR		// Variable handle number
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 is address of variable
	add	x12, x12, x17		// x12 pointer at m.s. word

	//
	// First check for zero
	//
	mov	x1, HAND_ACC		// Variable handle number
	bl	TestIfZero		// test ACC to see if zero
	cbz	x0, 10f			// not zero, skip past zero case

	//
	// Case of zero, output "+0.0"
	//
	mov	x0, #'+'
	bl	CharOutFmt
	mov	x0, #'0'
	bl	CharOutFmt
	mov	x0, #'.'
	bl	CharOutFmt
	mov	x0, #'0'
	bl	CharOutFmt
	b.al	done_print

10:	//
	// CHeck if negative
	//
	mov	x1, HAND_ACC		// Variable handle number
	bl	TestIfNegative		// See if original number was negative
	cbz	x0, 20f

	mov	x0, #'-'		// Then output minus sign
	bl	CharOutFmt

	mov	x1, HAND_ACC		// Variable handle number
	bl	TwosCompliment		// perform 2's compiment before print
	b.al	21f
20:
	mov	x0, #'+'
	bl	CharOutFmt		// Else positive, output the plug sign
21:
	//
	// Option to round off
	//
	mov	x0, GUARDWORDS		// If no guard words, then don't round
	cbz	x0, 25f

	mov	x1, HAND_OPR		// Handle number to variable
	bl	ClearVariable

	// Need x9 offset from address of variable M.S.word
	ldr	x9, =No_Word
	ldr	x9, [x9]		// x0 is count integer words
	sub	x9, x9, #1		// subtract 1 now x0 = (words - 1)
	sub	x9, xzr, x9, lsl X8SHIFT3BIT // (0 - (x9 * 8) = Neg offset to L.S. word

	// ----- select this to round off -------------
	movz	x0, #0x1000, lsl #16	// 0x0000000010000000
	str	x0, [x12, x9]		// x12 address x9 offset
	// --------------------------------------------

	// add the round value ACC = ACC + OPR
	mov	x1, HAND_ACC		// Variable handle number
	mov	x2, HAND_OPR
	mov	x3, HAND_ACC
	bl	AddVariable		// Add ACC = ACC = OPR

25:
	// In this next section, there is a loop that will divide
	// the input number by 10 until the integer part of the
	// number is less that 10. A counter is used to count
	// the loops so that during digit output, the decimal
	// point character can be issued at the proper place
	//
	mov	x15, #0			// decimal point counter
30:
	// loop re-entry here
	add	x15, x15, #1		// decimal point conter
	mov	x1, HAND_OPR		// Variable handle number
	bl	ClearVariable

	// Need x9 offset from address of variable M.S.word
	ldr	x9, =IntWSize
	ldr	x9, [x9]		// x9 is count integer words
	sub	x9, x9, #1		// Integer part (words- 1) to align pointer
	sub	x9, xzr, x9, lsl X8SHIFT3BIT // (0 - (x9*8)) = Neg offset to L.S Word Integer Part

	mov	x0, #10			// the OPR variable has value of 10.0
	str	x0, [x12, x9]		// [address, offset] L.S. integer word is 10

	//
	// first subtract to see if less than 10.0
	//
	mov	x1, HAND_ACC		// Variable handle number
	mov	x2, HAND_OPR
	mov	x3, HAND_OPR
	bl	SubtractVariable	// Subtract 10,  OPR = ACC - OPR
	mov	x1, HAND_OPR
	bl	TestIfNegative		// set x0 to 1 if negative
	cbnz	x0, 40f			// Yes negative, stop
	//
	// Divide by 10 and loop
	//
	mov	x1, HAND_ACC		// Variable handle number
	bl	DivideByTen		// divide by power of 10
	b.al	30b			// loop back
40:
	//
	// setup counters and pointers to print digits
	//
	ldr	x16, =NoSigDig		// number of digits (in fraction part)
	ldr	x16, [x16]

	// Need x9 offset from address of variable M.S.word
	ldr	x9, =IntWSize
	ldr	x9, [x9]		// x11 is count integer words
	sub	x9, x9, #1		// Subtract 1 now x9 = (words -1)
	sub	x9, xzr, x9, lsl X8SHIFT3BIT // (0 - (x9 * 8) = Neg offset to L.S. word

	//
	// Digit loop... Get next digit and form ascii
	//
50:
	ldrb	w0, [x11, x9]		// x11 address, x9 offset
	orr	w0, w0, #'0'		// Form ascii charactger
	bl	CharOutFmt
	mov	w0, #0			// erase the printed character before next loop
	strb	w0, [x11, x9]
	//
	// check desimal separator
	//
	cbz	x15, 60f		// branch if decimal point has already been output
	sub	x15, x15, #1
	cbnz	x15, 60f
	mov	x0, #'.'		// When reach zero, add decimal point to print character stream
	bl	CharOutFmt
60:
	//
	// multi by 10 to emit the binary coded decimal value
	//
	mov	x1, HAND_ACC		// Variable handle number
	bl	MultiplyByTen		// ACC = ACC * 10.0
	sub	x16, x16, #1
	cbnz	x16, 50b		// loop back to next digit
	//
	// Options for extended digits
	//
	ldr	x16, =NoExtDig		// Get current setting for extended digits to print
	ldr	x16, [x16]
	cbz	x16, done_print		// No etended digits skip to end

	// extended digit delimeter
	mov	x0, #'('		// Use parenthesis to delimiter extended digits
	bl	CharOutFmt
	//
	// Get next digit and form ascii
	//
70:
	ldrb	w0, [x11, x9]		// x11 address x9 offset
	orr	w0, w0, #'0'		// form ascii
	bl	CharOutFmt
	mov	w0, #0			// erase before next loop
	strb	w0, [x11, x9]
	// multi by 10
	mov	x1, HAND_ACC
	bl	MultiplyByTen
	sub	x16, x16, #1
	cbnz	x16, 70b
	// extended digit delimiter
	mov	x0, #')'		// Closing parenthesis
	bl	CharOutFmt

done_print:
	bl	CROut
	bl	CROut

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
	ldr	x15, [sp, #80]
	ldr	x16, [sp, #88]
	ldr	x17, [sp, #96]
	add	sp, sp, #128
	ret
