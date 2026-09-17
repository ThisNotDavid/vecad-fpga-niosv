# Third-party source and data

- **doomgeneric**: https://github.com/ozkl/doomgeneric,
  commit `dcb7a8dbc7a16ce3dda29382ac9aae9d77d21284`.
  GPL-2.0-or-later; retain the upstream license and copyright notices. The port's
  engine-linked software is supplied under the same GPL-2.0-or-later terms.
- **Freedoom 0.13.0**: https://github.com/freedoom/freedoom/releases/tag/v0.13.0.
  Downloaded release archive and extracted license/readme remain under `assets`.
  Retain its COPYING file when redistributing the IWAD. Freedoom is replacement
  game data, not the original commercial DOOM artwork or levels.
- **Altera IP and HAL**: generated from the user's Quartus Prime Lite 25.1
  installation. Generated files retain vendor notices. Do not treat vendor IP
  as GPL source or redistribute it without checking the applicable terms.
- **Terasic DE2-115 System CD**: board pin assignments are read from the local
  golden-top project. No unrelated demonstrations are modified.

Original commercial IWADs are not included. A different compatible IWAD can be
provided with `build_software.py niosv --wad PATH`.
