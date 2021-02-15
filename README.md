# WORK IN PROGRESS

Today is Feb 14, 2021. The goal is to write ARM64 program
to calculate pi, on a Raspberry Pi, by "Pi Day" March 14.
Since Raspberry Pi OS is only released as 32 bit stable release ARMHF,
I will try this with beta version ARM64

- Raspberry Pi 4 Model B Rev 1.2
- ARM64 (Beta) Debian GNU/Linux 10 (buster)
- https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/
- GNU Assembler + GNU linker with arch=armv8-a and cpu=cortex-a72

How far?  Day 1 = Hello World

```
git clone git@github.com:cotarr/calc-pi-arm64-asm.git
cd calc-pi-arm64-asm
cd src
make
# Hello world only
./calc-pi
```
