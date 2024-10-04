local questLib = include("diject.quest_guider.quest")
local config = include("diject.quest_guider.config")

local stringLib = include("diject.quest_guider.utils.string")

local this = {}

local objectTooltipMenu = {
    block = "qGuider_objectTooltip_block",
    involvedLabel = "qGuider_objectTooltip_involvedLabel",
    startsLabel = "qGuider_objectTooltip_startsLabel",
}

---@param parent tes3uiElement
---@param objectId string
---@return boolean|nil
function this.drawObjectTooltip(parent, objectId)
    objectId = objectId:lower()
    local objectInfo = questLib.getObjectData(objectId)
    if not objectInfo then return end

    local involvedQuests = {}
    for _, stageData in pairs(objectInfo.stages) do
        involvedQuests[stageData.id] = true
    end

    local involvedNames = {}
    for questId, _ in pairs(involvedQuests) do
        local questData = questLib.getQuestData(questId)
        if not questData or not questData.name then goto continue end

        table.insert(involvedNames, questData.name)

        ::continue::
    end

    local startersNames = {}
    if objectInfo.starts then
        for _, questId in pairs(objectInfo.starts) do
            local questData = questLib.getQuestData(questId)
            if not questData or not questData.name then goto continue end

            table.insert(startersNames, questData.name)

            ::continue::
        end
    end


    local involvedQuestNamesStr = stringLib.getValueEnumString(involvedNames, 3, " (%s)")
    local involvedCount = #involvedNames
    local startsQuestNamesStr = stringLib.getValueEnumString(startersNames, 3, " (%s)")
    local startsCount = #startersNames

    if involvedCount <= 0 and startsCount <= 0 then return end


    local block = parent:createBlock{ id = objectTooltipMenu.objectTooltipMenu }
    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoHeight = true
    block.autoWidth = true
    block.maxWidth = 400

    if startsCount > 0 then
        local text = string.format("Starts %d quest%s%s.", startsCount, startsCount == 1 and "" or "s", startsQuestNamesStr)

        local label = block:createLabel{
            id = objectTooltipMenu.startsLabel,
            text = text,
        }
        label.wrapText = true
        label.borderTop = 3
    end

    if involvedCount > 0 then
        local text = string.format("Involved in %d quest%s%s.", involvedCount, involvedCount == 1 and "" or "s", involvedQuestNamesStr)

        local label = block:createLabel{
            id = objectTooltipMenu.involvedLabel,
            text = text,
        }
        label.wrapText = true
        label.borderTop = 3
    end

    return true
end

---@param parent tes3uiElement
---@param reference tes3reference
---@return boolean|nil
function this.drawDoorTooltip(parent, reference)
    if not reference or not reference.destination or
            reference.destination.cell.isOrBehavesAsExterior then
        return
    end

    local markerCellName = reference.cell.editorName
    local innerCells = {  }

    ---@param cell tes3cell
    local function findInnerCells(cell)
        if cell.isOrBehavesAsExterior or cell.editorName == markerCellName then
            return
        end

        if not innerCells[cell.editorName] then
            innerCells[cell.editorName] = cell
        else
            return
        end

        for doorRef in cell:iterateReferences(tes3.objectType.door) do
            if doorRef.destination then
                findInnerCells(doorRef.destination.cell)
            end
        end
    end

    findInnerCells(reference.destination.cell)

    local startsQuest = {}
    local questObjects = {}

    for _, cell in pairs(innerCells) do
        for ref in cell:iterateReferences() do
            local objId = ref.baseObject.id
            local objData = questLib.getObjectData(objId)
            if objData then
                if objData.starts then
                    startsQuest[objId] = objData.starts
                end
                if objData.inWorld < 20 then
                    questObjects[objId] = objData
                end
            end
        end
    end

    local startsQuestCount = table.size(startsQuest)
    local questObjectsCount = table.size(questObjects)

    if startsQuestCount <= 0 and questObjectsCount <= 0 then return end

    local block = parent:createBlock{  }
    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoHeight = true
    block.autoWidth = true
    block.maxWidth = 400

    if startsQuestCount > 0 then
        local questHTable = {}
        local npcNames = {}
        for objId, quests in pairs(startsQuest) do
            for _, qId in pairs(quests) do
                questHTable[qId] = true
            end

            local obj = tes3.getObject(objId)
            if not obj then goto continue end

            npcNames[obj] = obj.name
            ::continue::
        end

        local questNames = {}
        for qId, _ in pairs(questHTable) do
            local questData = questLib.getQuestData(qId)
            if not questData or not questData.name then goto continue end
            questNames[questData.name] = questData.name
            ::continue::
        end

        local npcsStr = stringLib.getValueEnumString(npcNames, 3, " (%s)")
        local questStr = stringLib.getValueEnumString(questNames, 3, " (%s)")

        local label = block:createLabel{
            text = string.format("%d NPC%s%s that can start a quest%s.",
                startsQuestCount, startsQuestCount == 1 and "" or "s", npcsStr, questStr),
        }
        label.wrapText = true
        label.borderTop = 3
    end

    if questObjectsCount > 0 then

        local qObjectsNameTable = {}
        local qNPCsNameTable = {}
        for objId, data in pairs(questObjects) do

            if data.type == 1 then
                local obj = tes3.getObject(objId)
                if not obj then goto continue end
                if obj.objectType == tes3.objectType.npc or obj.objectType == tes3.objectType.creature then
                    qNPCsNameTable[obj.id] = obj.name
                else
                    qObjectsNameTable[obj.id] = obj.name
                end

            elseif data.type == 2 and data.parent then
                local obj = tes3.getObject(data.parent)
                if not obj then goto continue end
                qObjectsNameTable[obj.id] = obj.name
            end

            ::continue::
        end

        local qObjectsCount = table.size(qObjectsNameTable)
        local qObjestsStr = stringLib.getValueEnumString(qObjectsNameTable, 3, " (%s)")

        local npcsCount = table.size(qNPCsNameTable)
        if npcsCount > 0 then
            local npcsStr = stringLib.getValueEnumString(qNPCsNameTable, 3, " (%s)")

            local label = block:createLabel{ text = string.format("%d quest NPC%s%s.",
                npcsCount, npcsCount == 1 and "" or "s", npcsStr) }
            label.wrapText = true
            label.borderTop = 3
        end

        if qObjectsCount > 0 then
            local label = block:createLabel{ text = string.format("%d different quest object%s%s.",
                qObjectsCount, qObjectsCount == 1 and "" or "s", qObjestsStr) }
            label.wrapText = true
            label.borderTop = 3
        end
    end

    return true
end

return this