/* ----------------------------------------------------------------
	practice.s

	Sandbox for playing with various code

	Created:   2021-02-17
	Last edit: 2021-03-03

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

	.bss	// un-initialized data

FileBuf:	.skip	1024

	.text
	.align 4

practice:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]

	bl	CROut
	ldr	x0, =pracStr001
	bl	StrOut

// ///////////////////////////////////////////////
//              Code jump table
// ///////////////////////////////////////////////
//
// Comment each test as needed
//
	b	sub_carry_0_or_1
	// b	partial_register_addressing
	// b	file_write_then_read
	// b	save_carry_flag
	// b	ConditionalAssembly
	// b	multiply
	// b	sub_carry_loop
	// b	shift_addition
	// b	addition
	// b	subtraction
	// b	bit_shift
	// b	test_error
	// b	integer_addition
	// b	cmp_flags
	// b	conditional_branching
	// b	EndianCheck
	// b	print_registers_test
	// b	print_status_flags
	// b	print_reg_base10_unsigned
	// b	load_64_bit_immediate

// ///////////////////////////////////////////////


// -----------------------------------------------------------------------------------
//
test_error:
	ldr	x0, =TestErrorMsg	// Error message pointer
	mov	x1, #11			// 12 bit error code
	b	FatalError
TestErrorMsg:
	.asciz "A test error was generated in the practive sandbox"
	.align 4


partial_register_addressing:

	ldr	x1, =WordFFFF
	ldr	x1, [x1]
	ldr	x2, =word_64bit

	// memory contains 0x1122334455667788 before test
	str	w1, [x2]
	ldr	x0, [x2]	// x0 = 0x11223344FFFFFFFF

	str	x1, [x2]
	ldr	x0, [x2]	// x0 = 0xFFFFFFFFFFFFFFFF

	// memory contains 0x1122334455667788 before test
	str	w1, [x2]
	ldr	x0, [x2]	// x0 = 0xFFFFFFFFFFFFFFFF
	bl	Print0xWordHex
	b	exit_prac


file_write_then_read:
	//
	// Note: Web search could not find an example of ARM64 file I/O in assembly language.
	// The code below is the result of trial and error with arugments in
	// different registers.
	//
	// The code AT_FDCWD was referred to as use current directory in place
	// of directory file descriptor. I could not find this definition in
	// the local library header, but it seems to work with value -100
	// as found in other documentation.
	//
	// ----------------------------------------
	// Test of file open, create if not exist, write, and close
	// ----------------------------------------
	//
	// Open file, create if not exist, and save file description in x10
	//
	mov	x0, AT_FDCWD		// (dirfd) Special code to use current directory
	ldr	x1, =112f		// (*pathname) address pointer to filename
	mov	x2, O_CREAT + O_WRONLY	// (mode)
	mov	x3, #0644		// (flags) File perimission flags
	mov	x8, __NR_openat		// (openat())
	svc	0			// system call
	mov	x10, x0			// save file descriptor (or error)
	//
	// Check if error opening file
	//
	adds	xzr, xzr, x0		// error?
	b.pl	10f			// no branch
	//
	// Case of error, print error code and exit program
	//
	ldr	x0, =121f		// Message with error string
	bl	StrOut
	sub	x0, xzr, x10		// print error code
	bl	PrintWordB10
	bl	CROut
	b	exit_prac		// and exit due to error
10:
	//
	// Print message showing successful open and print file descriptor
	//
	ldr	x0, =120f		// Message showing successful open
	bl	StrOut
	mov	x0, x10			// print file descriptor
	bl	PrintWordB10
	bl	CROut
	//
	// Write "Hello world" string to file
	//
	mov	x0, x10			// (fd) file descriptor
	ldr	x1, =100f		// (*buf) buffer address
	mov	x2, (111f - 100f)	// (size_t) count of bytes to write
	mov	x8, __NR_write		// (write())
	svc	#0			// system call
	mov	x11, x0			// save return code
	//
	// Check for error writing to file
	//
	adds	xzr, xzr, x0		// error?
	b.pl	11f			// no branch
	//
	// Case of error, show error, but continue to close file
	//
	ldr	x0, =124f		// Message with error string
	bl	StrOut
	sub	x0, xzr, x11		// print error code
	bl	PrintWordB10
	bl	CROut
11:
	//
	// Close the file
	//
	mov	x0, x10			// (fd) file descriptor
	mov	x1, #0
	mov	x2, #0
	mov	x3, #0
	mov	x8, __NR_close		// (close())
	svc	0			// system call
	//
	// Check if error closing file
	//
	adds	xzr, xzr, x0		// return code
	b.mi	15f
	//
	// case of success, print successful close message
	//
	ldr	x0, =122f		// successful close message
	bl	StrOut
	bl	CROut
	b.al	file_read		// continue to try to read the file back again
15:
	//
	// Case of error closing file, print error
	//
	mov	x10, x0			// save error
	ldr	x0, =123f
	bl	StrOut
	sub	x0, xzr, x10		// error code
	bl	PrintWordB10
	bl	CROut
	b	file_read		// continue to try to reaqd the file back again

100:	.asciz	"Hello World!\n"
111:	.asciz	"/home/pi/test.txt"
112:	.asciz	"test2.txt"
120:	.asciz	"File opened for write, handle: "
121:	.asciz	"File Open for write error: "
122:	.asciz	"File closed."
123:	.asciz	"File Close Error: "
124:	.asciz	"File write error: "
	.align 4

	// ----------------------------------------
	// Test of open, read and close
	// ----------------------------------------
file_read:
	//
	// Open file for read and save file description in x12
	//
	mov	x0, AT_FDCWD		// (dirfd) Special code to use current directory
	ldr	x1, =212f		// (*pathname) address pointer to filename
	mov	x2, O_RDONLY		// (mode)
	mov	x3, #0644		// (flags) File perimission flags
	mov	x8, __NR_openat		// (openat())
	svc	0			// system call
	mov	x12, x0			// save file descriptor (or error)
	//
	// Check if error opening file
	//
	adds	xzr, xzr, x0		// error?
	b.pl	50f			// no branch
	//
	// Case of error, print error code and exit program
	//
	ldr	x0, =221f		// Message with error string
	bl	StrOut
	sub	x0, xzr, x12		// print error code
	bl	PrintWordB10
	bl	CROut
	b	exit_prac		// and exit due to error
50:
	//
	// Print message showing successful open and print file descriptor
	//
	ldr	x0, =220f		// Message showing successful open
	bl	StrOut
	mov	x0, x12			// print file descriptor
	bl	PrintWordB10
	bl	CROut
	//
	// Read to data into buffer, with maximum buffer length in x2
	//
	mov	x0, x12			// (fd) File descriptor
	ldr	x1, =FileBuf		// (*buf) dpoint to buffer
 	mov	x2, #256		// (size_t) buffer size (count)
	mov	x8, __NR_read		// (read())
	svc	#0			// system call
	mov	x13, x0			// save count or error
	//
	// Check for read error
	//
	adds	xzr, xzr, x0		// error?
	b.pl	60f			// no branch
	//
	// Case of error, print error message, but continue to close file
	//
	ldr	x0, =224f		// Message with error string
	bl	StrOut
	sub	x0, xzr, x13		// print error code
	bl	PrintWordB10
	bl	CROut
	b.al	70f
	//
	// print string that was read from the file
	//
60:	ldr	x1, =FileBuf		// need to null terminate string
	mov	x0, #0
	str	x0, [x1, x13]		// store zero byte at length
	mov	x0, x1			// buffer address
	bl	StrOut			// print string from buffer

70:	//
	// Close the file
	//
	mov	x0, x12			// (fd) file descriptor
	mov	x1, #0
	mov	x2, #0
	mov	x3, #0
	mov	x8, __NR_close		// (close())
	svc	0			// system call
	//
	// Check for error closing file
	//
 	adds	xzr, xzr, x0		// return code
	b.mi	15f
	//
	// Case of success, print successful close message
	//
	ldr	x0, =222f
	bl	StrOut
	bl	CROut
	b.al	20f
15:
	//
	// case of error, print error code
	//
	mov	x13, x0			// save error
	ldr	x0, =223f
	bl	StrOut
	sub	x0, xzr, x13		// error code
	bl	PrintWordB10
	bl	CROut
20:
	b exit_prac

211:	.asciz	"/home/pi/test.txt"
212:	.asciz	"test2.txt"
220:	.asciz	"File opened for read, handle: "
221:	.asciz	"File Open for read error: "
222:	.asciz	"File closed."
223:	.asciz	"File Close Error: "
224:	.asciz	"File read error: "
	.align 4

// -----------------------------------------------------------------------------------
//
save_carry_flag:
	ldr	x1, =100f
	ldr	x1, [x1]
	mov	x2, #1
	adds	x3, x1, x2	// NE LO/CC MI VS (CF==0)

	// ------- Preserve carry in register  ------
	sbc	x10, xzr, xzr	// x0 =  0xFFFFFFFFFFFFFFFF
	and	x10, x10, 1	// x10 = 0x0x0000000000000001
	// ------------------------------------------

	// ------------Restore carry from register-----------
	subs	xzr, xzr, x10	// NE LO/CC MI VS (Carry restored to 0)
	//---------------------------------------------------

	bl	PrintFlags
	bl	CROut

	ldr	x1, =100f
	ldr	x1, [x1]
	ldr	x2, =101f
	ldr	x2, [x2]
	adds	x3, x1, x2	// NE HS/CS PL VC (CF==1)
	// preserve inverse carry in x10
	sbc	x0, xzr, xzr	// x0 =  0x0000000000000000
	and	x10, x0, 1	// x10 = 0x0000000000000000
	// later use of x10 to restore carry
	subs	xzr, xzr, x10	// EQ HS/CS PL VC (Carry restored to 1)
	bl	PrintFlags
	bl	CROut
	b	exit_prac

//      aRuler -->0123456789abcdef
100:	.quad	0x8000000000000001
101:	.quad	0x8000000000000001
	.align 4

// -----------------------------------------------------------------------------------
//
ConditionalAssembly:
	// Message always displayed
	bl	CROut
	ldr	x0, =110f
	bl	StrOut
	bl	CROut

//.set MYDEF, 1
.ifdef MYDEF
	// message conditionally displayed
	ldr	x0, =111f
	bl	StrOut
	bl	CROut
.endif
	b	exit_prac

110:	.asciz	"always assembly"
111:	.asciz	"conditional assembly"
	.align 4
// -----------------------------------------------------------------------------------
//
multiply:
	ldr	x4, =103f
	ldr	x4, [x4]
//	ldr	x5, =103f
//	ldr	x5, [x5]

	mov	x4, #5
	mov	x3, #1
	sub	x5, xzr, x3

	mov	x0, x4
	bl	Print0xWordHex
	bl	CROut
	mov	x0, x5
	bl	Print0xWordHex
	bl	CROut

	// bits 63-0
	mul	x6, x4, x5

	bl	PrintFlags
	mov	x0, x6
	bl	Print0xWordHex
	bl	CROut

	//bits 127-64
	umulh	x7, x4, x5

	bl	PrintFlags
	mov	x0, x7
	bl	Print0xWordHex
	bl	CROut

	b	exit_prac


//      aRuler -->0123456789abcdef
100:	.quad	0x1111111111111111
101:	.quad	0x1111111111111111
102:    .quad	0xffffffffffffff7f
103:	.quad	0x0000000000000004
	.align 4


sub_carry_0_or_1:

	// confirm cleared carry C=1 not subtracted
	mov	x1, #4
	mov	X2, #4
	// set carry C=1  (NOT carry)
	mov	x0, #0
	subs	x0, x0, x0
	// subtract value of carry
	sbcs	x0, x1, x2 // EQ HS/CS PL VC 0x0000000000000000
	bl	PrintFlags
	bl	Print0xWordHex
	b	exit_prac
// -----------------------------------------------------------------------------------
//
sub_carry_loop:
// To perfrom multi-precision subtraction, the carry flag must be preserved.
// Loops are confusing, subtract impacts carry flag, decrement counter impacts carry flag.
// At first I tried compex was to preserve the flags (Carry)
// Then I disconvered the CBNZ instruction, confusing documentation.
// CBNZ can test register and branch WITHOUT altering flags (Will test here below)
//
//    There are 4 pre-test to get familiar with flag operation
//
//    Case 1 carry clear to 0 by negative result, counter remain above zero
//    Case 2 carry clear to 0 by negative result, counter reach zero
//    Case 3 carry remain 1 positive result, counter remain above zero
//    Case 4 carry remain 1 positive result, counter reaches zero
//
//    NOTE: print statements removed after testing, replaced by result text copy / paste

	// Pre-test 1 - First subtract without carry (0x40 - 0x20 = 0x30)
	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2
	subs	x0, x10, x11
	// NE HS/CS PL VC 0000000000000030

	// Pre-test 2 - next decrement a counter without (s) added, make sure see flags are not changed
	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2
	subs	x0, x10, x11
	sub	x4, x4, #1
	// NE HS/CS PL VC 0000000000000030

	// Pre-test 3 - now reverse the order, "NOT" carry negative result (0x20 - 0x40 = -0x30)
	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2
	subs	x0, x11, x10
	// NE LO/CC MI VS FFFFFFFFFFFFFFD0

	// pre-test 4 - next decrement a counter without (s) added, make sure see flags are not changed
	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2		// this will decrement to 1, not zero
	subs	x0, x11, x10	// this clears C flag (NOT carry)
	sub	x4, x4, #1	// this is 1 above zero, flags not impacted
	// NE LO/CC MI VS FFFFFFFFFFFFFFD0

	// Case 1 carry clear to 0 by negative result, counter remain above zero

	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2		// this will decrement to 1, not zero
	subs	x0, x11, x10	// this clears C flag (NOT carry)
	sub	x4, x4, #1	// this is 1 above zero, flags not impacted
	cbnz	x4, 20f
	// * * * condition not met * * *
	b.al	30f
20:
	// NE LO/CC MI VS FFFFFFFFFFFFFFD0 cbnz x4 not zero

30:
	// Case 2 carry clear to 0 by negative result, counter reach zero

	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #1		// <------ 1 to reach zero
	subs	x0, x11, x10	// this clears C flag (NOT carry)
	sub	x4, x4, #1	// This will decrement to zero, but not set flags
	cbnz	x4, 40f		// <----- x4 will now be zero, (verifiying no flag change)
	// NE LO/CC MI VS FFFFFFFFFFFFFFD0 cbnz x4 equal zero
	b.al	50f
40:
	// * * * * condition not met * * *

50:
	// Case 3 carry remain 1 positive result, counter remain above zero

	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #2   	// <------ 2 will go 1, above zero
	subs	x0, x10, x11	// positive result (0x40 - 0x20 = 0x30) carry not cleared (C=1)
	sub	x4, x4, #1	// / this is 1 above zero, flags not impacted
	cbnz	x4, 60f		// <----- this will now be 1, not zero
	// (* * * * condition not met)
60:
	// NE HS/CS PL VC 0000000000000030 cbnz x4 not zero
70:

	// Case 4 carry remain 1 positive result, counter reaches zero

	mov	x10, #0x0040
	mov	X11, #0x0010
	mov	x4, #1   	// <------ 1 to reach zero
	subs	x0, x10, x11	// positive result (0x40 - 0x20 = 0x30) carry not cleared (C=1)
	sub	x4, x4, #1	// This will decrement to zero, but not set flags
	cbnz	x4, 80f		// <----- this will now be zero
	// NE HS/CS PL VC 0000000000000030 cbnz x4 equal zero
	bl	PrintFlags
	bl	PrintWordHex
	ldr	x0, =140f
	bl	StrOut
	b.al	90f
80:
	// Case not met
	bl	PrintFlags
	bl	PrintWordHex
	ldr	x0, =130f
	bl	StrOut
90:
	// SUCCESS!!!, no to go write the 2's compliment function and test
	b	exit_prac


130:	.asciz	" cbnz x4 not zero"
140:	.asciz	" cbnz x4 equal zero"
	.align 4

// -----------------------------------------------------------------------------------
//
shift_addition:
	// x0 = x11 + x10 lsl 4
	mov	x10, #0x1000
	mov	X11, #0x0010
	adds	x0, x11, x10, lsl 4
	// NE LO/CC PL VC 0x0000000000010010
	bl	PrintFlags
	bl	PrintWordHex
	b	exit_prac
// -----------------------------------------------------------------------------------

addition:

	mov	x1, #0
	mov	x2, #0
	adds	x0, x1, x2	// EQ LO/CC PL VC

	ldr	x1, =100f
	ldr	x1, [x1]
	mov	x2, #1
	adds	x0, x1, x2	// NE LO/CC MI VS

	ldr	x1, =100f
	ldr	x1, [x1]
	ldr	x2, =100f
	ldr	x2, [x2]
	adds	x0, x1, x2	// EQ HS/CS PL VC



	bl	PrintFlags
	b	exit_prac
//      aRuler -->0123456789abcdef
100:	.quad	0x8000000000000000
	.align 4

//
subtraction:
	// x0 = x11 - x10
	mov	x10, #100
	mov	X11, #5
	subs	x0, x11, x10
	// NE LO/CC MI VS 0xFFFFFFFFFFFFFFA1
	subs	x0, x10, x11
	// NE HS/CS PL VC 000000000000005F
	bl	PrintFlags
	bl	PrintWordHex
	b	exit_prac
// -----------------------------------------------------------------------------------
//
bit_shift:
	mov	x0, #1
	ror	x0, x0, #1
	// 0x8000000000000000
	mov	x0, #1
	lsr	x0, x0, #1

	bl	PrintFlags
	bl	PrintWordHex

	b	exit_prac
// -----------------------------------------------------------------------------------
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


cmp_flags:
	mov	x1, #0
	mov	x2, #0
	cmp	x1, x2	// EQ HS/CS PL VC
	mov	x1, #1
	mov	x2, #0
	cmp	x1, x2  // NE HS/CS PL VC
	mov	x1, #0
	mov	x2, #1
	cmp	x1, x2  // NE LO/CC MI VS
	mov	x1, #1
	mov	x2, #1
	cmp	x1, x2  // EQ HS/CS PL VC
	bl	PrintFlags
	b	exit_prac


// -----------------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------------
//
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

// -----------------------------------------------------------------------------------
//
print_registers_test:
	// bl	ClearRegisters
	bl	PrintRegisters
	b	exit_prac

// -----------------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------------
//
// Test of print register in base 10 unsigned integer
//
print_reg_base10_unsigned:
	mov	x0, #1142
	bl	PrintWordB10
	bl	CROut
	b 	exit_prac

// -----------------------------------------------------------------------------------
//
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

// -----------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------

exit_prac:
	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	add	sp, sp, #32
	ret


pracStr001:
	.asciz	"Practice\n\n"
pracStr002:
	.asciz	"EndianCheck\n"
	.align	4

// -----------------
	.data
// -----------------

endian_test1:
	.align 4
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
