# WORK IN PROGRESS

## No Pi calculation available at this time

Today is Feb 14, 2021. The goal is to write ARM64 program
to calculate pi, on a Raspberry Pi, by "Pi Day" March 14.
Since Raspberry Pi OS is only released as 32 bit stable release ARMHF,
I will try this with beta version ARM64

- Raspberry Pi 4 Model B Rev 1.2
- ARM64 (Beta) Debian GNU/Linux 10 (buster)
- https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/
- GNU Assembler + GNU linker with arch=armv8-a and cpu=cortex-a72


```
git clone git@github.com:cotarr/calc-pi-arm64-asm.git
cd calc-pi-arm64-asm
cd src
make
# Simple command parser only (no calculation yet)
./calc-pi
```

### Commits of interest

See HISTORY.md

```
Hello world         d5188777cda71522eb2428c5fdba4ab9a0a63314
Keyboard Input      65da3a3638f6e00af1871582e16e8118a5e28419
Print words in Hex  5ff998d0ff4f71e28e12d000c9aa12471d1471ab
Command parser      
```
