# 7 Days to go ...

## Read file [HISTORY.md](../master/HISTORY.md) to follow progress to date.

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

## Update 2021-03-07 (See [HISTORY.md](../master/HISTORY.md)).

The core arithmetic functions are now working. This includes
addition, subtraction, multiplication, long division (bit-wise)
There may be some edge case errors, but the best way to find
these is to move forward with the rest of the program.

In this state, the program basically works like an RPN calculator.
Numbers may be input followed by the [enter] key. The
"*", "/", "+", and "-" operators will invoke the arithmetic
functions. Pressing a period will print the X-Register.

Summation of infinite series is in progress. As a test
the constant e (sum of n!) has been calculated to 1 million
decimal places and the square root (2) has been calculated
to 1 million decimal places.

The main purpose of this program is to calculate pi, and
coding of that infinite series is in progress.

I am optimistic I can calculate pi on a pi by pi-day.

## Commands available:

```
+ - * / . c.e chs clrstk clrx cmdlist
D.vars D.fill D.ofst enter exit help
hex log logoff mmode prac print q recip
quit rcl rdown rup sf sigfigs sqrt sto
test version xy
```

## First benchmark 2021-03-04 Calculation of e

First benchmark was able to calculate e to 1 million digits in
less than 5 minutes.

```
Terms    Request  Verified   Elapsed Time
(n)       Digits    Digits     In Seconds
-----    -------   -------   ------------
22            10        20
80           100       118
452         1000      1005
3255       10000     10021          0.168
25210     100000    100017          3.368
205027   1000000   1000024        279.820
```

## Second benchmark 2021-03-07 Calculation of square root (2)

```
   Digits     Seconds
    10000       0.575
    20000       2.263
    40000       9.378
   100000      48.134
   200000     202.544
  1000000    4238.884
```
