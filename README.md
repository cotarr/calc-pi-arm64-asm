# 11 Days to go ...

Read file [HISTORY.md](../master/HISTORY.md) to see progress to date.

## No Pi calculation yet, few more days please...

The start date was Feb 14, 2021. Time needed is 1 month.
The goal is to write ARM64 program to calculate pi, on a Raspberry Pi, by "Pi Day" March 14.

In order use a Raspberry Pi in 64-Bit mode, the new beta
version Raspberry OS 64 bit is required.

This is what I am using:

- Raspberry Pi 4 Model B Rev 1.2
- ARM64 (Beta) Debian GNU/Linux 10 (buster)
- https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/
- GNU Assembler + GNU linker with arch=armv8-a and cpu=cortex-a72
- Editor: Atom 1.48 with package: Language-arm v2.1.1
- Editor settings: tab size 8 with hard tabs

```
git clone git@github.com:cotarr/calc-pi-arm64-asm.git
cd calc-pi-arm64-asm
cd src
make

# to run
./calc-pi

```

Update 2021-03-01 (See [HISTORY.md](../master/HISTORY.md)).

The core arithmetic functions are now working. This includes
addition, subtraction, multiplication, long division (bit-wise)
There may be some edge case errors, but the best way to find
these is to move forward with the rest of the program.

In this state, the program basically works like an RPN calculator.
Numbers may be input followed by the [enter] key. The
"*", "/", "+", and "-" operators will invoke the arithmetic
functions. Pressing a period will print the X-Register.

In the next few days I plan to work with some code to
perform series summations and I build out other tools.
I still have Pi-day 2021 as a goal:

Calculate pi, on a pi, by pi-day.

## Commands available:

```
+ - * / . chs clrstk clrx cmdlist
D.vars D.fill D.ofst enter exit
help hex mmode prac print q quit
rdown rup sf sigfigs test version xy
```
