/* ----------------------------------------------------------------
	math-output.s

	Input binary variable from base 10

	Created:   2021-02-14
	Last edit: 2021-03-06

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
// .nolist
// ------------------------------------------------------------
// /usr/include/asm-generic/fcntl.h
.equ	O_CREAT,	00000100	//new (not fcntl)
.equ	O_RDONLY,	0
.equ	O_WRONLY,	1
.equ	O_APPEND,	00002000
.equ	O_PATH,		010000000


// /usr/include/asm-generic/unistd.h
.set	__NR_openat,		56
.set	__NR_close,		57
.set	__NR_read,		63
.equ	__NR_write,		64
.equ	__NR_exit,		93
.equ	__NR_gettimeofday, 	169

// from google
.equ	AT_FDCWD,	-100	// for openat dirfd in x0

// /usr/include/unistd.h
.equ	STDOUT_FILENO, 1
.equ	STDIN_FILENO,  1

.set	BIT_PER_WORD,	0x040   // 020H for 32 Bit, 040H for 64 Bit
.set	BYTE_PER_WORD,	0x08    // 004H for 32 Bit, 008H for 64 Bit
.set	X2SHIFT1BIT,	0x01	// how many bit to shift for multiply by 8 (word size)
.set	X4SHIFT2BIT,	0x02	// how many bit to shift for multiply by 8 (word size)
.set	X8SHIFT3BIT,	0x03	// how many bit to shift for multiply by 8 (word size)
.set	X16SHIFT4BIT,	0x04	// how many bit to shift for multiply by 8 (word size)
.set	X32SHIFT5BIT,	0x05	// how many bit to shift for multiply by 8 (word size)
.set	X64SHIFT4BIT,	0x06	// how many bit to shift for multiply by 8 (word size)

// -------------------------------------------------------------------
// Variable (integer part) and (fraction part)
// NOTE: these are too big to be used as ARM64 immediate,
// so they are also stored in math.s as constants.
//--------------------------------------------------------------------
.set	INT_WSIZE, 	0x02	// WARNING USE ONLY 0x02 UNTIL TESTED
.set	FCT_WSIZE, 	0x10	// 193 dig in fraction part
.set	FCT_WSIZE, 	0x40
// .set	FCT_WSIZE, 	0x400	// 19680 fraction part
// .set	FCT_WSIZE, 	0x40000	// 5050407 fractio part

.set	VAR_WSIZE,	(INT_WSIZE + FCT_WSIZE)
//--------------------------------------------------------------------

.set	VAR_MSW_OFST,	VAR_WSIZE * BYTE_PER_WORD - BYTE_PER_WORD // Offset mantissa most significant word

.set	GUARDWORDS,	4
.set	GUARDBYTES,	(GUARDWORDS*BYTE_PER_WORD)

.set	MINIMUM_WORD,	2+GUARDWORDS			//**** Includes GUARD Bytes ****

.set	INIT_SIG_DIG,	60
.set	INIT_EXT_DIG,	10
.set	MINIMUM_DIG,	5
.set	PREVIEW_DIG,	50

/*-------------------------
Variable Handle Numbers
-------------------------*/

.set	HAND_ACC,	0
.set	HAND_OPR,	1
.set	HAND_WORKA,	2
.set	HAND_WORKB,	3
.set	HAND_WORKC,	4
.set	HAND_XREG,	5
.set	HAND_YREG,	6
.set	HAND_ZREG,	7
.set	HAND_TREG,	8
.set	HAND_REG0,	9
.set	HAND_REG1,	10
.set	HAND_REG2,	11
.set	HAND_REG3,	12

/*	.set	HAND_REG4,	13
.set	HAND_REG5,	14
.set	HAND_REG6,	15
.set	HAND_REG7,	16
*/
.set	TOPHAND,	HAND_REG3

// .list
