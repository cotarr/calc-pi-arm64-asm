# Program history

### 2021-02-14 - Day 1 (28 days to go until pi day)

- Created empty git repository
- Installed 64 bit beta Raspberry OS from https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/
- Put SD card into: Raspberry Pi 4 Model B Rev 1.2
- Updated packages to current version `apt-get update && apt-get upgrade`

- Check for 64 bit mode

```
$uname -m
aarch64
```
- Run lscpu to get cpu and arch

```
$lscpu
Architecture:        aarch64
Byte Order:          Little Endian
CPU(s):              4
On-line CPU(s) list: 0-3
Thread(s) per core:  1
Core(s) per socket:  4
Socket(s):           1
Vendor ID:           ARM
Model:               3
Model name:          Cortex-A72
Stepping:            r0p3
CPU max MHz:         1500.0000
CPU min MHz:         600.0000
BogoMIPS:            108.00
Flags:               fp asimd evtstrm crc32 cpuid
```

- Created source file main.s iomodule.s, arch.inc, header.inc
- GNU assembler flags in arch.inc
```
  .arch armv8-a		// arm64 --> trying armv8-a
  .cpu  cortex-a72	// Raspberry Pi 4 from lscpu
```

- Wrote Hello World, print string with address in X0, first commit:

- main.s - assembler file with program entry point
- iomodule.s - Character print routines to stdout
- arch.s - Include file for 'cpu' and 'arch' directives
- header.s - Include file for configuration variables
- makefile - Build file to call assembler and linker

```
git checkout d5188777cda71522eb2428c5fdba4ab9a0a63314
```

### 2021-02-15 - Day-2 (27 days to go until pi day)

- Fixed several errors preserving registers in Hello World
- Added Keyboard input function KeyIn, reads line from console terminal with address in X0

```
git checkout be53bf079df40da133861fe7ebc44e38fe3a4d66
```

- util.s - New file with function to print byte and 64 bit word in hexadecimal format to stdout

```
git checkout 5ff998d0ff4f71e28e12d000c9aa12471d1471ab
```

- parser.s - New file to hold command parser code.

The command parser is a table of 8 byte null terminated strings and 8 byte jump addresses,
with 16 bytes per command. Upon a command match, the address of the handler is
put into the x30 register, and a `ret` command is executed as a "jump".
Initial commands: `cmdlist exit q quit test version`

Checks were added to make sure the stack pointer does not change and a check
that the command addresses are in byte alignment.

```
git checkout e54339d9f52c790d3e19fe42b6c0cc32b8e141d0
```

### 2021-02-16 - Day 3 (26 days to go until pi day)

Spent many hours reading asm64 docs. Following docs, cleaned up register use
following convention for register numbering. Cleaned up command parsing code in parser.s

- Added function ClearRegisters to zero all non-critical registers
- Added function PrintRegisters to show ARM registers x0 to x31
- Added function PrintFlags to show Z, C, N and V flags (may be inserted in loop)
- Added function to print 64 bit register as base-10 unsigned integer

```
git checkout 8b2540ab1f30d5fda32fc68e5f4d54e65f19bc59
```

### 2021-02-17 - Day 4 (25 days to go until pi day)

- practice.s - New file as sandbox to try learning ARM64 code.
- Added endian check for 32 bit w0 and 64 bit x0 memory load to register
- 64 bit string to integer converter

Use of command arguments: During user input an argument may be added
to a command followed by a space character to delimiter a string for parsing.
The address of the argument string is available in x0 in the command handler in parser.s.
Added a new function IntWordInput to convert integer string to binary unsigned 64 bit integer.
Error checking added for empty string and non-numeric characters.

```
git checkout fd759390c4cd42e42855eef002c2da5b597838f4
```

### 2021-02-18 - Day 5 (24 days to go until pi day)

- math.s - New file to hold variable declarations
- math-debug.s New file to hold debug tools used to write the program.
- arch-include.s - Renamed from arch.inc to get editor source highlighting.
- header-include.s - Renamed from header.inc to get editor source highlighting.

Typically, variables would be defined as binary floating point, with an
exponent, mantissa, and some extra words at the least significant end to absorb
errors which are called guard words.
```
   < binary exponent words>  <mantissa words> <guard words>
```

However, for the case of calculation of pi, scientific notation is not really
needed. To simplify the code, I am going to define the variables as fixed point.
In this case there must be a decimal point to separate integer part from fraction part.
```
   <binary integer part> /decimal point/ <binary fraction part>  <guard words>
```

In the case of this program, the variables are declared within the load image
of the application, rather than by dynamically allocated memory.

This raises the question of variable scope. Considering the names and references
to the variable area are complex, and size of the variables can be adjusted
by configuration variables, I intended to keep the scope of the name space
for variable definitions in the math.s module and then include arithmetic functions
as include files into the math.s file. This way I can have separate files
for math arithmetic functions, but all calculations will be within one object module.

- Added function FP_Initialize to setup variable space on program start

In order to view variables while writing the program, a tool is needed to display
variables in hexadecimal. This is useful when testing future code, such as integer addition.

- Add command with optional argument `hex [<reg-no>]` used to fully display one variable or abbreviate display all variables in hexadecimal

```
Op Code: hex
REG   Hand M.S. Word                      (no guard) L.S.W
ACC   ( 0) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
OPR   ( 1) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
WORKA ( 2) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
WORKB ( 3) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
WORKC ( 4) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
XREG  ( 5) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
YREG  ( 6) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
ZREG  ( 7) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
TREG  ( 8) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
REG0  ( 9) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
REG1  (10) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
REG2  (11) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000
REG3  (12) 0000000000000000 0000000000000000 0000000000000000 0000000000000000 .. 0000000000000000

Op Code: hex 4
WORKC  (4)
0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000 0000000000000000
0000000000000000 0000000000000000
Op Code:
```

- Added command `D.fill <reg number>` and to fill a variable with incremental bytes values, 11, 12, 13, ...


```
git checkout ef153bbb5fa1e279d214abb7029f15f3841bec91
```

### 2021-02-19 - Day 6 (23 days to go until pi day)

- math-subr.s - New file for boiler plate arithmetic utilities
- Added function ClearVariable argument x1 index number of variable to clear
- Added function CopyVariable argument x1 source x2 destination indexes of variable to clear
- help.s - New file to hold help utility in the future, added program start welcome message
- Added command `help [<command>]` to show help for commands.
- Added function to print error message following fatal errors
- math-rotate.s - New file to hold bit rotations function
- Added function Right1Bit to perform shift right 1 bit, copying sign bit

```
git checkout 019035bfb629efc95ab513a0a3e9ab3990725183
```

### 2021-02-20 - Day 7 (22 days to go until pi day)

- Added function Left1Bit to perform shift right 1 bit, zero fill l.s. bit

This is a good place to discuss number format. I am assuming a fixed point binary number.
On the most significant end, there will be 1 64 bit word for the integer part.
Using the top bit as a sign bit, this is 63 bits for integer number values.
All remaining words will be fraction part.

In the integer part, the bits moving upward represent 1, 2, 4, 8, 16 ...
In the fraction part, moving downward, the bits represent 1/2, 1/4, 1/8, 1/16, 1/32....

```
  [Most-significant 64 bit word]  -Decimal-Point  [Fraction part 64 bit word][word][word]
```  

- Added function SetToOne and SetToTwo to enter integer constants (using above assumptions)

I ran into a confusing situation with ARM64 flags. I want to write a Two's Compliment function.
This is a fancy way of saying, subtract the number from zero.
For multi-precision calculations, each 64 bit subtraction will borrow the carry flag
if needed. The next subtraction will subtract both the 64 bit value and the (NOT) carry flag.
However, a loop also needs a counter. Decrement the counter needs a test.
Other processors you can "push" or preserve the flag register. I could not find a
way to do this in ARM64. I tried complicated ways to save carry in a register, but
it was too complicated and costly in instructions.

Then I discovered the CBNZ instruction that will check a register and conditionally branch
WITHOUT changing the flags. I setup a test in practice.s to confirm this. It was successful.
The two's compliment loop appears successful with SBCS (use carry flag) and CBNS (not impact flag).

- Added function for 2's compliment.

Note about entry with variable equal to zero.
In scientific notation variables, i usually test the top word
of a normalized mantissa for zero, then skip the 2's compliment if
the variable is zero when 2's complement is called.
Since this is fixed point format, there is no normalized word to check.
Also, I have not provided a zero flag for the variable.
Executing this function with a zero value returns all words zero.
I have left it at this point, but may revisit a zero check in the future (TODO)

- Added function AddMantissa
- Standardized register use, the clean up all register use for today's work.
```
x0 - In/Out argument then scratch when saved
x1 - In/out argument then scratch
x2 - In/out argument then scratch
x3 - In/out argument then scratch
x8 - Buffer pointer for return values
x9 - Index offset into word
x10 - Word counter for loops
x11 - variable address pointer 1
x12 - variable address pointer 2
x13 - variable address pointer 2
```

```
git checkout d4207c8eea4d0921b38d41f9b2b87f3e8710ee07
```

### 2021-02-21 - Day 8 (21 days to go until pi day)

Before going further, I need to add some utilities to configure
the different variables related to the current setting
for accuracy. The program uses a number of base 10 digits
in the fraction part of the number. This is adjustable by
user input. Functions in the program convert between
binary 64 bit words and human readable base 10 printed digits.
The conversion is 19.2659197224948 digit/(64 bit word)

- Added command sf, sigfigs to set and view current accuracy settings
- Added sigfigs to help

This is an example of user input of number size, set 1000 digits and 10 extra digits

```
Op Code: sf 1000

Accuracy: 1000 Digits

Op Code: sf v

Decimal (base 10) Accuracy:
  Integer Part:        38 	Digits
  Fraction Part:       1000 	Digits
  Extended Digits:     10 	Digits
  Calculation Digits:  1079 	Digits
  Available Digits:    1156 	Digits

Binary Accuracy:
  Integer Part:        2 	Words
  Fraction Part:       50 	Words
  Guard Words:         4 	Words
  Combined:            56 	Words
  Available:           66 	Words

```

Ran into problem. I was using the offset of the most significant word
as an immediate value VAR_MSW_OFST. However, the assembler only
allows 12 bits for this immediate value. I moved several
of the declared constants to be stored in memory. Then a variable
is defined by INT_WSISE and FCT_WSIZE in 64 bit words for
the integer part and fraction part.

- Cleaned up previous function for VAR_MSW_OFFSET --> [VarMsbOfst]

```
git checkout 6775622f14c2687e3d7c0d35df9dc4cbe5aea585
```

### 2021-02-22 - Day 9 (20 days to go until pi day)

The next task is creation of conversion routines from binary to base-10 and
base-10 to binary.

- math-output.s - New file to contain number conversion (input conversion and print conversion)
- Added empty functions for PrintVariable and InputVariable
- Setup number detection in parser.s to differentiate "+", "-" and "." as number or command
- Added command . and print, calling empty PrintVariable
- Update help file for print and "." commands ("." = "print")
- Tested this far and git commit leaving PrintVariable and InputVariable empty
- Added commands clrx and clrstk to set X register and X,Y,Z,T registers (variables) to zero
- Added function to multiply by 10 using 32 bit x 32 bit = 64 bit process arithmetic
- Added function to divide by 10 using 64 bit / 32 bit = 32 bit quotient and 32 bit remainder
- Added function TestIfNegative looking at top bit of number
- Added function TestIfZero, 2's compliment if needed, then all word except guard words.
- Added function SubtractVariable

The binary to decimal conversion is now working. Basically it functions as follows:

```
1 - Check if zero, output "+0.0"
2 - Check if negative, print minus sign and perform 2's compliment
3 - Add rounding addition to L.S. word in guard words
4 - Check if integer part less than 10, if greater divide by 10 until less.
5 - In a loop multiply the number by 10.0 to eject digits one at a time.
```

- Test print 2.0 to 100,000 digits, elapsed about 7.5 seconds
- Test print 2.0 to 1,000,000 digits, elapsed time about 10 minutes

```
git checkout feff7da331abe0d37f38856384f0539babc8241b
```

### 2021-02-23 - Day 10 (19 days to go until pi day)

- math-input.s - New file to hold decimal to binary conversion
- Arranged code, moved MultiplyByTen and DivideByTen to math-subr.s
- Add debug function D.vars to show accuracy variable current values

- Added function InputVariable to convert base-10 decimal digits to binary

```
Character processing flow

1 - Detect End of string null byte (Go to step 5)
2 - Detect characters plus, minus, and decimal point, set state variable as needed
3 - Case of integer part digits:
   3A - Multiply previous accumulated number 10
   3B - Convert ascii to BCD
   3C - Add BCD btye to accumulated number
4 - Case of fraction part
  4A - Increment power of 10 decade counter
  4B - Convert ascii to BCD
  4C -  In loop for count of decade counter
       Divide BCD digit by 10
  4D - Add Divided BCD digit to accumulated result
5 - Perform 2's compliment if negative
```

Example (printing 50 digits):

```
Op Code: -123.456777345354
-123.45677734535400000000000000000000000000000000000
Op Code: 0
+0.0
Op Code: 0.1
+0.1000000000000000000000000000000000000000000000000
```

- Added function PrintResult to temporarily set accuracy to 50 digits and print result
- Input Decimal to binary and Output binary to base-10 decimal are working now.

```
git checkout 27f3dfa83583c4d55c1a7b44d5785812d7c2a3c2
```
- Added function PrintResult to be used with each command entry show intermediate result
- Added ChartOutFmt to implement formatted output

At this point, I found that my variables used to set accuracy level (number of significant digits)
were poorly chosen. There are issues with immediate values having range limitation
on the number of bits. I set out and re-engineered the config variables that
are defined or declared  as memory variable. This allows full 64 bit number values
to be pulled from RAM when the immediate range is limited for a function.

Fortunately, the selection of new variables will reduce a lot of redundant address and pointer
calculation, but this will have to be updated by hand. Unfortunately, changing the variable
names globally broke everything, and it took me the better part of a day to sort it out.

There is still a problem with number input at accuracy over 1000 digits and above, it breaks and
produced gibberish. This will be debugged another time.

### 2021-02-24 - Day 11 (18 days to go until pi day)

- address.s - New file for functions to calculate addresses and offsets for data variables

The goal for today is to re-organize the calculation of addresses and offset pointers.
After yesterday, I have gained a lot of understanding about ARM64 addressing and
range limitations of immediate values. My goal today is to consolidate these
address calculations into functions in address.s.

- Preliminary address calculation working in address.s
- Functions to return both offsets and addresses of different parts of variables
- Optimized addresses in math-input.s math-output.s and part of math-subr.s
- Fixed input error in input decimal to binary (was mis-matched stack push/pop)
- Numerous bug fixes and code clean up.
- Debug function D.ofst and D.vars to show offset and addresses.
- Both input and output base 10 conversion seem to be working now

Looking back, today was too many changes at one time causing simultaneous
defects that were difficult to debug. Further testing is needed
tomorrow to make sure there are no other issues.

```
git checkout 88c904e9643fea472503de0aef034be49a59b5ea
```
### 2021-02-25 - Day 12 (17 days to go until pi day)

- Finished code clean up in file math-subr.s
- Added commands "+", "-", and "chs" to help test program with RPN calculation.
- Code clean up address pointers in rotate.s
- Command parser monitoring of stack pointer to detect program code errors

After spending so much time yesterday due to a mis-matched stack
manipulation, the command parser now check SP value and the
first two word value on the stack to see if they change. If change
is detected, an error is printed.

- Modified PrintResult to show stack X,Y,Z,T with each operation
- math-div.s - New file for long division routines
- Function LongDivision is now working for debug
- Added command "/" to call divide in RPN calculator
-
This is a bit-wise long division. It is a VERY slow method to divide
two numbers, and thus not very useful to calculate pi. I have included
it to show how the division works.

Since this is a fixed point number, currently 2 integer part 64 bit words,
and variable fraction part words, there are some outstanding issues trying
to align the decimal separator to avoid overflow on the left (most significant
end), or loss of accuracy, pushing numbers out the right less significant end.
Currently, I am shifting the Dividend right 128 bits before divide
but I would like to optimize this and check for overflow. The rough
steps to divide are as follows, (code commented in more detail.)

```
1  Subtract WorkA[i] = OPR[i] - ACC[i]
2  If result negative (highest bit 1) then copy OPR = WorkA
3  Rotate OPR and WorkB left 1 bit at a time
4  For each cycle, if M.S.Bit of WorkA = 1 then Rotate 1 into L.S. Bit WorkB
5  When done all bits, result mantissa is in WorkB
```
```
Calculate 1/7 to 200 digits as example:

Op Code: 1
Op Code: 7
Op Code: /
Op Code: .
+0.1428571 4285714285 7142857142 8571428571 4285714285 7142857142 8571428571 4285714285 7142857142 8571428571
4285714285 7142857142 8571428571 4285714285 7142857142 8571428571 4285714285 7142857142 8571428571 4285714285
```

```
git checkout 24e5f1f024dd4ba9e2fcb9d0d4295de9300be6c6
```

### 2021-02-26 - Day 13 (16 days to go until pi day)

- Add function Right64bit, Left64Bit to logical shift even words
- First benchmark test bit-wise long division time 100000 digits 11 seconds on Pi 4
- Add function RightNBits, LeftNBits logical shift on full variable size.
- Add overflow error detection to long division
- Optimized of bit alignment in ACC and OPP during long division.
- Added commands xy, rup, rdown

```
git checkout 191ee7b1f0919b68e7c724ad209033c94228514b
```
### 2021-02-27 - Day 14 (15 days to go until pi day)

- Complete all edge cases of RightNBits and LeftNBits (some test code at end of rotate.s)
- Setup placeholder file for multiplication
- Spent rest of day writing multiplication.

### 2021-02-28 - Day 15 (14 days to go until pi day)

Most of today was spent debugging the multiplication function.
This method breaks the number into 64 bit words. They words are multiplied
using the ARM64 mul and umulh instructions in a matrix and recombined
into a product. It is functional for debug, but needs some optimization
to improve loss of significant bits on the least significant end.

- Fixed bug in MultiplyByTen DivideByTen with wrong left shift value.
- Fixed several stack push/pop typographic errors
- Fixed bug in input routine with random digits in lowest 32 bits.
- Multiplication is working for debug but not optimized yet.


### 2021-03-01 - Day 16 (13 days to go until pi day)

- Fixed and tested bit alignment for word multiplication
- Fixed error in sign flag on multiplication
- Added function Reg32BitDivision to divide full variable with 32 bit integer
- Added division selector to choose long division or faster 32 bit division
- Added function Reg64BitMultiplication to multiply full variable with 64 bit integer
- Added multiplication selector to choose long multiplication or faster 64 bit multiplication

This is a moment to step back and summarize. The core arithmetic functions are now
working. This includes addition, subtraction, multiplication (matrix 64bit*64bit-->128 bit),
long division (bitwise), and 32 bit division by integer, and 64bit multiplication by
by integer. There may be some edge case errors, but the best way to find these is to move
forward with the rest of the program. It would be nice to add a reciprocal function (1/x),
because multiplication of reciprocal is much faster than equivalent long division.
The reciprocal would be nice for square root calculation, but I think simple
series summation can move forward without it for now. I may add reciprocal later.

```
git checkout 99f360ec560a8a56ca043fd7bc4f6685c4d6dc5d
```

### 2021-03-02 - Day 17 (12 days to go until pi day)

- Added command mmode to disable shortcut multiplication and division
- Added command enter to duplicate x into y and roll stack
- Add range check on number input when integer part exceeds word size.
- Added argument "f" to print command to formatted or un-formatted
- Improved format print page layout, large integer part, and extended digits
- Multiple bug fixes in input, output, and formatted print
- Output rounding, moved round bit up to bit 8 of second guard word.
- Add calculation timer to display calculation interval with accuracy in milliseconds.

### 2021-03-03 - Day 18 (11 days to go until pi day)

There is no point to calculating pi if the number can not be saved to a file.
I spent some time working in practice.s to learn how to read and write
text file from ARM64. This was difficult. Google as I would, I could only
find ARM32 examples. The code definitions and registers are different. Also,
`open` is deprecated in ARM64, and `openat` must be used. I knew there were
4 arguments, dirfd, *filename, mode, and flags. I tried different
registers in x0, x1, x2, and x3 until it got it to work by trial and error.
I'm not sure this is fully correct, but it works to write text to a file, then
read the text back for printing. I'll put the git commit hash if it is useful
to anyone.
```
git checkout 43760215ecf87cd60f2f7f97a68306e4b21a7e99
```
- Added commands log and logoff. These echo stdout to sequentially numbered files out/out001.txt

This turned out to be more experimenting with ARM64 file I/O. Since the text files
are stored in a separate folder "out", then it was necessary to call `openat`
with mode `O_PATH` to obtain a file descriptor for the sub-directory.
The `openat` was called again with the sub-directory descriptor as the x0 dirfd attribute.

This files are numbered sequentially. They start at out/out000.txt, then increment up
to out/out999.txt.

### 2021-03-04 - Day 19 (10 days to go until pi day)

- Add calc.s as base file to include calculations
- Add calc-e.s to calculate e by summation 1/n!

Today the first series summation was added. To try this I used e where

e is infinite sum of  1 + (1/1) + (1/2) + (1/6) + (1/24) + ... + (1/n!)

Where n factorial is n! = 1 * 2 * 3 * 4 * 5 * ... * (n)

To simplify arithmetic, I am using the ARM udiv/msub instructions
to divide 64 bit Dividend by 32 bit divisor to get 32 bit quotient
and 32 bit remainder. Division is in a loop. There, n
may not exceed 32 bits and this is upper limit on this calculation.

There seems to be some accuracy range issues to work out
relative to 64 bit word size and overflowing bits.
This is my first series summation on a raspberry pi.

First benchmark was able to calculate e to 1 million digits in
less than 5 minutes.

```
Calculation of e

Terms    Request  Verified   Elapsed Time
  (n)    Digits    Digits     In Seconds
-----    -------   -------   ------------
22            10        20
80           100       118
452         1000      1005
3255       10000     10021          0.168
25210     100000    100017          3.368
205027   1000000   1000024        279.820
```

Rewrote some of the accuracy routines to set
number of printed digits and binary word count.
There was still an issue where changing the number
of guard words did not add more accuracy to
the calculation of e.

It turns out the problem was that the function TestIfZero
was not including guard bytes in the zero check.
Due to various round off errors I think I should probably
add a second function TestForNearlyZero. For now
the zero check looks at all words including the guard words.
the impact of guard words looks like this:

```
Calculation of e with different number of guard words

Guard   Terms    Request  Verified
Words     (n)    Digits    Digits
------  -----    -------   -------
0         450       1000       992
1         458       1000       991
2         466       1000      1009
3         473       1000      1030
4         480       1000      1049
2	25217     100000    100018
3	25222     100000    100038
4       25226     100000    100057
```

### 2021-03-05 - Day 20 (9 days to go until pi day)

I have decided to try writing a reciprocal function.
Reciprocal is much faster than long division.
Compare  ACC = OPR / ACC   verses  ACC = OPR * Reciprocal(ACC)
This may have an issue, because number must be
shifted into the range 0.5 to 1.0 for the reciprocal
to work. This is complicated because I am using
fixed precision (no exponent), but it is worth a try.

I decided to split multiplication into two separate functions.
The matrix processor multiplication is split into an internal
sub-routine. This is to allow use of the matrix multiply
part to be used in the reciprocal function.

- Function WordMultiplication split into WordMultiplication and _internal_matrix_multiply
- Added label of count of digits between paragraphs of 1000 digits.
- WordMultiplication rewrite of bit alignment of decimal separator and range check.
- WordMultiplication range check broken, commented out for now (TODO)

### 2021-03-06 - Day 21 (8 days to go until pi day)
- Created math-recip.s to hold reciprocal calculation
- Write reciprocal function using Newton Raphson method
- Added function CountLSBitsDifferent to compare two variables bit by bit
- Added function CountAbsValDifferenceBits compare absolute value of subtracted variables.
- RightNBits and LeftNBits allow input more than word size, returning zero work (all bits shifted, previously error)

Reciprocal Loop digit accuracy

```
Use Newton Raphson method
D = Demonimator
x = 1/D ,  make guesses for next Xn
Xn+1 =  Xn + (Xn*(1-Xn*D))

loops   Verified
  (n)     Digits
    5          6
    6         13
    7         26
    8         52
    9        104
```
After pushing I realize the WordMultiplictaion is broken, with some fault in the
new bit alignment code. Temporarily I copy/paste the old bit alignment code
into WordMultiplication until I can look at it further.

- Fixed stack push/pop range error in WordMultiplication (not related to alignment problem)
- Added mmode bit 0x02 - Force long division, else multiply reciprocal in place of divide.
- Function recip will switch between long division and reciprocal with mmode bit 0x02
- Some testing, arithmetic seems working (with old bit alignment code in multiply)

### 2021-03-07 - Day 22 (7 days to go until pi day)

- Added math-sqrt.s for square root calculation
- Added command sqrd to take square root of XReg

```
   Square root uses successive approximations
   X(i) = last guess   X(i+1) = next guess  A = input number
   X(i+1) =  [  (A / X(i))  + (X(i) ] / 2

Digits   Seconds
 10000     1.262
 20000     6.324
 40000    24.468
100000   180.340
200000   720.308
```

- Added functions Set_Temporary_Word_Size and Restore_Full_Accuracy
- In core arithmetic utilities, replace "... _Static" with "... _Optimized"

In order to speed up the calculation, the variables referring to the size of the
floating point variable and the pointer to the least significant word
are set to temporary values during parts of the calculation were full
accuracy is not needed. In the case of square root, the size of the
variable is set to 8 words, then increased by doubling the size at each increase.
This has reduced the time for the square root as follows:

```
Digits    Seconds
  10000     0.575
  20000     2.263
  40000     9.378
 100000    48.134
 200000   202.544
1000000  4238.884
```

```
git checkout te4fc3cdddddb573053bb53257b037dc6ee0c3435
```


### 2021-03-08 - Day 23 (6 days to go until pi day)

- Added command sto and rcl to use register 0 to 3 like a standard RPN calculator.
- Added command c.pi and c.pi.ch (same function) to calculate pi.

My first attempt at calculating pi is now coded for debugging.
The method used the Chudnovsky formula. I like this formula because it is
rapidly converging, gaining 14 digits per term of the series summation.

If you look at the there are two
apparent challenges: 1) calculation of square root of 10005 which is
calculated by successive approximations, and 2) the division
of the square root 10005 dividend by the full infinite series summation as divisor.
Both of these represent full precision slow calculations. Most of the rest of the calculation
can use 64 or 32 bit arithmetic and matrix through the variables word by word.

![Chudnovsky-Formula-Image](https://github.com/cotarr/calc-pi-arm64-asm/blob/main/images/Chudnovskyformula.jpg?raw=true)

There are some issues that need to be addressed that may increase the speed, as well
as some general code clean up.

Here is an initial benchmark of calculation times using a Raspberry Pi 4B at
standard CPU clock rate.

```
Digits   Seconds
  10000     1.049
  20000     4.820
  40000    23.344
 100000    77.266
 200000   321.775
1000000  7797.897

Binary to decimal conversion of 1000000 digits 299.708 seconds.
```

### 2021-03-09 - Day 24 (5 days to go until pi day)

Today, I tried running the program on several different
types of Raspberry Pi. It looks like 2B and earlier
won't boot the 64-Bit operating system.

```
Fail - Cortex-A7  Raspberry Pi 2 Model B Rev 1.1 (Won't boot 64 bit OS)
OK   - Cortex-A53 Raspberry Pi 3 Model B Rev 1.2
OK   - Cortex-A53 Raspberry Pi 3 Model B Plus Rev 1.3
OK   - Cortex-A72 Raspberry Pi 4 Model B Rev 1.2
```

This was a quick look at calculation speed and CPU temperature
on several pi. The test was calculation of pi was calculated to 200000 digits.
The raspberry pi and /boot/config.txt are at the factory
default values. There is no overclocking. Except for the last Pi-4B
there is no heat sink glued onto the processor. In general
one core was at 100% continuously. Access was by SSH so there was
no HDMI cable attached, so the GPU was possibly idle.

```
Model  Temperature   Time
Pi-3B       62       437.557 Seconds (No Heat Sink)
Pi-3B-Plus  60       373.523 Seconds (No Heat Sink)
Pi-4B       58       321.155 Seconds (No Heat Sink)
Pi-4B       42       317.762 Seconds (heat sink case)
```

### 2021-03-10 - Day 25 (4 days to go until pi day)

- Working on documentation and perhaps make a video for pi day.
- Updated chart of calculation times.

![Calculation-Time-Image](https://github.com/cotarr/calc-pi-arm64-asm/blob/main/images/pi-calc-time.png?raw=true)

### 2021-03-11 - Day 26 (3 days to go until pi day

- Update program start banner text.
- Add instructions to README.md

### 2021-03-12 - Day 27 (2 days to go until pi day)

I have discovered that making a video for this repository
is much more difficult than I expected. The past 2 days have
been spent moving the repository back in time to early
commits and discussing them in a video. I hope to
have it uploaded tomorrow so it will be online for pi-day.

### 2021-03-13 - Day 28 (last day)

- Added example calculation result in example-output/pi-1000000-digits.txt
- Fixed version string in command parser to 1.0
- Recording video covering day by day progress.

This ends my coding challenge to calculate pi on a pi for pi-day.

### Update: 2023-07-14

- Added /docs/ folder with a help web page.
- Updated README.md to note stable OS release.
- A few minor errors in comments in the code and help messages were corrected.
- No code changes were made, this commit contains only documentation additions.

