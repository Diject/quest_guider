local tableLib = include("diject.quest_guider.utils.table")

local storageName = "Quest_Guider_Config"

local this = {}

---@class questGuider.config
this.default = {
    enabled = true,
    journal = {
        enabled = true,
        info = {
            enabled = true,
        },
        requirements = {
            enable = true,
            currentByDefault = false,
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
        }
    },
    tracking = {
        quest = {
            enabled = true,
        },
        maxPositions = 50,
        giver = {
            enabled = true,
            namesMax = 3,
        },
    },
    init = {

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

return this