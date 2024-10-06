local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")

local types = include("diject.quest_guider.types")
local descriptionLines = include("diject.quest_guider.descriptionLines")

local dataHandler = include("diject.quest_guider.dataHandler")

local this = {}


---@param questId string
---@return { name: string, [string]: questDataGenerator.stageData }|nil
function this.getQuestData(questId)
    return dataHandler.quests[questId:lower()]
end

---@param objectId string
---@return questDataGenerator.objectInfo|nil
function this.getObjectPositionData(objectId)
    local objData = dataHandler.questObjects[objectId:lower()]
    if not objData then return end
    return objData.positions
end

---@param objectId string
---@return questDataGenerator.objectInfo
function this.getObjectData(objectId)
    return dataHandler.questObjects[objectId:lower()]
end

---@param text string
---@return questDataGenerator.questTopicInfo[]|nil
function this.getQuestInfoByJournalText(text)
    local str = text:gsub("@", ""):gsub("#", ""):gsub("\n", " ")
    return dataHandler.questByText[str]
end

---@param questData string|questDataGenerator.questData
---@param questIndex integer|string
---@return string[]|nil
function this.getNextIndexes(questData, questIndex)
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData)
    end
    if not questData then return end
    local tpData = questData[tostring(questIndex)]
    if not tpData then return end

    local nextIndexes = {}
    local foundNextIndex = false
    if tpData.next then
        for _, ind in pairs(tpData.next) do
            nextIndexes[ind] = true
            foundNextIndex = true
        end
    end
    if not foundNextIndex and tpData.nextIndex then
        nextIndexes[tpData.nextIndex] = true
    end

    nextIndexes = table.keys(nextIndexes)

    if #nextIndexes == 0 then return end

    table.sort(nextIndexes)

    return nextIndexes
end

---@class questGuider.quest.getDescriptionDataFromBlock.returnArr
---@field str string
---@field priority number
---@field objects string[]|nil

---@alias questGuider.quest.getDescriptionDataFromBlock.return questGuider.quest.getDescriptionDataFromBlock.returnArr[]

---@param reqBlock table<integer, questDataGenerator.requirementData>
---@return questGuider.quest.getDescriptionDataFromBlock.return|nil
function this.getDescriptionDataFromDataBlock(reqBlock)
    if not reqBlock then return end

    ---@type questGuider.quest.getDescriptionDataFromBlock.return
    local out = {}

    local objectObj

    for _, requirement in pairs(reqBlock) do

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = 0}

        local object = requirement.object
        local value = requirement.value
        local variable = requirement.variable
        local operator = requirement.operator
        local skill = requirement.skill
        local attribute = requirement.attribute
        local environment = {
            object = object,
            value = value,
            variable = variable,
            operator = operator,
            skill = skill,
            attribute = attribute,
            objectObj = objectObj,
            variableObj = nil,
            valueObj = nil,
            variableQuestName = "???",
            valueStr = "???",
            variableStr = "???",
        }
        if object then
            objectObj = tes3.getObject(object)
            environment.objectObj = objectObj
        end
        if value then
            if type(value) == "string" then
                local obj = tes3.getObject(value)
                if obj then
                    environment.valueObj = obj
                    goto done
                end
                local cell = tes3.getCell{id = value}
                if cell then
                    environment.valueObj = cell
                    goto done
                end
                local region = tes3.findRegion{id = value}
                if region then
                    environment.valueObj = region
                    goto done
                end
                local faction = tes3.getFaction(value)
                if faction then
                    environment.valueObj = faction
                    goto done
                end
                ::done::
            end
            environment.valueStr = tostring(value)
        end
        if variable then
            if type(variable) == "string" then
                local obj = tes3.getObject(variable)
                if obj then
                    environment.variableObj = obj
                    goto done
                end
                local cell = tes3.getCell{id = variable}
                if cell then
                    environment.variableObj = cell
                    goto done
                end
                local region = tes3.findRegion{id = variable}
                if region then
                    environment.variableObj = region
                    goto done
                end
                local faction = tes3.getFaction(variable)
                if faction then
                    environment.variableObj = faction
                    goto done
                end
                if dataHandler.quests[variable] then
                    environment.variableQuestName = dataHandler.quests[variable].name or "???"
                end
                ::done::
            end
            environment.variableStr = tostring(variable)
        end

        local reqStrDescrData = descriptionLines[requirement.type]
        if reqStrDescrData then
            local str = reqStrDescrData.str:gsub("#variable#", environment.variableStr)
            str = str:gsub("#value#", environment.valueStr)
            str = str:gsub("#variableQuestName#", environment.variableQuestName)
            if environment.operator then
                str = str:gsub("#operator#", types.operator.name[environment.operator])
            end
            local mapped = {}
            for codeStr in string.gmatch(str, "@(.-)@") do
                local pattern = "@"..codeStr.."@"
                local f = load("return "..codeStr, nil, nil, environment)
                local fSuccess, fRet = pcall(f)
                if not fSuccess then
                    log("pattern error", pattern, requirement, environment)
                    fRet = "<error>"
                end
                mapped[pattern] = fRet or "???"
            end
            for pattern, ret in pairs(mapped) do
                str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            end

            reqOut.str = str

            if reqStrDescrData.priority then
                reqOut.priority = reqStrDescrData.priority
            end
        else
            reqOut.str = tableLib.tableToStrLine(requirement) or "???"
        end

        local objects = {}
        if environment.objectObj then
            table.insert(objects, environment.object or "")
        end
        if environment.variableObj then
            table.insert(objects, environment.variable or "")
        end
        if environment.valueObj then
            table.insert(objects, environment.value or "")
        end

        if #objects > 0 then
            reqOut.objects = objects
        end

        table.insert(out, reqOut)
    end

    table.sort(out, function (a, b)
        return a.priority > b.priority
    end)

    return out
end


---@class questGuider.quest.getPlayerQuestData.returnArr
---@field id string
---@field name string|nil
---@field activeStage integer|nil
---@field isFinished boolean|nil
---@field isReachable boolean|nil

---@alias questGuider.quest.getPlayerQuestData.return questGuider.quest.getPlayerQuestData.returnArr[]

---@return questGuider.quest.getPlayerQuestData.return
function this.getPlayerQuestData()
    local out = {}

    local dialogueData = tes3.dataHandler.nonDynamicData.dialogues

    for _, dialogue in pairs(dialogueData) do
        if dialogue.type ~= tes3.dialogueType.journal then goto continue end

        local dialogueId = dialogue.id:lower()
        local storageData = dataHandler.quests[dialogueId]

        if not storageData then goto continue end

        ---@type questGuider.quest.getPlayerQuestData.returnArr
        local diaOutData = {} ---@diagnostic disable-line: missing-fields

        diaOutData.id = dialogueId
        diaOutData.name = storageData.name
        diaOutData.activeStage = dialogue.journalIndex
        -- diaOutData.isFinished = dialogue.journalIndex and storageData[tostring(dialogue.journalIndex)].finished or nil

        -- TODO
        diaOutData.isReachable = math.random() > 0.25 and true or false

        table.insert(out, diaOutData)

        ::continue::
    end

    return out
end


return this