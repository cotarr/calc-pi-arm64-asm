/* ----------------------------------------------------------------
	math-output.s

	Print binary variable in base 10
	Input binary variable from base 10

	Created:   2021-02-22
	Last edit: 2021-03-02

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
	PrintResult
------------------------------------------------------------- */

	.global	PrintVariable
	.global PrintResult

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
	ldr	x17, =IntMSW_WdPtr	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Treat this as a constant in this function
	lsl	x17, x17, X8SHIFT3BIT
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
	mov	x2, HAND_ACC
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

	// Need x9 offset from address of variable L.S.word
	ldr	x9, =Word_Size_Static
	ldr	x9, [x9]		// x0 is count integer words
	sub	x9, x9, #1		// subtract 1 now x0 = (words - 1)
	//
	// Index to guard word 2
	sub	x9, x9, #1

	sub	x9, xzr, x9, lsl X8SHIFT3BIT // (0 - (x9 * 8) = Neg offset to L.S. word

	// ----- select this to round off -------------
	movz	x0, #0x1, lsl #32	// 0x0000000100000000
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

	// Need x9 offset from address of integer part L.S.word
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

	// Need x9 offset from address of Integer Part L.S.word
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

	ldr	x16, =NoSigDig		// Reset number of digits (in fraction part)
	ldr	x16, [x16]		// i.e. counting starts right of decimal point
	add	x16, x16, #1		// align counter to requested digits

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

/* --------------------------------------------------------------

  Print Calculation Result (abbreviated format)

  During command input, this routine is intended
  to show the user an abbreviated view of the stack

-------------------------------------------------------------- */
PrintResult:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]


// %%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%
// This must match SetDigitAccuracy in util.s

	ldr	x2, =IntWSize		// words in integer part
	ldr	x2, [x2]		// number of Int part words
	add	x2, x2, GUARDWORDS
	mov	x0, PREVIEW_DIG
	bl	Digits_2_Words
	add	x2, x2, x0		// total words

	ldr	x3, =IntMSW_WdPtr	// Top word offset
	ldr	x3, [x3]
	add	x3, x3, #1
	sub	x3, x3, x2
// %%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%


	// Temporarily save existing variables on the stack
	// Assign an new value to each one

	sub	sp, sp, #80		// Room for 10 more words
	str	x30, [sp, #0]
	str	x29, [sp, #8]

	ldr	x1, =NoSigDig
	ldr	x0, [x1]
	str	x0, [sp, #16]
	mov	x0, PREVIEW_DIG
	str	x0, [x1]

	ldr	x1, =NoExtDig
	ldr	x0, [x1]
	str	x0, [sp, #24]
	mov	x0, #0
	str	x0, [x1]

	ldr	x1, =Word_Size_Static
	ldr	x0, [x1]
	str	x0, [sp, #32]
	str	x2, [x1]

	ldr	x1, =Word_Size_Optimized
	ldr	x0, [x1]
	str	x0, [sp, #40]
	str	x2, [x1]

	ldr	x1, =FctLSW_WdPtr_Static
	ldr	x0, [x1]
	str	x0, [sp, #48]
	str	x3, [x1]		// x3 from above

	ldr	x1, =FctLSW_WdPtr_Optimized
	ldr	x0, [x1]
	str	x0, [sp, #56]
	str	x3, [x1]		// x3 from above

	//
	// Print result at reduced accuracy
	//
/*
	mov	x1, HAND_XREG
	mov	x2, HAND_ACC
	bl	CopyVariable

	bl	CROut
	mov	x0, #0			// formatting disabled
	bl	CharOutFmtInit		// initialize format output
	bl	PrintVariable		// print variable unformatted
*/
	bl	CROut
	bl	PrintStack
	bl	CROut

	//
	// Restore accuracy varaibles
	//
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]

	ldr	x1, =NoSigDig
	ldr	x0, [sp, #16]
	str	x0, [x1]

	ldr	x1, =NoExtDig
	ldr	x0, [sp, #24]
	str	x0, [x1]

	ldr	x1, =Word_Size_Static
	ldr	x0, [sp, #32]
	str	x0, [x1]

	ldr	x1, =Word_Size_Optimized
	ldr	x0, [sp, #40]
	str	x0, [x1]

	ldr	x1, =FctLSW_WdPtr_Static
	ldr	x0, [sp, #48]
	str	x0, [x1]

	ldr	x1, =FctLSW_WdPtr_Optimized
	ldr	x0, [sp, #56]
	str	x0, [x1]

	add	sp, sp, #80

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	add	sp, sp, #64
	ret


PrintStack:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x3,  [sp, #40]

	mov	x1, HAND_XREG
	mov	x2, HAND_ACC
	bl	CopyVariable
	ldr	x0, =RegNameTable
	add	x0, x0, #40		// handle 5 * 8 bit
	bl	StrOut
	mov	x0, #0			// formatting disabled
	bl	CharOutFmtInit		// initialize format output
	bl	PrintVariable		// print variable unformatted

	mov	x1, HAND_YREG
	mov	x2, HAND_ACC
	bl	CopyVariable
	ldr	x0, =RegNameTable
	add	x0, x0, #48		// handle 6 * 8 bit
	bl	StrOut
	mov	x0, #0			// formatting disabled
	bl	CharOutFmtInit		// initialize format output
	bl	PrintVariable		// print variable unformatted

	mov	x1, HAND_ZREG
	mov	x2, HAND_ACC
	bl	CopyVariable
	ldr	x0, =RegNameTable
	add	x0, x0, #56		// handle 7 * 8 bit
	bl	StrOut
	mov	x0, #0			// formatting disabled
	bl	CharOutFmtInit		// initialize format output
	bl	PrintVariable		// print variable unformatted

	mov	x1, HAND_TREG
	mov	x2, HAND_ACC
	bl	CopyVariable
	ldr	x0, =RegNameTable
	add	x0, x0, #64		// handle 8 * 8 bit
	bl	StrOut
	mov	x0, #0			// formatting disabled
	bl	CharOutFmtInit		// initialize format output
	bl	PrintVariable		// print variable unformatted

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	add	sp, sp, #64
	ret
