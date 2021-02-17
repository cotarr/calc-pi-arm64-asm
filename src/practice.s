/* ----------------------------------------------------------------
	practice.s

	Sandbox for playing with various code

	Created:   2021-02-17
	Last edit: 2021-02-17

	PrintCommandList
	ParseCmd

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

   	.Include "arch.inc"	// .arch and .cpu directives
   	.include "header.inc"

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

//
// Endian check message
//
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
