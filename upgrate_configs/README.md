# Version 1.0.1

This manual only explains the actions I have taken. To implement these changes, please refer to Guide.txt.

I have made numerous changes to my printer's settings in this version. This document will explain each modification in detail.

## printer.cfg

### For the new configuration file:
1. Added KAMP configuration to my printer.
2. `Macro.cfg` includes all macros written by Infimech's official team.

### Changes included in printer.cfg:
1. Removed macros written by Infimech's official team.
2. Included `Macro.cfg`.
3. Included `Line_Purge.cfg`, `KAMP_Settings.cfg`, and `Adaptive_Meshing.cfg`.

### Changes to the stepper section in printer.cfg:
1. In `stepper_x` and `stepper_y`, changed `homing_speed` from `40` to `60`.
2. Changed `pressure_advance` from `0.058` to `0.02` (best to test and adjust this yourself).

### Changes to the TMC2209 section in printer.cfg:
#### For all steppers:
1. Added annotation for `hold_current`.

#### In `stepper_x`, `stepper_y`, and `extruder`:
1. Changed `interpolate` from `True` to `False`.

### Changes to the smart_effector section in printer.cfg:
1. Changed `samples` from `3` to `2`.

### Changes to the Bed leveling section in printer.cfg:
#### In `[bed_mesh]`:
1. Changed `mesh_pps` from `6, 6` to `5, 5`.

### Added `[screws_tilt_adjust]`:
1. I added a spring to my printer for leveling. If you don't want to add a spring, annotate this section.

### Changes to the idle_timeout section in printer.cfg:
1. Annotate this section. The printer will use the default `idle_timeout` setting.

### Added new function for using the M118 gcode command:
[respond]
default_prefix: System State:


## marco.cfg

### Rewrite `[homing_override]` macro:
#### In # Home Z:
1. Replaced `Z_DOUDONG` with `Z_DOUDONG1`.

#### In # Home X Y Z:
1. Rewrote XY homing.
2. Replaced `Z_DOUDONG` with `Z_DOUDONG1`.
3. Fix some homing bug.(Version 1.0.1)

### Rewrite `[PRINT_START]` macro:
1. Added `M118` gcode command to check printer state.
2. Rewrote `BED_MESH_CALIBRATE` to `BED_MESH_CALIBRATE ADAPTIVE=1` (Adaptive=1 means the printer only performs bed_mesh on the printing object area).
3. Added `Line_Purge` function to clean the nozzle before printing the first layer.
4. Removed the purge line written by Infimech's official team.
5. Optimized the heating sequence: the hotbed now heats first and reaches the target temperature before the hotend begins heating. (Version 1.0.1)

### In `[clean_nozzle_position]` macro:
1. Replaced `Z_DOUDONG` with `Z_DOUDONG1`.
2. Changed `M140 S40` to `S60`.
3. If hotbed temperature < 65°C than preheat hotbed else maintain hotbed temperature.(Version 1.0.1)
4. Speed up nozzle wipe process.(Version 1.0.1)

### Rewrite `[Z_DOUDONG1]` macro:
The vibration of the z_stepper will trigger the piezoelectric element. To avoid this, we need to `SET_PIN PIN=test_Z VALUE=1` and shake the printer bed to record a background value. However, it is not necessary to shake 110 times. In my tests, 8 times was sufficient.
