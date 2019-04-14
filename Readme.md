This script simply removes all but specified cells' files on server startup, if enough time has passed since they were last visited. This allows creatures to spawn in a way most similar to single player OpenMW.

`killReset.lua` is a plugin for this script, that also decreases the killcounts for any creatures or NPCs killed in the cell. Add `require("custom.CellReset.killCount")` after `CellReset = require("custom.CellReset.main")` in your `customScripts.lua` to enable it.

Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)!

You can find the configuration file in `server/data/custom/__config_CellReset.json`.
* `excludedCells` is a list of cells you don't want to be reset at all. Keep in mind that the names are case sensitive. Can also add to this list by using `/cellreset` chat command
* `resetTime` is the amount of time that will have to pass until a cell is reset. Units are game hours or real time minutes (assuming `timeRate` is at default 60), depending on the `useGameTime` setting.
* `timeRate` can be used to cout real time in game hours. Should be equal to your timescale.
* `useGameTime` switches between game time and real time for cell reset purposes.
* `command`
    * `staffRank` required to use the `/cellreset` command
    * `rankError`, `excludeMessage` and `includeMessage` allow to change messages shown by the `/cellreset` command
* `logCellTime` whether the script should log time passed for every cell on server startup. `false` by default.

There are also custom events provided for other scripts to use:
* `CellReset_OnReset(cellDescription)` called when a cell is being reset.
* `CellReset_OnResetFinished(cellDescriptions)` called after this script has finished processing cells, with a list of their `cellDescription`s as an argument. Doesn't have a validator. If no cells were reset, the list will be empty.