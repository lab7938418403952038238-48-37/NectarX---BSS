# NectarX implementation plan

This document separates the current UI scaffold from features that are not yet safe to advertise as working.

## Current milestone

- GUI pages for Dashboard, Farming, Patterns, Conversion, Quests, Planters, Screen Reader, Settings, and Logs.
- Saved default repetition count, movement scale, window title, image variation, movement method, selected field, and gather duration.
- Screen Reader can discover PNG/BMP templates in both the project root and `NectarX images/`.
- Roblox window detection and client-area image search are present.
- Start remains guarded; there is no supported execution engine yet.

## Stage 1 — Runtime safety and diagnostics

1. Run the GUI under AutoHotkey v2 on Windows and fix any runtime errors.
2. Confirm the Roblox process/window selection and client rectangle.
3. Verify Screen Reader matching at the user's display resolution and Roblox UI scale.
4. Keep Start guarded until a validated runner can guarantee key release on normal completion, Stop, errors, and window loss.
5. Add a visible execution state and last-error information to the Dashboard.

## Stage 2 — A small supported movement engine

The existing pattern and route snippets call helpers such as `Walk`, `nm_Walk`, `nm_gotoramp`, and `nm_gotocannon`, and expect key variables such as `TCLRKey`, `TCFBKey`, `AFCLRKey`, `AFCFBKey`, `FwdKey`, `BackKey`, `LeftKey`, `RightKey`, and `RotRight`. Those helper contracts are not defined by the current main script.

Before importing legacy scripts into a runner:

- Define and document the exact unit expected by each movement helper.
- Map the configured movement method to explicit walking or cannon steps, only when a route supports that step.
- Validate supported script commands and reject unknown functions instead of blindly executing arbitrary `.ahk` files.
- Implement cancellation checks between movement segments and release every held key on exit.
- Test one short, low-risk pattern before enabling field routes.
- Test camera/heading assumptions and route recovery in the user's actual game setup.

Do not guess movement duration units from the legacy snippets; a mismatch could cause over-travel or stuck movement.

## Stage 3 — Gathering cycle

1. Choose field, pattern, movement mode, and gather duration.
2. Verify the Roblox client is available and the expected field/starting state is visible.
3. Travel using a validated field route.
4. Run a validated pattern for the selected duration, checking cancellation between segments.
5. Add full-backpack detection only after the pollen meter template is confirmed.
6. Return to hive and confirm conversion; retry or stop safely when a state is not recognized.

A duration timer alone is not evidence that nectar was gathered successfully. The UI must distinguish elapsed time from confirmed game state.

## Stage 4 — Additional modules

- **Conversion:** full-backpack recognition, hive travel, conversion confirmation, return to field.
- **Quests:** explicit supported quest UI templates, progress checks, interaction steps, and completion confirmation.
- **Planters:** planter type, placed field, growth/ready state, harvest confirmation, and safe route.
- **Activities:** each mob, dispenser, boss, or challenge gets its own state machine and verified route.

## Screen-template rules

- Capture crops from the user's real Roblox client at the intended resolution and UI scale.
- Prefer stable UI elements over animated world objects.
- Use descriptive filenames and one template per clearly defined state.
- Test both positive and negative cases; a false positive must not trigger movement or interaction.
- Re-capture templates after meaningful UI, scale, or game updates.

## Acceptance checklist before public release

- [ ] GUI starts cleanly with AutoHotkey v2.
- [ ] Settings persist across restart.
- [ ] Screen Reader can find supplied templates and report misses clearly.
- [ ] Stop cancels execution promptly and releases all movement keys.
- [ ] Window loss and script errors stop safely.
- [ ] Walking travel works for a tested route.
- [ ] Cannon travel works for a tested route.
- [ ] One field pattern gathers for a configured duration.
- [ ] Backpack detection and honey conversion are verified end-to-end.
- [ ] README and changelog describe only tested capabilities.
