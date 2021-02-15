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

- Wrote Hello World, first commit:
