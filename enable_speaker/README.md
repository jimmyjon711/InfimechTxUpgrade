# Enabling Infimech-TX Piezo Buzzer
## Overview
The Infimech-TX has a Piezo Buzzer integrated on the MKS SKIPR MINI mainboard, but for some reason it hasn't been configured, and in several photo examples that I have seen, the sticker to keep it free of contaminents is still installed as shown below:

![Photo of Mainboard with Speaker Circled](https://github.com/jimmyjon711/InfimechTxUpgrade/blob/main/pics/speakerlocation.png)

> If you want a loud beep, I do recommend removing the sticker covering the buzzer, but removal of the sticker is not necessary.

## Installation
1. Download the `beeper.cfg` file from this repository and upload it to your printer's configuration files directory using your normal means.
2. Open your printer.cfg file and add the following line:

```
[include beeper.cfg]
```
3. Save and restart klipper to apply

## Removal
1. Simply remove the include directive that was added to your printer.cfg file, save and restart to revert the changes.

## How to make it buzzzzzzz??
The beeper.cfg file includes 3 components:
- The configuration of the beeper PIN for klipper.
- A gcode_macro for the M300 which is the standard command used to beep.
- A set of gcode_macros to turn a continuous buzzer on and off (BUZZ_ON/BUZZ_OFF) 

The M300 Macro has 2 parameters:
- `S` = The tone "frequency"
- `P` = The tone duration in milliseconds

> Please take the "frequency" parameter with a grain of salt.  This is a squeeky piezo buzzer, so acoustic accuracy is not a thing here.  Getting alerted when a print is finished or when filament runs out is!

### END_PRINT Macro
I added a little sequence of beeps to my END_PRINT macro to alert me when the job is done by using the M300 Macro:
```gcode
M300 S146 P20
M300 S0 P0
M300 S369 P20
M300 S0 P0
M300 S659 P20
M300 S0 P47
M300 S146 P20
M300 S0 P0
M300 S369 P20
M300 S0 P0
M300 S659 P20
M300 S0 P189
M300 S146 P20
M300 S0 P0
M300 S369 P20
M300 S0 P0
M300 S659 P20
M300 S0 P190
M300 S146 P20
M300 S0 P0
M300 S369 P20
M300 S0 P0
M300 S523 P20
M300 S0 P47
```

### Filament Switch Macro
You can add the following to your filament_switch_sensor stanza in the printer.cfg which will turn on your buzzer and leave it on for a constant "beeeeeeeeeep".  This is useful because the command turns on the beep, and leaves it on until you handle the situation and manually turn it off.  The M300 macro will only work for a brief duration.

#### Edited Printer.cfg fialment_switch_sensor stanza:
```gcode
[filament_switch_sensor fila_sensor]
pause_on_runout: True
runout_gcode:               
    PAUSE
    G4 P500           
    G91
    M118 Unloading filament...
    G0 E145 F400         ;Purge
    G0 E-70 F3000
    G0 E30 F1000
    M106 S255
    M104 S135
    G4 P50000
    G0 E-75 F3000
    M118 Filament unloaded!
    M106 S0
    M104 S190
    BUZZ_ON
event_delay: 3.0
pause_delay: 0.5
switch_pin: PA14
```
And to turn it off, enter "BUZZ_OFF" into the command window.