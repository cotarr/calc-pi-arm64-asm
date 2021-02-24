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
	Set_No_Word
------------------------------------------------------------- */

   	.include "arch-include.s"	// .arch and .cpu directives
   	.include "header-include.s"
	.include "math-subr.s"
	.include "math-rotate.s"
	.include "math-input.s"
	.include "math-output.s"
	.include "math-debug.s"

/* ------------------------------------------------------------ */
	// Functions
	.global	FP_Initialize
	.global	Set_No_Word

	// Sata variables
	.global	NoSigDig, NoExtDig
	.global	F_No_Word, V_No_Word
	.global	F_VarLSWOfst, V_VarLSWOfst
	.global	F_FctLSWOfst, V_FctLSWOfst

	// ----------------------------------------------------
	// These 4 don't change after initialization, treated like constants
	.global F_VarMSWOfst
	.global F_IntMSWOfst
	.global F_IntLSWOfst
	.global F_FctMSWOfst

	// ----------------------------------------------------
	// Constants (too big for immediate values)
	.global IntWSize, FctWsize, VarWSize
	.global	MinimumWord
	.global WordFFFF, Word8000, Word0000
	.global Word0123, Word1122

// -----------------------------------------------------
	.data   // Section containing initialized data
// -----------------------------------------------------

/*  = = = = =   Memory Map of Fixed Point Variable = = = = = =

F_VarMSWOfst Top word of entire variable (equals F_IntMSWOfst)
F_IntMSWOfst Top word of integer part (equals F_VarMSOfst)
  (integer data)
F_IntLSWOfst Bottom word of integer part

F_FctMSWOfst Top word of fraction part
  (fraction data)
F_FctLSWOfst Bottom word of fraction part (equals F_VarLSWOfst)
F_VarLSWOfst Bottom word of entire variable (equals F_FctLSWOfst)

 = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */


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

// F - Fixed precision config variables (does not change to optimize speed)
F_No_Word:	.skip	BYTE_PER_WORD
F_VarMSWOfst:	.skip	BYTE_PER_WORD
F_VarLSWOfst:	.skip	BYTE_PER_WORD
F_IntMSWOfst:	.skip	BYTE_PER_WORD
F_IntLSWOfst:	.skip	BYTE_PER_WORD
F_FctMSWOfst:	.skip	BYTE_PER_WORD
F_FctLSWOfst:	.skip	BYTE_PER_WORD

// V - Variable precision config (can change to increase speed)
V_No_Word:	.skip	BYTE_PER_WORD
V_VarLSWOfst:	.skip	BYTE_PER_WORD
V_FctLSWOfst:	.skip	BYTE_PER_WORD

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
	// These are constants
	//
	// Top of entire variable
	// Top of Intger part       (same)
	//
	// These never change, treat like constant
	//
	ldr	x1, =VarWSize
	ldr	x0, [x1]
	sub	x0, x0, #1
	ldr	x2, =F_VarMSWOfst
	str	x0, [x2]
	ldr	x2, =F_IntMSWOfst
	str	x0, [x2]
	//
	// Bottom of Integer part
	//
	// This never changes, treat like constant
	//
	ldr	x1, =VarWSize
	ldr	x0, [x1]
	ldr	x2, =IntWSize
	ldr	x2, [x2]
	sub	x0, x0, x2
	ldr	x2, =F_IntLSWOfst
	str	x0, [x2]
	//
	// Top of Fraction Part
	//
	// This never changes, treat like constant
	//
	ldr	x1, =VarWSize
	ldr	x0, [x1]
	sub	x0, x0, #1
	ldr	x2, =IntWSize
	ldr	x2, [x2]
	sub	x0, x0, x2
	ldr	x2, =F_FctMSWOfst
	str	x0, [x2]
	//
	// Set initial accuracy in digits base 10
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
Set_No_Word:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x10, [sp, #24]
	str	x11, [sp, #32]
	str	x17, [sp, #40]		// VAR_MSW_OFST

	ldr	x17, =F_VarMSWOfst	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
//
// [F_No_Word] is variable for number 32 bit words in mantissa
//
	ldr	x11, =F_No_Word		// [F_No_Word] number 64 bit words
	str	x0, [x11]
	ldr	x11, =V_No_Word	// Default [V_No_Word] value
	str	x0, [x11]
//
// [F_VarLSWOfst] is variable to offset to L.S. Word in mantissa
//
	mov	x10, x17		// offset to M.S.Word
	add	x10, x10, BYTE_PER_WORD	// Point 1 past
	sub	x10, x10, x0, lsl X8SHIFT3BIT // subtrat no words
	ldr	x11, =F_VarLSWOfst
	str	x10, [x11]
	ldr	x11, =V_VarLSWOfst
	str	x10, [x11]
	ldr	x11, =F_FctLSWOfst
	str	x10, [x11]
	ldr	x11, =V_FctLSWOfst
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
