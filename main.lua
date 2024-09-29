local dataHandler = include("diject.quest_guider.dataHandler")
local config = include("diject.quest_guider.config")
local markers = require("diject.map_markers.interop")
local questLib = include("diject.quest_guider.quest")
local ui = include("diject.quest_guider.ui")
local log = include("diject.quest_guider.utils.log")
local storage = include("diject.quest_guider.storage.localStorage")
local tracking = require("diject.quest_guider.tracking")


--- @param e uiActivatedEventData
local function uiJournalActivatedCallback(e)
    if e.newlyCreated then
        ui.updateJournalMenu()

        e.element:registerAfter(tes3.uiEvent.update, function (ei)
            ui.updateJournalMenu()
        end)
    end
end

--- @param e uiActivatedEventData
local function uiMapActivatedCallback(e)
    if e.newlyCreated then
        ui.updateMapMenu()
    end
end

--- @param e loadEventData
local function loadCallback(e)
    storage.reset()
    tracking.reset()
end

--- @param e loadedEventData
local function loadedCallback(e)
    if not storage.isPlayerStorageReady() then
        storage.initPlayerStorage()
    end
    tracking.isInit()
end

--- @param e initializedEventData
local function initializedCallback(e)
    if not dataHandler.init() then return end
    ui.init()
    event.register(tes3.event.load, loadCallback)
    event.register(tes3.event.loaded, loadedCallback)
    event.register(tes3.event.uiActivated, uiJournalActivatedCallback, {filter = "MenuJournal"})
    event.register(tes3.event.uiActivated, uiMapActivatedCallback, {filter = "MenuMap"})
end
event.register(tes3.event.initialized, initializedCallback)