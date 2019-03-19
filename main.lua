local CellReset = {}

CellReset.scriptName = "CellReset"

CellReset.defaultConfig = {
    excludedCells = {},
    resetTime = 120,
    timeRate = 60,
	useGameTime = true
}

CellReset.config = DataManager.loadConfiguration(CellReset.scriptName, CellReset.defaultConfig)

CellReset.excluded = {}

CellReset.defaultData = {
    excludedCells = {},
    cells = {}
}

CellReset.cellDir = tes3mp.GetModDir() .. "/cell/"

function CellReset.loadData()
    CellReset.data = DataManager.loadData(CellReset.scriptName, CellReset.defaultData)

    for _, cellDescription in pairs(CellReset.defaultConfig.excludedCells) do
        CellReset.exclude(cellDescription)
    end
end

function CellReset.saveData()
    DataManager.saveData(CellReset.scriptName, CellReset.data)
end


function CellReset.getGameTime()
    return WorldInstance.data.time.daysPassed*24 + WorldInstance.data.time.hour
end


function CellReset.isExcluded(cellDescription)
    return CellReset.data.excludedCells[cellDescription] ~= nil
end

function CellReset.exclude(cellDescription)
    CellReset.data.excludedCells[cellDescription] = true
end


function CellReset.updateCell(cellDescription)
    if CellReset.data.cells[cellDescription] == nil then
        CellReset.data.cells[cellDescription] = {}
    end
    CellReset.data.cells[cellDescription].gameTime = CellReset.getGameTime()
    CellReset.data.cells[cellDescription].osTime = os.time()
end

function CellReset.needsReset(cellDescription)
    if not CellReset.isExcluded(cellDescription) then
        local data = CellReset.data.cells[cellDescription]
        if data~=nil then
            local passedTime = 0

            if CellReset.config.useGameTime then
                passedTime = CellReset.getGameTime() - data.gameTime
            else
                passedTime = (os.time() - data.osTime) / CellReset.cofnig.timeRate
            end

            tes3mp.LogMessage(
                enumerations.log.INFO,
                "[CellReset] Time passed in " .. cellDescription.. ": " .. passedTime .."\n"
            )

            return passedTime > CellReset.config.resetTime
        else
            CellReset.updateCell(cellDescription)
        end
    end
    return false
end

function CellReset.resetCell(cellDescription)
    local cell = Cell(cellDescription)
    os.remove(CellReset.cellDir .. cell.entryFile)
end

function CellReset.manageCells()
    for cellDescription, data in pairs(CellReset.data.cells) do
        if CellReset.needsReset(cellDescription) then
            tes3mp.LogMessage(enumerations.log.INFO, "[CellReset] Resetting " .. cellDescription .. "\n")
            CellReset.resetCell(cellDescription)
        end
    end
end


function CellReset.OnServerPostInit(eventStatus)
    CellReset.loadData()
    CellReset.manageCells()
end

function CellReset.OnCellUnload(eventStatus, pid, cellDescription)
    CellReset.updateCell(cellDescription)
end

function CellReset.OnServerExit(eventStatus)
    CellReset.saveData()
end


customEventHooks.registerHandler("OnServerPostInit", CellReset.OnServerPostInit)
customEventHooks.registerHandler("OnCellUnload", CellReset.OnCellUnload)
customEventHooks.registerHandler("OnServerExit", CellReset.OnServerExit)

return CellReset