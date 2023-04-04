# PTHP, C64 basic extension

## PRINT TECHNIK HELP PLUS

This is a basic extension original written by the company Print-Technik for the Commodore PET in 1981, and later converted to VIC20, and C64/C128.
Information about this company you can find at: https://www.c64-wiki.de/wiki/Print-Technik

<br />The latest known Version is a module for the C128/C64, and its called "Help PC-128 Plus C-64".
<br />
<br />A special thanks goes to Johann Klasek, who has support me to get the C64/C128 version, and for his first examination on it.
<br />You can found more information about the C64/C128 Modul version on Johann Klasek's webpage: https://klasek.at/c64/helpplus/ 
<br />
<br />So far, there are 4 different version for the C64 known by me. 
<br />
### V1: 
This should be the initial version for the C64, the screen message shows "*** HELP C-64 PLUS ***".
<br />So far i can identify one error at address $8182, there is a "BCS $810C", and should be "BCS $810E"

### V2:
The screen message is the same with version 1, the error in $8182 is corrected, a new command is added, and some other changes are applied. 
<br />Added command #B = "RENEW". 
<br />There is a change in the directory command, it checks now additional for device No.4. 
<br />Additional one, in my opinion not necessary, JSR command was changed at address $89E3.

### V3:
The screen message is changed to "*PRINT-TECHNIK-HELP-PLUS*", additonal compare to version 2 a change in the dump command is done.
<br />A space is added to the output.
<br />Before the output was: "A =12".
<br />now the output is like: "A = 12".
<br />There are also other changes in other places, on which i did not do any further investigation.

The verion 1, 2 and 3 can be easy used as a modul, by programming it on an EPROM, and connect it to the C64

### V4:
This is as far as i know the last version.
<br />This version has a new hardware design for the modul. It will also mirror a part of the modul to address $DE00.
<br />At this location the modul has some switching commands, which allows to switch off the modul, and switch between RAM and ROM by changing the GAME and/or EXROM lines. Btw, this is also a nice copy protection.
<br />The code is rearranged, and optimezed in several places. So far i have not seen some functional changes in the different program parts, except the jumpings to the addresses in $DExx, for switching between RAM and ROM.

