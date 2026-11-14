DEAD FREQUENCY
A game developed by YASH AIL
Build {VERSION} (pre-release) for Windows 10/11, 64-bit

A radio that hears the past. Something in the signal that hears you.

------------------------------------------------------------------------
RUNNING THE GAME
------------------------------------------------------------------------
Unzip the whole folder anywhere and double-click DeadFrequency.exe.
Nothing is installed and nothing is written outside your saves folder.

Requirements: Windows 10 or 11 (64-bit), a graphics card and driver
with OpenGL 3.3 support, about 200 MB of disk space. Headphones are
strongly recommended: the creature hunts by sound, and so do you.

This build is not code-signed yet. If Windows SmartScreen shows
"Windows protected your PC", choose "More info" -> "Run anyway" only if
you received this file directly from the developer.

PHOTOSENSITIVITY WARNING: the game contains flickering lights and
flashing images. Settings -> "Reduce flashing effects" tones them down.

------------------------------------------------------------------------
CONTROLS
------------------------------------------------------------------------
                        Keyboard / mouse          Gamepad
Move / look             WASD / mouse              left / right stick
Sprint                  Shift                     L3
Crouch                  Ctrl or C                 B
Lean                    Q / E                     LB / RB
Interact                F or left click           A
Flashlight              T or middle click         Y
Radio on / off          R or right click          X
Tune the radio          mouse wheel or <- ->      D-pad left / right
Throw a bottle          G                         D-pad down
Use a medkit            H                         D-pad up
Journal                 Tab                       Back
Pause                   Esc                       Start
Skip a cinematic        hold Space / Enter        hold A

The radio: 89.1 MHz hears the past, 94.6 hears movement, 101.3 hears
what has not happened yet. Point it at a sound to hear it clearly.
Some frequencies are not on the dial's markings.

------------------------------------------------------------------------
SETTINGS
------------------------------------------------------------------------
Graphics preset (Low / Medium / High / Ultra), window resolution,
fullscreen, V-Sync, brightness, field of view, look sensitivity,
invert Y, head bob, toggle crouch, master / music / effects volume,
subtitles and subtitle size, reduce flashing effects.
If the game runs slowly, set Graphics preset to Low.

------------------------------------------------------------------------
SAVES
------------------------------------------------------------------------
The game saves automatically at checkpoints (the radio consoles).
Saves, settings and achievements are in:
    %APPDATA%\Godot\app_userdata\DEAD FREQUENCY\
save.json is your game (save.json.bak is the previous checkpoint, used
automatically if save.json is damaged); profile.json holds settings,
achievements and what the game remembers between playthroughs.
playtest.json is a local log of play time and deaths per chapter; it
never leaves your PC unless you send it to us with your feedback.
Delete the folder to reset everything.

------------------------------------------------------------------------
IF SOMETHING GOES WRONG
------------------------------------------------------------------------
* "Your video card driver does not support any of the supported OpenGL
  versions": update your graphics driver from the GPU maker's website
  (NVIDIA, AMD or Intel), not through Windows Update.
* Black screen, crash or stutter: update the graphics driver, then try
  Graphics preset Low, or delete the saves folder to reset settings.
* Built-in self-check: open a Command Prompt in this folder and run
      DeadFrequency.exe --smoketest
  It plays a short automated session (about a minute; it closes by
  itself), then writes smoketest.log and five screenshots to the saves
  folder above. Please attach smoketest.log to any bug report.

------------------------------------------------------------------------
ABOUT THIS BUILD
------------------------------------------------------------------------
Pre-release build. Known limitations:
* Dialogue is fully subtitled; spoken lines use a processed radio-voice
  placeholder until recorded voice acting is added.
* The Windows build has been run under Wine (Linux) by the developer;
  testing on a range of real Windows PCs is in progress.

DEAD FREQUENCY collects no personal data and makes no network
connections (see PRIVACY.txt).

Made with the Godot Engine (MIT licence). Portions of this software are
copyright (c) 2022 The FreeType Project (www.freetype.org). All rights
reserved. Fonts: Liberation (SIL Open Font License 1.1). Surface
textures: ambientCG (CC0). Full notices: THIRD_PARTY_NOTICES.txt and
the licenses folder.
