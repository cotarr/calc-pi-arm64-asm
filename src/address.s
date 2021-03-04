/* ----------------------------------------------------------------
	address.s

	Calculate address pointers and offset pointers

	Created:   2021-02-24
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

------------------------------------------------------------- */

   	.include "arch-include.s"	// .arch and .cpu directives
   	.include "header-include.s"

/* ------------------------------------------------------------ */

	.global	set_x9_to_Int_MS_Word_Addr_Offset
	.global	set_x9_to_Int_LS_Word_Addr_Offset
	.global	set_x9_to_Fct_MS_Word_Addr_Offset
	.global	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	.global	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	.global set_x9_to_Var_LS_Word_Addr_Offset

	.global set_x10_to_Word_Size_Static
	.global set_x10_to_Word_Size_Static_Minus_1
	.global	set_x10_to_Word_Size_Optimized
	.global set_x10_to_Word_Size_Optimized_Minus_1

	.global	set_x11_to_Int_MS_Word_Address
	.global	set_x11_to_Int_LS_Word_Address
	.global	set_x11_to_Fct_MS_Word_Address
	.global	set_x11_to_Fct_LS_Word_Address_Static
	.global	set_x11_to_Fct_LS_Word_Address_Optimized
	.global	set_x11_to_Var_LS_Word_Address

	.global	set_x12_to_Int_MS_Word_Address
	.global	set_x12_to_Int_LS_Word_Address
	.global	set_x12_to_Fct_MS_Word_Address
	.global	set_x12_to_Fct_LS_Word_Address_Static
	.global	set_x12_to_Fct_LS_Word_Address_Optimized
	.global	set_x12_to_Var_LS_Word_Address

	.global	set_x13_to_Int_MS_Word_Address
	.global	set_x13_to_Int_LS_Word_Address
	.global	set_x13_to_Fct_MS_Word_Address
	.global	set_x13_to_Fct_LS_Word_Address_Static
	.global	set_x13_to_Fct_LS_Word_Address_Optimized
	.global	set_x13_to_Var_LS_Word_Address

	.global set_x14_to_Var_LS_Word_Address

	.global	PrintAddressOffsets
	.global PrintAccuracyVars

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

	.text
	.align 4

/* ---------------------------------------
  Offset Pointer calculations

  Input: none

  Output: x9 hold offset in bytes

  These are byte (8 bit) address pointers
  to the 64 bit word referenced.
  The offset is always returned in x9
----------------------------------------- */

set_x9_to_Int_MS_Word_Addr_Offset:
	ldr	x9, =IntMSW_WdPtr
	ldr	x9, [x9]
	lsl	x9, x9, X8SHIFT3BIT
	ret

set_x9_to_Int_LS_Word_Addr_Offset:
	ldr	x9, =IntLSW_WdPtr
	ldr	x9, [x9]
	lsl	x9, x9, X8SHIFT3BIT
	ret

set_x9_to_Fct_MS_Word_Addr_Offset:
	ldr	x9, =FctMSW_WdPtr
	ldr	x9, [x9]
	lsl	x9, x9, X8SHIFT3BIT
	ret

set_x9_to_Fct_LS_Word_Addr_Offset_Static:
	ldr	x9, =FctLSW_WdPtr_Static
	ldr	x9, [x9]
	lsl	x9, x9, X8SHIFT3BIT
	ret

set_x9_to_Fct_LS_Word_Addr_Offset_Optimized:
	ldr	x9, =FctLSW_WdPtr_Optimized
	ldr	x9, [x9]
	lsl	x9, x9, X8SHIFT3BIT
	ret

set_x9_to_Var_LS_Word_Addr_Offset:
	mov	x9, #0
	ret

/* ---------------------------------------
  Obtain variable size

  Input: none

  Output: x10 holds a count of 64 bit words
----------------------------------------- */

set_x10_to_Word_Size_Static:
	ldr	x10, =Word_Size_Static	// Pointer to of words variable3
	ldr	x10, [x10]		// Number words in manti
	ret

set_x10_to_Word_Size_Static_Minus_1:
	ldr	x10, =Word_Size_Static	// Pointer to of words variable
	ldr	x10, [x10]		// Number words in manti
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)
	ret
set_x10_to_Word_Size_Optimized:
	ldr	x10, =Word_Size_Optimized // Pointer to of words variable
	ldr	x10, [x10]		// Number words in manti
	ret

set_x10_to_Word_Size_Optimized_Minus_1:
	ldr	x10, =Word_Size_Optimized // Pointer to of words variable
	ldr	x10, [x10]		// Number words in manti
	sub	x10, x10, #1		// Count - 1 (Note minimum count is 2)
	ret



/* ---------------------------------------
  Address Pointer calculations

  Input:   x1,  x2, or  x3 Variable nandle number

  Output: X11, X12, or X13 hold 64 bit address

----------------------------------------- */

// ----------------- x1  returnin x11 ---------------

set_x11_to_Int_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	bl	set_x9_to_Int_MS_Word_Addr_Offset
	add	x11, x11, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x11_to_Int_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	bl	set_x9_to_Int_LS_Word_Addr_Offset
	add	x11, x11, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x11_to_Fct_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	bl	set_x9_to_Fct_MS_Word_Addr_Offset
	add	x11, x11, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x11_to_Fct_LS_Word_Address_Static:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	add	x11, x11, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x11_to_Fct_LS_Word_Address_Optimized:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	add	x11, x11, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x11_to_Var_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x11, =RegAddTable	// Pointer to vector table
	add	x11, x11, x1, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x11, [x11]		// x11 pointer to variable address
	ldp	x9, x30, [sp], 16	// restore return address
	ret

// ----------------- x2  returnin x12 ---------------

set_x12_to_Int_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	bl	set_x9_to_Int_MS_Word_Addr_Offset
	add	x12, x12, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x12_to_Int_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	bl	set_x9_to_Int_LS_Word_Addr_Offset
	add	x12, x12, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x12_to_Fct_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	bl	set_x9_to_Fct_MS_Word_Addr_Offset
	add	x12, x12, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x12_to_Fct_LS_Word_Address_Static:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	add	x12, x12, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x12_to_Fct_LS_Word_Address_Optimized:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	add	x12, x12, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x12_to_Var_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x12, =RegAddTable	// Pointer to vector table
	add	x12, x12, x2, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x12, [x12]		// x12 pointer to variable address
	ldp	x9, x30, [sp], 16	// restore return address
	ret

// ----------------- x3  returnin x13 ---------------

set_x13_to_Int_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	bl	set_x9_to_Int_MS_Word_Addr_Offset
	add	x13, x13, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x13_to_Int_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	bl	set_x9_to_Int_LS_Word_Addr_Offset
	add	x13, x13, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x13_to_Fct_MS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	bl	set_x9_to_Fct_MS_Word_Addr_Offset
	add	x13, x13, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x13_to_Fct_LS_Word_Address_Static:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	add	x13, x13, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x13_to_Fct_LS_Word_Address_Optimized:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	add	x13, x13, x9
	ldp	x9, x30, [sp], 16	// restore return address
	ret
set_x13_to_Var_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x13, =RegAddTable	// Pointer to vector table
	add	x13, x13, x3, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x13, [x13]		// x13 pointer to variable address
	ldp	x9, x30, [sp], 16	// restore return address
	ret

//------------------------------------
// Create additional as needed here
//------------------------------------
set_x14_to_Var_LS_Word_Address:
	stp	x9, x30, [sp, -16]!	// preserve return address
	ldr	x14, =RegAddTable	// Pointer to vector table
	add	x14, x14, x4, lsl X8SHIFT3BIT // handle --> index into table
	ldr	x14, [x14]		// x12 pointer to variable address
	ldp	x9, x30, [sp], 16	// restore return address
	ret


/* -------------------------------------
  PrintAddressOffsets

  Input: none

  Output: none
------------------------------------- */
PrintAddressOffsets:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]

	bl	CROut

	bl	set_x9_to_Int_MS_Word_Addr_Offset
	ldr	x0, =100f
	bl	99f

	bl	set_x9_to_Int_LS_Word_Addr_Offset
	ldr	x0, =101f
	bl	99f

	bl	set_x9_to_Fct_MS_Word_Addr_Offset
	ldr	x0, =102f
	bl	99f

	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Static
	ldr	x0, =103f
	bl	99f

	bl	set_x9_to_Fct_LS_Word_Addr_Offset_Optimized
	ldr	x0, =104f
	bl	99f

	bl	set_x9_to_Var_LS_Word_Addr_Offset
	ldr	x0, =105f
	bl	99f

	bl	CROut
	bl	CROut

	ldr	x30, [sp, #0]	// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	add	sp, sp, #32
	ret

// Internal function
// Input x0 = string pointer
// Input x9 = variable address
99:	stp	x9, x30, [sp, -16]!	// preserve return address
	bl	StrOut
	mov	x0, x9
	bl	Print0xWordHex
	mov	x0, #' '
	bl	CharOut
	mov	x0, x9
	bl	PrintWordB10
	ldp	x29, x30, [sp], 16	// restore return address
	ret

100:	.asciz	  "Int MS Word Addr Ofst: "
101:	.asciz	"\nInt LS Word Addr Ofst: "
102:	.asciz	"\nFct MS Word Addr Ofst: "
103:	.asciz	"\nFct LS Word Addr Ofst: "
104:	.asciz	" (Static)\nFct LS Word Addr Ofst: "
105:	.asciz	" (Optimized)\nVar LS Word Addr Ofst: "

	.align 4

/***************************************

   PrintAccuracyVars

   Input:  none

   Output: none

***************************************/
PrintAccuracyVars:

	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]

	// Digits

	bl	CROut
	ldr	x0, =100f
	ldr	x1, =NoSigDig
	bl	99f

	ldr	x0, =101f
	ldr	x1, =NoExtDig
	bl	99f

	// Offset pointers

	bl	CROut
	ldr	x0, =200f
	ldr	x1, =IntMSW_WdPtr
	bl	99f

	ldr	x0, =202f
	ldr	x1, =IntLSW_WdPtr
	bl	99f

	ldr	x0, =203f
	ldr	x1, =FctMSW_WdPtr
	bl	99f

	ldr	x0, =204f
	ldr	x1, =FctLSW_WdPtr_Static
	bl	99f

	ldr	x0, =205f
	ldr	x1, =FctLSW_WdPtr_Optimized
	bl	99f

	ldr	x0, =206f
	ldr	x1, =VarLSW_WdPtr
	bl	99f

	// words

	bl	CROut
	ldr	x0, =300f
	ldr	x1, =Word_Size_Static
	bl	99f

	ldr	x0, =301f
	ldr	x1, =Word_Size_Optimized
	bl	99f

	ldr	x0, =302f
	ldr	x1, =MinimumWord
	bl	99f

	bl	CROut
	ldr	x0, =303f
	ldr	x1, =IntWSize
	bl	99f

	ldr	x0, =304f
	ldr	x1, =FctWsize
	bl	99f

	ldr	x0, =305f
	ldr	x1, =VarWSize
	bl	99f

	bl	CROut

	ldr	x30, [sp, #0]	// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	add	sp, sp, #32
	ret

// Internal function
// Input x0 = string pointer
// Input x1 = variable address
99:	stp	x29, x30, [sp, -16]!	// preserve return address
	bl	StrOut
	ldr	x0, [x1]
	bl	Print0xWordHex
	mov	x0, #0x20
	bl	CharOut
	ldr	x0, [x1]
	bl	PrintWordB10
	bl	CROut
	ldp	x29, x30, [sp], 16	// restore return address
	ret

//                 1234567812345678 <-- ruler
100:	.asciz	"NoSigDig               "
101:	.asciz	"NoExtDig               "

200:	.asciz	"IntMSW_WdPtr           "
202:	.asciz	"IntLSM_WdPtr           "
203:	.asciz	"FctMSW_WdPtr           "
204:	.asciz	"FctLSW_WdPtr_Static    "
205:	.asciz	"FctLSW_WdPtr_Optimized "
206:	.asciz	"VarLSW_WdPtr           "

300:	.asciz	"Word_Size_Static       "
301:	.asciz	"Word_Size_Optimized    "
302:	.asciz	"MinimumWord            "
303:	.asciz	"IntWsize               "
304:	.asciz	"FctWsize               "
305:	.asciz	"VarWSize               "

	.align 4

	.end
