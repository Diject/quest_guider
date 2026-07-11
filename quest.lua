local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")
local stringLib = include("diject.quest_guider.utils.string")
local cellLib = include("diject.quest_guider.cell")
local randomLib = include("diject.quest_guider.utils.random")

local config = include("diject.quest_guider.config")

local types = include("diject.quest_guider.types")
local descriptionLines = include("diject.quest_guider.descriptionLines")
local otherTypes = include("diject.quest_guider.Types.other")

local dataHandler = include("diject.quest_guider.dataHandler")
local playerQuests = include("diject.quest_guider.playerQuests")
local requirementChecker = include("diject.quest_guider.requirementChecker")

local this = {}

local weaponTypeNameById = otherTypes.weaponTypeNameById
local magicEffectConsts = otherTypes.magicEffectConsts
local vampireClan = otherTypes.vampireClan

local weatherById = {}

for name, id in pairs(tes3.weather) do
    weatherById[id] = name
end


local disallowedRequirementTypes = {
    [types.requirementType.CustomDialogueChoiceLink] = true
}


local filterForHandledReqBlock = {
    [types.requirementType.Dead] = true,
    [types.requirementType.Journal] = true,
    [types.requirementType.RankRequirement] = true,
    [types.requirementType.PlayerRankMinusNPCRank] = true,
    [types.requirementType.Item] = true,
    [types.requirementType.CustomOnDeath] = true,
}

local filterForDeadReqs = {
    [types.requirementType.Dead] = true,
    [types.requirementType.CustomOnDeath] = true,
}

local cellRequirementTypes = {
    [types.requirementType.NotActorCell] = true,
    [types.requirementType.CustomActorCell] = true,
    [types.requirementType.CustomPCCell] = true,
}

local forbiddenCells = {
    ["toddtest"] = true,
    ["t_test_hf"] = true,
    ["t_test_hr"] = true,
    ["t_test_pc"] = true,
    ["t_test_pi"] = true,
    ["t_test_shotn"] = true,
    ["t_test_skyskiff"] = true,
    ["t_test_tr"] = true,
    ["t_test_wolli"] = true,
}

local topicTestScripts = {
    ["t_sctest_topicstr1"] = true,
    ["t_sctest_topicstr2"] = true,
    ["t_sctest_topicstr3"] = true,
    ["t_sctest_topicstr4"] = true,
}

local supportedGiverTypes = {
    tes3.objectType.npc,
    tes3.objectType.creature,
    tes3.objectType.book,
    tes3.objectType.miscItem,
    tes3.objectType.weapon,
    tes3.objectType.activator,
    tes3.objectType.clothing,
    tes3.objectType.armor,
}



---@param questId string
---@return questDataGenerator.questData|nil
function this.getQuestData(questId)
    return dataHandler.quests[questId:lower()]
end

---@param objectId string
---@return questDataGenerator.objectPosition[]|nil
function this.getObjectPositionData(objectId)
    local objData = dataHandler.questObjects[objectId:lower()]
    if not objData then return end
    return objData.positions
end

---@param objectId string
---@return questDataGenerator.objectInfo?
function this.getObjectData(objectId)
    if not objectId then return end
    return dataHandler.questObjects[objectId:lower()]
end

function this.removeSpecialCharactersFromJournalText(text)
    return text:gsub("@", ""):gsub("#", "")
end

function this.removeNewLines(text)
    return text:gsub("\n", " ")
end

---@param text string
---@return questDataGenerator.questTopicInfo[]|nil
function this.getQuestInfoByJournalText(text)
    local str = this.removeNewLines(text)
    local strClear = this.removeSpecialCharactersFromJournalText(str)
    return dataHandler.questByText[strClear] or dataHandler.questByText[str] or dataHandler.questByText[str:sub(1, -2)]
end

---@param scriptName string
---@return table<string, questDataGenerator.localVariableData>|nil
function this.getLocalVariableDataByScriptName(scriptName)
    return dataHandler.localVariablesByScriptId[scriptName:lower()]
end

---@param questData string|questDataGenerator.questData
---@return integer[]|nil
function this.getIndexes(questData)
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData)
    end
    if not questData then return end

    local indexes = {}
    for ind, _ in pairs(questData) do
        local indInt = tonumber(ind)
        if indInt then
            table.insert(indexes, indInt)
        end
    end
    table.sort(indexes)
    return indexes
end

---@param questData string|questDataGenerator.questData
---@return integer|nil
function this.getFirstIndex(questData)
    local indexes = this.getIndexes(questData)
    if not indexes or #indexes == 0 then return end

    return indexes[1]
end

---@param questData string|questDataGenerator.questData
---@param quesId string?
---@param questIndex integer|string
---@param params {findInLinked: boolean?, findCompleted: boolean?}?
---@return integer[]?
---@return table<string, {index: integer, qData: questDataGenerator.questData}>?
---@return table<string, integer>?
function this.getNextIndexes(questData, quesId, questIndex, params, player)
    if not params then params = {} end
    if not questData then return end
    if type(questData) == "string" then
        questData = this.getQuestData(questData) ---@diagnostic disable-line: cast-local-type
    end
    if not questData then return end

    local tpData = questData[tostring(questIndex)]

    if tpData and tpData.finished then
        return
    end

    local plIndex = params.findCompleted == false and playerQuests.getCurrentIndex(quesId or "") or -1
    plIndex = plIndex or -1

    ---@type table<string, {index: integer, qData: questDataGenerator.questData}>
    local linkedNext

    if params.findInLinked and questData.links then
        for _, linkedId in pairs(questData.links) do
            local linkData = this.getQuestData(linkedId)
            if not linkData then goto continue end

            local firstIndex = this.getFirstIndex(linkData)
            if not firstIndex then goto continue end
            local linkRequirements = linkData[tostring(firstIndex)]
            if not linkRequirements then goto continue end

            if params.findCompleted == false and (playerQuests.getCurrentIndex(linkedId) or 0) ~= 0 then
                goto continue
            end

            local valid = false
            for _, block in pairs(linkRequirements.requirements) do
                valid = valid or requirementChecker.checkBlock(block, {
                    allowedTypes = {
                        [types.requirementType.Journal] = true,
                    },
                    threatErrorsAs = true,
                })
                if valid then break end
            end

            if valid then
                linkedNext = linkedNext or {}
                linkedNext[linkedId] = {index = firstIndex, qData = linkData}
            end

            ::continue::
        end
    end

    if not tpData and not linkedNext then
        local intQuestIndex = tonumber(questIndex)
        if intQuestIndex then
            local indexes = this.getIndexes(questData) or {}
            for i = #indexes, 1, -1 do
                local index = indexes[i]
                if index and index < intQuestIndex then
                    tpData = questData[tostring(index)]
                    break
                end
            end
        end
        if not tpData or tpData.finished then return end
    end

    if not tpData then return nil, linkedNext end

    local linkedMap = {}
    local checkedIndexes = {}
    local function checkIndex(ind, advancedChecks)
        if checkedIndexes[ind] ~= nil then return checkedIndexes[ind] end

        local dt = questData[tostring(ind)]
        if dt then
            local isPossible = not next(dt.requirements) and true or false
            for _, bl in pairs(dt.requirements or {}) do
                if not requirementChecker.isBlockCompletionPossible(bl, nil, player) then
                    isPossible = isPossible or false
                else
                    for _, linkDt in pairs(dt.linked or {}) do
                        linkedMap[linkDt[1]] = math.min(linkedMap[linkDt[1]] or math.huge, linkDt[2])
                    end

                    if advancedChecks then
                        local res = requirementChecker.checkBlock(bl, {
                            threatErrorsAs = true,
                            allowedTypes = {
                                [types.requirementType.Journal] = true,
                                [types.requirementType.RankRequirement] = true,
                                [types.requirementType.CustomPCRank] = true,
                                [types.requirementType.CustomPCFaction] = true,
                            }
                        })

                        isPossible = res or false
                    else
                        isPossible = true
                    end
                end

                if isPossible then
                    checkedIndexes[ind] = true
                    return true
                end
            end

            if not isPossible then
                checkedIndexes[ind] = false
                return false
            end
        end

        checkedIndexes[ind] = false
        return false
    end

    local nextIndexes = {}
    if tpData.next then
        for _, ind in pairs(tpData.next) do
            if plIndex < ind and checkIndex(ind) then
                nextIndexes[ind] = true
            end
        end
    end

    if tpData.nextIndex and plIndex < tpData.nextIndex and checkIndex(tpData.nextIndex, true) then
        nextIndexes[tpData.nextIndex] = true
    end

    if not next(nextIndexes) then
        checkedIndexes = {}
        local indexes = this.getIndexes(questData)

        for _, ind in ipairs(indexes) do
            if ind > plIndex and checkIndex(ind) then
                nextIndexes[ind] = true
                break
            end
        end
    end

    -- for cases where there are requirements with dialogues that are impossible to obtain
    if dataHandler.info.version >= 8 then
        for ind, _ in pairs(nextIndexes) do
            local dt = questData[tostring(ind)]
            if not dt then goto continue end

            for _, bl in pairs(dt.requirements or {}) do
                local diaId = types.getActorDialogueIdFromBlock(bl)
                if not diaId then goto continue end

                local diaDt = this.getObjectData(diaId)
                if diaDt then
                    if diaDt.links and (#diaDt.links > 1 or not topicTestScripts[diaDt.links[1][1] or ""]) then
                        goto continue
                    end
                else
                    goto continue
                end
            end

            for _, nInd in pairs(dt.next or {}) do
                if plIndex < nInd and not checkedIndexes[nInd] and checkIndex(nInd) then
                    nextIndexes[nInd] = true
                end
            end
            if dt.nextIndex and plIndex < dt.nextIndex and not checkedIndexes[dt.nextIndex] and checkIndex(dt.nextIndex) then
                nextIndexes[dt.nextIndex] = true
            end

            ::continue::
        end
    end

    local nextIndexKeys = table.keys(nextIndexes)

    if #nextIndexKeys == 0 then return nil, linkedNext end

    table.sort(nextIndexKeys)

    return nextIndexKeys, linkedNext, linkedMap
end


---@param tb {[1] : string} table with object ids
---@return table<string, string> out name by object id
---@return integer count
function this.getObjectNamesFromLinkTable(tb)
    local out = {}
    local count = 0
    for _, tbDt in pairs(tb or {}) do
        local id = tbDt[1]
        local dt = dataHandler.questObjects[id]
        if dt and (dt.type <= 2) then
            local obj = tes3.getObject(id)
            if obj and obj.name then
                out[id] = string.format("\"%s\" (%s)", obj.name, id)
            else
                out[id] = string.format("(%s)", id)
            end
            count = count + 1
        end
    end

    return out, count
end



--#################################################################################################

---@param dialogue tes3dialogue
---@return boolean?
local function isDialogueAvailable(dialogue)
    if not tes3.mobilePlayer then return end
    for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
        if dialogue == dia then
            return true
        end
    end
    return false
end


---@class questGuider.quest.getDescriptionDataFromBlock.returnArr
---@field str string description
---@field priority number
---@field objects table<string, string>|nil index is id, value is name
---@field positionData table<string, questGuider.quest.getRequirementPositionData.returnData>?
---@field data questDataGenerator.requirementData
---@field reqDataForHandling questDataGenerator.requirementBlock? requirement block that can be used for handling quest marker visibility
---@field reqDataForHandlingArr questDataGenerator.requirementBlock[]? alternative requirement blocks. Added to preserve old handling method.

---@alias questGuider.quest.getDescriptionDataFromBlock.return questGuider.quest.getDescriptionDataFromBlock.returnArr[]

---@param reqBlock questDataGenerator.requirementBlock
---@param questId string? diaId
---@param customConfig questGuider.config?
---@return questGuider.quest.getDescriptionDataFromBlock.return|nil
---@return table<string, {index: integer, qData: questDataGenerator.questData}>? linkedQuests
function this.getDescriptionDataFromDataBlock(reqBlock, questId, customConfig)
    if not reqBlock then return end

    -- local blockHash = types.gerRequirementBlockHash(reqBlock)
    -- local cachedVal = cacheLib.get("reqBlockDescrData", blockHash)
    -- if cachedVal then
    --     return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    -- end

    local configData = customConfig or config.data
    if not configData then
        log("Error: config data is required for getDescriptionDataFromDataBlock")
        return
    end
    ---@type table<string, {index: integer, qData: questDataGenerator.questData}>?
    local linkedQuests

    local function getName(obj, default)
        if obj and obj.id == "player" then
            return "the player"
        elseif obj and obj.name then
            return obj.name
        end
        return default or "???"
    end

    local cellRestrictions = {}
    local posReqs = types.getReqirementsByTypeFromBlock(reqBlock, types.requirementType.CustomActorCell)
    if posReqs then
        for _, req in pairs(posReqs) do
            cellRestrictions[req.value or ""] = true
        end
    end
    posReqs = types.getReqirementsByTypeFromBlock(reqBlock, types.requirementType.NotActorCell)
    if posReqs then
        for _, req in pairs(posReqs) do
            cellRestrictions[req.variable or ""] = false
        end
    end
    cellRestrictions = next(cellRestrictions) and cellRestrictions or nil

    ---@type questGuider.quest.getDescriptionDataFromBlock.return
    local out = {}

    ---@type table<string, boolean>
    local checkedDialogObjects = {}

    local processedReqs = {}

    ---@param requirement questDataGenerator.requirementData
    ---@param reqBlockForHandling questDataGenerator.requirementBlock?
    local function processRequirement(requirement, additionalPriority, skipNested, reqBlockForHandling)
        if disallowedRequirementTypes[requirement.type] then goto continue end

        if requirement.type == types.requirementType.Journal and requirement.variable == questId then
            goto continue
        elseif requirement.type == types.requirementType.CustomScript and requirement.script then
            local scrData = dataHandler.questObjects[requirement.script]
            if scrData and scrData.links then
                for _, dt in pairs(scrData.links) do
                    if dt[2] == nil then goto continue end

                    local objDt = this.getObjectData(dt[1])
                    if not objDt or objDt.type > 2 then goto continue end

                    processRequirement({type = "SCR2", operator = 48, variable = dt[1], script = requirement.script}, (additionalPriority or 0) - 10000)

                    ::continue::
                end
                return
            end
        end

        local recHash = types.getRequirementHash(requirement)
        if processedReqs[recHash] then goto continue end
        processedReqs[recHash] = true

        ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
        local reqOut = {str = "", priority = additionalPriority or 0, data = requirement}

        if reqBlockForHandling then
            reqOut.reqDataForHandling = reqBlockForHandling
        elseif requirement.type == types.requirementType.CustomActor then
            local blockCopy = table.copy(reqBlock)
            local objData = this.getObjectData(requirement.object)
            if objData and (objData.total or 0) < 2 then
                table.insert(blockCopy, {
                    type = types.requirementType.Dead,
                    operator = types.operator.value.Equal,
                    value = 0,
                    object = requirement.object,
                })
            end
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(blockCopy, filterForHandledReqBlock)
        elseif requirement.type == types.requirementType.Journal then

            local isAddedNotStartedQuest = false
            if requirement.type == types.requirementType.Journal
                    and not ((requirement.operator == types.operator.value.Equal or requirement.operator == types.operator.value.LessOrEqual) and requirement.value == 0)
                    and not (requirement.operator == types.operator.value.Less and requirement.value == 1) then

                local index = playerQuests.getCurrentIndex(requirement.variable or "")
                if not index or index == 0 then
                    local qDt = this.getQuestData(requirement.variable)
                    if qDt and qDt.givers then
                        local firstIndex = this.getFirstIndex(qDt)

                        local id = 1
                        for _, giverId in pairs(qDt.givers) do
                            local giverDt = dataHandler.questObjects[giverId]
                            if not giverDt or (giverDt.type > 2 and giverDt.type ~= 4) then goto continue end

                            reqOut.reqDataForHandlingArr = reqOut.reqDataForHandlingArr or {}
                            reqOut.reqDataForHandlingArr[id] = reqOut.reqDataForHandlingArr[id] or {}
                            if giverDt.type <= 2 then
                                local objData = this.getObjectData(requirement.object)
                                if objData and (objData.total or 0) < 2 then
                                    table.insert(reqOut.reqDataForHandlingArr[id], {
                                        type = types.requirementType.Dead,
                                        operator = types.operator.value.Equal,
                                        value = 0,
                                        object = giverId,
                                    })
                                end
                            end
                            table.insert(reqOut.reqDataForHandlingArr[id], {
                                type = types.requirementType.Journal,
                                operator = types.operator.value.Less,
                                value = firstIndex or 0,
                                variable = requirement.variable,
                            })
                            id = id + 1

                            isAddedNotStartedQuest = true

                            ::continue::
                        end
                    end
                end
            end

            if not isAddedNotStartedQuest then
                local req = table.copy(requirement)
                reqOut.reqDataForHandling = reqOut.reqDataForHandling or {}
                tableLib.addValues(requirementChecker.getFilterredRequirementBlock({req}, filterForHandledReqBlock), reqOut.reqDataForHandling)
            end

        elseif requirement.type == "SCR2" then
            local filteredBlock = requirementChecker.getFilterredRequirementBlock(reqBlock, filterForDeadReqs, true)
            for _, req in pairs(filteredBlock or {}) do
                req.object = requirement.variable
            end
            reqOut.reqDataForHandling = filteredBlock

        elseif requirement.type == "DIAP" then
            reqOut.reqDataForHandling = requirementChecker.getFilterredRequirementBlock(
                {{operator = 49, type = types.requirementType.CustomDialogue, variable = requirement.variable}}
            )
        end

        local object = requirement.object
        local value = requirement.value
        local variable = requirement.variable
        local operator = requirement.operator
        local skill = requirement.skill
        local attribute = requirement.attribute
        local script = requirement.script
        local environment = {
            object = object,
            value = value,
            variable = variable,
            operator = operator,
            script = script,
            skill = skill,
            attribute = attribute,
            objectObj = nil,
            variableObj = nil,
            valueObj = nil,
            variableQuestName = "???",
            valueStr = "???",
            variableStr = "???",
            weaponTypeName = weaponTypeNameById,
            magicEffectConsts = magicEffectConsts,
        }
        if object then
            local objectObj = tes3.getObject(object)
            environment.objectObj = objectObj
        end
        if value then
            if type(value) == "string" then
                local obj = tes3.getObject(value)
                if obj then
                    environment.valueObj = obj
                    goto done
                end

                if cellRequirementTypes[requirement.type] and type(value) == "string" then
                    local cell = cellLib.getCell(value)
                    if cell then
                        environment.valueObj = cell
                        goto done
                    end
                end
                -- local faction = tes3.getFaction(value)
                -- if faction then
                --     environment.valueObj = faction
                --     goto done
                -- end
                -- local class = tes3.findClass(value)
                -- if class then
                --     environment.valueObj = class
                --     goto done
                -- end
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

                if cellRequirementTypes[requirement.type] and type(variable) == "string" then
                    local cellVar = cellLib.getCell(variable)
                    if cellVar then
                        environment.variableObj = cellVar
                        goto done
                    end
                end
                -- local faction = tes3.getFaction(variable)
                -- if faction then
                --     environment.variableObj = faction
                --     goto done
                -- end
                if dataHandler.quests[variable] then
                    environment.variableQuestName = dataHandler.quests[variable].name or "???"
                end
                ::done::
            end
            environment.variableStr = tostring(variable)
        end

        local reqStrDescrData = descriptionLines[requirement.type]
        if reqStrDescrData then
            local str = reqStrDescrData.str
            local mapped = {}
            for codeStr in string.gmatch(reqStrDescrData.str, "#(.-)#") do
                local pattern = "#"..codeStr.."#"
                if codeStr == "object" then
                    mapped[pattern] = tostring(environment.object or "???")
                elseif codeStr == "variable" then
                    mapped[pattern] = environment.variableStr
                elseif codeStr == "value" then
                    mapped[pattern] = environment.valueStr
                elseif codeStr == "script" then
                    mapped[pattern] = environment.script or "???"
                elseif codeStr == "varQuestName" then
                    mapped[pattern] = environment.variableQuestName
                elseif codeStr == "objectName" then
                    mapped[pattern] = getName(environment.objectObj)
                elseif codeStr == "valueName" then
                    mapped[pattern] = getName(environment.valueObj)
                elseif codeStr == "varName" then
                    mapped[pattern] = getName(environment.variableObj)
                elseif codeStr == "skillName" then
                    mapped[pattern] = environment.skill and (tes3.skillName[environment.skill] or "???") or "???"
                elseif codeStr == "attributeName" then
                    mapped[pattern] = environment.attribute and (tes3.attributeName[environment.attribute] or "???") or "???"
                elseif codeStr == "valCellName" then
                    mapped[pattern] = environment.valueObj and environment.valueObj.displayName or "???"
                elseif codeStr == "weaponType" then
                    mapped[pattern] = environment.value and (weaponTypeNameById[environment.value] or "???") or "???"
                elseif codeStr == "magicEffect" then
                    mapped[pattern] = magicEffectConsts[environment.variable] and tes3.getMagicEffect(magicEffectConsts[environment.variable]).name or environment.variable
                elseif codeStr == "classVar" then
                    mapped[pattern] = tes3.findClass(environment.variable) and tes3.findClass(environment.variable).name or environment.variable
                elseif codeStr == "classVal" then
                    mapped[pattern] = tes3.findClass(environment.value) and tes3.findClass(environment.value).name or environment.value
                elseif codeStr == "rankName" then
                    mapped[pattern] = environment.variableObj and environment.variableObj:getRankName(environment.value) or environment.value
                elseif codeStr == "vampClanVal" then
                    mapped[pattern] = vampireClan[environment.value] and vampireClan[environment.value] or tostring(environment.value)
                elseif codeStr == "weatherIdVal" then
                    mapped[pattern] = weatherById[environment.value] and weatherById[environment.value] or tostring(environment.value)
                elseif codeStr == "varNameOrTheActor" then
                    mapped[pattern] = getName(environment.variableObj, "the actor")
                elseif codeStr == "objNameOrTheActor" then
                    mapped[pattern] = getName(environment.objectObj, "the actor")
                elseif codeStr == "raceByIntValue" then
                    local race = tes3.dataHandler.nonDynamicData.races[environment.value]
                    mapped[pattern] = race and race.name or "???"
                elseif codeStr == "factionValue" then
                    local faction = tes3.getFaction(environment.value or "")
                    mapped[pattern] = faction and faction.name or environment.value
                elseif codeStr == "factionVar" then
                    local faction = tes3.getFaction(environment.variable or "")
                    mapped[pattern] = faction and faction.name or environment.variable
                elseif codeStr == "varSpellName" then
                    mapped[pattern] = environment.variableObj and environment.variableObj.name or environment.variable
                elseif codeStr == "dialogueVariable" then
                    mapped[pattern] = environment.variableStr:sub(7)
                elseif codeStr == "dialogueValue" then
                    mapped[pattern] = environment.valueStr:sub(7)
                elseif codeStr == "operator" then
                    mapped[pattern] = types.operator.name[environment.operator]
                elseif codeStr == "notContr" then
                    mapped[pattern] = (value ~= nil and type(value) == "number") and
                        (((value==0 and operator==48) or (value==1 and operator==49) or (value==1 and operator==52) or (value==0 and operator==53)) and "n't" or "")
                        or ""
                elseif codeStr == "negNotContr" then
                    mapped[pattern] = (value ~= nil and type(value) == "number") and
                        (((value==1 and operator==48) or (value==0 and operator==49) or (value==0 and operator==50)) and "n't" or "")
                        or ""
                elseif codeStr == "scriptObjects" then
                    local res = ""
                    if environment.script then
                        local scrData = dataHandler.questObjects[environment.script]
                        if scrData and scrData.links then
                            local objs, count = this.getObjectNamesFromLinkTable(scrData.links)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s")
                            end
                        end
                    end

                    if res == "" then
                        res = "???"
                    end
                    mapped[pattern] = res
                elseif codeStr == "objectsInScript" then
                    local res = ""
                    if environment.value then
                        local scrData = dataHandler.questObjects[environment.value]
                        if scrData and scrData.contains then
                            local objs, count = this.getObjectNamesFromLinkTable(scrData.contains)

                            if count > 0 then
                                res = stringLib.getValueEnumString(objs, configData.journal.objectNames, "%s")
                            end
                        end
                    end

                    if res == "" then
                        res = "???"
                    end
                    mapped[pattern] = res
                end
            end
            for pattern, ret in pairs(mapped) do
                str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            end

            local mapped = {}
            for codeStr in string.gmatch(str, "@(.-)@") do
                local pattern = "@"..codeStr.."@"
                local f, err = load("return "..codeStr, nil, nil, environment)
                if err then
                    log("pattern error", err, pattern, requirement)
                else
                    local fSuccess, fRet = pcall(f)
                    if not fSuccess then
                        log("pattern error", pattern, requirement)
                        fRet = "<error>"
                    end
                    mapped[pattern] = fRet or "???"
                end
            end
            for pattern, ret in pairs(mapped) do
                str = str:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
            end

            reqOut.str = str:gsub("^%l", string.upper)

            if reqStrDescrData.priority then
                reqOut.priority = reqOut.priority + reqStrDescrData.priority
            end
        else
            local reqCopy = table.copy(requirement)
            for reqDescr, reqId in pairs(types.requirementType) do
                if reqCopy.type == reqId then
                    reqCopy.type = reqDescr
                    break;
                end
            end
            ---@diagnostic disable-next-line: assign-type-mismatch
            reqCopy.operator = types.operator.name[reqCopy.operator] or reqCopy.operator
            reqOut.str = tableLib.tableToStrLine(reqCopy) or "???"
        end

        local objects = {}
        if environment.objectObj and environment.object then
            objects[environment.object] = environment.objectObj and (environment.objectObj.name or "") or ""
        end
        if environment.variableObj and environment.variable then
            objects[environment.variable] = environment.variableObj and (environment.variableObj.name or "") or ""
        end
        if environment.valueObj and environment.value then
            objects[environment.value] = environment.valueObj and (environment.valueObj.name or "") or ""
        end
        if environment.script then
            local scrData = dataHandler.questObjects[environment.script]
            if scrData and scrData.links then
                for _, idDt in pairs(scrData.links) do
                    local linkData = dataHandler.questObjects[idDt[1]]
                    if linkData and (linkData.type <= 2) then
                        objects[idDt[1]] = idDt[1]
                    end
                end
            end
        end

        objects["player"] = nil

        if next(objects) then
            reqOut.objects = objects
        end

        local posData, linkedQuestFromPos = this.getRequirementPositionData(requirement, configData, questId, not skipNested and {
            cellRestrictions = cellRestrictions
        } or nil)
        reqOut.positionData = posData

        if linkedQuestFromPos then
            linkedQuests = linkedQuests or {}
            table.copy(linkedQuestFromPos, linkedQuests)
        end

        table.insert(out, reqOut)

        if not skipNested and requirement.type == types.requirementType.CustomLocal and requirement.variable and requirement.value then

            local function process(objectId, scriptId, addPriority)
                if not addPriority then addPriority = 0 end

                local localVarDt = dataHandler.localVariablesByScriptId[objectId]
                if not localVarDt then return end
                localVarDt = localVarDt[requirement.variable]
                if not localVarDt then return end
                ---@type questDataGenerator.requirementBlock[]
                local resReqBlock = localVarDt.results[tostring(requirement.value)]
                if not resReqBlock then return end
                if not next(resReqBlock) then return end

                -- currently only the first requirement block is used
                -- TODO: Implement support for multiple requirement blocks
                local reqs = resReqBlock[1]

                local scriptIds = {}
                if scriptId then
                    scriptIds[scriptId] = true
                end
                for _, req in pairs(reqs) do
                    local isNew = true
                    for _, r in pairs(reqBlock) do
                        if types.areRequirementsEqual(req, r) then
                            isNew = false
                            break
                        end
                    end

                    if isNew then
                        local reqCopy = table.copy(req)
                        processRequirement(req, addPriority - 9000, true, {types.invertRequirement(reqCopy)})
                        if req.script then
                            scriptIds[req.script] = true
                        end
                    end
                end

                for scrId, _ in pairs(scriptIds) do
                    processRequirement({type = types.requirementType.CustomScript, operator = 48, variable = scrId, script = scrId}, addPriority - 10000, true, reqs)
                end
            end

            if requirement.object or requirement.script then
                local id = requirement.object or requirement.script

                process(id, requirement.script)
                local qObjData = this.getObjectData(id)
                if qObjData and qObjData.contains then
                    for _, dt in ipairs(qObjData.contains) do
                        if dt[2] ~= nil then break end
                        local linkedObjData = this.getObjectData(dt[1])
                        if linkedObjData and linkedObjData.type == 4 then
                            process(dt[1], dt[1])
                        end
                    end
                end
            else
                local foundScripts = {}
                local varData = this.getObjectData(requirement.variable)
                -- TODO: dehardcode limit
                if varData and varData.links and (varData.total or 0) <= 10 then
                    local linkCount = #varData.links
                    if linkCount < 10 then
                        for _, dt in ipairs(varData.links) do
                            if dt[2] ~= nil then break end

                            if not foundScripts[dt[1]] then
                                local objData = this.getObjectData(dt[1])
                                if objData and objData.type == 4 then
                                    foundScripts[dt[1]] = objData
                                end
                            end
                        end
                    end
                end

                local foundValid = false
                for scrId, scrObjDt in pairs(foundScripts) do
                    local total = varData.total or 0 ---@diagnostic disable-line: need-check-nil
                    local linkCount = #(varData.links or {}) ---@diagnostic disable-line: need-check-nil
                    if total == 0 or linkCount == 1 then
                        process(scrId, scrId)
                        foundValid = true
                    else
                        for _, dt in pairs(scrObjDt.stages or {}) do
                            if dt.id == questId then
                                process(scrId, scrId)
                                foundValid = true
                                break
                            end
                        end
                    end
                end

                if not foundValid then
                    for i, req in pairs(reqBlock) do
                        if req.type == types.requirementType.CustomActor and req.object then
                            process(req.object, nil, -i * 10000)
                        end
                    end
                end
            end

        end

        local function addDialogueData(objId)
            if not objId or checkedDialogObjects[objId] then return end
            checkedDialogObjects[objId] = true

            local objData = dataHandler.questObjects[objId]
            if not objData or objData.type > 2 then return end

            if not tes3.getObject(objId) then return end

            for _, linkDt in pairs(objData.links or {}) do
                local linkName = linkDt[1]
                local linkData = dataHandler.questObjects[linkName]
                if not linkData then goto continue end

                if linkData.type == 3 then
                    if requirement.type == types.requirementType.Item then
                        processRequirement({type = "DIAO", operator = operator, object = variable, variable = linkName, value = value}, additionalPriority)
                    else
                        processRequirement({type = "DIAO", operator = operator, variable = linkName}, additionalPriority)
                    end
                end

                ::continue::
            end
        end

        if requirement.type ~= "DIAO" then
            addDialogueData(environment.object)
            addDialogueData(environment.value)
            addDialogueData(environment.variable)
        end

        ::continue::
    end

    for _, requirement in pairs(reqBlock) do
        processRequirement(requirement)
    end

    table.sort(out, function (a, b)
        return a.priority > b.priority
    end)

    -- cacheLib.set("reqBlockDescrData", blockHash, {out, linkedQuests})

    return out, linkedQuests
end


local function getQDialogueNearby()
    local objectIds = {}
    ---@param c tes3cell
    local function processCell(c, depth)
        depth = depth - 1

        for ref in c:iterateReferences(supportedGiverTypes) do
            objectIds[ref.baseObject.id] = true
            if ref.baseObject.script then
                objectIds[ref.baseObject.script.id] = true
            end
        end

        if depth <= 0 then return end
        for door in c:iterateReferences(tes3.objectType.door) do
            if not door.destination or door.deleted or door.disabled then goto continue end

            if door.destination.cell then
                processCell(door.destination.cell, depth)
            end

            ::continue::
        end
    end

    local plCell = tes3.player.cell
    if not plCell.isInterior then
        for i = -1, 1 do
            for j = -1, 1 do
                local c = tes3.getCell{x = plCell.gridX + i, y = plCell.gridY + j}
                if c then
                    processCell(c, 2)
                end
            end
        end
    else
        processCell(plCell, 2)
    end

    local diaIds = {}
    for objId, _ in pairs(objectIds) do
        local dt = this.getObjectData(objId)
        if dt and dt.starts then
            for _, diaId in pairs(dt.starts) do
                diaIds[diaId] = true
            end
        end
    end

    return diaIds
end


---@class questGuider.quest.getPlayerQuestData.returnArr
---@field id string
---@field name string|nil
---@field activeStage integer|nil
---@field isFinished boolean|nil
---@field isReachable boolean|nil

---@alias questGuider.quest.getPlayerQuestData.return questGuider.quest.getPlayerQuestData.returnArr[]

---@param nearbyMode boolean?
---@return questGuider.quest.getPlayerQuestData.return
function this.getPlayerQuestData(nearbyMode)
    local out = {}

    local dialogueData = tes3.dataHandler.nonDynamicData.dialogues
    local dialogueIdsNearby = nearbyMode and getQDialogueNearby() or {}

    local function isValid(dialogueId)
        return not nearbyMode or dialogueIdsNearby[dialogueId]
    end

    for _, dialogue in pairs(dialogueData) do
        if dialogue.type ~= tes3.dialogueType.journal then goto continue end

        local dialogueId = dialogue.id:lower()
        if not isValid(dialogueId) then goto continue end
        local storageData = dataHandler.quests[dialogueId]

        if not storageData then goto continue end

        ---@type questGuider.quest.getPlayerQuestData.returnArr
        local diaOutData = {} ---@diagnostic disable-line: missing-fields

        diaOutData.id = dialogueId
        diaOutData.name = storageData.name
        diaOutData.activeStage = dialogue.journalIndex
        diaOutData.isFinished = dialogue.journalIndex and storageData[tostring(dialogue.journalIndex)] and storageData[tostring(dialogue.journalIndex)].finished or nil

        table.insert(out, diaOutData)

        ::continue::
    end

    return out
end


---@param reqBlock table<integer, questDataGenerator.requirementData>
---@return boolean
function this.isContainsLocalVariableRequirement(reqBlock)
    for _, req in pairs(reqBlock) do
        if req.type == types.requirementType.CustomLocal then
            return true
        end
    end
    return false
end


---@param arr questGuider.quest.getRequirementPositionData.positionData[]
---@param objData questDataGenerator.objectInfo
---@param cellRestrictions table<string, boolean>?
---@return boolean? foundValidPos
local function addPosData(arr, objData, ownerId, configData, object, cellRestrictions)
    if not objData then return end

    if not objData.positions then
        return
    end

    local foundValidPos = false

    local isDoActorChecks = object and (object.servicesOffered ~= nil and objData.total and objData.total < 5)
    local function getNotFoundFlag(cell)
        if not isDoActorChecks then return end

        for _, ref in pairs(cell:getAll(object.isMale ~= nil and types.NPC or types.Creature)) do
            if ref.recordId == object.id then
                if ref.enabled then
                    return nil
                end
            end
        end
        return true
    end

    local function checkRestrictions(cellId)
        if not cellRestrictions then return true end

        for cId, val in pairs(cellRestrictions) do
            if string.sub(cellId, 1, #cId):lower() == cId then
                if val then
                    return true
                end
            elseif not val then
                return true
            end
        end

        return false
    end

    for i, posDt in ipairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        if posDt.name then
            if not checkRestrictions(posDt.name) then goto continue end

            local cell = tes3.getCell{id = posDt.name}

            if cell and cell.id then
                if forbiddenCells[cell.id] or cell.id:find("t_test") then goto continue end

                local notFoundFlag = getNotFoundFlag(cell)

                local newPosData = table.copy(posDt)
                if ownerId then
                    newPosData.type = 2 ---@diagnostic disable-line: inject-field
                    newPosData.id = ownerId ---@diagnostic disable-line: inject-field
                else
                    newPosData.type = 1 ---@diagnostic disable-line: inject-field
                end

                local exCellPos, doorPath, cellPath, isExterior, checkedCells
                if not cell.behavesAsExterior then
                    exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                else
                    exCellPos = tes3vector3.new(x, y, z)
                    cellPath = {cell}
                    isExterior = false
                    checkedCells = {[cell.id] = cell}
                end

                if exCellPos then

                    local exits = {}
                    local firstEntranceCellIds = {}
                    local exitPositions, _, entranceCells, lowestDepth = cellLib.findExitPositions(cell)
                    if exitPositions then
                        for _, pDt in pairs(exitPositions) do
                            if pDt.depth <= lowestDepth + 2 then
                                local nearestDoor = cellLib.findNearestDoor(pDt.pos)
                                if nearestDoor then
                                    table.insert(exits, nearestDoor.position)
                                else
                                    table.insert(exits, pDt.pos)
                                end
                            end
                        end
                        for cellId, depth in pairs(entranceCells or {}) do
                            if depth <= lowestDepth + 2 then
                                firstEntranceCellIds[cellId] = cellId
                            end
                        end
                    end

                    foundValidPos = foundValidPos or not notFoundFlag
                    table.insert(arr, {id = cell.id, position = tes3vector3.new(x, y, z), entrances = exits,  firstEntranceCellIds = firstEntranceCellIds,
                        exitPos = exCellPos, isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath, rawData = newPosData, notFound = notFoundFlag})

                else
                    local descr
                    if cellPath then
                        local list = {}
                        local count = 0
                        for _, cl in pairs(checkedCells) do
                            table.insert(list, cl.displayName or "???")
                            count = count + 1
                        end
                        tableLib.shuffle(list, count)
                        descr = stringLib.getValueEnumString(list, configData.journal.objectNames, "Reachable from %s")
                    end

                    foundValidPos = foundValidPos or not notFoundFlag
                    table.insert(arr, {description = descr or posDt.name, id = cell.id, position = tes3vector3.new(x, y, z), rawData = newPosData, notFound = notFoundFlag})
                end
            end
        elseif posDt.grid then
            local cell = tes3.getCell{x = posDt.grid[1], y = posDt.grid[2]}
            if cell then
                if not checkRestrictions(cell.name or "123") then goto continue end

                local notFoundFlag = getNotFoundFlag(cell)

                local descr = cell.displayName

                local pos = tes3vector3.new(x, y, z)
                local newPosData = tableLib.copy(posDt)
                if ownerId then
                    newPosData.type = 2
                    newPosData.id = ownerId
                else
                    newPosData.type = 1
                end

                foundValidPos = foundValidPos or not notFoundFlag
                table.insert(arr, {description = descr, id = nil, position = pos, exitPos = pos, isExitEx = true, rawData = newPosData, notFound = notFoundFlag})
            end
        end

        ::continue::
    end

    return foundValidPos
end


---@param cell tes3cell
local function addCellData(cell, id, arr, configData)
    if not cell.id then return end

    if cell.isInterior then
        local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)

        if exCellPos then

            -- local descr
            -- if cellPath then
            --     for i = #cellPath, 1, -1 do
            --         descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].name) or
            --             string.format("\"%s\"", cellPath[i].name)
            --     end
            -- end

            local exits = {}
            local firstEntranceCellIds = {}
            local exitPositions, _, entranceCells, lowestDepth = cellLib.findExitPositions(cell)
            if exitPositions then
                for _, pDt in pairs(exitPositions) do
                    if pDt.depth <= lowestDepth + 1 then
                        local nearestDoor = cellLib.findNearestDoor(pDt.pos)
                        if nearestDoor then
                            table.insert(exits, nearestDoor.position)
                        else
                            table.insert(exits, pDt.pos)
                        end
                    end
                end
                for cellId, depth in pairs(entranceCells or {}) do
                    if depth <= lowestDepth + 1 then
                        firstEntranceCellIds[cellId] = cellId
                    end
                end
            end

            table.insert(arr, {id = cell.name, exitPos = exCellPos, entrances = exits, firstEntranceCellIds = firstEntranceCellIds,
                isExitEx = isExterior, doorPath = doorPath, cellPath = cellPath})

        else
            local descr
            if cellPath then
                local list = {}
                local count = 0
                for _, cl in pairs(checkedCells) do
                    table.insert(list, cl.displayName or "???")
                    count = count + 1
                end
                tableLib.shuffle(list, count)
                descr = stringLib.getValueEnumString(list, configData.journal.objectNames, "Reachable from %s")
            end

            table.insert(arr, {description = descr or cell.displayName or cell.name or "???", id = cell.name, })
        end
    else
        table.insert(arr, {description = cell.displayName or "???", id = nil, exitPos = tes3vector3.new(cell.gridX * 8192 + 4000, cell.gridY * 8192 + 4000, 0)})
    end
end


---@param objectData questDataGenerator.objectInfo
---@param outD questGuider.quest.getRequirementPositionData.returnData?
---@return boolean? foundValidPos
local function fillLinkPositionData(posArr, objectData, configData, outD)
    if not objectData.links then return end

    local foundDirectLinks
    local foundValidPos = false

    for _, linkData in ipairs(objectData.links or {}) do
        local objId = linkData[1]
        local objChance = linkData[2]

        local objDt = this.getObjectData(objId)
        if not objDt then goto continue end

        if objDt.type <= 2 then
            if (objChance or 0) >= configData.tracking.minChance * 0.01 then
                local obj = tes3.getObject(objId)
                if not obj then goto continue end

                local hasValidPos = addPosData(posArr, objDt, objId, configData, obj)
                foundValidPos = foundValidPos or hasValidPos
                foundDirectLinks = true

                if outD then
                    outD.inWorld = (outD.inWorld or 0) + (objDt.inWorld or 0)
                end
            end
        elseif objDt.type == 6 then
            if not objDt.links then goto continue end
            for _, lDt in pairs(objDt.links) do
                if (lDt[2] or 0) < configData.tracking.minChance * 0.01 then goto continue end

                local lObjDt = this.getObjectData(lDt[1])
                if not lObjDt or lObjDt.type > 2 then goto continue end

                local obj = tes3.getObject(lDt[1])
                if not obj then goto continue end

                local hasValidPos = addPosData(posArr, lObjDt, lDt[1], configData, obj)
                foundValidPos = foundValidPos or hasValidPos
                foundDirectLinks = foundDirectLinks or false

                if outD then
                    outD.inWorld = (outD.inWorld or 0) + (lObjDt.inWorld or 0)
                end

                ::continue::
            end
        end

        if outD and foundDirectLinks == false then
            outD.disableInventoryTracking = true
        end

        ::continue::
    end

    return foundValidPos
end


---@class questGuider.quest.getRequirementPositionData.positionData
---@field description string?
---@field descriptionBackward string?
---@field id string? cell id of the position
---@field position tes3vector3? coordinates of the position
---@field distanceToPlayer number?
---@field pathFromPlayer string[]? cell names
---@field exitPos tes3vector3? coordinates in the game world of the entrance to the exterior cell that leads to the position
---@field entrances tes3vector3[]?
---@field firstEntranceCellIds table<string, any>?
---@field doorPath tes3travelDestinationNode[]? list of doors to exit from the position
---@field cellPath tes3cell[]? list of cells to exit from the position
---@field rawData questDataGenerator.objectPosition|{id : string}|nil *id* is injected owner id, if it exists
---@field isExitEx boolean? true, if the exit is in an exterior cell
---@field notFound boolean? true, if the object is not found in the game world

---@class questGuider.quest.getRequirementPositionData.returnData
---@field reqType string requirement type
---@field name string name of the object
---@field inWorld integer? number of instances of the object in the game world
---@field parentObject string?
---@field itemCount integer? item count from *types.requirementType.Item*
---@field disableInventoryTracking boolean? disables checking for the object in the object inventory if true, because the object is not directly linked to the requirement
---@field actorCount integer? kill count from *types.requirementType.Dead*
---@field isActorAliveReq boolean? true if the requirement is to have the actor alive
---@field positions questGuider.quest.getRequirementPositionData.positionData[]
---@field foundValidPos boolean true if at least one valid position is found for the requirement

---@param requirement questDataGenerator.requirementData
---@param customConfig questGuider.config?
---@param questId string diaId
---@param params {cellRestrictions: table<string, boolean>?}?
---@return table<string, questGuider.quest.getRequirementPositionData.returnData>? ret by object id
---@return table<string, {index: integer, qData: questDataGenerator.questData}>? linkedQuests
function this.getRequirementPositionData(requirement, customConfig, questId, params)

    -- local reqHash = types.getRequirementHash(requirement)
    -- local cachedVal = cacheLib.get("requirementPosData", reqHash)
    -- if cachedVal then
    --     return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    -- end

    local configData = customConfig or config.data
    if not configData then
        log("Error: no config data provided for getRequirementPositionData")
        return
    end
    local trackingConfig = configData.tracking

    if requirement.type == types.requirementType.CustomDialogue or
            requirement.type == types.requirementType.CustomPos then
        return
    end

    local linkedQuests = {}

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local out = {}

    local objects = {}
    ---@type table<tes3cell, string>
    local cells = {}

    local requirements = {requirement}


    local function fillDataForScriptByTableName(scriptId, tableName)
        local scrData = dataHandler.questObjects[scriptId]
        if not scrData or not scrData[tableName] then return end

        if scrData and scrData[tableName] then
            for _, linkDt in pairs(scrData[tableName]) do
                if linkDt[2] ~= nil and linkDt[2] >= configData.tracking.minChance * 0.01 then
                    local objData = dataHandler.questObjects[linkDt[1]]
                    if objData and objData.type <= 2 then
                        local obj = tes3.getObject(linkDt[1])
                        if obj then
                            objects[linkDt[1]] = obj
                        end
                    end
                end
            end
        end
    end

    if requirement.type == types.requirementType.Journal
            and not ((requirement.operator == types.operator.value.Equal or requirement.operator == types.operator.value.LessOrEqual) and requirement.value == 0)
            and not (requirement.operator == types.operator.value.Less and requirement.value == 1) then
        local index = playerQuests.getCurrentIndex(requirement.variable or "")
        if not index or index == 0 then
            local qDt = this.getQuestData(requirement.variable)
            if qDt and qDt.givers then
                linkedQuests = linkedQuests or {}
                linkedQuests[requirement.variable] = linkedQuests[requirement.variable] or {
                    index = this.getFirstIndex(qDt),
                    qData = qDt
                }

                for _, giverId in pairs(qDt.givers) do
                    local giverData = dataHandler.questObjects[giverId]
                    if giverData then
                        if giverData.type <= 2 then
                            local obj = tes3.getObject(giverId)
                            if obj then
                                objects[giverId] = obj
                            end
                        elseif giverData.type == 4 then
                            fillDataForScriptByTableName(giverId, "links")
                        end
                    end
                end
            end
        end
    end


    if requirement.type == types.requirementType.CustomActor and requirement.object then
        local obj = tes3.getObject(requirement.object)
        if obj then
            objects[requirement.object] = obj
        end

    elseif requirement.type == types.requirementType.CustomScript and (requirement.script or requirement.variable) then
        fillDataForScriptByTableName(requirement.script or requirement.variable, "links")

    elseif requirement.type == types.requirementType.CustomLocal and (not requirement.object and not requirement.script) then
        local foundScripts = {}
        local foundDias = {}
        local varData = this.getObjectData(requirement.variable)

        -- TODO: dehardcode limit
        if varData and varData.links and (varData.total or 0) <= 10 and #varData.links <= 10 then
            for _, dt in ipairs(varData.links) do
                if dt[2] ~= nil then break end

                local objData = this.getObjectData(dt[1])
                if objData then
                    if objData.type == 4 then
                        foundScripts[dt[1]] = objData
                    elseif objData.type == 3 then
                        foundDias[dt[1]] = objData
                    end
                end
            end
        end

        local foundValid = false
        for scrId, scrObjDt in pairs(foundScripts) do
            for _, dt in pairs(scrObjDt.stages or {}) do
                if dt.id == questId then
                    for _, linkDt in ipairs(scrObjDt.links or {}) do
                        if linkDt[2] ~= nil then break end

                        if not objects[linkDt[1]] then
                            local objData = this.getObjectData(linkDt[1])
                            if objData and objData.type <= 2 then
                                local obj = tes3.getObject(linkDt[1])
                                if obj then
                                    objects[linkDt] = obj
                                end
                            end
                        end
                    end

                    foundValid = true
                    break
                end
            end
        end

    elseif requirement.type == "SCR1" and requirement.value then
        fillDataForScriptByTableName(requirement.value, "contains")

    else
        for _, req in pairs(requirements) do

            if req.type == types.requirementType.CustomScript and req.variable then
                fillDataForScriptByTableName(req.variable, "links")
            end

            for name, value in pairs(req) do
                if value == "" then goto continue end

                if type(value) ~= "string" then
                    goto continue
                end

                local obj = tes3.getObject(value)
                if obj then
                    objects[value] = obj
                    goto continue
                end

                if cellRequirementTypes[req.type] and type(value) == "string" then
                    local cell = cellLib.getCell(value)
                    if cell then
                        cells[cell] = value
                        goto continue
                    end
                end

                if string.sub(value, 1, 6) == "#dia: " then

                    local function findDiaData(recordId, depth)
                        if depth <= 0 then return end

                        local diaData = this.getObjectData(recordId)
                        for _, linkInfo in pairs((diaData or {}).links or {}) do
                            local linkId = linkInfo[1]
                            local linkData = this.getObjectData(linkId)
                            if not linkData then goto continue end

                            if linkData.type == 6 then
                                findDiaData(linkId, depth - 1)
                            elseif linkData.type <= 2 then
                                local obj1 = tes3.getObject(linkId)
                                if obj1 then
                                    objects[linkId] = obj1
                                end
                            end

                            ::continue::
                        end
                    end

                    findDiaData(value, 2)

                    goto continue
                end

                ::continue::
            end
        end
    end

    for id, object in pairs(objects) do
        local positions = {}

        local objectData = this.getObjectData(id)
        if not objectData then goto continue end

        local foundValidPos = addPosData(positions, objectData, nil, configData, object, params and params.cellRestrictions)

        if not out[id] then
            out[id] = {reqType = requirement.type, name = object.name or object.id or "", positions = {}, foundValidPos = foundValidPos or false}
        end

        local outD = out[id]
        if outD then
            outD.inWorld = objectData.inWorld or 0
        end

        foundValidPos = fillLinkPositionData(positions, objectData, configData, outD) or foundValidPos

        outD.positions = positions
        outD.foundValidPos = foundValidPos

        ::continue::
    end

    for cell, id in pairs(cells) do
        if not out[id] then
            out[id] = {reqType = requirement.type, name = cell.displayName or cell.name or cell.id or "", positions = {}, foundValidPos = false}
        end
        addCellData(cell, id, out[id].positions, configData)
        out[id].foundValidPos = next(out[id].positions) and true or false
    end

    if not next(out) then
        return nil
    end

    if requirement.type == types.requirementType.Item or requirement.type == types.requirementType.Dead or
            (requirement.type == "DIAO" and requirement.value) then

        for _, data in pairs(out) do
            if requirement.value then
                data.parentObject = requirement.type == "DIAO" and requirement.object or requirement.variable

                if requirement.operator == types.operator.value.Greater then
                    data.itemCount = requirement.value + 1
                elseif requirement.operator == types.operator.value.Less then
                    data.itemCount = math.max(0, requirement.value - 1)
                elseif requirement.operator == types.operator.value.NotEqual then
                    if requirement.value == 0 then
                        data.itemCount = requirement.value + 1
                    else
                        data.itemCount = math.max(0, requirement.value - 1)
                    end
                else
                    data.itemCount = requirement.value
                end

                if data.itemCount == 0 then data.itemCount = nil end

                if requirement.type == types.requirementType.Dead then
                    data.actorCount = data.itemCount
                    if data.actorCount == nil then
                        data.isActorAliveReq = true
                    end
                    data.itemCount = nil
                end
            end
        end

    elseif requirement.type == types.requirementType.CustomScript then
        for id, data in pairs(out) do
            local obj = objects[id]
            if not obj then goto continue end

            if obj.isCarriable then
                data.parentObject = id
                data.itemCount = 1
            end

            ::continue::
        end
    end

    -- cacheLib.set("requirementPosData", reqHash, {out, linkedQuests})

    return out, linkedQuests
end


---@param object tes3npc|tes3creature
---@param questId string
---@param questIndex integer|string
---@return boolean?
function this.checkConditionsForQuestGiver(object, questId, questIndex)
    if not object then return end
    local questData = this.getQuestData(questId)
    if not questData then return end

    local indexStr = tostring(questIndex)
    local stageData = questData[indexStr]
    if not stageData then return end

    local requirements = stageData.requirements or {}

    if #requirements == 0 then return true end

    local allowedTypes = {
        [types.requirementType.Journal] = true,
        [types.requirementType.CustomActorFaction] = true,
        [types.requirementType.CustomPCFaction] = true,
        [types.requirementType.RankRequirement] = true,
        [types.requirementType.CustomPCRank] = true,
    }

    for _, reqBlock in pairs(stageData.requirements or {}) do
        local ret = requirementChecker.checkBlock(reqBlock, {
            allowedTypes = allowedTypes,
            object = object,
            threatErrorsAs = true,
        })

        if ret then
            return true
        end
    end

    return false
end


---@param questId string
---@param questIndex integer|string
---@param ref any?
---@param params {handleCustomActorReq: boolean?}?
---@return boolean?
function this.checkConditionsForQuest(questId, questIndex, ref, params)
    params = params or {}
    local questData = this.getQuestData(questId)
    if not questData then return end

    local indexStr = tostring(questIndex)
    local stageData = questData[indexStr]
    if not stageData then return end

    local requirements = stageData.requirements or {}

    if not next(requirements) then return true end

    if not ref then

        local allowedTypes = {
            [types.requirementType.Journal] = true,
            [types.requirementType.CustomPCFaction] = true,
            [types.requirementType.CustomPCRank] = true,
            [types.requirementType.CustomGlobal] = true,
            [types.requirementType.Dead] = true,
            [types.requirementType.CustomOnDeath] = true,
            [types.requirementType.Item] = true,
        }

        for _, reqBlock in pairs(stageData.requirements or {}) do
            local ret = requirementChecker.checkBlock(reqBlock, {
                allowedTypes = allowedTypes,
                threatErrorsAs = true,
            })

            if ret then
                return true
            end
        end

    else
        local ignoredTypes = {
            [types.requirementType.CustomDisposition] = true,
            [types.requirementType.CustomDialogue] = true,
            [types.requirementType.CustomDisposition] = true,
            [types.requirementType.NPCReputation] = true,
        }

        local truthTable = {
            [types.requirementType.PreviousDialogChoice] = true,
        }

        for _, reqBlock in pairs(stageData.requirements or {}) do
            local ret = requirementChecker.checkBlock(reqBlock, {
                ignoredTypes = ignoredTypes,
                threatErrorsAs = true,
                reference = ref,
                handleCustomActorReq = params.handleCustomActorReq,
            })

            if ret then return true end
        end

    end

    return false
end


---@param diaId string
---@return table<string, questDataGenerator.questData>
function this.getQuestMainDialogueIdsMap(diaId)
    local diaIdLower = diaId:lower()

    -- local cachedVal = cacheLib.get("mainDiaIds", diaId)
    -- if cachedVal ~= nil then return cachedVal end

    local questData = this.getQuestData(diaIdLower)
    if not questData then return {} end

    local out = {}

    if not questData.links then
        out[diaId] = questData
        -- cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    local questDias = {}

    local function addDia(id, qDt)
        local indexes = this.getIndexes(qDt) or {}
        local indCnt = #indexes

        table.insert(questDias, {id = id, qd = qDt, ind = indexes, indCnt = indCnt})
    end

    addDia(diaIdLower, questData)

    for _, link in pairs(questData.links) do
        local linkDt = this.getQuestData(link)
        if not linkDt then goto continue end

        addDia(link, linkDt)

        ::continue::
    end

    local diaCount = #questDias
    if diaCount == 1 then
        out[questDias[1].id] = questDias[1].qd
        -- cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    table.sort(questDias, function (a, b)
        return a.indCnt > b.indCnt
    end)

    local hasFinished = false
    local firstStageCount

    for i, dt in ipairs(questDias) do
        local first = dt.qd[tostring(dt.ind[1] or "")]
        if first and first.restart and dt.indCnt > 1 then
            out[dt.id] = dt.qd
        else
            firstStageCount = firstStageCount or dt.indCnt
        end
    end

    firstStageCount = firstStageCount or 0

    for i = diaCount, 1, -1 do
        local dt = questDias[i]
        if dt then
            if dt.indCnt * 2 <= firstStageCount or dt.indCnt <= 1 then
                questDias[i] = nil
            else
                hasFinished = dt.qd.hasFinished or hasFinished
            end
        end
    end

    diaCount = #questDias
    if diaCount == 1 then
        out[questDias[1].id] = questDias[1].qd
        -- cacheLib.set("mainDiaIds", diaId, out)
        return out
    end

    if hasFinished then
        for _, dt in pairs(questDias) do
            if dt.qd.hasFinished then
                out[dt.id] = dt.qd
            end
        end
    else
        for _, dt in pairs(questDias) do
            out[dt.id] = dt.qd
        end
    end


    -- cacheLib.set("mainDiaIds", diaId, out)
    return out
end


---@param ref tes3reference
---@return table<string, string>? diaIds by diaId - quest name
---@return boolean? isGiver
---@return boolean? activatedByScript
function this.getGiverQuests(ref)
    local diaIds = {}
    local activatedByScript
    local isGiver = false

    local function checkId(id, byScript)
        if not id then return end

        local objectData = this.getObjectData(id)
        if not objectData or not objectData.starts then return end

        isGiver = true

        for _, diaId in pairs(objectData.starts) do
            local diaIdLower = diaId:lower()

            if not this.getQuestMainDialogueIdsMap(diaIdLower)[diaIdLower] then goto continue end

            if config.data.tracking.giver.hideStarted and (playerQuests.getCurrentIndex(diaIdLower) or 0) > 0 then goto continue end

            local questData = this.getQuestData(diaIdLower)
            if not questData or not questData.name then goto continue end

            for _, linkId in pairs(questData.links or {}) do
                if (playerQuests.getCurrentIndex(linkId) or 0) > 0 then goto continue end
            end

            local firstIndexStr = this.getFirstIndex(questData)
            if not firstIndexStr then goto continue end
            if not this.checkConditionsForQuest(diaIdLower, firstIndexStr, ref, {handleCustomActorReq = true}) then
                goto continue
            end

            diaIds[diaId] = questData.name
            if byScript then
                activatedByScript = true
            end

            ::continue::
        end
    end

    checkId(ref.baseObject.id:lower())
    local script = ref.baseObject.script
    if script then
        checkId(script.id:lower(), true)
    end

    if not next(diaIds) then return nil, isGiver, activatedByScript end
    return diaIds, true, activatedByScript
end


---@param objData questDataGenerator.objectInfo
---@param maxNames integer
---@return string[]
function this.getObjectPositionDescription(objData, maxNames)
    local approxEnabled = config.data.tracking.approx.enabled

    local descriptions = {}
    for _, posDt in pairs(objData.positions) do
        local x = posDt.pos[1]
        local y = posDt.pos[2]
        local z = posDt.pos[3]

        local descr

        if posDt.name then
            local cell = tes3.getCell{id = posDt.name}
            if cell then
                local exCellPos, doorPath, cellPath, isExterior, checkedCells = cellLib.findExitPos(cell)
                if exCellPos then

                    if cellPath then

                        if not approxEnabled then
                            for i = #cellPath, 1, -1 do
                                descr = descr and string.format("%s => \"%s\"", descr, cellPath[i].displayName) or
                                    string.format("\"%s\"", cellPath[i].displayName)
                            end
                        else
                            local lastIndex = #cellPath
                            if #cellPath > 1 then
                                local regionName = cellPath[lastIndex].displayName
                                regionName = regionName == "" and "???" or regionName
                                descr = string.format("\"%s\"", regionName)
                                descr = descr .. string.format(" => \"%s\"", cellPath[lastIndex - 1].displayName)
                            else
                                descr = string.format("\"%s\"", cellPath[1].displayName)
                            end
                        end
                    end

                else
                    if cellPath then

                        if not approxEnabled then
                            local list = {}
                            local count = 0
                            for cl, c in pairs(checkedCells) do
                                table.insert(list, c.displayName or c.id)
                                count = count + 1
                            end
                            table.shuffle(list, count)
                            descr = string.format("\"%s\", %s", cell.displayName, stringLib.getValueEnumString(list, maxNames, "Reachable from %s"))
                        else
                            descr = string.format("\"%s\"", cell.displayName)
                        end
                    end
                end
            end
        elseif posDt.grid then
            local cell = tes3.getCell{x = posDt.grid[1], y = posDt.grid[2]}
            if cell then
                descr = approxEnabled and cell.displayName or cell.editorName
            end
        end

        if descr then
            table.insert(descriptions, descr)
        end
    end

    return descriptions
end

return this