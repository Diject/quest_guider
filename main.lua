local dataHandler = include("diject.quest_guider.dataHandler")
local config = include("diject.quest_guider.config")
local questLib = include("diject.quest_guider.quest")
local log = include("diject.quest_guider.utils.log")
local storage = include("diject.quest_guider.storage.localStorage")
local tracking = include("diject.quest_guider.tracking")
local playerQuests = include("diject.quest_guider.playerQuests")
local tooltipUI = include("diject.quest_guider.UI.tooltips")
local journalUI = include("diject.quest_guider.UI.journal")
local mapUI = include("diject.quest_guider.UI.map")
local dataGeneratoUI = include("diject.quest_guider.UI.dataGenerator")


--- @param e uiActivatedEventData
local function uiJournalActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.enabled or not config.data.journal.enabled then return end

    if e.newlyCreated then
        journalUI.updateJournalMenu()

        e.element:registerAfter(tes3.uiEvent.update, function (ei)
            journalUI.updateJournalMenu()
        end)
    end
end

--- @param e uiActivatedEventData
local function uiMapActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.enabled or not config.data.map.enabled then return end

    if e.newlyCreated then
        mapUI.updateMapMenu()
    end
end

--- @param e loadEventData
local function loadCallback(e)
    storage.reset()
    tracking.reset()
    playerQuests.reset()
end

--- @param e loadedEventData
local function loadedCallback(e)
    if not storage.isPlayerStorageReady() then
        storage.initPlayerStorage()
    end
    tracking.isInit()
    playerQuests.init()
end

--- @param e journalEventData
local function journalCallback(e)
    if not dataHandler.isReady() or not config.data.enabled then return end

    local topic = e.topic
    if topic.type ~= tes3.dialogueType.journal then return end

    local questId = e.topic.id:lower()

    playerQuests.updateIndex(questId, e.index)

    if config.data.tracking.quest.enabled then
        tracking.trackQuestFromCallback(questId, e)
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if not e.object and not e.reference then return end
    if not dataHandler.isReady() or not config.data.enabled then return end

    local shouldUpdate = false

    if e.reference and e.object.objectType == tes3.objectType.door then
        if config.data.tooltip.door.enabled then
            shouldUpdate = shouldUpdate or tooltipUI.drawDoorTooltip(e.tooltip, e.reference)
        end
    else
        if config.data.tooltip.object.enabled then
            shouldUpdate = shouldUpdate or tooltipUI.drawObjectTooltip(e.tooltip, e.reference and e.reference.baseObject.id or e.object.id)
        end
    end

    if shouldUpdate then
        e.tooltip:getTopLevelMenu():updateLayout()
    end
end

--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.enabled then return end

    playerQuests.init()
    tracking.isInit()

    if config.data.tracking.giver.enabled then
        tracking.createQuestGiverMarkers(e.cell)
    end
end

--- @param e enterFrameEventData
local function afterInitCallback(e)
    if config.data.enabled and config.compareGameFileData() then
        local isDataEmpty = config.isGameFileDataEmpty()
        dataGeneratoUI.createMenu{ dataChangedMessage = not isDataEmpty, dataNotExistsMessage = isDataEmpty }
    end
    event.unregister(tes3.event.enterFrame, afterInitCallback)
end

local function initCallbacks()
    event.register(tes3.event.load, loadCallback)
    event.register(tes3.event.loaded, loadedCallback)
    event.register(tes3.event.uiActivated, uiJournalActivatedCallback, {filter = "MenuJournal"})
    event.register(tes3.event.uiActivated, uiMapActivatedCallback, {filter = "MenuMap"})
    event.register(tes3.event.journal, journalCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    event.register(tes3.event.cellActivated, cellActivatedCallback)
    event.register(tes3.event.enterFrame, afterInitCallback)
end

--- @param e initializedEventData
local function initializedCallback(e)
    if not dataHandler.init() then return end
    journalUI.init()
    initCallbacks()
end
event.register(tes3.event.initialized, initializedCallback)