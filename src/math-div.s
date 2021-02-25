/* ----------------------------------------------------------------
	math-div.s

	Floating point division routines

	Created:   2021-02-15
	Last edit: 2021-02-25

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

	.global DivideVariable
	.global LongDivision

DivideVariable:
	b	LongDivision

/*-----------------------------------------

  Long_Division

  Perform full binary long division
  shift, subtract  --> borrow? --> CF

  Input:  OPR register is the Numerator
          ACC register is the Denominator

  Output  ACC register contains the Quotient

----------------------------------------- */

LongDivision:
sub	sp, sp, #128		// Reserve 16 words
str	x30, [sp, #0]		// Preserve Registers
str	x29, [sp, #8]
str	x0,  [sp, #16]
str	x1,  [sp, #24]
str	x2,  [sp, #32]
str	x3,  [sp, #40]
str	x9,  [sp, #48]
str	x10, [sp, #56]
str	x11, [sp, #64]
str	x12, [sp, #72]
str	x15, [sp, #80]
str	x16, [sp, #88]
str	x17, [sp, #96]



ldr	x30, [sp, #0]		// Restore registers
ldr	x29, [sp, #8]
ldr	x0,  [sp, #16]
ldr	x1,  [sp, #24]
ldr	x2,  [sp, #32]
ldr	x3,  [sp, #40]
ldr	x9,  [sp, #48]
ldr	x10, [sp, #56]
ldr	x11, [sp, #64]
ldr	x12, [sp, #72]
ldr	x15, [sp, #80]
ldr	x16, [sp, #88]
ldr	x17, [sp, #96]
add	sp, sp, #128
ret


MsgDivZero:
	.asciz	"FP_Long_Divison: Error: Division by Zero"
	.align 4
