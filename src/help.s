/* -------------------------------------------------------------
;	help.s
;
; This module contains user help
;
;	Created:   2021-02-19
;	Last Edit: 2021-02-19
;
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

	.global	Help_Welcome

// ------------------------------------------------------------
	.text
	.align 4
// ------------------------------------------------------------

Help_Welcome:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]
	str	x29, [sp, #8]
	str	x0,  [sp, #16]

	ldr	x0, =WelcomeMsg
	bl	StrOut

	ldr	x30, [sp, #0]		// Restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

// ------------------------------------------------------------
	.data
// ------------------------------------------------------------
//
// Welcome message shown at program start
//
WelcomeMsg:
	.ascii	"SINGLE THREAD FLOATING POINT MULTI-PRECISION CALCULATOR\n\n"
	.ascii	"MIT License\n\n"
	.ascii	"Copyright 2014-2020 David Bolenbaugh\n\n",
	.ascii	"Permission is hereby granted, free of charge, to any person obtaining a copy\n"
	.ascii	"of this software and associated documentation files (the \"Software\"), to deal\n"
	.ascii	"in the Software without restriction, including without limitation the rights\n"
	.ascii	"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
	.ascii	"copies of the Software, and to permit persons to whom the Software is\n"
	.ascii	"furnished to do so, subject to the following conditions:\n\n"
	.ascii	"The above copyright notice and this permission notice shall be included in all\n"
	.ascii	"copies or substantial portions of the Software.\n\n"
	.ascii	"THE SOFTWARE IS PROVIDED \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
	.ascii	"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \n"
	.ascii	"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
	.ascii	"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
	.ascii	"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \n"
	.ascii	"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n"
	.ascii	"SOFTWARE.\n\n"
	.ascii	"Source code: https://github.com/cotarr/calc-pi-arm64-asm\n\n"

	.ascii	"\nW O R K  I N   P R O G R E S S (no calculation yet)\n"
	.ascii	"\nCalculation of Pi on Raspberry Pi\n"
	.ascii	"Written in GNU Assembler (as)\n"
	.ascii	"Assembled arch=armv8-a cpu=cortex-a72\n\n"
	.byte	0
	.align 4

	.end
