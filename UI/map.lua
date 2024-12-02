local log = include("diject.quest_guider.utils.log")

local questLib = include("diject.quest_guider.quest")
local trackingLib = include("diject.quest_guider.tracking")
local tooltipLib = include("diject.quest_guider.UI.tooltipSys")

local config = include("diject.quest_guider.config")


local mapAddon = {
    buttonBlock = "qGuider_mapAddon_buttonBlock",
    showHideBtn = "qGuider_mapAddon_showHideBtn",
    removeAllBtn = "qGuider_mapAddon_removeAllBtn",
    scrollPane = "qGuider_mapAddon_scrollPane",
    trackingBlock = "qGuider_mapAddon_trackingBlock",
    questNameLabel = "qGuider_mapAddon_questNameLabel",
    questObjLabel = "qGuider_mapAddon_questObjLabel",
}

local this = {}

function this.updateMapMenu()
    if not trackingLib.isInit() then return end

    local menu = tes3ui.findMenu("MenuMap")
    if not menu then return end

    local menuWorld = menu:findChild("MenuMap_world")
    local menuLocal = menu:findChild("MenuMap_local")
    if not menuWorld or not menuLocal then return end

    local dragMenu = menu:findChild("PartDragMenu_main")
    if not dragMenu then return end

    local flowDirection = dragMenu.flowDirection

    local btnBlock = dragMenu:createBlock{ id = mapAddon.buttonBlock }
    btnBlock.autoHeight = true
    btnBlock.autoWidth = true
    btnBlock.absolutePosAlignX = 0
    btnBlock.absolutePosAlignY = 1
    btnBlock.flowDirection = tes3.flowDirection.leftToRight

    local trackedBtn = btnBlock:createButton{ id = mapAddon.showHideBtn, text = ">" }

    local removeAllBtn = btnBlock:createButton{ id = mapAddon.removeAllBtn, text = "Remove all" }
    removeAllBtn.visible = false

    local questPane = dragMenu:createVerticalScrollPane{ id = mapAddon.scrollPane }
    questPane.heightProportional = 1
    questPane.widthProportional = 0.75
    questPane.visible = false
    questPane.widget.scrollbarVisible = true

    dragMenu:reorderChildren(dragMenu.children[1], questPane, -1)

    ---@param parent tes3uiElement
    local function createTrackingBlock(parent, questId, trackingData)
        local questData = questLib.getQuestData(questId)
        if not questData then return end

        local block = parent:createBlock{ id = mapAddon.trackingBlock }
        block.autoHeight = true
        block.widthProportional = 1
        block.flowDirection = tes3.flowDirection.topToBottom
        block.borderBottom = 16

        local qNameLabel = block:createLabel{ id = mapAddon.questNameLabel, text = questData.name or "???" }
        qNameLabel.widthProportional = 1
        qNameLabel.wrapText = true
        qNameLabel.borderLeft = 10

        for objId, _ in pairs(trackingData.objects) do
            local object = tes3.getObject(objId)
            if not object then goto continue end
            local objectMarkerData = trackingLib.markerByObjectId[objId]
            if not objectMarkerData then goto continue end

            local markerColor = table.copy(objectMarkerData.color)

            local qDescrLabel = block:createLabel{ id = mapAddon.questObjLabel, text = object.name }
            qDescrLabel.widthProportional = 1
            qDescrLabel.wrapText = true
            qDescrLabel.borderLeft = 20
            qDescrLabel.color = markerColor

            if config.data.main.helpLabels then
                local tooltip = tooltipLib.new{parent = qDescrLabel}
                if config.data.main.helpLabels then
                    tooltip:add{name = "Click to remove."}
                end
            end

            qDescrLabel:register(tes3.uiEvent.mouseOver, function (e)
                local color = {1, 1, 1}
                qDescrLabel.color = color

                trackingLib.changeObjectMarkerColor(objId, color, 100)
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseLeave, function (e)
                qDescrLabel.color = markerColor
                trackingLib.changeObjectMarkerColor(objId, markerColor, 0)
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseClick, function (e)
                tes3.messageBox{
                    message = "Remove the marker?",
                    buttons = { "Yes", "No" },
                    showInDialog = false,
                    callback = function (e1)
                        if e1.button == 0 then
                            trackingLib.removeMarker{ objectId = objId }
                            trackingLib.updateMarkers(true)
                            qDescrLabel:getTopLevelMenu():updateLayout()
                        end
                    end,
                }
            end)

            ::continue::
        end
    end

    local function fillQuestPane()
        questPane:getContentElement():destroyChildren()
        for questId, trackingData in pairs(trackingLib.trackedObjectsByQuestId) do
            createTrackingBlock(questPane, questId, trackingData)
        end
        menu:updateLayout()
        questPane.widget:contentsChanged()
    end

    trackedBtn:register(tes3.uiEvent.mouseClick, function (e)
        questPane.visible = not questPane.visible
        trackedBtn.text = questPane.visible and "<" or ">"

        if questPane.visible then
            removeAllBtn.visible = true
            menuLocal.widthProportional = 2 - questPane.widthProportional
            menuWorld.widthProportional = 2 - questPane.widthProportional
            dragMenu.flowDirection = tes3.flowDirection.leftToRight
        else
            removeAllBtn.visible = false
            menuLocal.widthProportional = 1
            menuWorld.widthProportional = 1
            dragMenu.flowDirection = flowDirection
        end

        menu:updateLayout()
        questPane.widget:contentsChanged()
    end)

    removeAllBtn:register(tes3.uiEvent.mouseClick, function (e)
        trackingLib.removeMarkers()
        trackingLib.updateMarkers(true)
    end)

    trackingLib.callbackToUpdateMapMenu = fillQuestPane

    fillQuestPane()
end

return this