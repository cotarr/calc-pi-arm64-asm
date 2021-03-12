# 2 Days to go ...

## Read file [HISTORY.md](../master/HISTORY.md) to follow progress to date.

The start date was Feb 14, 2021. Time needed is 1 month.
The coding challenge was to write a program in assembly language to calculate pi,
on a Raspberry Pi, by "Pi Day" March 14, 2021.
The personal goal was to learn a little about ARM64/arm-v8a assembly language.
The technical goal was to avoid use of any external math libraries.

### Models Tested

- Raspberry Pi 4 Model B Rev 1.2
- Raspberry Pi 3 Model B Plus Rev 1.3
- Raspberry Pi 3 Model B Rev 1.2
- The 64 bit operating system does not load on Pi-2 and earlier.

### Operating System 64-Bit beta version of Raspberry OS

https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/

### What am I using?

- Raspberry Pi 4 Model B Rev 1.2 / Raspberry Pi 3 Model B Plus Rev 1.3
- ARM64 (Beta) Debian GNU/Linux 10 (buster)
- GNU Assembler + GNU linker with arch=armv8-a and cpu=cortex-a72
- Editor: Atom 1.48 with package: Language-arm v2.1.1
- Editor settings: tab size 8 with hard tabs

### Check Model of Raspberry Pi (3B, 3B+, 4B)

```bash
~ $ cat /proc/cpuinfo | grep Model
Model		: Raspberry Pi 4 Model B Rev 1.2
~ $
```

### Check OS is "aarch64" with `lscpu`
```bash
~ $ lscpu

Architecture:        aarch64  <-------------- Required
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
~ $
```


### Installation on Raspberry Pi-3 or Pi-4

```bash
git clone https://github.com/cotarr/calc-pi-arm64-asm.git
cd calc-pi-arm64-asm
cd src

make
```


## Run from within the src folder

```bash
./calc-pi
```

- Expected command prompt is "Op Code:"
- Response (License an other intro not shown here)

```
I/O Initialized
Accuracy: 60 Digits (fraction part)
Variables initialized.
Op Code:
```

# walk through to calculate pi

This will use the following commands:

- `sigfigs 1000` will set accuracy to 1000 digits in base 10
- `c.pi` will calculate pi
- `print f` will print the number in page formated layout

This is step by step.

- Set accuracy to 1000 digits using `sigfigs` command

```
Op Code: sigfigs 1000
```
- Response

```
Accuracy: 1000 Digits (fraction part)
```

- Calculate pi with `c.pi` command

```
Op Code: c.pi
```
- Response

```
Calculating: Square Root 10005  (Elapsed: 0.008 Sec)
Calculating: Chudnovsky infinite series  (Elapsed: 0.018 Sec)

XREG   +3.14159265358979323846264338327950288419716939937510
YREG   +0.0
ZREG   +0.0
TREG   +0.0

  (Elapsed: 0.021 Sec)
```

- Print binary to decimal conversion in formatted text with `print f` command.

```
Op Code: print f
```
- Response

```
+3.
  1415926535 8979323846 2643383279 5028841971 6939937510 5820974944 5923078164 0628620899 8628034825 3421170679
  8214808651 3282306647 0938446095 5058223172 5359408128 4811174502 8410270193 8521105559 6446229489 5493038196
  4428810975 6659334461 2847564823 3786783165 2712019091 4564856692 3460348610 4543266482 1339360726 0249141273
  7245870066 0631558817 4881520920 9628292540 9171536436 7892590360 0113305305 4882046652 1384146951 9415116094
  3305727036 5759591953 0921861173 8193261179 3105118548 0744623799 6274956735 1885752724 8912279381 8301194912
  9833673362 4406566430 8602139494 6395224737 1907021798 6094370277 0539217176 2931767523 8467481846 7669405132
  0005681271 4526356082 7785771342 7577896091 7363717872 1468440901 2249534301 4654958537 1050792279 6892589235
  4201995611 2129021960 8640344181 5981362977 4771309960 5187072113 4999999837 2978049951 0597317328 1609631859
  5024459455 3469083026 4252230825 3344685035 2619311881 7101000313 7838752886 5875332083 8142061717 7669147303
  5982534904 2875546873 1159562863 8823537875 9375195778 1857780532 1712268066 1300192787 6611195909 2164201989
 (3809525720 )

  (Elapsed: 0.046 Sec)
```

## Commands available:

```
+ - * / . c.e c.pi c.pi.ch chs clrstk clrx
cmdlist D.vars D.fill D.ofst enter exit help
hex log logoff mmode prac print q recip
quit rcl rdown rup sf sigfigs sqrt sto
test version xy
```

## Chudnovsky Formula

![CHudnovsky-Formula-Image](https://github.com/cotarr/calc-pi-arm64-asm/blob/main/images/Chudnovskyformula.jpg?raw=true)

## benchmark 2021-03-11 Calculation of pi

```
   Digits    Seconds
    10000      0.763
    20000      2.964
    50000     16.502
   100000     68.762
   200000    282.295
   500000   1694.834
  1000000   7153.571
```

![Calculation-Time-Image](https://github.com/cotarr/calc-pi-arm64-asm/blob/main/images/pi-calc-time.png?raw=true)


### Security Note

This application was intended for I/O limited to local keyboard and console output
within a Linux command line shell. This calculation includes a rather ubiquitous
use of memory pointers that have not been reviewed for safe pointer practices.
Therefore, modification of the program to service a direct internet connection
is not recommended.

System memory used for floating point number variables are defined in
math.s using statements to declare uninitialized blocks of memory
in the BSS section. These are statically allocated when the program is
started as part of the load image. No memory is dynamically allocated.

All input and output is performed using ARM64 `svc` system call statements.
All I/O functions are located in the "io_module.asm" file.
They are used to accept keyboard input, produce console output, capture
program text output to a disk file, and read the system clock.

There are no dependencies on third party libraries.
