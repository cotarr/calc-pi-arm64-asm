/* ----------------------------------------------------------------
	math.s

	Created:   2021-02-18
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
	FP_Initialize
	Set_Word_Size
------------------------------------------------------------- */

   	.include "arch-include.s"	// .arch and .cpu directives
   	.include "header-include.s"
	.include "math-subr.s"
	.include "math-rotate.s"
	.include "math-mult.s"
	.include "math-div.s"
	.include "math-input.s"
	.include "math-output.s"
	.include "math-debug.s"

/* ------------------------------------------------------------ */
	// Functions
	.global	FP_Initialize
	.global	Set_Word_Size

	// Data Tables
	.global RegAddTable

	// Data Configuration Variables
	.global	NoSigDig, NoExtDig
	.global	FctLSW_WdPtr_Static, FctLSW_WdPtr_Optimized
	.global	Word_Size_Static, Word_Size_Optimized
	.global	MathMode

	//  Constants, do not change
	.global IntWSize, FctWsize, VarWSize
	.global IntMSW_WdPtr
	.global IntLSW_WdPtr
	.global FctMSW_WdPtr
	.global	VarLSW_WdPtr
	.global	MinimumWord
	.global WordFFFF, Word8000, Word0000
	.global Word0123, Word1122


// ----------------- Memory Map of Typical Variable ------------
//
//			============	Next Variable start here
//	Int_MS_Word	------------	Top word in Integer Part
//	     		------------
//	Int_LS_Word	------------	Bottom word in integer part
//	Fct_MS_Word	------------	Top Word in Fraction Part
//			------------
//			    . . .
//			------------	Bottom word Optimized Accuracy
//			------------
//			------------
//		    	    . . .
//	Fct_LS_Word   	------------	Lowest valid word in Fraction Part
//			------------	Guard word n
//			------------	Guard word 2
//			------------	Bottom Word in Fraction part (Static Accuracy)
//			------------	Allocated, but not used
//			------------
//			    . . .
//			------------
//		     	------------
//	Var_LS_Word	=============	Base address of variable (lowest RAM address)
//
// ----------------- Memory Map of Typical Variable ------------

// -----------------------------------------------------
	.data   // Section containing initialized data
// -----------------------------------------------------

//
// Pointers to variables  (word address table)
//
	.align	4
RegAddTable:
	.quad	FP_Acc		// Handle = 0
	.quad	FP_Opr		// Handle = 1
	.quad	FP_WorkA	// Handle = 2
	.quad	FP_WorkB	// Handle = 3
	.quad	FP_WorkC	// Handle = 4
	.quad	FP_X_Reg	// Handle = 5
	.quad	FP_Y_Reg	// Handle = 6
	.quad	FP_Z_Reg	// Handle = 7
	.quad	FP_T_Reg	// Handle = 8
	.quad	FP_Reg0		// handle = 9
	.quad	FP_Reg1		// Handle = 10
	.quad	FP_Reg2		// Handle = 11
	.quad	FP_Reg3		// Handle = 12
/*
	.quad	FP_Reg4		// Handle = 13
	.quad	FP_Reg5		// Handle = 14
	.quad	FP_Reg6		// Handle = 15
	.quad	FP_Reg7		// Handle = 16
*/

// Register names (8 bytes per name, ASCII null terminated)
// Handle is converted to name address in GetVarNameAdd
//

	.align	4
RegNameTable:
	.ascii	"ACC   "
	.byte	0,0
	.ascii	"OPR   "
	.byte	0,0
	.ascii	"WORKA "
	.byte	0,0
	.ascii	"WORKB "
	.byte	0,0
	.ascii	"WORKC "
	.byte	0,0
	.ascii	"XREG  "
	.byte	0,0
	.ascii	"YREG  "
	.byte	0,0
	.ascii	"ZREG  "
	.byte	0,0
	.ascii	"TREG  "
	.byte	0,0
	.ascii	"REG0  "
	.byte	0,0
	.ascii	"REG1  "
	.byte	0,0
	.ascii	"REG2  "
	.byte	0,0
	.ascii	"REG3  "
	.byte	0,0

/*	.ascii	"REG4  "
	.byte	0,0
	.ascii	"REG5  "
	.byte	0,0
	.ascii	"REG6  "
	.byte	0,0
	.ascii	"REG7  "
	.byte	0,0
*/
	.align 4
// ---------------------------------------------------------
// ARM64 does not allow 64 bit immediate values.
// As alternative, I have stored some useful values here.
// These should be treated as constants
// ---------------------------------------------------------
IntWSize:	.quad	INT_WSIZE
FctWsize:	.quad	FCT_WSIZE
VarWSize:	.quad	VAR_WSIZE
MinimumWord:	.quad	MINIMUM_WORD

IntMSW_WdPtr:	.quad	VAR_WSIZE - 1
IntLSW_WdPtr:	.quad	VAR_WSIZE - INT_WSIZE
FctMSW_WdPtr:	.quad	VAR_WSIZE - INT_WSIZE - 1
VarLSW_WdPtr:	.quad	0

MathMode:	.quad	0

WordFFFF:	.quad	0x0FFFFFFFFFFFFFFFF
Word8000:	.quad	0x08000000000000000
Word0000:	.quad	0x00000000000000000
Word0123:	.quad	0x00123456789abcdef
Word1122:	.quad	0x01122334455667788
//                         0123456789abcdef <-- Ruler

// -----------------------------------------------------
	.bss	// Section contain un-initialized data
// -----------------------------------------------------

		.align 4
FP_Acc:		.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Opr:		.skip	VAR_WSIZE * BYTE_PER_WORD
FP_WorkA:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_WorkB:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_WorkC:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_X_Reg:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Y_Reg:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Z_Reg:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_T_Reg:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg0:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg1:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg2:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg3:	.skip	VAR_WSIZE * BYTE_PER_WORD
/*
FP_Reg4:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg5:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg6:	.skip	VAR_WSIZE * BYTE_PER_WORD
FP_Reg7:	.skip	VAR_WSIZE * BYTE_PER_WORD	// If changing, must adjust --> TOPHAND
*/
//
//  Miscellaneous program variables
//
		.align	4
NoSigDig:	.skip	BYTE_PER_WORD   // Number of Significant Digits
NoExtDig:	.skip	BYTE_PER_WORD   // Number of Extended Digits

Word_Size_Static:	.skip	BYTE_PER_WORD
Word_Size_Optimized:	.skip	BYTE_PER_WORD

FctLSW_WdPtr_Static:	.skip	BYTE_PER_WORD
FctLSW_WdPtr_Optimized:	.skip	BYTE_PER_WORD

// -----------------------------------------------------
	.text
	.align 4
// -----------------------------------------------------

/*--------------------------------------------------------------
  On program start, initialize the variable space

  Input:   none

  Output:  none

--------------------------------------------------------------*/
FP_Initialize:
	sub	sp, sp, #48		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	//
	ldr	x1, =NoSigDig		// Initial significatn Digits
	mov	x0, INIT_SIG_DIG
	mov	x0, #60			// NOTE: limited immediate size 16 bit
	bl	SetDigitAccuracy
	//
	// Set initial extended digits
	//
	ldr	x1, =NoExtDig		// Initial significatn Digits
	mov	x0, INIT_EXT_DIG
	bl	SetExtendedDigits

	ldr	x0, =10f
	bl	StrOut

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	add	sp, sp, #48
	ret
10:	.asciz	"Variables initialized.\n\n"
	.align 4

/*--------------------------------------------------------------
  Set Number of Words Variables

  Input:   x0 - Number of 64 bit words in mantissa

  Output:  none

--------------------------------------------------------------*/
Set_Word_Size:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x10, [sp, #24]
	str	x11, [sp, #32]
	str	x17, [sp, #40]		// VAR_MSW_OFST
//
// [Word_Size_Static] is variable for number 32 bit words in mantissa
//
	ldr	x11, =Word_Size_Static		// [Word_Size_Static] number 64 bit words
	str	x0, [x11]
	ldr	x11, =Word_Size_Optimized	// Default [Word_Size_Optimized] value
	str	x0, [x11]
//
// [FctLSW_WdPtr_Static] is variable to offset to L.S. Word in mantissa
//
	ldr	x10, =IntMSW_WdPtr	// Offset Top Word in Integer part
	ldr	x10, [x10]
	add	x10, x10, #1		// Point 1 past
	sub	x10, x10, x0 // subtrat word size
 	ldr	x11, =FctLSW_WdPtr_Static
	str	x10, [x11]
	ldr	x11, =FctLSW_WdPtr_Optimized
	str	x10, [x11]

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x10,  [sp, #24]
	ldr	x11,  [sp, #32]
	ldr	x17,  [sp, #40]
	add	sp, sp, #64
	ret

// ---------------------------------------------
	.end
