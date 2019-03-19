local CellReset = {}

CellReset.scriptName = "CellReset"

CellReset.defaultConfig = {
    excludedCells = {},
    resetTime = 120,
    timeRate = 60,
    useGameTime = true,
    command = {
        staffRank = 2,
        rankError = "You are not an admin!\n",
        excludeMessage = "\"%s\" will not be reset anymore!\n",
        includeMessage = "\"%s\" will be reset normally now!\n"
    }
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

function CellReset.unExclude(cellDescription)
    CellReset.data.excludedCells[cellDescription] = nil
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
        if data == nil then
            CellReset.updateCell(cellDescription)
        end
    
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
    end
    return false
end

function CellReset.resetCell(cellDescription)
    local cell = Cell(cellDescription)

    local cellFilePath = CellReset.cellDir .. cell.entryFile
    
    if tes3mp.DoesFileExist(cellFilePath) then
        cell:Load()

        for type, links in pairs(cell.data.recordLinks) do
            local recordStore = RecordStores[type]
            for refId, objects in pairs(links) do
                recordStore:RemoveLinkToCell(refId, cell)
            end
        end

        os.remove(cellFilePath)
    end

    CellReset.data.cells[cellDescription] = nil
end

function CellReset.manageCells()
    for cellDescription, data in pairs(CellReset.data.cells) do
        if CellReset.needsReset(cellDescription) then
            tes3mp.LogMessage(enumerations.log.INFO, "[CellReset] Resetting " .. cellDescription)
            CellReset.resetCell(cellDescription)
        end
    end
end


function CellReset.OnServerPostInit(eventStatus)
    CellReset.loadData()
    CellReset.manageCells()
    CellReset.saveData()
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


function CellReset.Command(pid, cmd)
    if Players[pid].data.settings.staffRank >= CellReset.config.command.staffRank then
        local cellDescription = ""
        if cmd[3] ~= nil then
            cellDescription = cmd[3]
            for i = 4, #cmd do
                cellDescription = cellDescription .. " " .. cmd[i]
            end
        else
            cellDescription = tes3mp.GetCell(pid)
        end
        
        if cmd[2] == "exclude" then
            tes3mp.SendMessage(pid, string.format(CellReset.config.command.excludeMessage, cellDescription))
            CellReset.exclude(cellDescription)
        elseif cmd[2] == "include" then
            tes3mp.SendMessage(pid, string.format(CellReset.config.command.includeMessage, cellDescription))
            CellReset.unExclude(cellDescription)
        else
            tes3mp.SendMessage(pid, "Command usage: /cellreset <exclude/include> [cellDescription]\n")
        end
    else
        tes3mp.SendMessage(pid, CellReset.config.rankError)
    end
end

customCommandHooks.registerCommand("cellreset", CellReset.Command)

return CellReset