/*-------------------------------------------------------------
	SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR

	For Raspberry Pi ARM64

	David Bolenbaugh

	Created:   02/14/21
	Last Edit: 02/14/21
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

	.Include "arch.inc"	// .arch and .cpu directives

	.global	_start
	.global	ProgramExit

	.include "header.inc"
//	.arch	armv8-a		// arm64 --> trying armv8-a
//	.cpu	cortex-a72	// Raspberry Pi 4 from lscpu

	.text
	.align 4

_start:
main:
	ldr	x0, =hello	// Pointer to text string
	bl	StrOut		// Send string to stdout
	bl	CROut		// End of line character

ProgramExit:
	mov	x0, #0  	// exit with status 0
	mov	x8, sys_exit 	// exit
	svc	#0      	// syscall

	.data
hello:
	.ascii "Hello World",
	.byte	0

.end
