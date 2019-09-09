Software for Gigatron ROM
=========================

Important files
===============
```
gigatron-rom
 +--- LICENSE                   2-Clause BSD License
 +--- Makefile                  Marcel's Makefile
 +--- Core/                     Gigatron kernel and build tools
 |     +--- dev.py              Development ROM (type 'make' to build):
 |     |                        Video/audio/io/kernel loops and cold storage
 |     |                        for applications and data ("kernel + ROM disk")
 |     +--- ROMv4.py            Source for release ROM v4 (most recent release)
 |     `--- compilegcl.py       Stand-alone GCL to vCPU compiler (GT1 files)
 +--- interface.json            Formal bindings interface to ROM for programs
 +--- Apps/                     Built-in and example applications (GCL and GT1)
 |     +--- Blinky/Blinky.gcl   Very simple GCL program
 |     `--- HelloWorld/         Program that draws "Hello world" on screen
 +--- BASIC/                    Example BASIC programs
 +--- Utils/
 |     +--- BabelFish/          Generic Arduino sketch for talking with Gigatron
 |     +--- gt1dump.py          Dump or disassemble GT1 files
 |     +--- lcc/                LCC compiler with vCPU backend (NOT YET STABLE)
 |     `--- sendFile.py         Send GT1 or BASIC file from laptop/PC
 +--- Libs/                     C libraries for Gigatron programs
 |     `--- Example.c           Example C program
 +--- Docs/
 |     +--- GCL-language.txt    Gigatron Control Language and vCPU explanation
 |     +--- GT1-files.txt       vCPU object file format and ROM versioning
 |     +--- gtemu.c             Instruction set definition (as executable code)
 |     +--- SYS-functions.txt   Explanation on how SYS extensions work
 |     `--- vCPU-summary.txt    Overview of 16-bit virtual CPU instruction set
 `--- Contrib/                  Contributions outside the kit's ROM and tooling:
       +--- at67/               Emulator/visualizer (SDL2), 8-bit/16-bit
       |                        assembler, debugger, MIDI music, demos (sprites,
       |                        lines, game of life, Tetronis game...)
       +--- Cwiiis/             Gigatris game
       +--- dhkolf/             Fast emulator; Demos (SprPaint, PianoBeep,...)
       +--- flok99/             Simple (and slow) visualizer using SDL2
       +--- gigawalt/           Walter's script
       +--- kervinck/           Ramblings (all work in progress)
       +--- PhilThomas/         Javascript-based Gigatron emulator
       +--- tbraun-de/          Gigatron Mac; Python port of gtemu.c; maze.gt1
       +--- xopr/               NetTerm: Terminal program for SPI interface
       `--- xxxbxxx/            Bricks game; RPi port of BabelFish; frogstroll
```

Files generated by ROMv4.py
===========================
```
ROMv4.asm                       Disassembly, with labels and comments (large!)
ROMv4.rom                       ROM file for 27C1024 (PCB versions)
```

Memory map (RAM)
================
```
              0 1          47 48     127 128 129         (vSP)       255
             +-+-------------+-----------+-+-------------+--------------+
page 0       |0| System vars | User vars |1| User vars <-| Stack/Loader |
             +-+-------------+-----------+-+------+------+--+-----------+
page 1       | Video table                        | vReset  | Channel 1 |
             +------------------------------------+---------+-----------+ ---
page 2       |0                                239 240   249| Channel 2 |  ^
             |                                              +-----------+  |  Also see
page 3       |                                              | Channel 3 |  |  channelMask
             |                                              +-----------+  |
page 4       |            User vCPU code and/or data        | Channel 4 |  v
             |                                              +-----------+ ---
page 5-6     |                                               250     255|
             |                                                          |
             |                                               <- C stack |
             +----------------------------------------------------------+
page 7       | Sound tables                                             |
             +--------------------------------+-------------------------+
page 8-127   |0                            159|160                   255|
             | 120 lines of 160 pixels        |  Extra space for user   |
             | Default video memory           |  code and/or data       |
             =                                =                         =
             |                                |                         |
             +--------------------------------+-------------------------+
page 128-255 | Not used in the 32K system: mirror of page 0-127         |
             +----------------------------------------------------------+
              0                                                      255

[Note: In the next section, names in parentheses refer to *internal*
variables that are subject to change between ROM versions. See for a
more detailed explanation on compatibility the file Docs/GT1-files.txt]

Address   Name          Description
--------- ------------- -----------
0000      zeroConst     Constant value 0 (for arithmetic carry)
0001      memSize       Number of RAM pages detected at hard reset (64kB=0)
0002      (channel)     Sound channel update on current scanline
0003      (sample)      Accumulator for synthesizing next sound sample
0004      (reserved)    Reserved (SPI state? Video? MMU? Keyboard map? ...?)
0005      (vCPUselect)  Entry page of active interpreter (offset fixed to 255)
0006-0008 entropy       Randomness from SRAM boot and input, updated each frame
0009      videoY        Counts up from 0 to 238 in steps of 2 (odd in vBlank)
000a      (frameX)      Starting byte within page for pixel burst
000b      (frameY)      Page of current pixel row (updated by videoA)
000c      (nextVideo)   Jump offset to scan line handler (videoA, B, C...)
000d      (videoModeD)  Handler for every 4th line (pixel burst or vCPU)
000e      frameCount    Continuous video frame counter
000f      serialRaw     New raw serial read
0010      (serialLast)  Previous serial read (used for edge detection)
0011      buttonState   Edge-triggered and resettable input bits
0012      (resetTimer)  After 2 seconds of holding 'Start', do a soft reset
0013      (xout)        Memory cache for XOUT register
0014      xoutMask      The blinkenlights and sound on/off state
0015      (vTicks)      Remaining interpreter ticks (=units of 2 CPU cycles)
0016-0017 vPC           Interpreter program counter, points into RAM
0018-0019 vAC           Interpreter accumulator, 16-bits
001a-001b vLR           Return address, for returning after CALL
001c      vSP           Stack pointer
001d      (vTmp)        Scratch storage location for vCPU
001e      (vReturn)     Return address (L) from vCPU into the loop (H is fixed)
001f      (videoModeB)  ROMv2: Handler for every 2nd line (pixel burst or vCPU)
0020      (videoModeC)  ROMv2: Handler for every 3rd line (pixel burst or vCPU)
0021      romType       ROMv1=$1c ROMv2=$20 ROMv3=$28 ROMv4=$38 DEVROM=$f8
0021      channelMask   Low bits set active channels (x011->4, x001->2, x000->1)
0022-0023 sysFn         Address for SYS function call
0024-002b sysArgs       Arguments for SYS functions
002c      soundTimer    Countdown timer for playing sound
002d      (ledTimer)    Number of frames until next LED change
002e      ledState      Current LED state machine value (branch offset)
002f      ledTempo      Next value for ledTimer after LED state change
0030-007f userVars      Program variables
0080      oneConst      Constant value 1 (for arithmetic carry)
0081-.... userVars2     More space for program variables
....-00ff <stack>       Call and value stack for vCPU (also used by ROM loader)
0100-01ef videoTable    Video indirection table (Y0,dX0,Y1,dX1,Y2,...,dX119)
01f0-01f9 vReset        vCPU routine to load and start Reset sequence
01fa      wavA[1]       Sound channel 1: Waveform modulation with `adda'
01fb      wavX[1]       ...............: Waveform modulation with `xora'
01fc      keyL[1]       ...............: Frequency low 7 bits (bit7 == 0)
01fd      keyH[1]       ...............: Frequency high 8 bits
01fe      oscL[1]       ...............: Phase low 7 bits
01ff      oscH[1]       ...............: Phase high 8 bits
0200-02f9 userCode      vCPU code/data (default start of user code)
02fa      wavA[2]       Sound channel 2: Waveform modulation with `adda'
02fb      wavX[2]       ...............: Waveform modulation with `xora'
02fc      keyL[2]       ...............: Frequency low 7 bits (bit7 == 0)
02fd      keyH[2]       ...............: Frequency high 8 bits
02fe      oscL[2]       ...............: Phase low 7 bits
02ff      oscH[2]       ...............: Phase high 8 bits
0300-03f9 -             vCPU code/data
03fa      wavA[3]       Sound channel 3: Waveform modulation with `adda'
03fb      wavX[3]       ...............: Waveform modulation with `xora'
03fc      keyL[3]       ...............: Frequency low 7 bits (bit7 == 0)
03fd      keyH[3]       ...............: Frequency high 8 bits
03fe      oscL[3]       ...............: Phase low 7 bits
03ff      oscH[3]       ...............: Phase high 8 bits
0400-04f9 -             vCPU code/data
04fa      wavA[4]       Sound channel 4: Waveform modulation with `adda'
04fb      wavX[4]       ...............: Waveform modulation with `xora'
04fc      keyL[4]       ...............: Frequency low 7 bits (bit7 == 0)
04fd      keyH[4]       ...............: Frequency high 8 bits
04fe      oscL[4]       ...............: Phase low 7 bits
04ff      oscH[4]       ...............: Phase high 8 bits
0500-05ff -             vCPU code/data
0600-06ff -             vCPU code/data
0700-07ff soundTable    Interlaced waveforms (metal, triangle, pulse, sawtooth)
0800-7fff screenMemory  Default pages for screen memory
0800-089f -             Pixel line 0
08a0-08ff -             vCPU code/data
.........
7f00-7f9f -             Pixel line 119
7fa0-7fff -             vCPU code/data
--------- ------------- -----------
```

Memory map (ROM)
================
```
             +----------------------------------------------------------+  ---
$0000        | Boot and reset sequences                                 |   ^
             +----------------------------------------------------------+   |
$0100        | Video and audio loop (vertical blank lines)              |   |
             |                                                          |   |
$0200        | Video and audio loop (visible lines)                     |   |
             +----------------------------------------------------------+   |
$0300        | vCPU interpreter loop (primary page)                     |   |
             |                                                          |   |
$0400        | vCPU extended instructions (and some SYS functions)      |   |
             +----------------------------------------------------------+   |
$0500        | Shift tables                                             |   |
             |                                                          |   |  Core system
$0600        | SYS functions (LSRW and others)                          |   |  Kernel and drivers
             +----------------------------------------------------------+   |
$0700        | Font table (ASCII 32..81)                                |   |
             |                                                          |   |
$0800        | Font table (ASCII 82..126 and symbols 127-131)           |   |
             |                                                          |   |
$0900        | Notes table (C-0..A#7)                                   |   |
             |                                                          |   |
$0a00        | Inversion table                                          |   |
             +----------------------------------------------------------+   |
$0b00        | SYS functions (SendSerial, Sprites, SPI, ...)            |   |
             |                                                          |   |
$0d82-$11ff  | v6502 secondary interpreter (planned)                    |   v
             +==========================================================+  ---
             |                                                          |   ^
             | ROM tables: Embedded high-resolution images (packed)     |   |
             |                                                          |   |  Applications /
$1200-$ffff  | Include files: application-specific SYS functions        |   |  cold storage
             |                                                          |   |
             | ROM files: Embedded vCPU/v6502 applications (serialized) |   |
             |                                                          |   v
             +----------------------------------------------------------+  ---
              0                                                      255
```

SYS functions (ROM)
===================

```
Available since ROM v1:

00ad    SYS_Exec_88             Load serialized vCPU code from ROM and execute
04a7    SYS_Random_34           Get random number and update entropy
0600    SYS_LSRW1_48            Shift right 1 bit
0619    SYS_LSRW2_52            Shift right 2 bits
0636    SYS_LSRW3_52            Shift right 3 bits
0652    SYS_LSRW4_50            Shift right 4 bits
066d    SYS_LSRW5_50            Shift right 5 bits
0687    SYS_LSRW6_48            Shift right 6 bits
04b9    SYS_LSRW7_30            Shift right 7 bits
04c6    SYS_LSRW8_24            Shift right 8 bits
06a0    SYS_LSLW4_46            Shift left 4 bits
04cd    SYS_LSLW8_24            Shift left 8 bits
04e1    SYS_VDrawBits_134       Draw 8 vertical pixels
06c0    SYS_Unpack_56           Unpack 3 bytes into 4 pixels
04d4    SYS_Draw4_30            Copy 4 pixels to screen memory
00f4    SYS_Out_22              Write byte to hardware OUT register
00f9    SYS_In_24               Read byte from hardware IN register

Added in ROM v2:

0b00    SYS_SetMode_v2_80       Set video mode 0..3
0b03    SYS_SetMemory_v2_54     Set 1..256 bytes of memory to value

Added in ROM v3:

0b06    SYS_SendSerial1_v3_80   Send data out over game controller port
0c00    SYS_Sprite6_v3_64       Draw sprite of 6 pixels wide and N pixels high
0c40    SYS_Sprite6x_v3_64      Draw sprite mirrored in X direction
0c80    SYS_Sprite6y_v3_64      Draw sprite upside down
0cc0    SYS_Sprite6xy_v3_64     Draw sprite mirrored and upside down

Added in ROM v4:

0b09    SYS_ExpanderControl_v4_40       Set register in I/O and RAM expander
0b0f    SYS_ResetWaveforms_v4_50        Setup sound tables in page 7
0b12    SYS_ShuffleNoise_v4_46          Shuffle noise table in page 7
0b15    SYS_SpiExchangeBytes_v4_134     Send and receive bytes

Under development:

0b0c    SYS_Run6502_DEVROM_80   Execute MOS 6502 code until BRK

```
