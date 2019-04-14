local resetCellkills = function (eventStatus, cellDescription)
    if eventStatus.validCustomHandlers then
        if LoadedCells[cellDescription] == nil then
            logicHandler.LoadCell(cellDescription)
        end

        local data = LoadedCells[cellDescription].data
        local kills = WorldInstance.data.kills
        for uniqueIndex, object in pairs(data.objectData) do
            if object.killer ~= nil then
                local refId = object.refId
                if kills[refId] ~= nil then
                    CellReset.LogMessage(string.format("Decreasing kill count for %s", refId))
                    kills[refId] = kills[refId] - 1
                    if kills[refId] == 0 then
                        kills[refId] = nil
                    end
                end
            end
        end
        WorldInstance:Save()
    end
end

customEventHooks.registerValidator("CellReset_OnReset", resetCellkills)