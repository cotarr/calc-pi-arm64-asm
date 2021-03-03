/*-------------------------------------------------------------
	SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR

	For Raspberry Pi ARM64

	David Bolenbaugh

	Created:   2021-02-14
	Last Edit: 2021-02-23
--------------------------------------------------------------
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
*****************************************************************************/

	.Include "arch-include.s"	// .arch and .cpu directives
	.include "header-include.s"

	.global	_start
	.global	ProgramExit
	.global	FatalError

	.text
	.align 4

_start:
main:

//
// Welcome message
//
	bl	InitTimerAtProgramStart

	bl	ClrScr			// Terminal setup
	bl	Help_Welcome

	bl	InitializeIO		// Setup operating system I/O

	bl	FP_Initialize		// Initialize Variab les

	bl	ParseCmd		// Infinite loop... user input


ProgramExit:
	ldr	x0, =NormalExitStr2	// An error code provided
	bl	StrOut
	//
	// If logging, close log file
	//
	bl	FileCloseForExit
	//
	// Terminate Program
	//
	mov	x0, #0  		// exit with status 0
	mov	x8, __NR_exit 		// exit
	svc	#0      		// syscall

// ------------------------------------------------------
//   Error Handler
//
//   x0 = 0, assume error message already printerd
//   x0 Pointer to error striong
//   x1 Error code number
//
FatalError:
	cmp	x0, #0			// is error code zero (assume message already printed
	b.eq	10f			// nonzero, show message number
	bl	StrOut			// Print message
10:
	cmp	x1, #0
	b.eq	20f
	ldr	x0, =ErrorMsg1 		// An error code provided
	bl	StrOut
	mov	x0, x1
	bl	PrintWordB10		// Print the error code
20:
	ldr	x0, =ErrorMsg2
	bl	StrOut
	//
	// If logging, close log file
	//
	bl	FileCloseForExit
	//
	// Terminate Program
	//
	mov	x0, #1			// exit with error 1
	mov	x8, __NR_exit		// terminate program
	svc	#0			// syscall

// ----------------
	.data
	.align 4
// ----------------

NormalExitStr1:
	.asciz	"     Program run time: "
NormalExitStr2:
	.asciz	"\nGraceful Exit\n\n"
ErrorMsg1:
	.asciz	"\nError Code: "
ErrorMsg2:
	.asciz "\nProgram halted due to error.\n\n"
	.align 4


.end
