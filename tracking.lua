local storage = include("diject.quest_guider.storage.localStorage")
local markerLib = include("diject.map_markers.interop")
local stringLib = include("diject.quest_guider.utils.string")
local colors = include("diject.quest_guider.Types.gradient")
local dataHandler = include("diject.quest_guider.dataHandler")
local cellLib = include("diject.quest_guider.cell")
local questLib = include("diject.quest_guider.quest")
local playerQuests = include("diject.quest_guider.playerQuests")
local config = include("diject.quest_guider.config")

local log = include("diject.quest_guider.utils.log")

local storageLabel = "tracking"

local this = {}

---@class questGuider.tracking.markerImage
---@field path string
---@field pathAbove string|nil
---@field pathBelow string|nil
---@field scale number
---@field shiftX integer
---@field shiftY integer

---@type questGuider.tracking.markerImage
this.localMarkerImageInfo = { path = "diject\\quest guider\\circleMarker16x16.dds",
        pathAbove = "diject\\quest guider\\circleMarkerUp16x16.dds", pathBelow = "diject\\quest guider\\circleMarkerDown16x16.dds", shiftX = -4, shiftY = 4, scale = 0.5 }
---@type questGuider.tracking.markerImage
this.localDoorMarkerImageInfo = { path = "diject\\quest guider\\circleMarker16x16.dds",
        pathAbove = "diject\\quest guider\\circleMarkerUp16x16.dds", pathBelow = "diject\\quest guider\\circleMarkerDown16x16.dds", shiftX = -4, shiftY = 4, scale = 0.5 }
---@type questGuider.tracking.markerImage
this.worldMarkerImageInfo = { path = "diject\\quest guider\\circleMarker8.dds", shiftX = -4, shiftY = 4, scale = 1 }
---@type questGuider.tracking.markerImage
this.questGiverImageInfo = { path = "diject\\quest guider\\exclamationMark8x16.dds", shiftX = -3, shiftY = 10, scale = 0.75 }

---@class questGuider.tracking.storageData
---@field markerByObjectId table<string, questGuider.tracking.markerRecord>?
---@field trackedObjectsByQuestId table<string, {objects : table<string, string[]>, color : number[]}>?
---@field colorId integer?

---@type questGuider.tracking.storageData
this.storageData = {} -- data of quest map markers

---@type table<string, boolean>
this.scannedCellsForTemporaryMarkers = {}

---@class questGuider.tracking.markerRecord
---@field quests table<string, {id : string, index : integer}>
---@field color number[]
---@field localMarkerId string|nil
---@field localDoorMarkerId string|nil
---@field worldMarkerId string|nil

---@type table<string, questGuider.tracking.markerRecord>
this.markerByObjectId = {}

---@type table<string, {objects : table<string, string[]>, color : number[]}>
this.trackedObjectsByQuestId = {}


this.callbackToUpdateMapMenu = nil

local initialized = false

---@return boolean isSuccessful
function this.init()
    initialized = false
    if not markerLib then return false end
    if not storage.isPlayerStorageReady() then
        storage.initPlayerStorage()
    end
    if not storage.player then return false end

    if not storage.player[storageLabel] then
        storage.player[storageLabel] = {colorId = 1}
    end
    this.storageData = storage.player[storageLabel]
    this.storageData.markerByObjectId = this.storageData.markerByObjectId or {}
    this.storageData.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId or {}

    this.markerByObjectId = this.storageData.markerByObjectId
    this.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId

    this.scannedCellsForTemporaryMarkers = {}

    initialized = true
    return initialized
end

function this.reset()
    initialized = false
    this.callbackToUpdateMapMenu = nil
    this.markerByObjectId = {}
    this.trackedObjectsByQuestId = {}
    this.scannedCellsForTemporaryMarkers = {}
end

function this.isInit()
    if not initialized then
        return this.init()
    end
    return true
end

local function runCallbacks()
    if this.callbackToUpdateMapMenu then
        this.callbackToUpdateMapMenu()
    end
end

---@class questGuider.tracking.addMarker
---@field questId string should be lower
---@field questStage integer
---@field objectId string should be lower
---@field color number[]|nil
---@field associatedNumber number|nil not used

---@param params questGuider.tracking.addMarker
---@return boolean|nil
---@return boolean|nil
function this.addMarker(params)
    if not initialized then return end

    local objectId = params.objectId
    local object = tes3.getObject(objectId) or tes3.getScript(objectId)

    if not object then return end

    local objectPositions = questLib.getObjectPositionData(objectId)

    if not objectPositions or #objectPositions > config.data.tracking.maxPositions then return end

    local questData = questLib.getQuestData(params.questId)

    if not questData then return end

    local qTrackingInfo
    if this.trackedObjectsByQuestId[params.questId] then
        qTrackingInfo = this.trackedObjectsByQuestId[params.questId]
    else
        local colorId = math.min(this.storageData.colorId, #colors)
        qTrackingInfo = {objects = {}, color = colors[colorId]}
        this.storageData.colorId = colorId < #colors and colorId + 1 or 1
    end

    local objectTrackingData = this.markerByObjectId[objectId]
    if not objectTrackingData then

        local color = table.copy(qTrackingInfo.color)

        local objNum = table.size(qTrackingInfo.objects)
        color[1] = math.clamp(color[1] + (objNum % 3 == 0 and (math.random() > 0.5 and -0.25 or 0.25) or 0) + (math.random() - 0.5) * 0.25, 0, 1)
        color[2] = math.clamp(color[2] + (objNum % 3 == 1 and (math.random() > 0.5 and -0.25 or 0.25) or 0) + (math.random() - 0.5) * 0.25, 0, 1)
        color[3] = math.clamp(color[3] + (objNum % 3 == 2 and (math.random() > 0.5 and -0.25 or 0.25) or 0) + (math.random() - 0.5) * 0.25, 0, 1)

        objectTrackingData = { quests = {}, color = color } ---@diagnostic disable-line: missing-fields
    end

    objectTrackingData.localMarkerId = objectTrackingData.localMarkerId or markerLib.addRecord{
        path = this.localMarkerImageInfo.path,
        pathAbove = this.localMarkerImageInfo.pathAbove,
        pathBelow = this.localMarkerImageInfo.pathBelow,
        color = objectTrackingData.color,
        textureShiftX = this.localMarkerImageInfo.shiftX,
        textureShiftY = this.localMarkerImageInfo.shiftY,
        scale = this.localMarkerImageInfo.scale,
        name = object.name,
        description = string.format("Quest: \"%s\"", questData.name or "")
    }
    objectTrackingData.worldMarkerId = objectTrackingData.worldMarkerId or markerLib.addRecord{
        path = this.worldMarkerImageInfo.path,
        color = objectTrackingData.color,
        textureShiftX = this.worldMarkerImageInfo.shiftX,
        textureShiftY = this.worldMarkerImageInfo.shiftY,
        scale = this.worldMarkerImageInfo.scale,
        name = object.name,
        description = string.format("Quest: \"%s\"", questData.name or "")
    }

    if not objectTrackingData.localMarkerId and not objectTrackingData.worldMarkerId then return end

    if not objectTrackingData.quests then objectTrackingData.quests = {} end
    objectTrackingData.quests[params.questId] = { id = params.questId, index = params.questStage }

    local objects = {}
    objects[objectId] = true

    for _, positionData in pairs(objectPositions) do

        if objectTrackingData.localMarkerId then

            if positionData.type == 1 then
                markerLib.addLocalMarker{
                    recordId = objectTrackingData.localMarkerId,
                    objectId = objectId,
                }

            elseif positionData.type == 2 then
                objects[positionData.id] = true
                markerLib.addLocalMarker{
                    recordId = objectTrackingData.localMarkerId,
                    objectId = positionData.id,
                    itemId = objectId,
                }

            elseif positionData.type == 4 then
                objects[positionData.id] = true
                markerLib.addLocalMarker{
                    recordId = objectTrackingData.localMarkerId,
                    objectId = positionData.id,
                }
            end

        end

        if positionData.grid then

            if objectTrackingData.worldMarkerId then
                markerLib.addWorldMarker{
                    recordId = objectTrackingData.worldMarkerId,
                    x = positionData.pos[1],
                    y = positionData.pos[2],
                }
            end

        else
            local cell = tes3.getCell{id = positionData.name}
            if cell then

                local exitPos, path = cellLib.findExitPos(cell)

                if exitPos and objectTrackingData.worldMarkerId then
                    markerLib.addWorldMarker{
                        recordId = objectTrackingData.worldMarkerId,
                        x = exitPos.x,
                        y = exitPos.y,
                    }
                end

                if path then
                    objectTrackingData.localDoorMarkerId = objectTrackingData.localDoorMarkerId or markerLib.addRecord{
                        path = this.localDoorMarkerImageInfo.path,
                        pathAbove = this.localDoorMarkerImageInfo.pathAbove,
                        pathBelow = this.localDoorMarkerImageInfo.pathBelow,
                        color = objectTrackingData.color,
                        textureShiftX = this.localDoorMarkerImageInfo.shiftX,
                        textureShiftY = this.localDoorMarkerImageInfo.shiftY,
                        scale = this.localDoorMarkerImageInfo.scale,
                        name = object.name,
                        description = string.format("Quest: \"%s\"", questData.name or "")
                    }

                    if objectTrackingData.localDoorMarkerId then
                        for i = #path, 1, -1 do
                            local node = path[i]
                            local markerPos = node.marker.position
                            markerLib.addLocalMarker{
                                recordId = objectTrackingData.localDoorMarkerId,
                                cellName = node.cell.isInterior == true and node.cell.name or nil,
                                position = markerPos,
                            }
                        end
                    end
                end
            end
        end
    end

    for objId, _ in pairs(objects) do
        this.markerByObjectId[objId] = objectTrackingData
    end

    qTrackingInfo.objects[objectId] = table.keys(objects)

    this.trackedObjectsByQuestId[params.questId] = qTrackingInfo
    return true
end

---@class questGuider.tracking.addMarkersForQuest
---@field questId string should be lowercase
---@field questIndex integer|string

---@param params questGuider.tracking.addMarkersForQuest
function this.addMarkersForQuest(params)

    local questData = questLib.getQuestData(params.questId)
    if not questData then return end

    local indexStr = tostring(params.questIndex)
    local indexData = questData[indexStr]
    if not indexData then return end

    for i, reqDataBlock in pairs(indexData.requirements or {}) do

        local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock)
        if not requirementData then goto continue end

        for _, requirement in ipairs(requirementData) do
            for _, objId in pairs(requirement.objects or {}) do

                local objPosData = questLib.getObjectPositionData(objId)
                if not objPosData then goto continue end

                this.addMarker{ objectId = objId, questId = params.questId, questStage = params.questIndex }

                ::continue::
            end
        end

        ::continue::
    end
end


---@class questGuider.tracking.removeMarker
---@field questId string|nil should be lowercase
---@field objectId string|nil should be lowercase

---@param params questGuider.tracking.removeMarker
function this.removeMarker(params)
    if not params.questId and not params.objectId then return end

    local function removeMarkersFromObject(id)
        local objData = this.markerByObjectId[id]
        if not objData then return end

        if objData.worldMarkerId then
            markerLib.removeRecord(objData.worldMarkerId)
        end

        if objData.localMarkerId then
            markerLib.removeRecord(objData.localMarkerId)
        end

        if objData.localDoorMarkerId then
            markerLib.removeRecord(objData.localDoorMarkerId)
        end

        this.markerByObjectId[id] = nil
    end

    local function removeFromObject(objectId)
        local data = this.markerByObjectId[objectId]
        if data then
            for qId, dt in pairs(data.quests or {}) do
                local questTrackedData = this.trackedObjectsByQuestId[dt.id]
                if questTrackedData then
                    removeMarkersFromObject(objectId)
                    for _, objId in pairs(questTrackedData.objects[objectId] or {}) do
                        this.markerByObjectId[objId] = nil
                    end
                    questTrackedData.objects[objectId] = nil

                    if table.size(questTrackedData.objects) == 0 then
                        this.trackedObjectsByQuestId[dt.id] = nil
                    end
                end
            end
        end
    end

    if params.questId then

        local questTrackedData = this.trackedObjectsByQuestId[params.questId]
        if questTrackedData then
            local protectedMarkerIds = {}
            local markerIdsToRemove = {}
            for parentObjId, objId in pairs(table.keys(questTrackedData.objects)) do
                local objectData = this.markerByObjectId[objId]
                if not objectData then goto continue end

                objectData.quests[params.questId] = nil

                markerIdsToRemove[objectData.localDoorMarkerId or ""] = true
                markerIdsToRemove[objectData.localMarkerId or ""] = true
                markerIdsToRemove[objectData.worldMarkerId or ""] = true

                if table.size(objectData.quests) == 0 then
                    this.markerByObjectId[objId] = nil
                else
                    protectedMarkerIds[objectData.localDoorMarkerId or ""] = true
                    protectedMarkerIds[objectData.localMarkerId or ""] = true
                    protectedMarkerIds[objectData.worldMarkerId or ""] = true
                end

                ::continue::
            end

            markerIdsToRemove[""] = nil
            for markerId, _ in pairs(markerIdsToRemove) do
                if not protectedMarkerIds[markerId] then
                    markerLib.removeRecord(markerId)
                end
            end

            this.trackedObjectsByQuestId[params.questId] = nil
        end
    end

    if params.objectId then
        removeFromObject(params.objectId)
    end

end

function this.removeMarkers()
    local questIds = table.keys(this.trackedObjectsByQuestId)

    for _, qId in pairs(questIds) do
        this.removeMarker{ questId = qId }
    end
end

---@param trackedObjectId string
---@param priority number?
---@return boolean|nil
function this.changeObjectMarkerColor(trackedObjectId, color, priority)
    local data = this.markerByObjectId[trackedObjectId]
    if not data then return end

    if data.localMarkerId then
        local record = markerLib.getRecord(data.localMarkerId)
        if record then
            record.color = table.copy(color)
            if priority then
                record.priority = priority
            end
        end
    end

    if data.worldMarkerId then
        local record = markerLib.getRecord(data.worldMarkerId)
        if record then
            record.color = table.copy(color)
            if priority then
                record.priority = priority
            end
        end
    end

    if data.localDoorMarkerId then
        local record = markerLib.getRecord(data.localDoorMarkerId)
        if record then
            record.color = table.copy(color)
            if priority then
                record.priority = priority
            end
        end
    end

    return true
end


function this.updateMarkers(callbacks)
    if callbacks then
        runCallbacks()
    end
    markerLib.updateWorldMarkers(true)
    markerLib.updateLocalMarkers(true)
end


---@param questId string should be lowercase
function this.getQuestData(questId)
    return this.trackedObjectsByQuestId[questId]
end

---@param objectId string should be lowercase
function this.getObjectData(objectId)
    return this.markerByObjectId[objectId]
end


---@param cell tes3cell
function this.createQuestGiverMarkers(cell)
    if this.scannedCellsForTemporaryMarkers[cell.editorName] then return end
    this.scannedCellsForTemporaryMarkers[cell.editorName] = true

    for ref in cell:iterateReferences{ tes3.objectType.npc, tes3.objectType.creature } do
        local objectId = ref.baseObject.id
        local objectData = questLib.getObjectData(objectId)
        if not objectData or not objectData.starts then goto continue end

        local questNames = {}

        for _, questId in pairs(objectData.starts) do
            local questIdLower = questId:lower()
            local questData = questLib.getQuestData(questIdLower)
            if not questData or not questData.name then goto continue end

            local playerData = playerQuests.getQuestData(questId)
            if not playerData or (config.data.tracking.hideStarted and playerData.index > 0) then
                goto continue
            end

            table.insert(questNames, questData.name)

            ::continue::
        end

        if #questNames <= 0 then goto continue end

        local recordId = markerLib.addRecord{
            path = this.questGiverImageInfo.path,
            pathAbove = this.questGiverImageInfo.pathAbove,
            pathBelow = this.questGiverImageInfo.pathBelow,
            color = tes3ui.getPalette(tes3.palette.normalColor),
            textureShiftX = this.questGiverImageInfo.shiftX,
            textureShiftY = this.questGiverImageInfo.shiftY,
            scale = this.questGiverImageInfo.scale,
            priority = -100,
            temporary = true,
            name = ref.baseObject.name,
            description = stringLib.getValueEnumString(questNames, config.data.tracking.giver.namesMax, "Starts %s")
        }

        markerLib.addLocalMarker{
            recordId = recordId,
            trackedRef = ref,
            temporary = true,
        }

        ::continue::
    end
end


---@param questId string should be lowercase
---@param e journalEventData
function this.trackQuestFromCallback(questId, e)
    local shouldUpdate = false

    local questTrackingData = this.getQuestData(questId)
    if questTrackingData then
        this.removeMarker{ questId = questId }
        shouldUpdate = true
    end

    local questNextIndexes = questLib.getNextIndexes(questId, e.index)

    if not questNextIndexes or e.info.isQuestFinished then
        this.removeMarker{ questId = questId }
        this.updateMarkers(true)
    elseif questNextIndexes then
        for _, indexStr in pairs(questNextIndexes) do
            this.addMarkersForQuest{ questId = questId, questIndex = indexStr }
        end
        shouldUpdate = true
    end

    if shouldUpdate then
        this.updateMarkers(true)
    end
end

return this