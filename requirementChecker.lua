local log = require("diject.quest_guider.utils.log")
local playerQuests = include("diject.quest_guider.playerQuests")
local stringLib = include("diject.quest_guider.utils.string")
local types = include("diject.quest_guider.types")
local operator = types.operator
local dataHandler = include("diject.quest_guider.dataHandler")

local this = {}


---@type table<string, fun(req:questDataGenerator.requirementData, obj:tes3object|tes3npc, mobile:tes3mobileNPC|tes3mobileCreature, ref:tes3reference):boolean?>
local dataFuncs = {
    [types.requirementType.Journal] = function (req)
        if not req.variable then return end
        local plIndex = playerQuests.getCurrentIndex(req.variable) or 0
        return operator.check(plIndex, req.value, req.operator)
    end,

    [types.requirementType.CustomActorFaction] = function (req, obj)
        local faction = tes3.getFaction(req.value)
        if not faction then return end
        if not obj then return end
        if not obj.faction then return end
        return operator.check(obj.faction.id:lower(), req.value, req.operator)
    end,

    [types.requirementType.CustomPCFaction] = function (req)
        local faction = tes3.getFaction(req.value)
        if not faction then return end
        local factionId = ""
        if faction.playerJoined then
            factionId = faction.id:lower()
        end
        return operator.check(factionId, req.value, req.operator)
    end,

    [types.requirementType.RankRequirement] = function (req, obj)
        if not req.variable then return end
        local object = req.object and tes3.getObject(req.object) or obj
        if not object then return end

        if not object or not object.faction or not object.factionRank then return end
        if object.faction.id:lower() ~= req.variable then return false end
        return operator.check(object.factionRank, req.value, req.operator)
    end,

    [types.requirementType.CustomPCRank] = function (req)
        if not req.variable then return end
        local faction = tes3.getFaction(req.variable)
        if not faction then return end
        return operator.check(faction.playerRank, req.value, req.operator)
    end,

    [types.requirementType.Dead] = function (req)
        if not req.variable then return end
        local obj = tes3.getObject(req.variable)
        if not obj or not (obj.objectType == tes3.objectType.creature or obj.objectType == tes3.objectType.npc) then return end
        local kilCount = tes3.getKillCount{ actor = obj }
        return operator.check(kilCount, req.value, req.operator)
    end,

    [types.requirementType.CustomOnDeath] = function (req, obj)
        if not req.object and not obj then return end
        obj = obj or tes3.getObject(req.object)
        if not obj or not (obj.objectType == tes3.objectType.creature or obj.objectType == tes3.objectType.npc) then return end
        local kilCount = tes3.getKillCount{ actor = obj }
        return operator.check(kilCount, req.value, req.operator)
    end,

    [types.requirementType.Item] = function (req, obj, mobile)
        if not req.variable and not (req.object or mobile) then return end
        local item = tes3.getObject(req.variable)
        if not item or not item.isCarriable then return end
        local itemCount
        if req.object == "player" then
            itemCount = tes3.getItemCount{ reference = tes3.mobilePlayer, item = item }
        elseif mobile then
            itemCount = tes3.getItemCount{ reference = mobile, item = item }
        end
        if not itemCount then return end
        return operator.check(itemCount, req.value, req.operator)
    end,

    [types.requirementType.CustomGlobal] = function (req)
        if req.object or not req.variable then return end
        local var = tes3.dataHandler.nonDynamicData:findGlobalVariable(req.variable)
        if not var then return end
        return operator.check(var.value, req.value, req.operator)
    end,

    [types.requirementType.CustomLocal] = function (req, obj, mobile, ref)
        if not req.variable or not ref then return end
        local baseObj = ref.baseObject
        if req.script and baseObj.script.id:lower() ~= req.script then return false end
        if req.object and baseObj.id:lower() ~= req.object then return false end
        if not ref.context then return end
        local val = ref.context[req.value]
        if not val then return false end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.CustomNotLocal] = function (req, obj, mobile, ref)
        if not req.variable or not ref then return end
        local baseObj = ref.baseObject
        if req.script and baseObj.script.id:lower() ~= req.script then return false end
        if req.object and baseObj.id:lower() ~= req.object then return false end
        if not ref.context then return end
        local val = ref.context[req.value]
        if not val then return true end

        return false
    end,

    [types.requirementType.CustomDialogue] = function (req)
        if not req.variable then return end
        if not tes3.mobilePlayer then return end
        local dialogueId = stringLib.convertDialogueName(req.variable)
        for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
            if dialogueId == dia.id:lower() then
                return operator.check(true, true, req.operator)
            end
        end
        return operator.check(false, true, req.operator)
    end,

    [types.requirementType.NotActorID] = function (req, obj, mobile, ref)
        if not req.variable or not (obj or mobile or ref) then return end
        local id = obj and obj.id or (mobile and mobile.reference or ref).baseObject.id
        return not operator.check(id, req.variable, req.operator)
    end,

    [types.requirementType.PlayerExpelledFromNPCFaction] = function (req, obj, mobile, ref)
        if not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        local res = object.faction.playerExpelled and 1 or 0

        return operator.check(res, req.value, req.operator)
    end,

    [types.requirementType.NPCSameFactionAsPlayer] = function (req, obj, mobile, ref)
        if not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        local res = object.faction.playerJoined and 1 or 0

        return operator.check(res, req.value, req.operator)
    end,

    [types.requirementType.ValueFLTV] = function (req, obj, mobile, ref)
        if not req.variable or not req.value or not ref then return end

        if not ref.context then return end
        local val = ref.context[req.variable]
        if not val then return false end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.NotActorClass] = function (req, obj, mobile, ref)
        if not req.variable or not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj

        local val = object.class.id:lower() ~= req.variable and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.NotActorCell] = function (req, obj, mobile, ref)
        if not req.variable or not req.value or not (ref or not mobile) then return end

        ref = ref or mobile.reference

        local val = string.sub(ref.cell.editorName, 1, #req.value):lower() ~= req.value and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.CustomActorCell] = function (req, obj, mobile, ref)
        if not req.variable or not req.value or not (ref or not mobile) then return end

        ref = ref or mobile.reference

        local val = string.sub(ref.cell.editorName, 1, #req.value):lower() == req.value and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.CustomPCCell] = function (req, obj, mobile, ref)
        if not req.value or not req.variable then return end

        local val = string.sub(tes3.player.cell.editorName, 1, #req.value):lower() == req.value and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.NPCHealthPercent] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end

        local health = mobile.health
        local val = health.current / health.base * 100

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerRankMinusNPCRank] = function (req, obj, mobile, ref)
        if not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        local faction = object.faction

        local plRank = faction.playerRank or 0
        local rank = object.factionRank

        return operator.check(plRank - rank, req.value, req.operator)
    end,

    [types.requirementType.NotActorRace] = function (req, obj, mobile, ref)
        if not req.variable or not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        if not object.race then return end

        local val = object.race.id:lower() ~= req.variable and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerHealthPercent] = function (req, obj, mobile, ref)
        if not req.value then return end

        local health = tes3.mobilePlayer.health
        local val = health.current / health.base * 100

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerIsVampire] = function (req, obj, mobile, ref)
        if not req.value then return end

        local res = tes3.mobilePlayer.hasVampirism and 1 or 0

        return operator.check(res, req.value, req.operator)
    end,

    [types.requirementType.PlayerCrimeLevel] = function (req, obj, mobile, ref)
        if not req.value then return end
        return operator.check(tes3.mobilePlayer.bounty, req.value, req.operator)
    end,

    [types.requirementType.NPCSameGenderAsPlayer] = function (req, obj, mobile, ref)
        if not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj

        local val = object.female == tes3.player.object.female and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.CustomSkill] = function (req, obj, mobile, ref)
        if not req.value or not req.skill then return end
        if req.object == "player" then
            mobile = tes3.mobilePlayer
        end
        if mobile then return end

        local skill = mobile.skills[req.skill + 1]
        if not skill then return end

        return operator.check(skill.current, req.value, req.operator)
    end,

    [types.requirementType.CustomAttribute] = function (req, obj, mobile, ref)
        if not req.value or not req.attribute then return end
        if req.object == "player" then
            mobile = tes3.mobilePlayer
        end
        if mobile then return end

        local attribute = mobile.attributes[req.attribute + 1]
        if not attribute then return end

        return operator.check(attribute.current, req.value, req.operator)
    end,

    [types.requirementType.PlayerClothingModifier] = function (req, obj, mobile, ref)
        if not req.value then return end

        local val = 0
        for slot, item in pairs(tes3.player.object.equipment) do
            val = val + item.object.value
        end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.NPCSameRaceAsPlayer] = function (req, obj, mobile, ref)
        if not req.value or not (ref or obj or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        if not object.race then return end

        local val = object.race.id == tes3.player.object.race.id and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerGender] = function (req, obj, mobile, ref)
        if not req.value then return end

        local val = tes3.player.object.female and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerLevel] = function (req, obj, mobile, ref)
        if not req.value then return end
        return operator.check(tes3.player.object.level, req.value, req.operator)
    end,

    [types.requirementType.Weather] = function (req, obj, mobile, ref)
        if not req.value then return end

        local weatherId = tes3.getCurrentWeather().index

        return operator.check(weatherId, req.value, req.operator)
    end,

    [types.requirementType.NPCReputation] = function (req, obj, mobile, ref)
        if not req.value or not (ref or mobile) then return end

        local object = ref.object or mobile.reference.object

        return operator.check(object.disposition, req.value, req.operator)
    end,

    [types.requirementType.PlayerHealth] = function (req, obj, mobile, ref)
        if not req.value then return end

        local health = tes3.mobilePlayer.health

        return operator.check(health.current, req.value, req.operator)
    end,

    [types.requirementType.NPCFlee] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end

        local id = mobile.reference.baseObject.id

        if req.object and id ~= req.object then return false end

        return operator.check(mobile.flee, req.value, req.operator)
    end,

    [types.requirementType.NPCHello] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end

        local id = mobile.reference.baseObject.id

        if req.object and id ~= req.object then return false end

        return operator.check(mobile.hello, req.value, req.operator)
    end,

    [types.requirementType.NPCAlarm] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end

        local id = mobile.reference.baseObject.id

        if req.object and id ~= req.object then return false end

        return operator.check(mobile.alarm, req.value, req.operator)
    end,

    [types.requirementType.NPCFight] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end

        local id = mobile.reference.baseObject.id

        if req.object and id ~= req.object then return false end

        return operator.check(mobile.fight, req.value, req.operator)
    end,

    [types.requirementType.NPCLevel] = function (req, obj, mobile, ref)
        if not req.value or not (mobile or ref) then return end

        local object = ref.object or mobile.reference.object
        local id = obj and obj.id or ref and ref.baseObject.id or mobile and mobile.reference.baseObject.id

        if req.object and id ~= req.object then return false end

        return operator.check(object.level, req.value, req.operator)
    end,

    [types.requirementType.NPCIsWerewolf] = function (req, obj, mobile, ref)
        if not req.value or not mobile then return end
         if req.object == "player" then
            mobile = tes3.mobilePlayer
        end

        if req.object and mobile.reference.baseObject.id ~= req.object then return false end

        local val = mobile.werewolf and 1 or 0

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.NotActorFaction] = function (req, obj, mobile, ref)
        if not req.value or not req.variable or not (obj or ref or mobile) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj

        local val = object.faction and object.faction.id:lower() == req.variable and 0 or 1

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerCommonDisease] = function (req, obj, mobile, ref)
        if not req.value then return end

        local val = 0
        for _, spell in pairs(tes3.player.object.spells) do
            val = spell.castType == tes3.spellType.disease and 1 or 0
            if val == 1 then break end
        end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerBlightDisease] = function (req, obj, mobile, ref)
        if not req.value then return end

        local val = 0
        for _, spell in pairs(tes3.player.object.spells) do
            val = spell.castType == tes3.spellType.blight and 1 or 0
            if val == 1 then break end
        end

        return operator.check(val, req.value, req.operator)
    end,

    [types.requirementType.PlayerCorprus] = function (req, obj, mobile, ref)
        if not req.value then return end

        local val = 0
        for _, spell in pairs(tes3.player.object.spells) do
            val = spell.isCorprusDisease and 1 or 0
            if val == 1 then break end
        end

        return operator.check(val, req.value, req.operator)
    end,


    [types.requirementType.CustomDisposition] = function (req, obj, mobile, ref)
        if not req.value or not (ref or mobile) then return end

        local object = ref.object or mobile.reference.object

        return operator.check(object.disposition, req.value, req.operator)
    end,

    [types.requirementType.CustomRace] = function (req, obj, mobile, ref)
        if not req.variable or not (mobile or ref or obj) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        if not object then return end

        return operator.check(object.race.id:lower(), req.variable, req.operator)
    end,

    -- [types.requirementType.CustomActor] = function (req, obj, mobile, ref)
    --     if not req.object or not req.variable or not req.value or not ref then return end
    --     local dialogue = tes3.findDialogue{ topic = stringLib.convertDialogueName(req.variable) }
    --     if not dialogue then return end
    --     local dialogueInfo = tes3.getDialogueInfo{ dialogue = dialogue, id = req.value }
    --     if not dialogueInfo then return end

    --     return dialogueInfo:filter(ref.object, ref, 0, dialogue)
    -- end,

    -- In the current version, only checks the availability of the current dialogue topic or topics that unlock the current one
    [types.requirementType.CustomActor] = function (req, obj, mobile, ref)
        if not req.variable or not req.object or not (mobile or ref) then return end

        local object = ref and ref.baseObject or mobile and mobile.reference.baseObject or obj
        if not object then return end
        mobile = mobile or ref and ref.mobile

        if ref and req.object ~= object.id then
            return false
        end

        if req.variable:find("greeting", 1, true) then
            return true
        end

        local diaObjectDt = dataHandler.questObjects[req.variable]
        if not diaObjectDt then return true end

        if not diaObjectDt.links or not next(diaObjectDt.links) then
            return true
        end

        local playerTopics = {}
        for _, dia in pairs(tes3.mobilePlayer.dialogueList) do
            playerTopics[dia.id:lower()] = dia
        end

        local dialogueId = stringLib.convertDialogueName(req.variable)
        if playerTopics[dialogueId] then
            return true
        end

        local checkedObjects = {}

        for _, link in pairs(diaObjectDt.links) do
            local id = link[1]
            if checkedObjects[id] then goto continue end
            checkedObjects[id] = true

            local linkDt = dataHandler.questObjects[id]
            if not linkDt or linkDt.type ~= 6 or not linkDt.links or not next(linkDt.links) then goto continue end

            for _, l in pairs(linkDt.links) do
                local lId = l[1]
                if checkedObjects[lId] then goto continue end
                checkedObjects[lId] = true

                local lDt = dataHandler.questObjects[lId]
                if not lDt or lDt.type ~= 3 then goto continue end

                local dId = stringLib.convertDialogueName(lId)
                if dId:find("greeting", 1, true) then return true end

                local plDia = playerTopics[dId]
                if plDia then
                    local info =  plDia:getInfo{ actor = mobile }
                    if info then return true end
                end

                ::continue::
            end

            ::continue::
        end

        return false
    end,
}


---@param req questDataGenerator.requirementData
---@param reference tes3reference?
---@param object tes3npc|tes3creature|nil
---@param mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileActor|nil
---@return boolean?
function this.check(req, object, mobile, reference)
    local func = dataFuncs[req.type]
    if func then
        local status, res = pcall(func, req, object, mobile, reference)
        if not status then return end
        return res
    end
    return nil
end


local function isReqEssentialForCompleting(req)
    return req.type == types.requirementType.CustomGlobal and req.variable == "pcrace" or
            req.type == types.requirementType.CustomRace and req.object == "player" or
            req.type == types.requirementType.NPCSameGenderAsPlayer and req.object ~= nil
end


---@class questGuider.requirementChecker.checkForBlock.params
---@field reference tes3reference?
---@field object tes3npc|tes3creature|nil
---@field mobile tes3mobilePlayer|tes3mobileNPC|tes3mobileActor|nil
---@field ignoredTypes table<string, any>?
---@field allowedTypes table<string, any>?
---@field typeTruthTable table<string, boolean>?
---@field threatErrorsAs boolean?
---@field handleCustomActorReq boolean?

---@param block questDataGenerator.requirementData[]
---@param params questGuider.requirementChecker.checkForBlock.params
---@return boolean?
---@return questDataGenerator.requirementData[]? ignoredRequirements
---@return boolean? impossibleToComplete
function this.checkBlock(block, params)
    if not params then params = {} end
    if not params.ignoredTypes then params.ignoredTypes = {} end

    if params.handleCustomActorReq ~= true then
        params.ignoredTypes[types.requirementType.CustomActor] = true
    end

    local ignoredRequirements = {}
    local impossibleToComplete = false
    local res = true
    for _, req in pairs(block) do
        if not dataFuncs[req.type] then goto continue end

        if (params.ignoredTypes and params.ignoredTypes[req.type]) or
                (params.allowedTypes and not params.allowedTypes[req.type]) then
            table.insert(ignoredRequirements, req)
            goto continue
        end

        if params.typeTruthTable and params.typeTruthTable[req.type] then
            res = res and params.typeTruthTable[req.type]
            goto continue
        end

        local ref
        if req.object == "player" then
            ref = tes3.player
        else
            ref = params.reference
        end

        local r = this.check(req, params.object, params.mobile, params.reference)
        if r == false and isReqEssentialForCompleting(req) then
            impossibleToComplete = true
        end
        if r == nil and params.threatErrorsAs ~= nil then
            r = params.threatErrorsAs
        end

        res = res and r

        if not res then break end

        ::continue::
    end

    return res, ignoredRequirements, impossibleToComplete
end


---@param block questDataGenerator.requirementData[]
---@param params questGuider.requirementChecker.checkForBlock.params?
function this.isBlockCompletionPossible(block, params, player)
    for _, req in pairs(block) do
        if isReqEssentialForCompleting(req) then
            local ref
            if req.object == "player" then
                ref = player
            else
                ref = params and params.reference
            end
            local r = this.check(req, ref, player)
            if r == false then return false end
        end
    end

    return true
end


---@param reqBlock questDataGenerator.requirementBlock
---@param  filter table<string, any>? by requirement type id
---@param invert boolean?
---@return questDataGenerator.requirementBlock?
---@return integer count
function this.getFilterredRequirementBlock(reqBlock, filter, invert)
    local outReqBlock = {}
    local count = 0
    for _, req in pairs(reqBlock) do
        if not filter or filter[req.type] then
            local r = not invert and table.copy(req) or types.invertRequirement(table.copy(req))
            table.insert(outReqBlock, r)
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return outReqBlock, count
end

return this