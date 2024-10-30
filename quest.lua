local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")

local types = include("diject.quest_guider.types")
local descriptionLines = include("diject.quest_guider.descriptionLines")

local dataHandler = include("diject.quest_guider.dataHandler")

local this = {}

local weaponTypeNameById = {
    [-1] = "unarmed",
    [0] = "short blade, one handed",
    [1] = "long blade, one handed",
    [2] = "long blade, two handed",
    [3] = "blunt, one handed",
    [4] = "blunt, two handed close",
    [5] = "blunt, two handed wide",
    [6] = "spear, two handed",
    [7] = "axe, one handed",
    [8] = "axe, two handed",
    [9] = "bow",
    [10] = "crossbow",
    [11] = "thrown weapon",
    [12] = "arrow",
    [13] = "bolt",
}

local magicEffectConsts = {
    ["seffectabsorbattribute"] = 85,
    ["seffectdrainfatigue"] = 20,
    ["seffectrestorefatigue"] = 77,
    ["seffectabsorbfatigue"] = 88,
    ["seffectdrainhealth"] = 18,
    ["seffectrestorehealth"] = 75,
    ["seffectabsorbhealth"] = 86,
    ["seffectdrainskill"] = 21,
    ["seffectrestoreskill"] = 78,
    ["seffectabsorbskill"] = 89,
    ["seffectdrainspellpoints"] = 19,
    ["seffectrestorespellpoints"] = 76,
    ["seffectabsorbspellpoints"] = 87,
    ["seffectextraspell"] = 126,
    ["seffectsanctuary"] = 42,
    ["seffectalmsiviintervention"] = 63,
    ["seffectfeather"] = 8,
    ["seffectshield"] = 3,
    ["seffectblind"] = 47,
    ["seffectfiredamage"] = 14,
    ["seffectshockdamage"] = 15,
    ["seffectboundbattleaxe"] = 123,
    ["seffectfireshield"] = 4,
    ["seffectsilence"] = 46,
    ["seffectboundboots"] = 129,
    ["seffectfortifyattackbonus"] = 117,
    ["seffectslowfall"] = 11,
    ["seffectboundcuirass"] = 127,
    ["seffectfortifyattribute"] = 79,
    ["seffectsoultrap"] = 58,
    ["seffectbounddagger"] = 120,
    ["seffectfortifyfatigue"] = 82,
    ["seffectsound"] = 48,
    ["seffectboundgloves"] = 131,
    ["seffectfortifyhealth"] = 80,
    ["seffectspellabsorption"] = 67,
    ["seffectboundhelm"] = 128,
    ["seffectfortifymagickamultiplier"] = 84,
    ["seffectstuntedmagicka"] = 136,
    ["seffectboundlongbow"] = 125,
    ["seffectfortifyskill"] = 83,
    ["seffectsummonancestralghost"] = 106,
    ["seffectboundlongsword"] = 121,
    ["seffectfortifyspellpoints"] = 81,
    ["seffectsummonbonelord"] = 110,
    ["seffectboundmace"] = 122,
    ["seffectfrenzycreature"] = 52,
    ["seffectsummoncenturionsphere"] = 134,
    ["seffectboundshield"] = 130,
    ["seffectfrenzyhumanoid"] = 51,
    ["seffectsummonclannfear"] = 103,
    ["seffectboundspear"] = 124,
    ["seffectfrostdamage"] = 16,
    ["seffectsummondaedroth"] = 104,
    ["seffectburden"] = 7,
    ["seffectfrostshield"] = 6,
    ["seffectsummondremora"] = 105,
    ["seffectcalmcreature"] = 50,
    ["seffectinvisibility"] = 39,
    ["seffectsummonflameatronach"] = 114,
    ["seffectcalmhumanoid"] = 49,
    ["seffectjump"] = 9,
    ["seffectsummonfrostatronach"] = 115,
    ["seffectchameleon"] = 40,
    ["seffectlevitate"] = 10,
    ["seffectsummongoldensaint"] = 113,
    ["seffectcharm"] = 44,
    ["seffectlight"] = 41,
    ["seffectsummongreaterbonewalker"] = 109,
    ["seffectcommandcreatures"] = 118,
    ["seffectlightningshield"] = 5,
    ["seffectsummonhunger"] = 112,
    ["seffectcommandhumanoids"] = 119,
    ["seffectlock"] = 12,
    ["seffectsummonleastbonewalker"] = 108,
    ["seffectcorpus"] = 132,
    ["seffectmark"] = 60,
    ["seffectsummonscamp"] = 102,
    ["seffectcureblightdisease"] = 70,
    ["seffectnighteye"] = 43,
    ["seffectsummonskeletalminion"] = 107,
    ["seffectcurecommondisease"] = 69,
    ["seffectopen"] = 13,
    ["seffectsummonstormatronach"] = 116,
    ["seffectcurecorprusdisease"] = 71,
    ["seffectparalyze"] = 45,
    ["seffectsummonwingedtwilight"] = 111,
    ["seffectcureparalyzation"] = 73,
    ["seffectpoison"] = 27,
    ["seffectsundamage"] = 135,
    ["seffectcurepoison"] = 72,
    ["seffectrallycreature"] = 56,
    ["seffectswiftswim"] = 1,
    ["seffectdamageattribute"] = 22,
    ["seffectrallyhumanoid"] = 55,
    ["seffecttelekinesis"] = 59,
    ["seffectdamagefatigue"] = 25,
    ["seffectrecall"] = 61,
    ["seffectturnundead"] = 101,
    ["seffectdamagehealth"] = 23,
    ["seffectreflect"] = 68,
    ["seffectvampirism"] = 133,
    ["seffectdamagemagicka"] = 24,
    ["seffectremovecurse"] = 100,
    ["seffectwaterbreathing"] = 0,
    ["seffectdamageskill"] = 26,
    ["seffectresistblightdisease"] = 95,
    ["seffectwaterwalking"] = 2,
    ["seffectdemoralizecreature"] = 54,
    ["seffectresistcommondisease"] = 94,
    ["seffectweaknesstoblightdisease"] = 33,
    ["seffectdemoralizehumanoid"] = 53,
    ["seffectresistcorprusdisease"] = 96,
    ["seffectweaknesstocommondisease"] = 32,
    ["seffectdetectanimal"] = 64,
    ["seffectresistfire"] = 90,
    ["seffectweaknesstocorprusdisease"] = 34,
    ["seffectdetectenchantment"] = 65,
    ["seffectresistfrost"] = 91,
    ["seffectweaknesstofire"] = 28,
    ["seffectdetectkey"] = 66,
    ["seffectresistmagicka"] = 93,
    ["seffectweaknesstofrost"] = 29,
    ["seffectdisintegratearmor"] = 38,
    ["seffectresistnormalweapons"] = 98,
    ["seffectweaknesstomagicka"] = 31,
    ["seffectdisintegrateweapon"] = 37,
    ["seffectresistparalysis"] = 99,
    ["seffectweaknesstonormalweapons"] = 36,
    ["seffectdispel"] = 57,
    ["seffectresistpoison"] = 97,
    ["seffectweaknesstopoison"] = 35,
    ["seffectdivineintervention"] = 62,
    ["seffectresistshock"] = 92,
    ["seffectweaknesstoshock"] = 30,
    ["seffectdrainattribute"] = 17,
    ["seffectrestoreattribute"] = 74,
}

local vampireClan = {
    [1] = "Aundae",
    [2] = "Berne",
    [3] = "Quarra",
}

local weatherById = {}

for name, id in pairs(tes3.weather) do
    weatherById[id] = name
end

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
        local script = requirement.script
        local environment = {
            object = object,
            value = value,
            variable = variable,
            operator = operator,
            script = script,
            skill = skill,
            attribute = attribute,
            objectObj = objectObj,
            variableObj = nil,
            valueObj = nil,
            variableQuestName = "???",
            valueStr = "???",
            variableStr = "???",
            weaponTypeName = weaponTypeNameById,
            magicEffectConsts = magicEffectConsts,
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
                local class = tes3.findClass(value)
                if class then
                    environment.valueObj = class
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
                elseif codeStr == "varQuestName" then
                    mapped[pattern] = environment.variableQuestName
                elseif codeStr == "objectName" then
                    mapped[pattern] = environment.objectObj and (environment.objectObj.name or "???") or "???"
                elseif codeStr == "valueName" then
                    mapped[pattern] = environment.valueObj and (environment.valueObj.name or "???") or "???"
                elseif codeStr == "varName" then
                    mapped[pattern] = environment.variableObj and (environment.variableObj.name or "???") or "???"
                elseif codeStr == "skillName" then
                    mapped[pattern] = environment.skill and (tes3.skillName[environment.skill] or "???") or "???"
                elseif codeStr == "attributeName" then
                    mapped[pattern] = environment.attribute and (tes3.attributeName[environment.attribute] or "???") or "???"
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
                    mapped[pattern] = weaponTypeNameById[environment.value] and weaponTypeNameById[environment.value] or tostring(environment.value)
                elseif codeStr == "operator" then
                    mapped[pattern] = types.operator.name[environment.operator]
                elseif codeStr == "notContr" then
                    mapped[pattern] = ((value==0 and operator==48) or (value==1 and operator==49) or (value==1 and operator==52)) and "n't" or ""
                elseif codeStr == "negNotContr" then
                    mapped[pattern] = ((value==1 and operator==48) or (value==0 and operator==49) or (value==0 and operator==50)) and "n't" or ""
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