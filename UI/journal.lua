local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")
local tooltipLib = include("diject.quest_guider.UI.tooltipSys")

local questLib = include("diject.quest_guider.quest")
local cellLib = include("diject.quest_guider.cell")
local trackingLib = include("diject.quest_guider.tracking")
local playerQuests = include("diject.quest_guider.playerQuests")
local types = include("diject.quest_guider.types")

local mapMarkerLib = include("diject.map_markers.marker")

local config = include("diject.quest_guider.config")

local markerColors = include("diject.quest_guider.Types.color")

local mcp_mapExpansion = tes3.hasCodePatchFeature(tes3.codePatchFeature.mapExpansionForTamrielRebuilt)

local this = {}

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
    scroll = "qGuider_scroll_pane",
    text = "qGuider_req_text",
    headerLabel = "qGuider_req_headerLabel",
    finishedLabel = "qGuider_req_finishedLabel",
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
    localValueTooltipBlock = "qGuider_req_localValueTooltipBlock",
}

local scriptLocalsMenu = {
    block = "qGuider_locals_block",
    headerLabel = "qGuider_locals_headerLabel",
    requirementsFullBlock = "qGuider_locals_requirementsFullBlock",
    requirementsBlock = "qGuider_locals_requirementsBlock",
    resultLabel = "qGuider_locals_resultLabel"
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
    trackBtn = "qGuider_container_trackBtn",
}

local journalMenu = {
    requirementBlock = "qGuider_journal_reqBlock",
    questNameLabel = "qGuider_journal_qNameLabel",
    questNameBlock = "qGuider_journal_qNameBlock",
    requirementsIcon = "qGuider_journal_reqIcon",
    mapIcon = "qGuider_journal_MapIcon",
}

this.colors = {
    default = {0.792, 0.647, 0.376},
    lightDefault = {0.892, 0.747, 0.476},
    lightGreen = {0.5, 1, 0.5},
    lightYellow = {0.8, 0.8, 0.5},
    lightLightYellow = {0.8, 0.8, 0.3},
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


---@param mainBlock tes3uiElement
---@param scrollBlock tes3uiElement|nil
local function updateContainerMenu(mainBlock, scrollBlock)
    local topMenu = mainBlock:getTopLevelMenu()
    topMenu:updateLayout()
    if scrollBlock and scrollBlock.widget then
        scrollBlock.widget:contentsChanged()
    end

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
        if scrollBlock and scrollBlock.widget then
            scrollBlock.widget:contentsChanged()
        end
    end
end

local function isColorsEqual(color1, color2)
    if not color1 or not color2 then return end
    return color1[1] == color2[1] and color1[2] == color2[2] and color1[3] == color2[3]
end

---@param element tes3uiElement
---@param color number[]|nil
local function makeLabelSelectable(element, color)
    local originalColor
    element:registerAfter(tes3.uiEvent.mouseOver, function (e)
        if not isColorsEqual(element.color, {1, 1, 1}) then
            originalColor = table.copy(element.color)
            element.color = color or {1, 1, 1}
            element:getTopLevelMenu():updateLayout()
        end
    end)
    element:registerAfter(tes3.uiEvent.mouseLeave, function (e)
        element.color = originalColor or element.color
        element:getTopLevelMenu():updateLayout()
    end)
end

---@param element tes3uiElement
function this.centerToCursor(element)
    local width, height = tes3.getViewportSize()
    local scale = tes3ui.getViewportScale()
    width = width / scale
    height = height / scale
    local halfWidth = width / 2
    local halfHeight = height / 2
    local curPos = tes3.getCursorPosition()

    element.positionX = math.clamp(curPos.x - element.width / 2, -halfWidth, halfWidth - element.width)
    element.positionY = math.clamp(curPos.y + 10, -halfHeight + element.height, halfHeight)

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

    local currentIndex = playerQuests.getCurrentIndex(questId)
    if currentIndex then
        local currentIndexStr = string.format("Current stage: %d", currentIndex)
        local currentIndexLabel = mainBlock:createLabel{ id = infoMenu.currentIndex, text = currentIndexStr }
        currentIndexLabel.borderTop = 10
    end

    updateContainerMenu(mainBlock)
end


---@param parent tes3uiElement
---@param scriptNames table<string, table<string, string>>
---@return boolean|nil ret return true, if contains a script var from "scriptNames"
function this.drawScriptLocalsMenu(parent, scriptNames)
    local ret = false

    local mainBlock = parent:createBlock{ id = scriptLocalsMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.widthProportional = 1
    mainBlock.visible = true

    local function isContainsVarName(scrName, varName)
        local scrData = scriptNames[scrName]

        if not scrData then return false end

        if scrData[varName] then
            return true
        end

        local varsToFind = table.copy(scrData)
        for n, v in pairs(scrData) do
            if not tonumber(v) then
                varsToFind[v] = true
            end
        end

        local scriptData = questLib.getLocalVariableDataByScriptName(scrName)
        if not scriptData then return false end

        local function findInResults()
            local count = table.size(varsToFind)

            for varN, data in pairs(scriptData) do
                for _, valBlock in pairs(data.results) do
                    for _, block in pairs(valBlock) do
                        for _, req in pairs(block) do
                            for n, _ in pairs(varsToFind) do
                                if not varsToFind[req.value] and string.find(req.value or "", n) then
                                    varsToFind[req.value] = true
                                end
                                if not varsToFind[req.variable] and string.find(req.variable or "", n) then
                                    varsToFind[req.variable] = true
                                end
                            end
                        end
                    end
                end
            end

            if count ~= table.size(varsToFind) then findInResults() end
        end

        findInResults()

        if varsToFind[varName] then return true end

        return false
    end

    local wasCreated = false

    for scriptName, varTargetData in pairs(scriptNames) do

        local scriptData = questLib.getLocalVariableDataByScriptName(scriptName)

        if not scriptData then goto continue end

        local divider = mainBlock:createDivider{ id = nil }
        local headerLabel = mainBlock:createLabel{ id = nil, text = string.format("Script \"%s\":", scriptName) }
        headerLabel.color = this.colors.lightYellow

        for varName, varData in pairs(scriptData) do
            if not isContainsVarName(scriptName, varName) then
                goto continue
            end

            wasCreated = true

            local varLabel = mainBlock:createLabel{ id = nil, text = string.format("Variable \"%s\":", varName) }
            varLabel.borderLeft = 5
            varLabel.borderTop = 5

            local varValuesBlock = mainBlock:createBlock{ id = nil }
            varValuesBlock.borderTop = 4
            varValuesBlock.borderLeft = 8
            varValuesBlock.autoHeight = true
            varValuesBlock.widthProportional = 1
            varValuesBlock.flowDirection = tes3.flowDirection.leftToRight

            local varReqsBlock = mainBlock:createBlock{ id = scriptLocalsMenu.requirementsFullBlock }
            varReqsBlock.borderTop = 2
            varReqsBlock.autoHeight = true
            varReqsBlock.widthProportional = 1
            varReqsBlock.flowDirection = tes3.flowDirection.topToBottom

            local varValueLabel = varValuesBlock:createLabel{ id = nil, text = "Value:" }
            varValueLabel.color = this.colors.lightLightYellow
            varValueLabel.borderRight = 10

            for valueStr, resData in pairs(varData.results or {}) do
                local resLabel = varValuesBlock:createLabel{ id = scriptLocalsMenu.resultLabel, text = string.format("- %s -", tostring(valueStr)) }
                resLabel.borderRight = 6
                resLabel.color = this.colors.disabled

                makeLabelSelectable(resLabel)

                resLabel:register(tes3.uiEvent.mouseClick, function (e)
                    for _, child in pairs(varValuesBlock.children) do
                        if child.name == scriptLocalsMenu.resultLabel then
                            child.color = this.colors.disabled
                        end
                    end
                    resLabel.color = this.colors.lightGreen
                    varReqsBlock:destroyChildren()

                    for _, requirements in pairs(resData) do

                        if #varReqsBlock.children > 0 then
                            local block = varReqsBlock:createBlock{ id = nil }
                            block.autoHeight = true
                            block.widthProportional = 1
                            block.flowDirection = tes3.flowDirection.topToBottom
                            block.childAlignX = 0.5

                            local label = block:createLabel{ id = nil, text = "or" }
                        end

                        local requirementData = questLib.getDescriptionDataFromDataBlock(requirements)

                        local reqsBlock = varReqsBlock:createRect{ id = scriptLocalsMenu.requirementsBlock }
                        reqsBlock.alpha = 0.1
                        reqsBlock.autoHeight = true
                        reqsBlock.widthProportional = 1
                        reqsBlock.flowDirection = tes3.flowDirection.topToBottom

                        if requirementData then
                            reqsBlock:setLuaData("requirementData", requirementData)
                            for _, req in pairs(requirementData) do
                                local reqLabel = reqsBlock:createLabel{ id = requirementsMenu.requirementLabel, text = req.str }
                                reqLabel.borderTop = 4
                                reqLabel.color = this.colors.lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)

                                makeLabelSelectable(reqLabel)
                            end
                        else
                            local reqLabel = reqsBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = this.colors.lightDefault
                            reqLabel.borderTop = 4

                            makeLabelSelectable(reqLabel)
                        end
                    end

                    local parentMain = parent:getTopLevelMenu():findChild(mapMenu.block)
                    local scroll = parent:getTopLevelMenu():findChild(requirementsMenu.scroll)
                    if parentMain then
                        updateContainerMenu(parentMain, scroll)
                    else
                        updateContainerMenu(mainBlock, scroll)
                    end
                end)

                if ((varTargetData[varName]) and (varTargetData[varName] == valueStr or not tonumber(valueStr))) or
                        table.find(varTargetData, varName) then
                    resLabel:triggerEvent(tes3.uiEvent.mouseClick)
                    ret = true
                end
            end
            ::continue::
        end

        ::continue::
    end

    if not wasCreated then
        mainBlock.visible = false
    end

    return ret
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string
---@param questData questDataGenerator.questData
---@return boolean|nil
function this.drawQuestRequirementsMenu(parent, questId, index, questData)
    local topicData = questData[tostring(index)]
    if not topicData then return end
    local questName = questData.name or "???"
    local topicIndexStr = tostring(index) or "???"
    local playerCurrentIndex = playerQuests.getCurrentIndex(questId)
    local currentTopicData = questData[tostring(playerCurrentIndex)]
    local playerCurrentIndexStr = tostring(playerCurrentIndex or "???")

    local mainBlock = parent:createBlock{ id = requirementsMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.height = 400
    mainBlock.width = 400
    mainBlock.visible = false

    local scrollBlock = mainBlock:createVerticalScrollPane{ id = requirementsMenu.scroll }
    scrollBlock.heightProportional = 1
    scrollBlock.widthProportional = 1
    scrollBlock.widget.scrollbarVisible = true

    local scrollBlockContent = scrollBlock:getContentElement()

    local headerLabel = scrollBlockContent:createLabel{ id = requirementsMenu.headerLabel, text = string.format("(%s) %s", topicIndexStr, questName) }
    headerLabel.borderBottom = 2

    if currentTopicData and currentTopicData.finished then
        local finishedLabel = scrollBlockContent:createLabel{ id = requirementsMenu.finishedLabel, text = "Finished" }
        finishedLabel.color = this.colors.lightGreen
        finishedLabel.widthProportional = 1
    end

    local showSelectedCurrentBlock = true
    local selectedCurrentBlock = scrollBlockContent:createBlock{ id = requirementsMenu.selectedCurrentBlock }
    selectedCurrentBlock.autoHeight = true
    selectedCurrentBlock.autoWidth = true
    selectedCurrentBlock.flowDirection = tes3.flowDirection.leftToRight
    selectedCurrentBlock.borderBottom = 2
    selectedCurrentBlock.visible = false
    selectedCurrentBlock:createLabel{ id = requirementsMenu.text, text = "Stage:" }.borderRight = 20
    local selLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.selectedLabel, text = string.format("Selected (%s)", topicIndexStr) }
    local lstLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.currentLabel, text = string.format("Current (%s)", playerCurrentIndexStr) }
    lstLabel.borderLeft = 20

    makeLabelSelectable(selLabel)
    makeLabelSelectable(lstLabel)

    local reqIndexMainBlock = scrollBlockContent:createBlock{ id = requirementsMenu.requirementIndexMainBlock }
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

    local indexTabBlock = scrollBlockContent:createBlock{ id = requirementsMenu.indexTabBlock }
    indexTabBlock.autoHeight = true
    indexTabBlock.autoWidth = true
    indexTabBlock.flowDirection = tes3.flowDirection.leftToRight
    indexTabBlock.visible = false

    local reqBlock = scrollBlockContent:createBlock{ id = requirementsMenu.requirementBlock }
    reqBlock.autoHeight = true
    reqBlock.widthProportional = 1
    reqBlock.borderTop = 12
    reqBlock.flowDirection = tes3.flowDirection.topToBottom


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

        local nextIndexes = questLib.getNextIndexes(questData, topicIndex)
        if not nextIndexes then return end

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

            makeLabelSelectable(nextIndexValueLabel)

            nextIndexValueLabel:register(tes3.uiEvent.mouseClick, function (e)

                for _, tb in pairs(nextIndTabs) do
                    tb.color = this.colors.disabled
                end
                e.source.color = this.colors.lightGreen

                indexTabBlock:destroyChildren()

                indexTabBlock:createLabel{ id = requirementsMenu.text, text = "Requirements:" }.borderRight = 10

                local tabs = {}
                for i, reqDataBlock in pairs(indTopicData.requirements or {}) do

                    indexTabBlock.visible = true
                    selectedCurrentBlock.visible = showSelectedCurrentBlock

                    if #tabs > 0 then
                        local textLabel = indexTabBlock:createLabel{ id = requirementsMenu.text, text = "or" }
                        textLabel.borderLeft = 5
                        textLabel.borderRight = 5
                    end

                    local tab = indexTabBlock:createLabel{ id = requirementsMenu.indexTab, text = "-"..tostring(i).."-" }
                    table.insert(tabs, tab)

                    makeLabelSelectable(tab)

                    local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock, questId)
                    tab:setLuaData("requirementData", requirementData)

                    tab:register(tes3.uiEvent.mouseClick, function (e)
                        reqBlock:destroyChildren()

                        ---@type table<string, table<string, string>>
                        local variableScripts = {}

                        if requirementData then
                            reqBlock:setLuaData("requirementData", requirementData)
                            for _, req in pairs(requirementData) do
                                local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = req.str }
                                reqLabel.borderTop = 4
                                reqLabel.color = this.colors.lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)

                                makeLabelSelectable(reqLabel)

                                local reqType = req.data.type
                                local scriptName = req.data.script
                                if scriptName and (reqType == types.requirementType.CustomLocal or reqType == types.requirementType.CustomNotLocal) then
                                    if not variableScripts[scriptName] then
                                        variableScripts[scriptName] = {[req.data.variable] = req.data.value}
                                    else
                                        variableScripts[scriptName][req.data.variable] = req.data.value
                                    end

                                    reqLabel:register(tes3.uiEvent.help, function (e)
                                        local tooltip = tes3ui.createTooltipMenu()

                                        local block = tooltip:createBlock{id = requirementsMenu.localValueTooltipBlock}
                                        block.flowDirection = tes3.flowDirection.topToBottom
                                        block.autoHeight = true
                                        block.autoWidth = false
                                        block.width = 400

                                        if not this.drawScriptLocalsMenu(block, {[scriptName] = {[req.data.variable] = req.data.value}}) then
                                            tooltip:destroy()
                                        else
                                            updateContainerMenu(tooltip)
                                        end
                                    end)
                                end
                            end
                        else
                            local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = this.colors.lightDefault
                            reqLabel.borderTop = 4

                            makeLabelSelectable(reqLabel)
                        end

                        if config.data.journal.requirements.scriptValues and table.size(variableScripts) > 0 then
                            this.drawScriptLocalsMenu(reqBlock, variableScripts)
                        end

                        for _, tb in pairs(tabs) do
                            tb.color = this.colors.disabled
                        end
                        tab.color = this.colors.lightGreen

                        local callback = reqBlock:getLuaData("callback")
                        if callback then
                            callback(reqBlock, requirementData)
                        else
                            updateContainerMenu(mainBlock, scrollBlock)
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

    if config.data.journal.requirements.currentByDefault then
        lstLabel:triggerEvent(tes3.uiEvent.mouseClick)
    else
        selLabel:triggerEvent(tes3.uiEvent.mouseClick)
    end

    updateContainerMenu(mainBlock, scrollBlock)

    mainBlock.visible = indexTabBlock.visible or nextIndexLabel.visible or selectedCurrentBlock.visible

    return mainBlock.visible
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
---@param pane tes3uiElement
---@return number x, number y
local function convertObjectPosToWorldPaneCoordinates(params, pane)
    local currentZoomX = pane.width /  tes3.dataHandler.nonDynamicData.mapTexture.width
    local currentZoomY = pane.height / tes3.dataHandler.nonDynamicData.mapTexture.height

    local zoomBar = mapMarkerLib.menu.uiExpZoomBar
    local xOffset = 4
    local yOffset = 4
    if zoomBar then
        xOffset = 0
        yOffset = 0
    else
        if mcp_mapExpansion then
            xOffset = 1
            yOffset = 2
        end
    end

    local x = ((-mapMarkerLib.worldBounds.minX + params.x / 8192) * mapMarkerLib.worldBounds.cellResolution + xOffset) * currentZoomX
    local y = ((-mapMarkerLib.worldBounds.maxY - 1 + params.y / 8192) * mapMarkerLib.worldBounds.cellResolution - yOffset) * currentZoomY

    return x, y
end

---@param params questGuider.ui.createMarker.params
---@return tes3uiElement|nil
---@return number|nil alignX
---@return number|nil alignY
local function createMarker(params)
    if not params.pane then return end
    if not params.markerData or not params.markerData.path then return end

    local image = params.pane:createImage{id = mapMenu.marker, path = params.markerData.path}

    if not image then return end

    local x, y = convertObjectPosToWorldPaneCoordinates(params, params.pane)

    local alignX = x / params.pane.width
    local alignY = -y / params.pane.height

    image.autoHeight = true
    image.autoWidth = true
    image.absolutePosAlignX = math.max(0, math.min(1, alignX))
    image.absolutePosAlignY = math.max(0, math.min(1, alignY))
    image.color = params.color or {1, 1, 1}

    image:setLuaData("records", {params})

    local tooltip = tooltipLib.new{parent = image}
    tooltip:add{name = params.name, description = params.description}

    return image, alignX, alignY
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

    local imageWidth = tes3.dataHandler.nonDynamicData.mapTexture.width
    local imageHeight = tes3.dataHandler.nonDynamicData.mapTexture.height

    local pane = mapBlock:createBlock{ id = mapMenu.pane }
    pane.width = imageWidth
    pane.height = imageHeight
    pane.ignoreLayoutX = true
    pane.ignoreLayoutY = true

    local mapMarkersBlock = pane:createBlock{ id = mapMenu.markerBlock }
    mapMarkersBlock.widthProportional = 1
    mapMarkersBlock.heightProportional = 1
    mapMarkersBlock.childAlignX = 0
    mapMarkersBlock.childAlignY = 1
    mapMarkersBlock.ignoreLayoutX = true
    mapMarkersBlock.ignoreLayoutY = true
    mapMarkersBlock.width = imageWidth
    mapMarkersBlock.height = imageHeight

    mapMarkersBlock:getTopLevelMenu():updateLayout()

    if not this.drawQuestRequirementsMenu(reqBlock, questId, index, questData) then
        return false
    end

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

        ---@type { parent : tes3uiElement, marker : tes3uiElement }[]
        local markers = {}

        ---@param e tes3uiEventData
        local function mouseOver(e)
            local parentEl = e.source
            for _, markerDt in pairs(markers) do
                if parentEl.color[1] ~= markerDt.parent.color[1] or
                        parentEl.color[2] ~= markerDt.parent.color[2] or
                        parentEl.color[3] ~= markerDt.parent.color[3] then
                    markerDt.marker.visible = false
                end
            end
        end

        ---@param e tes3uiEventData
        local function mouseLeave(e)
            for _, markerDt in pairs(markers) do
                markerDt.marker.visible = true
            end
        end

        ---@param child tes3uiElement
        local function processChild(child)
            if child.name ~= requirementsMenu.requirementLabel and child.name ~= scriptLocalsMenu.requirementLabel then return end

            ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
            local reqData = child:getLuaData("requirement")
            if not reqData or not reqData.objects then return end

            local color = markerColors[colorIndex]

            local objectIds = {}

            local foundObjectsInChildren = 0
            for _, objId in pairs(reqData.objects) do

                local obj = tes3.getObject(objId)
                local objName = obj and obj.name
                local objPosData = questLib.getObjectPositionData(objId)

                if not objPosData then goto continue1 end

                foundObjectsInChildren = foundObjectsInChildren + 1

                local trackingObj = trackingLib.getObjectData(objId)

                if trackingObj then
                    color = trackingObj.color
                    if colorOfObject[objId] then colorOfObject[objId] = color end
                end

                if colorOfObject[objId] then
                    color = colorOfObject[objId]
                    goto continue1
                else
                    colorOfObject[objId] = color
                end

                objectIds[objId] = true

                for _, posData in pairs(objPosData) do
                    local x = posData.pos[1]
                    local y = posData.pos[2]

                    local cellPath
                    local doorPath

                    if posData.name then
                        local cell = tes3.getCell{id = posData.name}
                        if cell then
                            local exCellPos
                            exCellPos, doorPath, cellPath = cellLib.findExitPos(cell)
                            if exCellPos then
                                x = exCellPos.x
                                y = exCellPos.y
                            else
                                goto continue2
                            end
                        end
                    end

                    table.insert(markersData, { parent = child, x = x, y = y, color = color, objId = objId, objName = objName, cellPath = cellPath })
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
                    for objId, _ in pairs(reqData.objects) do
                        trackingLib.addMarker{objectId = objId, color = color, questId = questId, questStage = index}
                    end
                    trackingLib.updateMarkers(true)
                    drawMarkers(reqBl)
                end

                child:register(tes3.uiEvent.mouseClick, mouseClick)
            end
        end

        for _, child in pairs(reqBl.children) do
            processChild(child)
        end

        local scriptBlock = reqBl:findChild(scriptLocalsMenu.block)
        if scriptBlock then
            for children in table.traverse({scriptBlock}, "children") do
                processChild(children)
            end
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
                    for i = #data.cellPath, 1, -1 do
                        descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].editorName) or string.format("\"%s\"",
                            data.cellPath[i].editorName)
                    end
                end

                local im, alignX, alignY = createMarker{pane = mapMarkersBlock, markerData = this.markers.quest,
                    x = data.x, y = data.y, color = data.color,
                    name = data.objName,
                    description = descr,
                }

                if im then
                    table.insert(markers, {marker = im, parent = data.parent})
                    minMaxAlignX[1] = math.min(minMaxAlignX[1], alignX)
                    minMaxAlignX[2] = math.max(minMaxAlignX[2], alignX)
                    minMaxAlignY[1] = math.min(minMaxAlignY[1], alignY)
                    minMaxAlignY[2] = math.max(minMaxAlignY[2], alignY)
                end
            end

            local xDiff = minMaxAlignX[2] - minMaxAlignX[1]
            local yDiff = minMaxAlignY[2] - minMaxAlignY[1]
            local xCenter = (minMaxAlignX[1] + minMaxAlignX[2]) / 2
            local yCenter = (minMaxAlignY[1] + minMaxAlignY[2]) / 2
            local xScale = mapBlock.width / (xDiff * 1.5 * imageWidth)
            local yScale = mapBlock.height / (yDiff * 1.5 * imageHeight)
            local scale = math.max(0.1, math.min(config.data.journal.map.maxScale, xScale, yScale))

            mapMarkersBlock.width = imageWidth * scale
            mapMarkersBlock.height = imageHeight * scale
            pane.width = imageWidth * scale
            pane.height = imageHeight * scale

            image.imageScaleX = scale
            image.imageScaleY = scale

            pane.positionX = math.clamp(-xCenter * pane.width + mapBlock.width / 2, -(pane.width - mapBlock.width), 0)
            pane.positionY = math.clamp(yCenter * pane.height - mapBlock.height / 2, 0, pane.height - mapBlock.height)
        end

        ::continue::

        local scroll = parent:getTopLevelMenu():findChild(requirementsMenu.scroll)
        updateContainerMenu(mainBlock, scroll)
    end

    drawMarkers(innMenuReqBlock)

    innMenuReqBlock:setLuaData("callback", function(reqBl)
        drawMarkers(reqBl)
    end)

    return true
end


---@param label string
---@param callback fun( menu : tes3uiElement, buttonBlock : tes3uiElement)?
function this.drawContainer(label, callback)
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
    buttonBlock.childAlignX = 1

    if callback then
        callback(element, buttonBlock)
    end

    local closeButton = buttonBlock:createButton{ id = containerMenu.closeBtn, text = "Close"}
    closeButton:register(tes3.uiEvent.mouseClick, function (e)
        element:destroy()
    end)

    return element, buttonBlock
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
    if not config.data.journal.map.enabled and
            not config.data.journal.requirements.enabled and
            not config.data.journal.info.enabled then
        return
    end

    local menu = tes3ui.findMenu("MenuJournal")
    if not menu then return end

    if menu:findChild(journalMenu.requirementBlock) then
        return
    end

    for _, pageName in pairs({"MenuBook_page_1", "MenuBook_page_2"}) do
        local page = menu:findChild(pageName)

        if not page then goto continue end

        local isDescription = true
        for i, element in pairs(page.children) do

            if element.type == tes3.uiElementType.text then
                element.height = 4
            end
            if element.name ~= "MenuBook_hypertext" then goto continue end

            isDescription = not isDescription
            if not isDescription then
                element.borderAllSides = -1
                goto continue
            end

            local questInfo = questLib.getQuestInfoByJournalText(element.text)

            if not questInfo then goto continue end

            local questId = questInfo[1].id
            local questIndex = questInfo[1].index
            local quest = questLib.getQuestData(questId)

            if not quest then goto continue end

            local function createTrackAllButton(menuEl, buttonBlock)
                local trackButton = buttonBlock:createButton{ id = containerMenu.trackBtn, text = "Track all" }
                trackButton:register(tes3.uiEvent.mouseClick, function (e)
                    trackingLib.trackQuestsFromQuest(questId, questIndex)
                    local innMenuReqBlock = menuEl:findChild(requirementsMenu.requirementBlock)
                    if innMenuReqBlock then
                        local drawFunc = innMenuReqBlock:getLuaData("callback")
                        if drawFunc then
                            drawFunc(innMenuReqBlock)
                        end
                    end
                end)
            end

            local block = page:createBlock{ id = journalMenu.requirementBlock }
            page:reorderChildren(element, block, 1)
            block.flowDirection = tes3.flowDirection.leftToRight
            block.autoHeight = true
            block.autoWidth = true

            if config.data.journal.info.enabled then
                local infoBlock = block:createBlock{ id = journalMenu.questNameBlock }
                infoBlock.autoHeight = true
                infoBlock.autoWidth = false
                infoBlock.borderRight = 5
                infoBlock.width = math.max(1, page.width - 42)

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
                    this.centerToCursor(el)
                end)
            end

            if config.data.journal.requirements.enabled then
                local reqLabel = block:createImage{ id = journalMenu.requirementsIcon, path = "Icons\\m\\Tx_parchment_02.tga" }
                reqLabel.imageScaleX = 0.5
                reqLabel.imageScaleY = 0.5
                reqLabel.borderRight = 2

                reqLabel:register(tes3.uiEvent.help, function (ei)
                    local tooltip = tes3ui.createTooltipMenu()
                    if not this.drawQuestRequirementsMenu(tooltip, questId, questIndex, quest) then
                        tooltip:destroy()
                    end
                end)
                reqLabel:register(tes3.uiEvent.mouseClick, function (ei)
                    local el, buttonBlock = this.drawContainer("Requirements", createTrackAllButton)

                    if not el or not buttonBlock then return end

                    if not this.drawQuestRequirementsMenu(el, questId, questIndex, quest) then
                        el:destroy() ---@diagnostic disable-line: need-check-nil
                        return
                    end
                    this.centerToCursor(el)
                end)
            end

            if config.data.journal.map.enabled then
                local mapLabel = block:createImage{ id = journalMenu.mapIcon, path = "Icons\\m\\Tx_note_02.tga" }
                mapLabel.imageScaleX = 0.5
                mapLabel.imageScaleY = 0.5

                mapLabel:register(tes3.uiEvent.help, function (ei)
                    local tooltip = tes3ui.createTooltipMenu()
                    if not this.drawMapMenu(tooltip, questId, questIndex, quest) then
                        tooltip:destroy()
                    end
                end)
                mapLabel:register(tes3.uiEvent.mouseClick, function (ei)
                    local el, buttonBlock = this.drawContainer("Map", createTrackAllButton)

                    if not el or not buttonBlock then return end

                    if not this.drawMapMenu(el, questId, questIndex, quest) then
                        el:destroy() ---@diagnostic disable-line: need-check-nil
                        return
                    end
                    this.centerToCursor(el)
                end)
            end

            ::continue::
        end

        ::continue::
    end
end

return this