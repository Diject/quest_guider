local dataHandler = include("diject.quest_guider.dataHandler")
local config = include("diject.quest_guider.config")
local questLib = include("diject.quest_guider.quest")
local ui = include("diject.quest_guider.ui")
local log = include("diject.quest_guider.utils.log")
local storage = include("diject.quest_guider.storage.localStorage")
local tracking = require("diject.quest_guider.tracking")
local tooltipUI = require("diject.quest_guider.UI.tooltips")


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

--- @param e journalEventData
local function journalCallback(e)
    local topic = e.topic
    if topic.type ~= tes3.dialogueType.journal then return end

    local questId = e.topic.id:lower()

    local shouldUpdate = false

    local questTrackingData = tracking.getQuestData(questId)
    if questTrackingData then
        tracking.removeMarker{ questId = questId }
        shouldUpdate = true
    end

    local questNextIndexes = questLib.getNextIndexes(questId, e.index)

    if not questNextIndexes or e.info.isQuestFinished then
        tracking.removeMarker{ questId = questId }
        tracking.updateMarkers(true)
    elseif questNextIndexes then
        for _, indexStr in pairs(questNextIndexes) do
            tracking.addMarkersForQuest{ questId = questId, questIndex = indexStr }
        end
        shouldUpdate = true
    end

    if shouldUpdate then
        tracking.updateMarkers(true)
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if not e.object and not e.reference then return end
    log(e)
    local shouldUpdate = false

    if e.reference and e.object.objectType == tes3.objectType.door then
        shouldUpdate = shouldUpdate or tooltipUI.drawDoorTooltip(e.tooltip, e.reference)
    else
        shouldUpdate = shouldUpdate or tooltipUI.drawObjectTooltip(e.tooltip, e.reference and e.reference.baseObject.id or e.object.id)
    end

    if shouldUpdate then
        e.tooltip:getTopLevelMenu():updateLayout()
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    if not dataHandler.init() then return end
    ui.init()
    event.register(tes3.event.load, loadCallback)
    event.register(tes3.event.loaded, loadedCallback)
    event.register(tes3.event.uiActivated, uiJournalActivatedCallback, {filter = "MenuJournal"})
    event.register(tes3.event.uiActivated, uiMapActivatedCallback, {filter = "MenuMap"})
    event.register(tes3.event.journal, journalCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
end
event.register(tes3.event.initialized, initializedCallback)