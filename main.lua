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
    },
    logCellTime = false
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


function CellReset.LogMessage(mes)
    tes3mp.LogMessage(enumerations.log.INFO, "[CellReset] " .. mes)
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
            passedTime = (os.time() - data.osTime) / CellReset.config.timeRate
        end

        if CellReset.config.logCellTime then
            CellReset.LogMessage("Time passed in " .. cellDescription.. ": " .. passedTime)
        end

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
    local reset_cells = {}
    for cellDescription, data in pairs(CellReset.data.cells) do
        if CellReset.needsReset(cellDescription) then
            local eventStatus = customEventHooks.triggerValidators("CellReset_OnReset", {cellDescription})
            if eventStatus.validDefaultHandler then
                table.insert(reset_cells, cellDescription)
                CellReset.LogMessage("Resetting " .. cellDescription)
                CellReset.resetCell(cellDescription)
            end
            customEventHooks.triggerHandlers("CellReset_OnReset", eventStatus, {cellDescription})
        end
    end
    customEventHooks.triggerHandlers(
        "CellReset_OnResetFinished",
        customEventHooks.makeEventStatus(true, true),
        {reset_cells}
    )
end


function CellReset.OnServerPostInit(eventStatus)
    CellReset.loadData()
    CellReset.manageCells()
    CellReset.saveData()
end

function CellReset.OnCellUnload(eventStatus, pid, cellDescription)
    if not eventStatus.validCustomHandlers then
        return
    end
    CellReset.updateCell(cellDescription)
end

function CellReset.OnServerExit(eventStatus)
    for cellDescription, cell in pairs(LoadedCells) do
        CellReset.updateCell(cellDescription)
    end
    CellReset.saveData()
end


customEventHooks.registerHandler("OnServerPostInit", CellReset.OnServerPostInit)
customEventHooks.registerHandler("OnCellUnload", CellReset.OnCellUnload)
customEventHooks.registerHandler("OnServerExit", CellReset.OnServerExit)


function CellReset.Command(pid, cmd)
    if Players[pid].data.settings.staffRank >= CellReset.config.command.staffRank then
        local cellDescription = ""
        if cmd[3] ~= nil then
            cellDescription = table.concat(cmd, " ", 3)
        else
            cellDescription = tes3mp.GetCell(pid)
        end
        
        if cmd[2] == "exclude" then
            tes3mp.SendMessage(pid, string.format(CellReset.config.command.excludeMessage, cellDescription))
            CellReset.exclude(cellDescription)
        elseif cmd[2] == "include" then
            tes3mp.SendMessage(pid, string.format(CellReset.config.command.includeMessage, cellDescription))
            CellReset.unExclude(cellDescription)
        elseif cmd[2] == "save" then
            CellReset.saveData()
        else
            tes3mp.SendMessage(pid, "Command usage: /cellreset <exclude/include/save> [cellDescription]\n")
        end
    else
        tes3mp.SendMessage(pid, CellReset.config.rankError)
    end
end

customCommandHooks.registerCommand("cellreset", CellReset.Command)

return CellReset