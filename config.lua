local tableLib = include("diject.quest_guider.utils.table")
local log = include("diject.quest_guider.utils.log")

local storageName = "Quest_Guider_Config"

local version = 4

local this = {}

this.firstInit = true

---@class questGuider.config
this.default = {
    version = version,
    main = {
        enabled = true,
        helpLabels = true,
        iconProfile = "default",
    },
    journal = {
        enabled = true,
        info = {
            enabled = true,
            tooltip = true,
        },
        requirements = {
            enabled = true,
            tooltip = true,
            currentByDefault = true,
            scriptValues = true,
            pathDescriptions = 5,
        },
        map = {
            enabled = true,
            tooltip = true, -- deprecated
            maxScale = 3,
            marker = {
                alpha = 0.9,
                zoneAlpha = 0.6,
            },
        },
        objectNames = 3,
    },
    map = {
        enabled = true,
        showJournalTextTooltip = true,
    },
    tooltip = {
        width = 400,
        object = {
            enabled = true,
            changeTitleForTracked = true,
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
            maxPositions = 20,
            minChance = 0.1,
        }
    },
    tracking = {
        quest = {
            enabled = true,
            finished = false, -- autotrack finished
            oneEntryDialogues = false, -- new, local
            sideBranches = false, -- new, local
        },
        maxPositions = 20,
        minChance = 0.5, -- do not track parent objects with a chance to get less than this value
        maxCellDepth = 12,
        hideObtained = true,
        hideKilled = true,
        hideFinActors = true,
        showJournalTextOnMarker = true,
        onlyOneMarkerToInterior = false,
        approx = {
            enabled = false,
            worldMap = {
                radius = 20000,
            },
            interior = {
                enabled = true,
                radius = 600,
                minCellDepth = 4,
            },
        },
        giver = {
            enabled = true,
            hideStarted = true,
            namesMax = 3,
            filter = true, -- deprecated
        },
        marker = {
            alpha = 0.9,
            zoneAlpha = 0.25,
        },
    },
    integration = {
        questLogMenu = {
            enabled = true,
            tooltip = true,
            hideHidden = true,
        },
    },
    init = {
        ignoreDataChanges = false,
    },
    data = {
        maxPos = 20,
    },
}

this.protected = {
    tracking = {
        interior = {
            depthConut = 2,
            depthMaxDifference = 3,
        },
    },
}

---@class questGuider.config
this.data = mwse.loadConfig(storageName)


function this.save()
    this.data.version = version
    mwse.saveConfig(storageName, this.data)
end


if this.data then
    if not this.data.version then -- for old versions
        if this.data.journal.map.enabled then
            this.data.journal.requirements.enabled = true
        end
        this.save()

    elseif this.data.version == 3 then
        if this.data.tracking.minChance < 0.5 then
            this.data.tracking.minChance = 0.5
        end
        if this.data.data.maxPos > 20 then
            this.data.data.maxPos = 20
        end
        if this.data.tooltip.tracking.maxPositions > 20 then
            this.data.tooltip.tracking.maxPositions = 20
        end

        this.save()
    end

    tableLib.addMissing(this.data, this.default)
    this.firstInit = false
else
    this.data = table.deepcopy(this.default)
    mwse.saveConfig(storageName, this.data)
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