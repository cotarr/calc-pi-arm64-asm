/* ----------------------------------------------------------------
	math-output.s

	Input binary variable from base 10

	Created:   2021-02-23
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
	InputVariable

------------------------------------------------------------- */

	.global	PrintVariable

/* ----------------------------------------------------
 Floating Point Input

 Convert ASCII string to floating point number

    Input:    x0 = Address of null terminated character buffer

    Output:   x1 = Error code, 0=no error

    Valid number syntax

    Leading +, -
      12
      +12
      -12
    Decimal Point
      .12
      1.2
      12.
      0.12
      12.34
 ------------------------------------------------------

  InFlags bits
  0x0001 0 = Accepting leading + or - in mantissa, 1=done
  0x0002 0 = positive sign 1 = negative sign need 2's compliment
  0x0004 0 = Accepting integer part before decimal point, 1=done
  0x0008 0 = Accepting fraction part after dcimal point, 1=done
  0x0080 1 = Not Zero
  0x0100 1 = mantissa integer part has digits
  0x0200 1 = mantissa fraction part has digits

 ------------------------------------------------------- */

InputVariable:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve Registers
	str	x29, [sp, #8]
	str	x0,  [sp, #16]
	str	x1,  [sp, #24]
	str	x2,  [sp, #32]
	str	x9,  [sp, #40]
	str	x10, [sp, #48]
	str	x11, [sp, #56]
	str	x12, [sp, #64]
	str	x13, [sp, #72]

	mov	x1, #1

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
//	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x9,  [sp, #40]
	ldr	x10, [sp, #48]
	ldr	x11, [sp, #56]
	ldr	x12, [sp, #64]
	ldr	x13, [sp, #72]
	add	sp, sp, #80
	ret
