/* ----------------------------------------------------------------
	math-debug.s
	Include file for math.s

	Created:   2021-02-18
	Last edit: 2021-02-18

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

	.global	PrintVar
	.global	PrintHex
	.global	DebugFillVariable
// .global	EndianCheck

/*--------------------------------------------------------------
;   Print specified variable in HEX format
;
;   Input:  x1 = variable handle number
;
;   Output: none
;
;--------------------------------------------------------------*/
PrintVar:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x10,  [sp, #32]		// Variable handle #
	str	x11,  [sp, #40]		// Variable base Address
	str	x12,  [sp, #48]		// Pointer offset
	str	x13,  [sp, #56]		// Word Counter
	str	x14,  [sp, #64]		// Line Feed Counter


	mov	x10, x1			// Save register handle
	ldr	x0, =RegNameTable	// Point to start of address table
	mov	x1, x10, LSL #3		// 8 byte per fixed length string
	add	x0, x0, x1
	bl	StrOut			// Print variable name
	mov	x0, #' '
	bl 	CharOut
	mov	x0, #'('
	bl	CharOut
	mov	x0, x10			// get variable handle
	bl	PrintWordB10		// print handle number
	mov	x0, #')'
	bl	CharOut
	bl	CROut
	//
	// Print all of mantissa in words
	//
	ldr	x11, =RegAddTable	// x11 address vector table
	mov	x1, x10, lsl #3		// 64 bit address size
	add	x11, x11, x1
	ldr	x11, [x11]		// x11 point to variable address
	ldr	x12,=VAR_MSW_OFST	// Offset pointer

	mov	x14, #0			// line feed counter
	ldr	x13, =No_Word
	ldr     x13, [x13]		// x13 mantissa word counter
	10:

	ldr     x0, [x11, x12]		// get word
	bl	PrintWordHex		// output hex word
	mov	x0, #' '		// print space
	bl	CharOut
	add	x14, x14, #1
	cmp	x14, #0x07
	b.le	20f			// need line feed?
	bl	CROut			// yes, CR LF
	mov	x14, #0			// reset counter
	20:
	sub	x12, x12, #BYTE_PER_WORD // pointer to next word
	subs	x13, x13, #1		// decrement word counter
	b.ne	10b	  		// Done? no... loop

	bl	CROut

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10,  [sp, #32]
	ldr	x11,  [sp, #40]
	ldr	x12,  [sp, #48]
	ldr	x13,  [sp, #56]
	ldr	x14,  [sp, #64]
	add	sp, sp, #80
	ret

/*;--------------------------------------------------------------
;   Print all variables in HEX format
;
;   Input:  none
;
;   Output: none
;
;--------------------------------------------------------------*/
PrintHex:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x10,  [sp, #32]		// Variable handle #
	str	x11,  [sp, #40]		// Variable base Address
	str	x12,  [sp, #48]		// Variable offset
	str	x13,  [sp, #56]		// Word Counter
//
// print heading
//
	ldr	x0, =.HexTabString	// print table headings
	bl	StrOut
	bl	CROut
	mov	x10, #0			// point at first variable handle

// loop to here for each register, first print register name
10:
	ldr	x0, =RegNameTable	// Point to name string table
	mov	x1, x10, lsl #3		// 8 byte per fixed length string
	add	x0, x0, x1
	bl	StrOut			// Print variable name

	mov	x0, #'('
	bl	CharOut
	cmp	x10, #9
	bgt	20f
	mov	x0, #' '
	bl	CharOut
20:
	mov	x0, x10			// Get handle number
	bl	PrintWordB10		// Print handle number
	mov	x0, #')'
	bl	CharOut
	mov	x0, #' '
	bl	CharOut

//
// Print word values Mantissa
//
	ldr	x11, =RegAddTable	// variable vector table
	mov	x1, x10, lsl #3		// 8 byte / 64 bit address
	add	x11, x11, x1		// offset from handle
	ldr	x11, [x11]		// x11 point at variable
	ldr	x12, =VAR_MSW_OFST	// Offset pointer

	mov	x13, #4			// count for words to show
30:
	ldr	x0, [x11, x12]
	bl	PrintWordHex		// output hex byte
	mov	x0, #' '		// print space
	bl	CharOut
	sub	x12, x12, #BYTE_PER_WORD // address next word
	subs	x13, x13, #1		// decrement word counter
	b.ne	30b	  		// Done? no... loop
//
//  Print L.S.Word
//
	mov	x0, #'.'
	bl	CharOut
	mov	x0, #'.'
	bl	CharOut
	mov	x0, #' '
	bl	CharOut

	ldr	x12, =LSWOfst
	ldr	x12, [x12]
	add	x12, x12, #GUARDBYTES

	ldr	x0, [x11, x12]
	bl	PrintWordHex
	mov	x0, #' '
	bl	CharOut

	bl	CROut
//
//  increment counter and  loop back
//
	add	x10, x10, #1		// Increment handle to next variable
	cmp	x10, #TOPHAND		// shall we do all?
	b.le	10b
	bl	CROut
//
//  return, we are done
//
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x10,  [sp, #32]
	ldr	x11,  [sp, #40]
	ldr	x12,  [sp, #48]
	ldr	x13,  [sp, #56]
	add	sp, sp, #64
	ret
;
.HexTabString:
	.asciz	"REG   Hand M.S. Word                      (no guard) L.S.W"
	.align 3


/*;--------------------------------------------------------------
;   DEBUG - Fill variable with sequential numbers
;
;   MSB = 1 (higher address), then increment value 2, 3, 4  as approach LSB (lower address)
;
;   Input:  x1 = handle of variable
;
;   Output: none
;
;--------------------------------------------------------------*/
DebugFillVariable:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]		// Variable handle #

	ldr	x2, =RegAddTable	// Address of vector table
	mov	x0, x1, lsl #3		// offset = index * size
	add	x2, x2, x0
	ldr	x2, [x2]		// x2 holds variable address

//	push	{x2}

	ldr	x0, =VAR_MSB_OFST
	add	x2, x2, x0		// x2 point at mantissa M.S.Byte
	mov	x0, #0x11		// fill value 11,12,13...
	ldr	x1, =No_Byte
	ldr	x1, [x1]		// counter

10:
	strb	w0, [x2], #-1		// store ane decrement
	add	x0, x0, #1
	subs	x1, x1, #1
	b.ne	10b
	bl	CROut
	b.al	20f
//
// Option to set sign bit, comment out otherwise
//
//	pop	{x2}
//	ldr	x0, =VAR_MSB_OFST
//	add	x2, x2, x0
//	ldrb	x0, [x2]
//	orr	x0, x0, #0x80
//////////////////// Set Sign Bit //////////////////////////////
//	strb	x0, [x2]
//////////////////////////////////////////////////////////////////////////////

20:	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	add	sp, sp, #64
	ret
