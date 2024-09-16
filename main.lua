local dataHandler = include("diject.quest_guider.dataHandler")

local config = include("diject.quest_guider.config")

local markers = require("diject.map_markers.interop")

local questLib = include("diject.quest_guider.quest")

local ui = include("diject.quest_guider.ui")

local log = include("diject.quest_guider.utils.log")


--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if e.newlyCreated then
        ui.updateJournalMenu()

        e.element:registerAfter(tes3.uiEvent.update, function (ei)
            ui.updateJournalMenu()
        end)
    end
end



--- @param e initializedEventData
local function initializedCallback(e)
    if not dataHandler.init() then return end
    ui.init()
    event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuJournal"})
end
event.register(tes3.event.initialized, initializedCallback)