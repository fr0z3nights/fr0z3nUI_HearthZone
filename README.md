# fr0z3nUI HearthZone

Shows your hearth bind location and current zone, with a small UI and optional macro helper.

## Install
1. Copy the folder `fr0z3nUI_HearthZone` into:
	- `World of Warcraft/_retail_/Interface/AddOns/`
2. Launch WoW and enable the addon.

## Slash Commands
- `/fhz` — toggle window
- `/fhz macro` — create/update a macro named `HearthZone` (uses selected toy if set)
- `/fhz help` or `/fhz ?` — show help

## Useful /run snippets
- `/run fHZ:GetZone()`
- `/run print(fHZ:GetHomeText())`

## SavedVariables
- Character: `fr0z3nUI_HearthZoneCharDB`

## Notes
- Macro updates are skipped in combat (as required by the WoW UI environment).
