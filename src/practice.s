/* ----------------------------------------------------------------
	practice.s

	Sandbox for playing with various code

	Created:   2021-02-17
	Last edit: 2021-02-19

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

//  	.cpu	cortex-a72		// RPI-4
//	.cpu	cortex-a7		// RPI-2B
//	.cpu	arm1176jzf-s		// RPI-1 Model B
/* ------------------------------------------------------------ */

	.global		practice


	.text
	.align 3

practice:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]

	bl	CROut
	ldr	x0, =pracStr001
	bl	StrOut

// ///////////////////////////////////////////////
//              Code jump table
// ///////////////////////////////////////////////
//
// Comment each test as needed
//
	b	integer_addition
	// b	conditional_branching
	// b	EndianCheck
	// b	print_registers_test
	// b	print_status_flags
	// b	print_reg_base10_unsigned
	// b	load_64_bit_immediate

// ///////////////////////////////////////////////


// -----------------------------------------------
//
//
integer_addition:
	movz	x0, #0x1111, lsl 48
	movk	x0, #0x1111, lsl 32
	movk	x0, #0x1111, lsl 16
	movk	x0, #0x1111
	// x0 = 0x1111111111111111
	mov	x1, x0
	// x0 = 0x1111111111111111
	add	x0, x0, x1
	// x0 = 0x2222222222222222
//	bl	PrintWordHex

	movz	x0, #0x1111, lsl 48
	movk	x0, #0x1111, lsl 32
	movk	x0, #0x1111, lsl 16
	movk	x0, #0x1111
	// 1111111111111111
	movz	x1, #0x4
	// 0x0000000000000004
	add	x0, x0, x1, lsl #2
	// 0x1111111111111121
	//bl	PrintWordHex

	movz	x0, #0x1111, lsl 48
	movk	x0, #0x1111, lsl 32
	movk	x0, #0x1111, lsl 16
	movk	x0, #0x1111
	// 1111111111111111
	mov	x1, x0
	// 0x1111111111111111
	add	x0, x0, x1, lsl #2
	// 0x5555555555555555
	bl	PrintWordHex

	b	exit_prac


// -----------------------------------------------
//
//
conditional_branching:

	// CCMP
	//
	// Conditional compare, 4th operand is condition exist when called
	// If condition met, compare operand 1,2 else 1,3, then set flags
	mov	x2, #8
	mov	x3, #8
	mov	x10, #4
	subs	x1, x2, x3
	// EQ HS/CS PL VC
	// operand 2 (0-31) operand 3 (0-15)
	// z=1 ccmp conditon "eq" so compare operand 1 and 2
	ccmp	x10, #4, #2, eq
	// EQ HS/CS PL VC
	subs	x1, x2, x3
	// EQ HS/CS PL VC
	// z=1 ccmp condition "ne" so compare operand 1 and 3
	ccmp	x10, #4, #2, ne
	// NE HS/CS PL VC
	// bl	PrintFlags

	// CSEL
	//
	// If condition in 4th operand met when called,
	// Then operand 1 register set to operand 2
	// Else set operand 1 register to operand 3 register
	mov	x2, #8
	mov	x3, #8
	mov	x10, #4
	mov	x11, #5
	subs	x1, x2, x3
	// EQ HS/CS PL VC
	// bl	PrintFlags
	csel	x0, x10, x11, eq
	// x0 = 0000000000000004 (value of x10)
	bl	PrintWordHex
	bl	CROut
	subs	x1, x2, x3
	// EQ HS/CS PL VC
	csel	x0, x10, x11, ne
	// x0 = 0000000000000005 (value of x11)
	bl	PrintWordHex
	bl	CROut

	b	exit_prac

// -----------------------------------------------
// Endian check
//
EndianCheck:
	ldr	x0, =pracStr002
	bl	StrOut
//
// Little Endian Check 64 bit .qword
//
	ldr	x0, =word_64bit
	ldr	x0, [x0]
	bl	PrintWordHex
	bl	CROut
	ldr	x0, =byte_8_x_8bit
	ldr	x0, [x0]
	bl	PrintWordHex
	bl	CROut
//
// Little Endian Check 32 bit .word
//
	ldr	x0, =word_32bit
	ldr	w0, [x0]
	bl	PrintWordHex
	bl	CROut
	ldr	x0, =byte_4_x_8bit
	ldr	w0, [x0]
	bl	PrintWordHex
	bl	CROut
	b	exit_prac

// -----------------------------------------------
// Print Registers
//
print_registers_test:
	// bl	ClearRegisters
	bl	PrintRegisters
	b	exit_prac
//
// Test print status flags
//
print_status_flags:
	mov	x0, #10
	mov	x1, #10
	subs	x0, x0, x1 // z=1 c=1 n=0 v=0
 	bl	PrintFlags
	mov	x0, #100
	mov	x1, #10
	subs	x0, x0, x1 // z=0 c=1 n=0 v=0
 	bl	PrintFlags
	mov	x0, #10
	mov	x1, #100
	subs	x0, x0, x1 // z=0 c=0 n=1 v=1
 	bl	PrintFlags
	b	exit_prac

// -----------------------------------------------
// Test of print register in base 10 unsigned integer
//
print_reg_base10_unsigned:
	mov	x0, #1142
	bl	PrintWordB10
	bl	CROut
	b 	exit_prac

// -----------------------------------------------
// Test of print of 64 bit work in hex
// Load 0x0123456789ABCDEF into x0
//
load_64_bit_immediate:
	movz	x0, #0x0123, lsl 48
	movk	x0, #0x4567, lsl 32
	movk	x0, #0x89ab, lsl 16
	movk	x0, #0xcdef
	bl	PrintWordHex
	bl	CROut
	movz	x0, #0xF000, lsl 48
	bl	PrintWordHex

	b	exit_prac
//
// -----------------------------------------------
//
exit_prac:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #64
	ret


pracStr001:
	.asciz	"Practice\n\n"
pracStr002:
	.asciz	"EndianCheck\n"
	.align	3

// -----------------
	.data
// -----------------

endian_test1:
	.align 3
	.quad	0
word_64bit:
	.quad	0x1122334455667788
	.quad	0
byte_8_x_8bit:
	.byte	0x88
	.byte	0x77
	.byte	0x66
	.byte	0x55
	.byte	0x44
	.byte	0x33
	.byte	0x22
	.byte	0x11
	.quad	0

//	.word	0x1122334455667788
// 76 0008 88776655 	.word	0x1122334455667788
// ****  Warning: value 0x1122334455667788 truncated to 0x55667788

	.word	0xabababab
word_32bit:
	.word	0x12345678
	.word	0xcdcdcdcd
byte_4_x_8bit:
	.byte	0x78
	.byte	0x56
	.byte	0x34
	.byte	0x12
	.word	0

endian_test2:
	.word	0,0,0,0, 0,0,0,0
	.word	0,0,0,0, 0,0,0,0
	.word	0,0,0,0, 0,0,0,0
	.word	0,0,0,0, 0,0,0,0

my_data:
	.string "This is a test"

my_align2:
	.align 2 // 32 bit
	.byte 1
	.align 2
	.byte 2
my_align3:
	.align 2 // 32 bit
	.byte 1
	.align 3 // 64 bit
	.byte 4
my_align4:
	.byte 1
	.align 4 // 128 bit
	.byte 8

	.end
