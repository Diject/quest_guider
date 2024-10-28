local dataHandler = include("diject.quest_guider.dataHandler")
local questLib = include("diject.quest_guider.quest")
local log = include("diject.quest_guider.utils.log")

local this = {}

---@param data questDataGenerator.requirementData
local function getRequirementDataHash(data)
    local ret = ""
    for name, _ in pairs(data) do
        ret = ret..name
    end
    return ret
end

function this.descriptionLines()
    local descriptionLines = include("diject.quest_guider.descriptionLines")
    ---@type table<string, table<string, questDataGenerator.requirementData>>
    local types = {}

    local reqTypeNum = 0
    local knownNum = 0

    for qId, qStages in pairs(dataHandler.quests) do

        for _, qData in pairs(qStages) do
            if qId == "name" then
                goto continue
            end

            for _, reqBlock in pairs(qData.requirements or {}) do
                for _, req in pairs(reqBlock) do
                    reqTypeNum = reqTypeNum + 1
                    if descriptionLines[req.type] then
                        knownNum = knownNum + 1
                    end

                    local reqTypeList = types[req.type]
                    if not reqTypeList then
                        types[req.type] = {}
                        reqTypeList = types[req.type]
                    end
                    reqTypeList[getRequirementDataHash(req)] = req
                end
            end

            ::continue::
        end
    end

    for tp, _ in pairs(types) do
        if not descriptionLines[tp] then
            log("Not found:", tp)
        end
    end
    log("Found requirements:", reqTypeNum)
    log("Known requirements:", knownNum)
    log("Coverage:", knownNum / reqTypeNum)

    for type, data in pairs(types) do
        print("")
        print("")
        log("Type:", type)
        print("")
        for _, req in pairs(data) do
            local resData = questLib.getDescriptionDataFromDataBlock({req})
            log(resData[1].str) ---@diagnostic disable-line: need-check-nil
            print("")
            log(req)
        end
    end
end

return this