# Program history

### 2021-02-14 - Initial setup

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

### 2021-02-14

- Wrote Hello World, print string with address in X0, first commit:

- main.s - assembler file with program entry point
- iomodule.s - Character print routines to stdout
- arch.s - Include file for 'cpu' and 'arch' directives
- header.s - Include file for configuration variables
- makefile - Build file to call assembler and linker

```
git checkout d5188777cda71522eb2428c5fdba4ab9a0a63314
```

### 2021-02-15

- Fixed several errors preserving registers in Hello World
- Added Keyboard input function KeyIn, reads line from console terminal with address in X0

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

### 2021-02-16

Spent many hours reading asm64 docs. Following docs, cleaned up register use
following convention for register numbering. Cleaned up command parsing code in parser.s

- Added function ClearRegisters to zero all non-critical registers
- Added function PrintRegisters to show ARM registers x0 to x31
- Added function PrintFlags to show Z, C, N and V flags (may be inserted in loop)
- Added function to print 64 bit register as base-10 unsigned integer

```
git checkout 8b2540ab1f30d5fda32fc68e5f4d54e65f19bc59
```

### 2021-02-17

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

### 2021-02-18

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

- Add command with optional argument 'hex [<reg-no>]` used to fully display one variable or abbreviate display all variables in hexadecimal

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

### 2021-02-19

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

### 2021-02-20

- Added function Left1Bit to perform shift right 1 bit, zero fill l.s. bit
