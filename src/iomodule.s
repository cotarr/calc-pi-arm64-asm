/* -------------------------------------------------------------
	io_module.s

	This module contains operating system input/output
	subroutines.

	Created:   2021-02-14
	Last Edit: 2021-03-05

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
	InitializeIO
	KeyIn
	StrOut
	CharOut
	CharOutFmt
	CharOutFmtInit
	CROut
	ClrScr
------------------------------------------------------------- */

	.include "arch-include.s"	// .arch and .cpu directives
	.include "header-include.s"

/* ------------------------------------------------------------ */

	.global InitializeIO
	.global FileCloseForExit
	.global StartEcho
	.global StopEcho
	.global CheckEchoing
	.global KeyIn
	.global	StrOut
	.global	CharOut
	.global CharOutFmt
	.global CharOutFmtInit
	.global	CROut
	.global	ClrScr
	.global ReadSysTime

// -----------------------------------

	.data
	.align 4
FileName_Echo:
	.asciz	"out000.txt"
	.quad	0,0	// extra space
DirName_Echo:
	.asciz	"log"
	.quad	0,0	// extra space

// -------------------------------------

	.bss  // Section containing uninitialized data
	.align 4

OutChar: // Character output buffer (1 64 bit word)
	.skip	8

KeyBuf:	// Keyboard Input Buffer
	.set	KeyBufLen, 0x100
	.skip	KeyBufLen

PrintVarFormatMode:	.skip	BYTE_PER_WORD
OutCharacterCounter:	.skip	BYTE_PER_WORD
OutParagraphCounter:	.skip	BYTE_PER_WORD
OutLineCounter:		.skip	BYTE_PER_WORD
OutCharacterLimit:	.skip	BYTE_PER_WORD
OutParagraphLimit:	.skip	BYTE_PER_WORD
OutLineLimit:		.skip	BYTE_PER_WORD
ParagraphLabelCounter:	.skip	BYTE_PER_WORD

time_buf:		.skip	16	// for read sys clock

fileDescriptor_echo:	.skip	8	// Log file, file descriptor
dirDescriptor_echo:	.skip	8	// Log file, file descriptor


/* ------------------------------------------------------------ */
	.text
	.align	4
/******************************************************
  Initialize I/O

  Input: none

  Output: none

  Called at program start

*******************************************************/
InitializeIO:

	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	ldr	x1, =dirDescriptor_echo
	mov	x0, #0
	str	x0, [x1]

	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	str	x0, [x1]

	ldr	x1, =PrintVarFormatMode
	mov	x0, #0
	str	x0, [x1]

	ldr	x1, =OutCharacterLimit
	mov	x0, #10
	str	x0, [x1]

	ldr	x1, =OutParagraphLimit
	mov	x0, #10
	str	x0, [x1]

	ldr	x1, =OutLineLimit
	mov	x0, #10
	str	x0, [x1]

	ldr	x0, =10f
	bl	StrOut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	add	sp, sp, #48
	ret

10:	.ascii	"I/O Initialized\n"
	.byte	0
	.align 4

//--------------------------------------------------------------
//
//   Shutdown I/O for protram exit
//
//--------------------------------------------------------------
FileCloseForExit:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x8, [sp, #40]
	//
	// Is the directory descriptor still open? close it
	//
	ldr	x1, =fileDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	10f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	str	x0, [x1]
10:
	//
	// Is the directory descriptor still open? close it
	//
	ldr	x1, =dirDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	20f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =dirDescriptor_echo
	mov	x0, #0
	str	x0, [x1]
20:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	ldr	x8, [sp, #40]
	add	sp, sp, #64
	ret

//--------------------------------------------------------------
//
//   Echo console output to sequential numbered file
//
//   Input:  none
//
//   Output: none
//
//--------------------------------------------------------------
StartEcho:
	sub	sp, sp, #80		// Reserve 10 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x3, [sp, #40]
	str	x8, [sp, #48]
	str	x9, [sp, #56]
	//
	// Check if alreay Echoing
	//
	ldr	x1, =fileDescriptor_echo
	ldr	x0, [x1]
	cmp	x0, #0			// is there active file descrdiptor?
	b.eq	100f			// no, continue...
	ldr	x0, =echo_msg04		// else error, print message
	bl	StrOut
	b	999f
100:
	//
	// Get subdirectory descriptor
	//
	mov	x0, AT_FDCWD		// (dirfd) Special code to use current directory
	ldr	x1, =DirName_Echo		// (*pathname) address pointer to filename
	mov	x2, O_PATH		// (mode)
	mov	x3, #0644		// (flags) File perimission flags
	mov	x8, __NR_openat		// (openat())
	svc	0			// system call
	mov	x9, x0			// save directory descriptor (or error)
	//
	// Was subdirectory found?
	//
	adds	xzr, xzr, x0		// error?
	b.pl	110f
	//
	// Case of error, print error code and leave log off
	//
	ldr	x0, =echo_msg07	// Message with error string
	bl	StrOut
	ldr	x0, =DirName_Echo	// folder name
	bl	StrOut
	ldr	x0, =echo_msg08	// Message with error string
	bl	StrOut
	sub	x0, xzr, x9		// print error code
	bl	PrintWordB10
	bl	CROut
	bl	CROut
	bl	CROut
	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	ldr	x0, [x1]		// logging off
	b.al	999f
110:
	//
	// save sub-directory file descriptor
	//
	ldr	x1, =dirDescriptor_echo	// address of directory descriptor
	str	x9, [x1]		// save directory descriptor
	bl	CROut


120:
	//
	// Print trying Message
	//
	ldr	x0, =echo_msg02
	bl	StrOut
	ldr	x0, =DirName_Echo
	bl	StrOut
	mov	x0, #'/'
	bl	CharOut
	ldr	x0, =FileName_Echo
	bl	StrOut
	bl	CROut
	//
	// Test read file to see if filename needs to be re-indexed.
	//
200:
	ldr	x0, =dirDescriptor_echo	// address of directory descriptor
	ldr	x0, [x0]
	ldr	x1, =FileName_Echo	// (*pathname) address pointer to filename
	mov	x2, O_RDONLY	// (mode)
	mov	x3, #0644		// (flags) File perimission flags
	mov	x8, __NR_openat		// (openat())
	svc	0			// system call
	mov	x9, x0			// save file descriptor (or error)
	//
	// Check if error opening file
	//
	adds	xzr, xzr, x0		// error?
	b.mi	300f			// no, need new filename
	//
	// Close file, can't use this one
	//
	mov	x0, x9
	mov	x8, __NR_close		// (close())
	svc	0
	//
	// modify filename
	//
	ldr	x1, =FileName_Echo	// pointer to string
	// Third numeral
	ldrb	w0, [x1, #5]
	add	w0, w0, #1
	cmp	w0, #'9'
	b.hi	210f
	strb	w0, [x1, #5]
	b.al	200b
210:
	mov	w0, #'0'
	strb	w0, [x1, #5]
	// Second numeral
	ldrb	w0, [x1, #4]
	add	w0, w0, #1
	cmp	w0, #'9'
	b.hi	220f
	strb	w0, [x1, #4]
	b.al	200b
220:
	mov	w0, #'0'
	strb	w0, [x1, #4]
	// Third numeral
	ldrb	w0, [x1, #3]
	add	w0, w0, #1
	cmp	w0, #'9'
	b.hi	230f
	strb	w0, [x1, #3]
	b.al	200b
230:
	//
	// Done, no more numbers, error
	//
	ldr	x0, =echo_msg05
	bl	StrOut
	b.al	999f

300:
	//
	// Open file for write creating new file
	//
	ldr	x0, =dirDescriptor_echo	// address of directory descriptor
	ldr	x0, [x0]
	ldr	x1, =FileName_Echo	// (*pathname) address pointer to filename
	mov	x2, O_CREAT + O_WRONLY	// (mode)
	mov	x3, #0644		// (flags) File perimission flags
	mov	x8, __NR_openat		// (openat())
	svc	0			// system call
	mov	x9, x0			// save file descriptor (or error)
	//
	// Check if error opening file
	//
	adds	xzr, xzr, x0		// error?
	b.pl	320f
	//
	// Case of error, print error code and leave log off
	//
	ldr	x0, =echo_msg01		// Message with error string
	bl	StrOut
	sub	x0, xzr, x9		// print error code
	bl	PrintWordB10
	bl	CROut
	bl	CROut
	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	ldr	x0, [x1]		// logging off
	b.al	999f
320:
	ldr	x1, =fileDescriptor_echo// file descriptor variable
	str	x9, [x1]		// save file descriptor
	ldr	x0, =echo_msg06		// Start log message
	bl	StrOut
	ldr 	x0, =DirName_Echo	// filename buffer
	bl	StrOut
	mov	x0, #'/'
	bl	CharOut
	ldr 	x0, =FileName_Echo	// filename buffer
	bl	StrOut
	ldr	x0, =echo_msg09
	bl	StrOut
	bl	CROut
	bl	CROut
999:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	ldr	x3, [sp, #40]
	ldr	x8, [sp, #48]
	ldr	x9, [sp, #56]
	add	sp, sp, #80
	ret
echo_msg01:	.asciz	"\nError trying to open file for console echo. Code: "
echo_msg02:	.asciz	"      Trying file: "
echo_msg03:	.asciz	" not found. Creating file.\n"
echo_msg04:	.asciz	"\nError: There is already a file handle associated with console echo\n\n"
echo_msg05:	.asciz	"\nError: Only 999 sequential filenames allowed.\n\n"
echo_msg06:	.asciz	"\nEchoing stdout to file: "
echo_msg07:	.asciz	"\nError: unable to find sub-folder: "
echo_msg08:	.asciz	"\nThis folder must exist in the current directory.\nError Code: "
echo_msg09:	.asciz	". To cancel, type: logoff"
	.align	4

//--------------------------------------------------------------
//
//   Terminate console output to log file
//
//   Input:  none
//
//   Output: none
//
//--------------------------------------------------------------
StopEcho:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x8, [sp, #40]
	//
	// Confirm console echo enabled
	//
	ldr	x1, =fileDescriptor_echo
	ldr	x0, [x1]
	cmp	x0, #0			// is there active file descrdiptor?
	b.ne	100f			// no, continue...
	ldr	x0, =echo_msg11		// else error, print message
	bl	StrOut
	b	999f
100:
	//
	// Is the fo;e descriptor still open? close it
	//
	ldr	x1, =fileDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	110f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	str	x0, [x1]

110:
	//
	// Is the directory descriptor still open? close it
	//
	ldr	x1, =dirDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	120f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =dirDescriptor_echo
	mov	x0, #0
	str	x0, [x1]

120:
	ldr	x0, =echo_msg12
	bl	StrOut
	ldr	x0, =DirName_Echo
	bl	StrOut
	mov	x0, #'/'
	bl	CharOut
	ldr	x0, =FileName_Echo
	bl	StrOut
	bl	CROut
	bl	CROut
999:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	ldr	x8, [sp, #40]
	add	sp, sp, #64
	ret

echo_msg11:	.asciz	"\nError: output not currently echoing to file\n\n"
echo_msg12:	.asciz	"\nClosed file: "
echo_msg13:	.asciz	"\nError closing text capture output file\n"
	.align 4

//--------------------------------------------------------------
//
//   Check if output is echoing to file
//
//  Output  x0 = 0, not echoing
//          x0 = 1, echoing
//
//--------------------------------------------------------------
CheckEchoing:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]

	ldr	x0, =fileDescriptor_echo
	ldr	x0, [x0]

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	add	sp, sp, #32
	ret


/******************************************************
  KeyIn - Read text line from console input

  Input: none

  Output: X8 = address of buffer

*******************************************************/
KeyIn:
	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	mov	x0, STDIN_FILENO		// stdin stream
	ldr	x1, =KeyBuf		// point to buffer
 	mov	x2, #(KeyBufLen-8)	// buffer size (count)
	mov	x8, __NR_read		// Request code
	svc	#0			// kernel syscall

	tst	x0, x0			// count zero?
	b.eq	10f
	sub	x0, x0, #1		// point prior to LF (0x10)
10:
	mov	w2, #0			// null terminate string
	strb	w2, [x1,x0]		// Character EOL --> 0x00

	ldr	x8, =KeyBuf		// Return buffer address

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x1, [sp, #24]
	ldr	x2, [sp, #32]
	add	sp, sp, #48
	ret

/* *****************************************************
  StrOut - Print null-terminated string

  Input: x0 contains 64 bit address of string

  Output: none

  x0 is preserved

****************************************************** */
StrOut:
	sub	sp, sp, #48		// Reserve 6 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x9, [sp, #24]

	tst	x0,x0			//check for zero in pointer
	b.eq	20f			//yes, done, exit

	mov	x9, x0			// Setup pointer
	ldrb	w0, [x9], #1		// w0 first character to print
	tst	w0, w0			// null string?
	b.eq	20f			// Yes, exit on empty string
10:
	bl	CharOut			// Output character
	ldrb	w0, [x9], #1		// w0 = next character
	tst	w0, w0			// End of string?
	b.ne	10b			// Yes, exit on zero byte

20:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0, [sp, #16]
	ldr	x9, [sp, #24]
	add	sp, sp, #48
	ret

/* *****************************************************
  CharOut - Output character in x0 to stdout

  Input: low byte of x0 contains ASCII character to print

  Output: none

****************************************************** */
CharOut:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x8, [sp, #40]

	ldr	x1, =OutChar		// buffer address
	str	x0, [x1]		// store character for print
	mov	x0, STDOUT_FILENO	// stream
	mov	x2, #1  		// count
	mov	x8, __NR_write		// write
	svc	#0			// syscall

	ldr	x0, =fileDescriptor_echo
	ldr	x0, [x0]		// get file descriptor
	cmp	x0, #0			// is echo to log file enabled
	b.eq	100f

	// x0 is file descriptor
	// x1 is buffer address
	mov	x2, #1  		// count
	mov	x8, __NR_write		// write
	svc	#0
	//
	// Check for error writing to file
	//
	adds	xzr, xzr, x0		// error?
	b.pl	100f
	//
	// Is the file descriptor still open? close it
	//
	ldr	x1, =fileDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	10f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =fileDescriptor_echo
	mov	x0, #0
	str	x0, [x1]
10:
	//
	// Is the directory descriptor still open? close it
	//
	ldr	x1, =dirDescriptor_echo
	ldr	x0, [x1]		// directory file descriptor
	cmp	x0, #0			// is there active descriptor?
	b.eq	20f			// no skip
	mov	x8, __NR_close		// (close())
	svc	0
	// zero descriptor variable
	ldr	x1, =dirDescriptor_echo
	mov	x0, #0
	str	x0, [x1]
20:
	//
	// Now print the error message
	//
	//
	// Case of error
	//
	ldr	x0, =echo_msg20
	bl	StrOut
100:
	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	add	sp, sp, #64
	ret

echo_msg20:	.asciz "\nError writing console output to file. Logging stopped.\n\n"
	.align 4


/* *****************************************************
  CharOutFmt - Output character in x0 to stdout

  Input: low byte of x0 contains ASCII character to print

  Output: none

****************************************************** */
CharOutFmt:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	mov	x2, x0			// save character to print

	ldr	x1, =PrintVarFormatMode
	ldr	x0, [x1]
	tst	x0, #1
	b.ne	10f
	mov	x0, x2
	bl	CharOut
	b.al	99f
10:
	cmp	x2, #'+'
	b.eq	11f
	cmp	x2, #'-'
	b.eq	11f
	b.al	14f
11:	mov	x0, x2			// get the + or - character
	bl	CharOut			// output the + or - sign
	ldr	x1, =OutCharacterCounter
	ldr	x0, [x1]		// get current count
	sub	x0, x0, #1		// decrement
	str	x0, [x1]		// and save
	b.al	99f
14:
	cmp	x2, #'.'
	b.ne	15f
	mov	x0,#'.'
	bl	CharOut			// print decimal point
	bl	CROut			// print end of line return
	mov	x0,#' '			// print 2 leading ascii space characters
	bl	CharOut
	bl	CharOut

	ldr	x1, =OutCharacterCounter
	mov	x0, #-1
	str	x0, [x1]
	ldr	x1, =OutParagraphCounter
	mov	x0, #0
	str	x0, [x1]
	ldr	x1, =OutLineCounter
	mov	x0, #0
	str	x0, [x1]
	b.al	99f
15:
	cmp	x2, #'('		// separate extended digits with ( )
	b.ne	16f
	bl	CROut
	mov	x0, #' '		// leading space
	bl	CharOut
	mov	x0, #'('		// parenthesis
	bl	CharOut
	ldr	x1, =OutCharacterCounter
	mov	x0, #-1
	str	x0, [x1]
	ldr	x1, =OutParagraphCounter
	mov	x0, #0
	str	x0, [x1]
	ldr	x1, =OutLineCounter
	mov	x0, #0
	str	x0, [x1]
	b.al	99f
16:
	ldr	x1, =OutCharacterLimit
	ldr	x1, [x1]
	ldr	x0, =OutCharacterCounter
	ldr	x0, [x0]
	add	x0, x0, #1
	cmp	x1, x0
	b.hi	19f
	ldr	x1, =OutCharacterCounter
	mov	x0, #0
	str	x0, [x1]
	mov	x0, #' '
	bl	CharOut
	b.al	20f
19:
	ldr	x1, =OutCharacterCounter
	str	x0, [x1]
	b.al	50f
20:
	ldr	x1, =OutParagraphLimit
	ldr	x1, [x1]
	ldr	x0, =OutParagraphCounter
	ldr	x0, [x0]
	add	x0, x0, #1
	cmp	x1, x0
	b.hi	29f
	ldr	x1, =OutParagraphCounter
	mov	x0, #0
	str	x0, [x1]
	bl	CROut
	mov	x0, #' '		// print 2 blank spaces
	bl	CharOut
	bl	CharOut
	b.al	30f
29:
	ldr	x1, =OutParagraphCounter
	str	x0, [x1]
	b.al	50f
30:
	ldr	x1, =OutLineLimit
	ldr	x1, [x1]
	ldr	x0, =OutLineCounter
	ldr	x0, [x0]
	add	x0, x0, #1
	cmp	x1, x0
	b.hi	39f
	ldr	x1, =OutLineCounter
	mov	x0, #0
	str	x0, [x1]

	mov	x0, #' '		// print 2 blank spaces
	bl	CharOut
	bl	CharOut
	bl	CharOut
	mov	x0, #'('		// print 2 blank spaces
	bl	CharOut
	ldr	x1, =ParagraphLabelCounter
	ldr	x0, [x1]
	add	x0, x0, #1000
	str	x0, [x1]
	bl	PrintWordB10
	mov	x0, #')'		// print 2 blank spaces
	bl	CharOut

	bl	CROut			// print 2nd end of line returns (first from paragraph)
	mov	x0, #' '		// print 2 blank spaces
	bl	CharOut
	bl	CharOut
	b.al	50f
39:
	ldr	x1, =OutLineCounter
	str	x0, [x1]
50:
	// Output the character
	mov	x0, x2
	bl	CharOut
99:

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	add	sp, sp, #64
	ret

/* *****************************************************
  CharOutFmtInit - Output character in x0 to stdout

  Input: x0 is format mode
  	bit 0 --> 0=disabled, 1=enabled

  Output: none

****************************************************** */
CharOutFmtInit:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]

	ldr	x1, =PrintVarFormatMode
	str	x0, [x1]

	mov	x0, #0
	ldr	x1, =OutCharacterCounter
	str	x0, [x1]
	mov	x0, #0
	ldr	x1, =OutParagraphCounter
	str	x0, [x1]
	ldr	x1, =OutLineCounter
	str	x0, [x1]
	ldr	x1, =ParagraphLabelCounter
	str	x0, [x1]

	mov	x0, #' '		// lead number with 1 blank spaces to left
	bl	CharOut


	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	add	sp, sp, #64
	ret


/* *****************************************************
  CROut - Output Return and LineFeed to stdout

  Input:  none

  Output: none


****************************************************** */
CROut:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]

	mov	x0, #0x0A		// ASCII Linefeed Char
	bl	CharOut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

/* *****************************************************
  ClrScr - Output control characters to clear screen

  Input:  none

  Output: none

****************************************************** */
ClrScr:
	sub	sp, sp, #32		// Reserve 4 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]

	ldr	x0, =Clear_String
	bl	StrOut

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
	ldr	x0,  [sp, #16]
	add	sp, sp, #32
	ret

Clear_String:
	.byte	27
	.ascii 	"[2J"			// Clear Screen
	.byte	27
	.ascii	"[H"			// Home Cursor
	.byte	0			// End of string
	.align 4


//--------------------------------------------------------------
//
//  Get system time
//
//  Input:   none
//
//  Output:  x0  Time in seconds
//           x1  Time in microseconds
//
//--------------------------------------------------------------
ReadSysTime:
	sub	sp, sp, #64		// Reserve 8 words
	str	x30, [sp, #0]		// Preserve these registers
	str	x29, [sp, #8]
	str	x0, [sp, #16]
	str	x1, [sp, #24]
	str	x2, [sp, #32]
	str	x8, [sp, #40]

//	bl	ClearRegisters

	ldr	x0, =time_buf
	mov	x8, __NR_gettimeofday	// 64 bit syscall code (169)
	svc	#0

	ldr	x1, =time_buf		// sys call buffer
	ldr	x0, [x1]		// time in seconds
	mov	x2, #1000		// seconds --> milliseconds
	mul	x0, x2, x0
	ldr	x1, [x1, #8]		// microseconds
	udiv	x1, x1, x2		// microseconds --> milliseconds
	add	x0, x0, x1

	ldr	x30, [sp, #0]		// restore registers
	ldr	x29, [sp, #8]
//	ldr	x0,  [sp, #16]
	ldr	x1,  [sp, #24]
	ldr	x2,  [sp, #32]
	ldr	x8,  [sp, #40]
	add	sp, sp, #64
	ret


// ------------------------------------------------------------

	.end
