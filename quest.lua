local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")

local types = include("diject.quest_guider.types")
local descriptionLines = include("diject.quest_guider.descriptionLines")

---@type questDataGenerator.quests
local questData = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")

---@type questDataGenerator.questObjectPositions
local objectPositions = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjectPositions")

local this = {}


---@param quest tes3dialogue|string
---@return integer|nil
function this.getPlayerQuestIndex(quest)
    return tes3.getJournalIndex{ id = quest }
end

function this.getQuestData(questId)
    return questData[questId:lower()]
end

function this.getObjectPositionData(objectId)
    return objectPositions[objectId:lower()]
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
                if questData[variable] then
                    environment.variableQuestName = questData[variable].name or "???"
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



return this