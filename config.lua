local tableLib = include("diject.quest_guider.utils.table")
local log = include("diject.quest_guider.utils.log")

local storageName = "Quest_Guider_Config"

local this = {}

---@class questGuider.config
this.default = {
    main = {
        enabled = true,
    },
    journal = {
        enabled = true,
        info = {
            enabled = true,
        },
        requirements = {
            enabled = true,
            currentByDefault = false,
            scriptValues = true,
        },
        map = {
            enabled = true,
            maxScale = 3,
        },
    },
    map = {
        enabled = true,
    },
    tooltip = {
        width = 400,
        object = {
            enabled = true,
            invNamesMax = 3,
            startsNamesMax = 3,
        },
        door = {
            enabled = true,
            starterNames = 3,
            starterQuestNames = 3,
            objectNames = 3,
            npcNames = 3,
        },
        tracking = {
            maxPositions = 50,
        }
    },
    tracking = {
        quest = {
            enabled = true,
        },
        maxPositions = 20,
        giver = {
            enabled = true,
            hideStarted = true,
            namesMax = 3,
        },
    },
    init = {

    },
    gameFiles = {

    },
}

---@class questGuider.config
this.data = mwse.loadConfig(storageName)

if this.data then
    tableLib.addMissing(this.data, this.default)
else
    this.data = table.deepcopy(this.default)
    mwse.saveConfig(storageName, this.data)
end


function this.save()
    mwse.saveConfig(storageName, this.data)
end


function this.updateGameFileData()
    this.data.gameFiles = {}
    for _, gameFile in pairs(tes3.dataHandler.nonDynamicData.activeMods) do
        if gameFile.playerName == "" then
            this.data.gameFiles[gameFile.filename] = true
        end
    end
end

function this.isGameFileDataEmpty()
    return table.size(this.data.gameFiles) == 0
end

---@return boolean ret returns true if the data changed
function this.compareGameFileData()
    local ret = false
    local compareArray = table.copy(this.data.gameFiles)
    for _, gameFile in pairs(tes3.dataHandler.nonDynamicData.activeMods) do
        if gameFile.playerName == "" then
            compareArray[gameFile.filename] = true
        end
    end

    if table.size(compareArray) ~= table.size(this.data.gameFiles) then
        ret = ret or true
    end

    return ret
end

---@param path string
---@return any
function this.getValueByPath(path)
    return tableLib.getValueByPath(this.data, path)
end

---@param path string
---@param newValue any
---@return boolean success
function this.setValueByPath(path, newValue)
    return tableLib.setValueByPath(this.data, path, newValue)
end

return this