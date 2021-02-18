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

### 2021-02-15

- Fixed several errors perserving registers in Hello World
- Added Keyboard input function KeyIn, reads line from console terminal with address in X0
- Added util.s with function to print byte and 64 bit word in hexadecimal format to stdout

- Added command parser

The command parser is a table of 8 byte null terminated strings and 8 byte jump addresses,
with 16 bytes per command. Upon a command match, the address of the handler is
put into the x30 register, and a `ret` command is executed as a "jump".

Checks were added to make sure the stack pointer does not change and a check
that the command addresses are in btye alignment.

### 2021-02-16

Spent many hours reading asm64 docs. Following docs, cleaned up register use
following convention for register numbering. Cleaned up command parsing code in parser.s

- Added function ClearRegisters to zero all non-critical registers
- Added function PrintRegisters to show all 31 registers
- Added function PrintFlags to show Z, C, N and V flags (may be inserted in loop)
- Added function to print 64 bit register as base-10 unsigned integer

### 2021-02-17

- Added practice.s as sandbox to try learning ARM64 code
- Added endian check for 32 bit w0 and 64 bit x0 memory load to register
- 64 bit string to integer converter

During user input, following command a space delimited string is available for parsing.
The address of the argument string is available in x0.
Wrote function IntWordInput to convert integer string to binary unsigned 64 bit integer.
Error checking added for empty string and non-numeric characters.

### 2021-02-18

- created math.s to hold variable declarations

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
of the application, rather than use dynamically allocated memory.

This raises the question of variable scope. Considering the names and references
to the variable area are complex, and size of the variables can be adjusted
by configuration variables, I intended to keep the scope of the name space
for variable definitions in the math.s module and then include arithmetic functions
as include files into the math.s file. This way I can have separate files
for math arithmetic functions, but all calculations will be within one object module.

- Renamed arch.inc-->arch-header.s and header.inc-->header-include.s to get editor syntax highlighting.
