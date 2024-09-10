local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")

local questLib = include("diject.quest_guider.quest")
-- local markers = require("diject.world_map_markers.interop")
local cellLib = require("diject.quest_guider.cell")

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

local defaultColor = {0.792, 0.647, 0.376}
local lightDefault = {0.892, 0.747, 0.476}
local lightGreenColor = {0.5, 1, 0.5}
local lightBlue = {0.5, 0.5, 1}

local markerImage = {
    0,0,0,0,  255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,  0,0,0,0,
    255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,
    255,0,255,1,  255,0,255,0.5,  0,0,0,0,  255,0,255,0.5,  255,0,255,1,
    255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,
    0,0,0,0,  255,0,255,0.5,  255,0,255,1,  255,0,255,0.5,  0,0,0,0,
}

local markerColors = {
    -- {255, 0, 0},
    -- {0, 0, 255},
    -- {0, 255, 0},
    {255, 255, 0},
    {0, 255, 255},
    {255, 0, 255},
    {255, 63, 63},
    {63, 63, 255},
    {63, 255, 63},
    {255, 255, 63},
    {63, 255, 255},
    {255, 63, 255},
    {255, 127, 127},
    {127, 127, 255},
    -- {127, 255, 127},
    {255, 255, 127},
    {127, 255, 255},
    {255, 127, 255},
    {255, 191, 191},
    {191, 191, 255},
    {191, 255, 191},
    {255, 255, 191},
    {191, 255, 255},
    {255, 191, 255},
}

---@param color integer[]
---@return integer[]
local function colorByteToFloat(color)
    local out = {}
    for _, val in ipairs(color) do
        table.insert(out, val / 255)
    end
    return out
end

---@param color integer[]
---@return number[]
local function getMarkerPixels(color)
    local markerIm = tableLib.copy(markerImage)
    for i = 1, #markerImage, 4 do
        if markerIm[i] == 255 then
            markerIm[i] = color[1]
            markerIm[i + 1] = color[2]
            markerIm[i + 2] = color[3]
        end
    end
    return markerIm
end

local this = {}

local function updateTopLevelMenu(mainBlock)
    local topMenu = mainBlock:getTopLevelMenu()
    topMenu:updateLayout()

    if not topMenu.autoHeight and not topMenu.autoWidth then
        topMenu.height = mainBlock.height
        topMenu.width = mainBlock.width
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

    updateTopLevelMenu(mainBlock)
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
    -- parent:getTopLevelMenu():updateLayout()
    -- selectedCurrentBlock.absolutePosAlignX = 0.5
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
    -- parent:getTopLevelMenu():updateLayout()
    -- reqIndexBlock.absolutePosAlignX = 0.5

    local indexTabBlock = mainBlock:createBlock{ id = requirementsMenu.indexTabBlock }
    indexTabBlock.autoHeight = true
    indexTabBlock.autoWidth = true
    -- parent:getTopLevelMenu():updateLayout()
    -- indexTabBlock.absolutePosAlignX = 0.5
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
        selLabel.color = defaultColor
        lstLabel.color = defaultColor
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
                                reqLabel.color = lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)
                            end
                        else
                            local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = lightDefault
                            reqLabel.borderTop = 4
                        end

                        for _, tb in pairs(tabs) do
                            tb.color = lightDefault
                        end
                        tab.color = lightGreenColor

                        local callback = reqBlock:getLuaData("callback")
                        if callback then
                            callback(reqBlock, requirementData)
                        else
                            updateTopLevelMenu(mainBlock)
                        end

                    end)
                end

                if #tabs > 0 then
                    tabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
                    reqIndexMainBlock.visible = true
                    nextIndexLabel.visible = true
                    -- tabs[1].color = lightGreenColor

                    if #tabs == 1 then
                        tabs[1].visible = false
                    end
                end

            end)

            ::continue::
        end

        if #nextIndTabs > 0 then
            nextIndTabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
            nextIndTabs[1].color = lightGreenColor
        end
    end

    selLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        selLabel.color = lightGreenColor
        drawTopicInfo(index)
    end)

    lstLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        lstLabel.color = lightGreenColor
        drawTopicInfo(playerCurrentIndex)
    end)

    selLabel:triggerEvent(tes3.uiEvent.mouseClick)
end



---@class questGuider.ui.createMarker.params
---@field pane tes3uiElement
---@field path string
---@field width number
---@field height number
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

    local image = params.pane:createImage{id = mapMenu.marker, path = params.path}

    local alignX = (worldWidthMinPart + params.x) / worldWidth
    local alignY = -(params.y - worldHeightMaxPart) / worldHeight

    image.autoHeight = true
    image.autoWidth = true
    image.absolutePosAlignX = alignX
    image.absolutePosAlignY = alignY
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

        for _, child in pairs(reqBl.children) do
            if child.name ~= requirementsMenu.requirementLabel then goto continue0 end

            ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
            local reqData = child:getLuaData("requirement")
            if not reqData or not reqData.objects then goto continue0 end

            local color = markerColors[colorIndex]

            local foundObjectsInChildren = 0
            for _, objId in pairs(reqData.objects) do

                local objPosData = questLib.getObjectPositionData(objId)

                if not objPosData then goto continue1 end

                foundObjectsInChildren = foundObjectsInChildren + 1

                if colorOfObject[objId] then
                    color = colorOfObject[objId]
                    goto continue1
                else
                    colorOfObject[objId] = color
                end

                for _, pos in pairs(objPosData) do
                    local x = pos.position[1]
                    local y = pos.position[2]

                    if pos.name then
                        local cell = tes3.getCell{id = pos.name}
                        if cell then
                            local exCellPos = cellLib.findExitPos(cell)
                            if exCellPos then
                                x = exCellPos.x
                                y = exCellPos.y
                            else
                                goto continue2
                            end
                        end
                    end

                    table.insert(markersData, {x = x, y = y, color = color, objId = objId})
                    ::continue2::
                end

                ::continue1::
            end

            if foundObjectsInChildren > 0 then
                child.color = colorByteToFloat(color)
                colorIndex = colorIndex == #markerColors and 1 or colorIndex + 1
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
                local im, alignX, alignY = createMarker{pane = mapMarkersBlock, path = "textures\\qmarker.tga", height = 8, width = 8,
                    x = data.x, y = data.y, color = colorByteToFloat(data.color)}

                minMaxAlignX[1] = math.min(minMaxAlignX[1], alignX)
                minMaxAlignX[2] = math.max(minMaxAlignX[2], alignX)
                minMaxAlignY[1] = math.min(minMaxAlignY[1], alignY)
                minMaxAlignY[2] = math.max(minMaxAlignY[2], alignY)
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

        updateTopLevelMenu(mainBlock)
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

return this