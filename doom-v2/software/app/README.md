# Import this application into RiscFree

Import the folder C:/FPGA/doom-v2/software/app (not an individual C file).
Use File > Import Nios V CMake Project, choose this folder, then Finish.
Right-click the imported application and select Build Project.

The application compiles the existing patched DOOM engine and board port with
-O2, debug symbols, the embedded Freedoom IWAD, and live FPS overlay enabled.
It does not program the board or modify the RiscFree workspace automatically.

The build produces doom.elf inside the build directory selected by RiscFree.
Use that ELF in Main > C/C++ Application and in Startup image/symbol settings.
Do not select the old demo-fps ELF when intending to test a new IDE build.

Prerequisites already available in this repository/workstation:
- C:/altera_lite/25.1std (Quartus/RiscFree compiler and CMake tools)
- C:/Python314/python.exe and Git available on PATH
- ../../vendor/doomgeneric pinned dependency and ../../assets/freedoom-0.13.0/freedoom1.wad
- ../../build/bsp/system.h, linker.x and make_build/libhal2_bsp.a

This app links the existing verified BSP library; it does not automatically build
a separately imported BSP project. If hardware/BSP changes, regenerate and build
the repository BSP before rebuilding this app. Importing the BSP separately is
optional for browsing its sources.

CMake cache settings: QUARTUS_ROOT, DOOM_PYTHON, DOOM_WAD, DOOM_FPS_OVERLAY (ON).
If configuring the build generator manually, use Unix Makefiles with:
C:/altera_lite/25.1std/riscfree/build_tools/bin/make.exe

prepare.py reuses tools/build_software.py engine preparation and WAD validation.
Generated engine files live in ../../build/engine; WAD assembly/data and compiler
commands live in the chosen CMake build directory. Edit maintained sources under
../../software or patch-generation code under ../../tools; changes made directly
to generated engine files are overwritten on the next configuration.

Do not run multiple CLI/CMake configurations simultaneously: engine preparation
uses the repository's shared build/engine directory.

Validation: configured and compiled using the installed RiscFree CMake and RV32
GCC tools. GUI import is left to the user. No board download is part of setup.
