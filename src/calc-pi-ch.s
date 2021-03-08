/* ----------------------------------------------------------------
	calc-e.s

	Calculation of pi by Chudnovsky Formula

	Created:   2021-03-08
	Last edit: 2021-03-08

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

	.global	Function_calc_pi_ch

Function_calc_pi_ch:
	sub	sp, sp, #192		// Reserve 24 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]		// scratch
	str	x1,  [sp, #24]		// Internal variable handle argument
	str	x2,  [sp, #32]		// Internal variable handle argument
	str	x3,  [sp, #40]		// Internal variable handle argument
	str	x8,  [sp, #48]		// Holds incremental value of n during summation
	str	x10, [sp, #56]		// Constant value, bits to stop summation
	str	x11, [sp, #64]		// Internal address pointer
	// Stack Variables
	.set value_n, 120
	.set value_3n, 128
	.set value_6n, 136
	.set value_640320, 144
	.set flag_term_A_done, 152
	.set flag_temp_B_done, 160

	//
	// Print description
	//
	ldr	x0, =calc_pi_ch_description
	bl	StrOut


	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x3,  [sp, #40]
	ldr	x8,  [sp, #48]
	ldr	x10, [sp, #56]
	ldr	x11, [sp, #64]
	add	sp, sp, #192
	ret

calc_pi_ch_overflow_message:
	.asciz	"Error: Summation error, n overflow"
calc_pi_ch_description:
	.asciz	"\nFunction_calc_e: Calculating pi using Chudnovsky Formul\n"
	.align 4
calc_pi_ch_overflow_mask:
	.quad	0xffffffff00000000
//      Ruler --> 1234567812345678
	.align 4
