local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")

local dataHandler = include("diject.quest_guider.dataHandler")

local questLib = include("diject.quest_guider.quest")
local cellLib = include("diject.quest_guider.cell")
local trackingLib = include("diject.quest_guider.tracking")


local infoMenu = {
    block = "qGuider_info_block",
    headerId = "qGuider_info_header",
    questidId = "qGuider_info_questId",
    indexId = "qGuider_info_index",
    nextIndexes = "qGuider_info_nextIndexes",
    currentIndex = "qGuider_info_currentIndex",
}

local requirementsMenu = {
    block = "qGuider_req_block",
    text = "qGuider_req_text",
    headerLabel = "qGuider_req_headerLabel",
    selectedCurrentBlock = "qGuider_req_selectedCurrentBlock",
    selectedLabel = "qGuider_req_selectedLabel",
    currentLabel = "qGuider_req_currentLabel",
    indexTabBlock = "qGuider_req_indexTabBlock",
    indexTabLabel = "qGuider_req_indexTabLabel",
    indexTab = "qGuider_req_indexTab",
    requirementBlock = "qGuider_req_requirementBlock",
    requirementLabel = "qGuider_req_requirementLabel",
    requirementIndexMainBlock = "qGuider_req_requirementIndexMainBlock",
    requirementIndexBlock = "qGuider_req_requirementIndexBlock",
    nextIndexValueLabel = "qGuider_req_nextIndexValueLabel",
    nextIndexLabel = "qGuider_req_nextIndexLabel",
}

local mapMenu = {
    block = "qGuider_map_block",
    requirementBlock = "qGuider_map_requirementBlock",
    mapBlock = "qGuider_map_mapBlock",
    pane = "qGuider_map_pane",
    markerBlock = "qGuider_map_markerBlock",
    image = "qGuider_map_image",
    marker = "qGuider_map_marker",
    tooltipBlock = "qGuider_map_tooltipBlock",
    tooltipName = "qGuider_map_tooltipName",
    tooltipDescription = "qGuider_map_tooltipDescription",
}

local containerMenu = {
    id = "qGuider_container",
    buttonBlock = "qGuider_container_btnBlock",
    closeBtn = "qGuider_container_closeBtn",
}

local journalMenu = {
    requirementBlock = "qGuider_journal_reqBlock",
    questNameLabel = "qGuider_journal_qNameLabel",
    questNameBlock = "qGuider_journal_qNameBlock",
    requirementsIcon = "qGuider_journal_reqIcon",
    mapIcon = "qGuider_journal_MapIcon",
}

local mapAddon = {
    showHideBtn = "qGuider_mapAddon_showHideBtn",
    removeAllBtn = "qGuider_mapAddon_removeAllBtn",
    scrollPane = "qGuider_mapAddon_scrollPane",
    trackingBlock = "qGuider_mapAddon_trackingBlock",
    questNameLabel = "qGuider_mapAddon_questNameLabel",
    questObjLabel = "qGuider_mapAddon_questObjLabel",
}


local mcp_mapExpansion = tes3.hasCodePatchFeature(tes3.codePatchFeature.mapExpansionForTamrielRebuilt)

local cellWidth = mcp_mapExpansion and 5 or 9
local cellHeight = mcp_mapExpansion and 5 or 9
local minCellGridX = mcp_mapExpansion and -51 or -28
local minCellGridY = mcp_mapExpansion and -64 or -28
local maxCellGridX = mcp_mapExpansion and 51 or 28
local maxCellGridY = mcp_mapExpansion and 38 or 28
local mapGridWidth = mcp_mapExpansion and 103 or 57
local mapGridHeight = mcp_mapExpansion and 103 or 57
local worldWidthMinPart = -minCellGridX * 8192
local worldHeightMaxPart = (maxCellGridY + 1) * 8192
local worldWidth = (-minCellGridX + maxCellGridX) * 8192
local worldHeight = (-minCellGridY + maxCellGridY) * 8192

local markerColors = include("diject.quest_guider.Types.color")


local this = {}

this.colors = {
    default = {0.792, 0.647, 0.376},
    lightDefault = {0.892, 0.747, 0.476},
    lightGreen = {0.5, 1, 0.5},
    disabled = {0.25, 0.25, 0.25}
}

function this.init()
    this.colors.default = tes3ui.getPalette(tes3.palette.normalColor)
    this.colors.lightDefault = tes3ui.getPalette(tes3.palette.notifyColor)
    this.colors.disabled = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
end


---@class questGuider.ui.markerImage
---@field path string
---@field shiftX integer|nil
---@field shiftY integer|nil

---@type table<string, questGuider.ui.markerImage>
this.markers = {
    quest = {path = "textures\\diject\\quest guider\\circleMarker8.dds", shiftX = -4, shiftY = -4},
}



local function updateContainerMenu(mainBlock)
    local topMenu = mainBlock:getTopLevelMenu()
    topMenu:updateLayout()

    if topMenu.name == "qGuider_container" then
        topMenu.maxWidth = nil
        topMenu.maxHeight = nil
        topMenu.minWidth = nil
        topMenu.minHeight = nil
        topMenu.height = mainBlock.height + 74
        topMenu.width = mainBlock.width + 24
        topMenu.maxWidth = topMenu.width
        topMenu.maxHeight = topMenu.height
        topMenu.minWidth = topMenu.width
        topMenu.minHeight = topMenu.height
        topMenu:updateLayout()
    end
end

---@param element tes3uiElement
function this.centreToCursor(element)
    local curPos = tes3.getCursorPosition()
    element.positionX = curPos.x - element.width / 2
    element.positionY = curPos.y
    element:getTopLevelMenu():updateLayout()
end

---@param parent tes3uiElement
---@param questId string
---@param index integer|string
---@param questData questDataGenerator.questData
function this.drawQuestInfoMenu(parent, questId, index, questData)
    local topicData = questData[tostring(index)]
    local questName = questData.name or "???"
    local topicIndex = tostring(index) or "???"

    local mainBlock = parent:createBlock{ id = infoMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true
    mainBlock.maxWidth = 300

    local headerLabel = mainBlock:createLabel{ id = infoMenu.headerId, text = questName }

    local questIdStr = questId or "???"
    local questIdLabel = mainBlock:createLabel{ id = infoMenu.questidId, text = "Quest id: "..questIdStr }

    local indexesStr = ""
    local indexes = {}
    for ind, _ in pairs(questData) do
        local indInt = tonumber(ind)
        if indInt then
            table.insert(indexes, indInt)
        end
    end
    table.sort(indexes)
    for _, ind in ipairs(indexes) do
        indexesStr = indexesStr..tostring(ind)..", "
    end
    if #indexesStr > 0 then
        indexesStr = indexesStr:sub(1, -3)
    end
    local indexStr = string.format("Stage: %s of [%s]", topicIndex, indexesStr)
    local topicIndexLabel = mainBlock:createLabel{ id = infoMenu.indexId, text = indexStr }

    if topicData and topicData.next and #topicData.next > 0 then
        local nextIndexesStr = "Next stage"..(#topicData.next > 1 and "es" or "")..": "..tableLib.valuesToStr(topicData.next)
        local topicnextIndexesLabel = mainBlock:createLabel{ id = infoMenu.nextIndexes, text = nextIndexesStr }
    end

    local currentIndex = questLib.getPlayerQuestIndex(questId)
    if currentIndex then
        local currentIndexStr = string.format("Current stage: %d", currentIndex)
        local currentIndexLabel = mainBlock:createLabel{ id = infoMenu.currentIndex, text = currentIndexStr }
        currentIndexLabel.borderTop = 10
    end

    updateContainerMenu(mainBlock)
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string
---@param questData questDataGenerator.questData
function this.drawQuestRequirementsMenu(parent, questId, index, questData)
    local topicData = questData[tostring(index)]
    local questName = questData.name or "???"
    local topicIndexStr = tostring(index) or "???"
    local playerCurrentIndex = questLib.getPlayerQuestIndex(questId)
    local playerCurrentIndexStr = tostring(playerCurrentIndex) or "???"

    local mainBlock = parent:createBlock{ id = requirementsMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true
    mainBlock.maxWidth = 400

    local headerLabel = mainBlock:createLabel{ id = requirementsMenu.headerLabel, text = string.format("(%s) %s", topicIndexStr, questName) }
    headerLabel.borderBottom = 2

    local showSelectedCurrentBlock = true
    local selectedCurrentBlock = mainBlock:createBlock{ id = requirementsMenu.selectedCurrentBlock }
    selectedCurrentBlock.autoHeight = true
    selectedCurrentBlock.autoWidth = true
    selectedCurrentBlock.flowDirection = tes3.flowDirection.leftToRight
    selectedCurrentBlock.borderBottom = 2
    selectedCurrentBlock.visible = false
    selectedCurrentBlock:createLabel{ id = requirementsMenu.text, text = "Stage:" }.borderRight = 20
    local selLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.selectedLabel, text = string.format("Selected (%s)", topicIndexStr) }
    local lstLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.currentLabel, text = string.format("Current (%s)", playerCurrentIndexStr) }
    lstLabel.borderLeft = 20

    local reqIndexMainBlock = mainBlock:createBlock{ id = requirementsMenu.requirementIndexMainBlock }
    reqIndexMainBlock.autoHeight = true
    reqIndexMainBlock.autoWidth = true
    reqIndexMainBlock.borderBottom = 2
    reqIndexMainBlock.flowDirection = tes3.flowDirection.leftToRight
    local nextIndexLabel = reqIndexMainBlock:createLabel{ id = requirementsMenu.nextIndexLabel, text = "Next stage:" }
    nextIndexLabel.visible = false

    local reqIndexBlock = reqIndexMainBlock:createBlock{ id = requirementsMenu.requirementIndexBlock }
    reqIndexBlock.autoHeight = true
    reqIndexBlock.autoWidth = true
    reqIndexBlock.borderLeft = 10

    local indexTabBlock = mainBlock:createBlock{ id = requirementsMenu.indexTabBlock }
    indexTabBlock.autoHeight = true
    indexTabBlock.autoWidth = true
    indexTabBlock.flowDirection = tes3.flowDirection.leftToRight
    indexTabBlock.visible = false

    local reqBlock = mainBlock:createBlock{ id = requirementsMenu.requirementBlock }
    reqBlock.autoHeight = true
    reqBlock.autoWidth = true
    reqBlock.borderTop = 12
    reqBlock.flowDirection = tes3.flowDirection.topToBottom
    reqBlock.maxWidth = 400


    if not topicData then return end
    if topicData.finished then
        selLabel.visible = false
        lstLabel.visible = false
        nextIndexLabel.text = "Finished"
        return
    end

    if index == playerCurrentIndex then
        selectedCurrentBlock.visible = false
        showSelectedCurrentBlock = false
    end


    local function resetDynamicToDefault()
        indexTabBlock.visible = false
        reqBlock:destroyChildren()
        reqIndexBlock:destroyChildren()
        indexTabBlock:destroyChildren()
        selLabel.color = this.colors.disabled
        lstLabel.color = this.colors.disabled
    end

    ---@param topicIndex integer
    local function drawTopicInfo(topicIndex)
        if not topicIndex then return end

        local tpData = questData[tostring(topicIndex)]
        if not tpData then return end

        local nextIndexes = {}
        local foundNextIndex = false
        if tpData.next then
            for _, ind in pairs(tpData.next) do
                nextIndexes[ind] = true
                foundNextIndex = true
            end
        end
        if not foundNextIndex and tpData.nextIndex then
            nextIndexes[tpData.nextIndex] = true
        end

        nextIndexes = tableLib.tableIndexesToArray(nextIndexes)

        if #nextIndexes == 0 then return end

        table.sort(nextIndexes)

        local nextIndTabs = {}
        for _, ind in ipairs(nextIndexes) do

            local indStr = tostring(ind)
            local indTopicData = questData[indStr]
            if not indTopicData then goto continue end

            if #nextIndTabs > 0 then
                local textLabel = reqIndexBlock:createLabel{ id = requirementsMenu.text, text = "," }
                textLabel.borderRight = 4
            end

            local nextIndexValueLabel = reqIndexBlock:createLabel{ id = requirementsMenu.nextIndexValueLabel, text = "-"..indStr.."-" }
            table.insert(nextIndTabs, nextIndexValueLabel)

            nextIndexValueLabel:register(tes3.uiEvent.mouseClick, function (e)

                for _, tb in pairs(nextIndTabs) do
                    tb.color = this.colors.disabled
                end
                e.source.color = this.colors.lightGreen

                indexTabBlock:destroyChildren()

                indexTabBlock:createLabel{ id = requirementsMenu.text, text = "Requirements:" }.borderRight = 10

                local tabs = {}
                for i, reqDataBlock in pairs(indTopicData.requirements) do

                    indexTabBlock.visible = true
                    selectedCurrentBlock.visible = showSelectedCurrentBlock

                    if #tabs > 0 then
                        local textLabel = indexTabBlock:createLabel{ id = requirementsMenu.text, text = "or" }
                        textLabel.borderLeft = 5
                        textLabel.borderRight = 5
                    end

                    local tab = indexTabBlock:createLabel{ id = requirementsMenu.indexTab, text = "-"..tostring(i).."-" }
                    table.insert(tabs, tab)
                    local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
                    tab:setLuaData("requirementData", requirementData)

                    tab:register(tes3.uiEvent.mouseClick, function (e)
                        reqBlock:destroyChildren()
                        if requirementData then
                            reqBlock:setLuaData("requirementData", requirementData)
                            for _, req in pairs(requirementData) do
                                local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = req.str }
                                reqLabel.borderTop = 4
                                reqLabel.color = this.colors.lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)
                            end
                        else
                            local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = this.colors.lightDefault
                            reqLabel.borderTop = 4
                        end

                        for _, tb in pairs(tabs) do
                            tb.color = this.colors.disabled
                        end
                        tab.color = this.colors.lightGreen

                        local callback = reqBlock:getLuaData("callback")
                        if callback then
                            callback(reqBlock, requirementData)
                        else
                            updateContainerMenu(mainBlock)
                        end

                    end)
                end

                if #tabs > 0 then
                    tabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
                    reqIndexMainBlock.visible = true
                    nextIndexLabel.visible = true
                    -- tabs[1].color = this.colors.lightGreen

                    if #tabs == 1 then
                        tabs[1].visible = false
                    end
                end

            end)

            ::continue::
        end

        if #nextIndTabs > 0 then
            nextIndTabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
            -- nextIndTabs[1].color = this.colors.lightGreen
        end
    end

    selLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        selLabel.color = this.colors.lightGreen
        drawTopicInfo(index)
    end)

    lstLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        lstLabel.color = this.colors.lightGreen
        drawTopicInfo(playerCurrentIndex)
    end)

    selLabel:triggerEvent(tes3.uiEvent.mouseClick)
    updateContainerMenu(mainBlock)
end



---@class questGuider.ui.createMarker.params
---@field pane tes3uiElement
---@field markerData questGuider.ui.markerImage
---@field x number
---@field y number
---@field color number[]|nil
---@field name string|nil
---@field description string|nil

---@param params questGuider.ui.createMarker.params
---@return tes3uiElement|nil
---@return number|nil alignX
---@return number|nil alignY
local function createMarker(params)
    if not params.pane then return end
    if not params.markerData or not params.markerData.path then return end

    local image = params.pane:createImage{id = mapMenu.marker, path = params.markerData.path}

    if not image then return end

    local imageShiftX = params.markerData.shiftX and params.markerData.shiftX / 512 or -image.width / 1024
    local imageShiftY = params.markerData.shiftY and -params.markerData.shiftY /512 or image.height / 1024

    local alignX = (worldWidthMinPart + params.x) / worldWidth
    local alignY = -(params.y - worldHeightMaxPart) / worldHeight

    image.autoHeight = true
    image.autoWidth = true
    image.absolutePosAlignX = math.max(0, math.min(1, alignX + imageShiftX))
    image.absolutePosAlignY = math.max(0, math.min(1, alignY + imageShiftY))
    image.color = params.color or {1, 1, 1}

    image:setLuaData("records", {params})

    image:register(tes3.uiEvent.help, function (e)
        if not e.source then return end
        local luaData = e.source:getLuaData("records")
        if not luaData then return end

        local tooltip = tes3ui.createTooltipMenu()

        local blockCount = 0
        for i, rec in pairs(luaData) do
            if not rec.name and not rec.description then goto continue end

            local block = tooltip:createBlock{id = mapMenu.tooltipBlock}
            block.flowDirection = tes3.flowDirection.topToBottom
            block.autoHeight = true
            block.autoWidth = true
            block.maxWidth = 250
            block.borderBottom = 3

            blockCount = blockCount + 1

            if rec.name then
                local label = block:createLabel{id = mapMenu.tooltipName, text = rec.name}
                label.autoHeight = true
                label.autoWidth = true
                label.maxWidth = 250
                label.wrapText = true
                label.justifyText = tes3.justifyText.center
            end

            if rec.description then
                local label = block:createLabel{id = mapMenu.tooltipDescription, text = rec.description}
                label.autoHeight = true
                label.autoWidth = true
                label.maxWidth = 250
                label.wrapText = true
                label.justifyText = tes3.justifyText.left
            end

            ::continue::
        end

        if blockCount == 0 then
            tooltip:destroy()
        else
            tooltip:getTopLevelMenu():updateLayout()
        end
    end)

    return image, alignX, alignY
end

---@param markerElement tes3uiElement
---@param recordToAdd questGuider.ui.createMarker.params
local function addInfoToMarker(markerElement, recordToAdd)
    if not markerElement or not recordToAdd then return end

    local luaData = markerElement:getLuaData("records")
    if luaData then
        table.insert(luaData, recordToAdd)
        markerElement:setLuaData("records", luaData)
    end
end

---@param parent tes3uiElement
---@param questId string
---@param index integer|string
---@param questData questDataGenerator.questData
function this.drawMapMenu(parent, questId, index, questData)
    local mainBlock = parent:createBlock{ id = mapMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.leftToRight
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true

    local reqBlock = mainBlock:createBlock{ id = mapMenu.requirementBlock }
    reqBlock.flowDirection = tes3.flowDirection.topToBottom
    reqBlock.autoHeight = true
    reqBlock.autoWidth = true

    local mapBlock = mainBlock:createBlock{ id = mapMenu.mapBlock }
    mapBlock.flowDirection = tes3.flowDirection.topToBottom
    mapBlock.width = 400
    mapBlock.height = 400

    local pane = mapBlock:createBlock{ id = mapMenu.pane }
    pane.width = 512
    pane.height = 512
    pane.ignoreLayoutX = true
    pane.ignoreLayoutY = true

    local mapMarkersBlock = pane:createBlock{ id = mapMenu.markerBlock }
    mapMarkersBlock.widthProportional = 1
    mapMarkersBlock.heightProportional = 1
    mapMarkersBlock.childAlignX = 0
    mapMarkersBlock.childAlignY = 1
    mapMarkersBlock.ignoreLayoutX = true
    mapMarkersBlock.ignoreLayoutY = true
    mapMarkersBlock.width = 512
    mapMarkersBlock.height = 512

    mapMarkersBlock:getTopLevelMenu():updateLayout()

    this.drawQuestRequirementsMenu(reqBlock, questId, index, questData)

    local innMenuReqBlock = reqBlock:findChild(requirementsMenu.requirementBlock)
    if not innMenuReqBlock then
        mapBlock.visible = false
        return
    end


    ---@param reqBl tes3uiElement 
    local function drawMarkers(reqBl)
        if not reqBl then return end

        mapMarkersBlock:destroyChildren()
        local image = mapMarkersBlock:createImage{id = mapMenu.image}
        image.texture = tes3.dataHandler.nonDynamicData.mapTexture:clone()

        local colorIndex = 1

        local colorOfObject = {}

        local markersData = {}

        local markers = {}

        ---@param e tes3uiEventData
        local function mouseOver(e)
            for _, marker in pairs(markers) do
                local color = marker.color
                if color and e.source.color and (color[1] ~= e.source.color[1] or color[2] ~= e.source.color[2] or color[3] ~= e.source.color[3]) then
                    marker.visible = false
                end
            end
        end

        ---@param e tes3uiEventData
        local function mouseLeave(e)
            for _, marker in pairs(markers) do
                marker.visible = true
            end
        end

        for _, child in pairs(reqBl.children) do
            if child.name ~= requirementsMenu.requirementLabel then goto continue0 end

            ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
            local reqData = child:getLuaData("requirement")
            if not reqData or not reqData.objects then goto continue0 end

            local color = markerColors[colorIndex]

            local objectIds = {}

            local foundObjectsInChildren = 0
            for _, objId in pairs(reqData.objects) do

                local obj = tes3.getObject(objId)
                local objName = obj and obj.name
                local objPosData = questLib.getObjectPositionData(objId)

                if not objPosData then goto continue1 end

                foundObjectsInChildren = foundObjectsInChildren + 1

                if colorOfObject[objId] then
                    color = colorOfObject[objId]
                    goto continue1
                else
                    colorOfObject[objId] = color
                end

                objectIds[objId] = true

                for _, pos in pairs(objPosData) do
                    local x = pos.position[1]
                    local y = pos.position[2]

                    local cellPath

                    if pos.name then
                        local cell = tes3.getCell{id = pos.name}
                        if cell then
                            local exCellPos
                            exCellPos, cellPath = cellLib.findExitPos(cell)
                            if exCellPos then
                                x = exCellPos.x
                                y = exCellPos.y
                            else
                                goto continue2
                            end
                        end
                    end

                    table.insert(markersData, { x = x, y = y, color = color, objId = objId, objName = objName, cellPath = cellPath })
                    ::continue2::
                end

                ::continue1::
            end

            if foundObjectsInChildren > 0 then
                child.color = color
                colorIndex = colorIndex == #markerColors and 1 or colorIndex + 1

                child:register(tes3.uiEvent.mouseOver, mouseOver)
                child:register(tes3.uiEvent.mouseLeave, mouseLeave)

                ---@param e tes3uiEventData
                local function mouseClick(e)
                    for objId, _ in pairs(objectIds) do
                        trackingLib.addMarker{objectId = objId, color = color, questId = questId, questStage = index}
                    end
                    trackingLib.updateMarkers(true)
                end

                child:register(tes3.uiEvent.mouseClick, mouseClick)
            end

            ::continue0::
        end

        if #markersData == 0 then
            mapBlock.width = 0
            mapBlock.height = 0
            goto continue
        else
            mapBlock.width = 400
            mapBlock.height = 400
        end

        do
            local minMaxAlignX = {1, 0}
            local minMaxAlignY = {1, 0}

            for _, data in pairs(markersData) do

                local descr
                if data.cellPath then
                    for i = #data.cellPath - 1, 1, -1 do
                        descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].cell.editorName) or string.format("\"%s\"",
                            data.cellPath[i].cell.editorName)
                    end
                end

                local im, alignX, alignY = createMarker{pane = mapMarkersBlock, markerData = this.markers.quest,
                    x = data.x, y = data.y, color = data.color,
                    name = data.objName,
                    description = descr,
                }

                if im then
                    table.insert(markers, im)
                    minMaxAlignX[1] = math.min(minMaxAlignX[1], alignX)
                    minMaxAlignX[2] = math.max(minMaxAlignX[2], alignX)
                    minMaxAlignY[1] = math.min(minMaxAlignY[1], alignY)
                    minMaxAlignY[2] = math.max(minMaxAlignY[2], alignY)
                end
            end

            local maxScale = math.min(1 / (minMaxAlignX[2] - minMaxAlignX[1]), 1 / (minMaxAlignY[2] - minMaxAlignY[1]))
            local scale = math.max(1, math.min(4, maxScale))

            mapMarkersBlock.width = 512 * scale
            mapMarkersBlock.height = 512 * scale
            pane.width = 512 * scale
            pane.height = 512 * scale

            image.imageScaleX = scale
            image.imageScaleY = scale

            pane.positionX = -(pane.width - mapBlock.width) / 2 + (0.5 - (minMaxAlignX[2] + minMaxAlignX[1]) / 2) * pane.width
            pane.positionY = (pane.height - mapBlock.height) / 2 - (0.5 - (minMaxAlignY[2] + minMaxAlignY[1]) / 2) * pane.height
        end

        ::continue::

        updateContainerMenu(mainBlock)
    end

    drawMarkers(innMenuReqBlock)

    innMenuReqBlock:setLuaData("callback", function(reqBl)
        drawMarkers(reqBl)
    end)
end


---@param label string
function this.drawContainer(label)
    local element = tes3ui.createMenu{ id = containerMenu.id, dragFrame = true, }
    element.text = label
    local frame = element:findChild("PartDragMenu_drag_frame")
    if not frame then return end
    local buttonBlock = frame:createBlock{ id = containerMenu.buttonBlock }
    buttonBlock.autoHeight = true
    buttonBlock.autoWidth = true
    buttonBlock.flowDirection = tes3.flowDirection.leftToRight
    buttonBlock.widthProportional = 1
    buttonBlock.borderTop = 2
    buttonBlock.borderBottom = 1
    local closeButton = buttonBlock:createButton{ id = containerMenu.closeBtn, text = "Close"}
    closeButton.absolutePosAlignX = 1
    closeButton.paddingBottom = 0
    closeButton.paddingTop = 0
    closeButton:register(tes3.uiEvent.mouseClick, function (e)
        element:destroy()
    end)

    return element
end


---TODO
---@param parent tes3uiElement
---@return tes3uiElement|nil
function this.drawQuestsMenu(parent)
    if not parent then return end

    local playerQuestData = questLib.getPlayerQuestData()

    if not playerQuestData then return end

    local mainBlock = parent:createBlock{ id = "qGuider_quests_block" }
    mainBlock.flowDirection = tes3.flowDirection.leftToRight
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true

    local infoBlock = mainBlock:createBlock{ id = "qGuider_quests_infoBlock" }
    infoBlock.flowDirection = tes3.flowDirection.topToBottom
    infoBlock.autoHeight = true
    infoBlock.maxHeight = 600
    infoBlock.width = 500

    local listBlock = mainBlock:createBlock{ id = "qGuider_quests_listBlock" }
    listBlock.flowDirection = tes3.flowDirection.topToBottom
    listBlock.autoHeight = true
    listBlock.autoWidth = true

    local filterBlock = listBlock:createBlock{ id = "qGuider_quests_filterBlock" }
    filterBlock.flowDirection = tes3.flowDirection.topToBottom
    filterBlock.autoHeight = true
    filterBlock.autoWidth = true

    local filterTextInput = filterBlock:createTextInput{ id = "qGuider_quests_filterTextInput" }
    filterTextInput.width = 200
    filterTextInput.autoHeight = true

    local questPane = listBlock:createVerticalScrollPane{ id = "qGuider_quests_questPane" }
    questPane.heightProportional = nil
    questPane.widthProportional = nil
    questPane.height = 580
    questPane.width = 200

    table.sort(playerQuestData, function (a, b)
        return (a.name or " ") > (b.name or " ")
    end)

    for _, qData in ipairs(playerQuestData) do
        local border = questPane:createThinBorder{}
        border.autoWidth = true
        border.autoHeight = true

        local questName = qData.name or string.format(" id \"%s\"", qData.id)
        local label = border:createLabel{ id = "qGuider_quests_questLabel", text = questName }
    end

    updateContainerMenu(mainBlock)

    return mainBlock
end

function this.updateJournalMenu()
    local menu = tes3ui.findMenu("MenuJournal")
    if not menu then return end

    if menu:findChild(journalMenu.requirementBlock) then
        return
    end

    for _, pageName in pairs({"MenuBook_page_1", "MenuBook_page_2"}) do
        local page = menu:findChild(pageName)

        if not page then goto continue end

        local isDescription = false
        for i, element in pairs(page.children) do

            if element.type == tes3.uiElementType.text then
                element.height = 4
            end
            if element.name ~= "MenuBook_hypertext" then goto continue end

            if not isDescription then
                element.borderAllSides = -1
                isDescription = not isDescription
                goto continue
            end

            local str = element.text:gsub("@", ""):gsub("#", ""):gsub("\n", " ")

            if not dataHandler.questByText[str] then goto continue end

            local questId = dataHandler.questByText[str][1].quest
            local questIndex = dataHandler.questByText[str][1].index
            local quest = dataHandler.quests[questId]

            if not quest then goto continue end

            local block = page:createBlock{ id = journalMenu.requirementBlock }
            page:reorderChildren(element, block, 1)
            block.flowDirection = tes3.flowDirection.leftToRight
            block.autoHeight = true
            block.autoWidth = true

            local infoBlock = block:createBlock{ id = journalMenu.questNameBlock }
            infoBlock.autoHeight = true
            infoBlock.autoWidth = false
            infoBlock.borderRight = 5

            local infoLabel = infoBlock:createLabel{ id = journalMenu.questNameLabel, text = "("..tostring(questIndex)..") "..(quest.name or "") }
            infoLabel.color = this.colors.lightGreen
            infoLabel.alpha = 1

            infoLabel:register(tes3.uiEvent.help, function (ei)
                local tooltip = tes3ui.createTooltipMenu()
                this.drawQuestInfoMenu(tooltip, questId, questIndex, quest)
            end)
            infoLabel:register(tes3.uiEvent.mouseClick, function (ei)
                local el = this.drawContainer("Info")
                this.drawQuestInfoMenu(el, questId, questIndex, quest)
                this.centreToCursor(el)
            end)

            local reqLabel = block:createImage{ id = journalMenu.requirementsIcon, path = "Icons\\m\\Tx_parchment_02.tga" }
            reqLabel.imageScaleX = 0.5
            reqLabel.imageScaleY = 0.5
            reqLabel.borderRight = 5

            reqLabel:register(tes3.uiEvent.help, function (ei)
                local tooltip = tes3ui.createTooltipMenu()
                this.drawQuestRequirementsMenu(tooltip, questId, questIndex, quest)
            end)
            reqLabel:register(tes3.uiEvent.mouseClick, function (ei)
                local el = this.drawContainer("Requirements")
                this.drawQuestRequirementsMenu(el, questId, questIndex, quest)
                this.centreToCursor(el)
            end)

            local mapLabel = block:createImage{ id = journalMenu.mapIcon, path = "Icons\\m\\Tx_note_02.tga" }
            mapLabel.imageScaleX = 0.5
            mapLabel.imageScaleY = 0.5

            mapLabel:register(tes3.uiEvent.help, function (ei)
                local tooltip = tes3ui.createTooltipMenu()
                this.drawMapMenu(tooltip, questId, questIndex, quest)
            end)
            mapLabel:register(tes3.uiEvent.mouseClick, function (ei)
                local el = this.drawContainer("Map")
                this.drawMapMenu(el, questId, questIndex, quest)
                this.centreToCursor(el)
            end)

            infoBlock.width = math.max(1, page.width - (16 + 16 + 10))

            ::continue::
        end

        ::continue::
    end

    menu:updateLayout()
end

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

    local btnBlock = dragMenu:createBlock{}
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
        local questData = dataHandler.quests[questId]
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

            qDescrLabel:register(tes3.uiEvent.mouseOver, function (e)
                local color = {1, 1, 1}
                qDescrLabel.color = color

                trackingLib.changeObjectMarkerColor(objId, color)
                trackingLib.updateMarkers(false, true)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseLeave, function (e)
                qDescrLabel.color = markerColor
                trackingLib.changeObjectMarkerColor(objId, markerColor)
                trackingLib.updateMarkers(false, true)
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