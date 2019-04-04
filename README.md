# Video Game Reader [*outdated*]

Video Game Reader is a script (desktop automation) providing a basic translation/game guide system, integrated into the emulation. It focuses on ease of use when involving such ressources while playing video games.


### Key features

* The software is suitable for the emulation of most part of video game consoles from the fifth/sixth-generation.
  - Compatible with pSX, PCSX2 and Dolphin.
* Embedded visual keyboard with predictive text input feature to quickly search for words.
  - Both normal text strings and regular expressions (dot-star pattern) are supported.
* As with the visual keyboard, the main features are accessible by using a PC game controller.
  - Customisable keyboard/game controller shortcuts.
* Embedded game guide PDF viewer (this will, however, necessitate the installation of [Foxit Reader](https://www.foxitsoftware.com/pdf-reader/)).

Video Game Reader does not in any way facilitate the download of illegal ROM images or warez of any kind.


### Download

The software is available in source code. It can be download from [here](https://github.com/A-AhkUser/VideoGameReader/releases).

### Initial Setup

Video Game Reader is a Windows-only software.

##### Run VGR in compiled form (executable format)
- Double-click on `Video Game Reader.exe` in the main directory.
##### Run VGR from source code (debug mode enabled)
- Download and install AutoHotkey 32-bit Unicode from [Autohotkey](http://autohotkey.com/download/).
- Double-click on `Video Game Reader.ahk` in the main directory.
#####

You should in all likelihood see the Video Game Reader icon on the tray menu (bottom-right part of the screen by default).

#### Command-line support

You can specify certain options when launching VGR from the command-line, in accordance with the following syntax:

```
Video Game Reader.exe debugMode=1 game="Metal Gear Solid" cd=2
Video Game Reader.exe game=FFX
```
```
PathToAutoHotkeyU32Exe Video Game Reader.ahk game="Metal Gear Solid" cd=2 debugMode=0
PathToAutoHotkeyU32Exe Video Game Reader.ahk game=FFX
```

> notes:</br>
> * `game` is not case sensitive but must be enclosed in double quotes if it contains spaces.
> * `debugMode` defaults to `1` (true) when running VGR from the source.
> * `cd` defaults to `1` when unspecified.
> * `\settings.json` will be loaded to determine the common settings.
