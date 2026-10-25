# NectarX---BSS

NectarX is a Windows AutoHotkey project for Bee Swarm Simulator.

## Current project layout

- `NectarX.ahk` — main GUI scaffold (AutoHotkey v2).
- `NectarX paths/` — movement/path scripts.
- `NectarX patterns/` — pattern snippets used by the movement system.
- `NectarX.ini` — generated locally when settings are saved.
- `NectarX.log` — generated locally for status/log messages.

## Running the GUI

1. Install **AutoHotkey v2** on Windows.
2. Download or clone this repository.
3. Run `NectarX.ahk`.
4. Choose a pattern and configure repetitions and movement scale.
5. Save settings when needed.

## Important: current development status

The GUI is a scaffold and the Start button is intentionally guarded. The uploaded pattern files are code fragments, not standalone macros: they refer to shared functions such as `Walk()` and variables such as `reps`, `size`, and movement-key bindings. The shared runner/controller still needs to be implemented and tested before pattern execution can be enabled.

Image recognition, Roblox-window checks, reliable stop handling, and any additional macro modules are also future integration work. Do not assume the macro is ready for unattended use.

## Contributing

Keep path scripts in `NectarX paths/` and pattern snippets in `NectarX patterns/`. The GUI discovers `.ahk` files in the pattern folder automatically.
