local dataHandler = include("diject.quest_guider.dataHandler")

local markers = require("diject.world_map_markers.interop")

local questLib = include("diject.quest_guider.quest")

local ui = include("diject.quest_guider.ui")

local log = include("diject.quest_guider.utils.log")


local function registerTooltip()
    local menu = tes3ui.findMenu("MenuJournal")
    if not menu then return end

    for _, pageName in pairs({"MenuBook_page_1", "MenuBook_page_2"}) do
        local page = menu:findChild(pageName)

        if page then
            local isDescription = false
            for i, element in pairs(page.children) do
                local str = element.text:gsub("@", ""):gsub("#", ""):gsub("\n", " ")
                if element.name == "MenuBook_hypertext" then
                    if isDescription then
                        if dataHandler.questByText[str] then
                            local questId = dataHandler.questByText[str][1].quest
                            local questIndex = dataHandler.questByText[str][1].index
                            local quest = dataHandler.quests[questId]
                            if quest then
                                local rect = page:createRect{}
                                page:reorderChildren(element, rect, 1)
                                rect.flowDirection = tes3.flowDirection.leftToRight
                                rect.autoHeight = true
                                rect.autoWidth = true
                                rect.alpha = 0
                                local infoRect = rect:createRect{}
                                infoRect.alpha = 0
                                infoRect.autoHeight = true
                                infoRect.autoWidth = false
                                infoRect.borderRight = 5
                                local infoLabel = infoRect:createLabel{ text = "("..tostring(questIndex)..") "..(quest.name or ""), id = "QuestGuider_QuestNameLabel" }
                                infoLabel.color = {0.5,1,0.5}
                                infoLabel.alpha = 1
                                local reqLabel = rect:createLabel{ text = "req" }
                                reqLabel.color = {1,1,0.8}
                                reqLabel.borderRight = 5
                                reqLabel:register(tes3.uiEvent.help, function (ei)
                                    local tooltip = tes3ui.createTooltipMenu()
                                    ui.drawQuestRequirementsMenu(tooltip, questId, questIndex, quest)
                                end)
                                local trackingLabel = rect:createLabel{ text = "map" }
                                trackingLabel.color = {1,1,0.8}
                                trackingLabel:register(tes3.uiEvent.help, function (ei)
                                    local tooltip = tes3ui.createTooltipMenu()
                                    ui.drawMapMenu(tooltip, questId, questIndex, quest)
                                end)
                                trackingLabel:register(tes3.uiEvent.mouseClick, function (ei)
                                    local el = ui.drawContainer("Map")
                                    ui.drawMapMenu(el, questId, questIndex, quest)
                                    ui.centreToCursor(el)
                                end)

                                local testLabl = rect:createLabel{ text = "test" }
                                testLabl:register(tes3.uiEvent.mouseClick, function (ei)
                                    local el = ui.drawContainer("Test")
                                    ui.drawQuestsMenu(el)
                                    ui.centreToCursor(el)
                                end)

                                page:getTopLevelMenu():updateLayout()
                                infoRect.width = math.max(1, page.width - (trackingLabel.width + reqLabel.width + testLabl.width + 15))
                                infoLabel:register(tes3.uiEvent.help, function (ei)
                                    local tooltip = tes3ui.createTooltipMenu()
                                    ui.drawQuestInfoMenu(tooltip, questId, questIndex, quest)
                                end)
                            end
                        end
                    end
                    isDescription = not isDescription
                end
            end
            page:getTopLevelMenu():updateLayout()
        end
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    print("ui activated, element "..tostring(e.element).." new "..tostring(e.newlyCreated))
    if e.newlyCreated then
        registerTooltip()
        -- logChildrens(e.element)
        local btn = e.element:findChild("MenuBook_button_prev")
        btn:registerAfter(tes3.uiEvent.mouseClick, function (ei)
            registerTooltip()
        end)
        btn = e.element:findChild("MenuBook_button_next")
        btn:registerAfter(tes3.uiEvent.mouseClick, function (ei)
            registerTooltip()
        end)
        btn = e.element:findChild("MenuBook_button_take")
        btn:registerAfter(tes3.uiEvent.mouseClick, function (ei)
            registerTooltip()
        end)
        btn = e.element:findChild("MenuBook_button_close")
        btn:registerAfter(tes3.uiEvent.mouseClick, function (ei)
            registerTooltip()
        end)
    end
end



--- @param e initializedEventData
local function initializedCallback(e)
    if not dataHandler.init() then return end
    event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuJournal"})
end
event.register(tes3.event.initialized, initializedCallback)