# Swiftly Order Squad - Immersive Addon

Your followers don't teleport. They travel.

An immersion addon for [Swiftly Order Squad](https://www.nexusmods.com/skyrimspecialedition/mods/63259). Gathering
your party respects distance, injuries, danger and time: nearby companions rejoin with a quick fade, distant ones
take as long as the trip plausibly would, and wounded or dead companions stay behind.

**Download:** [Nexus Mods, mod 193237](https://www.nexusmods.com/skyrimspecialedition/mods/193237). This repo is the
source; install the Nexus download with your mod manager.

## Features

- Distance-based Gather Party: the time skip follows your furthest follower who will actually come.
- Same town, dungeon or building: fade only, no time skip. Outdoors: real distance (default 16,000 units per hour).
  Same hold only: 4 hours. No shared location: 8 hours. Unknown location: 3 hours. Capped at 24 hours.
- Works across cell boundaries, interiors and the city worldspaces.
- Followers in bleedout (or downed by [Death Timer - Immersive Bleedout](https://www.nexusmods.com/skyrimspecialedition/mods/193403))
  don't rejoin; if the whole party is down, gathering is refused before any time passes. Dead followers are ignored.
- No gathering in combat. Wait, Follow and Inventory only reach companions within earshot.
- Fix: the menu doesn't open when you have no followers.
- Every message and travel-time value is in `SOS Immersive Settings.json`; deleting a line falls back to the defaults.

## Requirements

- Swiftly Order Squad, SKSE64, PapyrusUtil SE, powerofthree's Papyrus Extender.

Let it overwrite Swiftly Order Squad. Remove the first Immersive Patch if you use it: this replaces it.

## What's here

| Path | What |
|---|---|
| `mod/Source/Scripts/qfcAliasScript.psc` | the changed script (source) |
| `mod/Scripts/qfcAliasScript.pex` | the compiled script |
| `mod/SOS Immersive Settings.json` | settings and texts (keep `gatherDebug` at 0 in releases) |

The Nexus download also carries the Immersive Patch's unchanged `Quick Follower Commands.esp` and its translation file;
those aren't this mod's own work and aren't in this repo. Each release is a tag (`v1`, `v1.1`).

## Credits

- OsmosisWrench for Swiftly Order Squad.
- HeZijie for Swiftly Order Squad Immersive Patch, whose code this addon started from.
