/* ----------------------------------------------------------------
	math.s

	Created:   2021-02-18
	Last edit: 2021-02-21

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
	.include "math-debug.s"

/* ------------------------------------------------------------ */

	.global	FP_Initialize
	.global	Set_No_Word

	// data variables
	.global	No_Word, No_Byte,
	.global NoSigDig, NoExtDig

	// Constants (too big for immediate values)
	.global IntWSize, FctWsize, VarWSize
	.global IntBSize, FctBsize, VarBSize
	.global VarMswOfst, VarMsbOfst
	.global InitNoWord
	.global	MinimumWord
	.global WordFFFF, Word8000, Word0000
// -----------------------------------------------------
	.data   // Section containing initialized data
// -----------------------------------------------------

/*  = = = = =   Memory Map of Fixed Point Variable = = = = = =

M.S Integer Word       <-- (base addr) + VAR_WSIZE - (1 word)
  ...
LS Integer Word        <-- (base addr) + VAR_WSIZE  INT_WSIZE
  (decimal separator goes here)
M.S. Fracton word      <-- (base addr) + FCT_WSIZE - (1 word)
  ...
  ...
  ...
L.S. Fraction word    <-- (base addr) + GUARDWORDS
  ...
Guard-words           <-- (base addr) + [LSWOfst]
  ...
Unused words
  ...
Fraction L.S.Word     <-- (base addr) <-- A variable starts here

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

IntBSize:	.quad	INT_BSIZE
FctBsize:	.quad	FCT_BSIZE
VarBSize:	.quad	VAR_BSIZE

VarMswOfst:	.quad	VAR_MSW_OFST
VarMsbOfst:	.quad	VAR_MSB_OFST

InitNoWord:	.quad	INIT_NO_WORD
MinimumWord:	.quad	MINIMUM_WORD

WordFFFF:	.quad	0x0FFFFFFFFFFFFFFFF
Word8000:	.quad	0x08000000000000000
Word0000:	.quad	0x00000000000000000
//                         0123456789abcdef <-- Ruler

// -----------------------------------------------------
	.bss	// Section contain un-initialized data
// -----------------------------------------------------

		.align 4
FP_Acc:		.skip	VAR_BSIZE
FP_Opr:		.skip	VAR_BSIZE
FP_WorkA:	.skip	VAR_BSIZE
FP_WorkB:	.skip	VAR_BSIZE
FP_WorkC:	.skip	VAR_BSIZE
FP_X_Reg:	.skip	VAR_BSIZE
FP_Y_Reg:	.skip	VAR_BSIZE
FP_Z_Reg:	.skip	VAR_BSIZE
FP_T_Reg:	.skip	VAR_BSIZE
FP_Reg0:	.skip	VAR_BSIZE
FP_Reg1:	.skip	VAR_BSIZE
FP_Reg2:	.skip	VAR_BSIZE
FP_Reg3:	.skip	VAR_BSIZE
/*
FP_Reg4:	.skip	VAR_BSIZE
FP_Reg5:	.skip	VAR_BSIZE
FP_Reg6:	.skip	VAR_BSIZE
FP_Reg7:	.skip	VAR_BSIZE	// If changing, must adjust --> TOPHAND
*/
//
//  Miscellaneous program variables
//
		.align	4
No_Word:	.skip	BYTE_PER_WORD	// Number of words in mantissa
No_Byte:	.skip	BYTE_PER_WORD	// Number of bytes in mantissa (32_64_CHECK align and RESD vs DQ)
LSWOfst:	.skip	BYTE_PER_WORD	// Offset address of MS Word at No_Word accuracy
D_Flt_Word:	.skip	BYTE_PER_WORD	// Default number of words in mantissa
D_Flt_Byte:	.skip	BYTE_PER_WORD	// Default number of bytes in mantissa
D_Flt_LSWO:	.skip	BYTE_PER_WORD	// Default Offset address of MS Word

NoSigDig:	.skip	BYTE_PER_WORD   // Number of Significant Digits
NoExtDig:	.skip	BYTE_PER_WORD   // Number of Extended Digits



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
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]

	ldr	x1, =NoSigDig		// Initial significatn Digits
	mov	x0, INIT_SIG_DIG
	str	x0, [x1]

	ldr	x1, =NoExtDig		// Initial significatn Digits
	mov	x0, INIT_EXT_DIG
	str	x0, [x1]

	mov	x0, INIT_NO_WORD
	bl	Set_No_Word

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	add	sp, sp, #32
	ret


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
	str	x10,  [sp, #24]
	str	x11,  [sp, #32]
	str	x17, [sp, #40]		// VAR_MSW_OFST

	ldr	x17, =VarMswOfst	// VAR_MSW_OFST is to big for immediate value
	ldr	x17, [x17]		// Store in register as constant value
//
// [No_Word] is variable for number 32 bit words in mantissa
//
	ldr	x11, =No_Word		// [No_Word] number 64 bit words
	str	x0, [x11]
	ldr	x11, =D_Flt_Word	// Default [No_Word] value
	str	x0, [x11]
//
// [No_Byte] is variable for number 8 bit bytes in mantissa
//
	ldr	x11, =No_Byte
	mov	x10, x0, lsl WORDSIZEBITS // Convert to bytes [No_Byte]
	str	x10, [x11]
	ldr	x11, =D_Flt_Byte	// Default value
	str	x10, [x11]
//
// [LSWOfst] is variable to offset to L.S. Word in mantissa
//
	add	x11, x17, BYTE_PER_WORD
	sub	x10, x11, x10		// MSByte-[No_Byte]
	ldr	x11, =LSWOfst
	str	x10, [x11]
	ldr	x11, =D_Flt_LSWO
	str	x10, [x11]		// Default value

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
