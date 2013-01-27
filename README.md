# MDOnAChip
MDOnAChip is an attempt at faithfully recreating an entire Mega Drive in a single Cyclone II FPGA, using the hardware available on the DE-1 board for I/O.

Once complete, this project will have a fully-functional VDP, including all bugs exhibited on real hardware, support for up to 8 MB of ROM, save memories, loading of ROMs from an SD card, and YM2612 and SM76489 sound outputted through the on-board audio codec.

## Why would you waste your time on this?
The Mega Drive was the first system I ever played a video game on, even though I missed the 16-bit generation of consoles by about 10 years. It's also the system that taught me the do's and dont's of embedded hardware design, and it uses my beloved 68000 CPU. Last of all, it's a cool project to do when getting started with FPGAs. =P

## Current Progress
As of right now, there is a fully functional 68000 CPU core, based on the TG68 core, as well as a VGA output core. The FPGA has a 1Kx16 ROM to hold test programs, and many of the basic components of the MD are already sketched out.
