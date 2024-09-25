local storage = include("diject.quest_guider.storage.localStorage")
local markerLib = include("diject.map_markers.interop")
local colors = include("diject.quest_guider.Types.color")
local dataHandler = include("diject.quest_guider.dataHandler")
local cellLib = include("diject.quest_guider.cell")
local questLib = include("diject.quest_guider.quest")

local log = include("diject.quest_guider.utils.log")

local storageLabel = "tracking"

local this = {}

---@class questGuider.tracking.markerImage
---@field path string
---@field scale number
---@field shiftX integer
---@field shiftY integer

---@type questGuider.tracking.markerImage
this.localMarkerImageInfo = { path = "diject\\quest guider\\circleMarker8.dds", shiftX = -4, shiftY = 4, scale = 1 }
---@type questGuider.tracking.markerImage
this.localDoorMarkerImageInfo = { path = "diject\\quest guider\\circleMarker8.dds", shiftX = -4, shiftY = 4, scale = 1 }
---@type questGuider.tracking.markerImage
this.worldMarkerImageInfo = { path = "diject\\quest guider\\circleMarker8.dds", shiftX = -4, shiftY = 4, scale = 1 }

this.storageData = {}

---@class questGuider.tracking.markerRecord
---@field questId string
---@field questStage integer
---@field localMarkerId string|nil
---@field localDoorMarkerId string|nil
---@field worldMarkerId string|nil
---@field activationLimit integer|nil

---@type table<string, questGuider.tracking.markerRecord>
this.markerByObjectId = {}

---@type table<string, {objects : table<string, boolean>, color : number[]}>
this.trackedObjectsByQuestId = {}


local initialized = false

---@return boolean isSuccessful
function this.init()
    initialized = false
    if not markerLib then return false end
    if not storage.player then return false end

    if not storage.player[storageLabel] then
        storage.player[storageLabel] = {colorId = 1}
    end
    this.storageData = storage.player[storageLabel]
    this.storageData.markerByObjectId = this.storageData.markerByObjectId or {}
    this.storageData.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId or {}

    this.markerByObjectId = this.storageData.markerByObjectId
    this.trackedObjectsByQuestId = this.storageData.trackedObjectsByQuestId

    initialized = true
    return initialized
end

function this.reset()
    initialized = false
    this.markerByObjectId = {}
    this.trackedObjectsByQuestId = {}
end

---@class questGuider.tracking.addMarker
---@field questId string should be lower
---@field questStage integer
---@field objectId string should be lower
---@field color number[]|nil
---@field activationLimit integer|nil

---@param params questGuider.tracking.addMarker
---@return boolean|nil
function this.addMarker(params)
    if not initialized then return end

    local objectId = params.objectId
    local object = tes3.getObject(objectId) or tes3.getScript(objectId)

    if not object then return end

    local objectPositions = questLib.getObjectPositionData(objectId)

    if not objectPositions then return end

    local questData = dataHandler.quests[params.questId]

    if not questData then return end

    local objectOldTrackingData = this.markerByObjectId[objectId]
    if objectOldTrackingData then
        if objectOldTrackingData.localMarkerId then
            markerLib.removeRecord(objectOldTrackingData.localMarkerId)
        end
        if objectOldTrackingData.worldMarkerId then
            markerLib.removeRecord(objectOldTrackingData.worldMarkerId)
        end
    end

    local qTrackingInfo
    if this.trackedObjectsByQuestId[params.questId] then
        qTrackingInfo = this.trackedObjectsByQuestId[params.questId]
    else
        local colorId = math.min(this.storageData.colorId, #colors)
        qTrackingInfo = {objects = {}, color = colors[colorId]}
        this.storageData.colorId = colorId < #colors and colorId + 1 or 1
    end

    local localMarkerId = markerLib.addRecord{
        path = this.localMarkerImageInfo.path,
        color = qTrackingInfo.color,
        textureShiftX = this.localMarkerImageInfo.shiftX,
        textureShiftY = this.localMarkerImageInfo.shiftY,
        scale = this.localMarkerImageInfo.scale,
        name = object.name,
        description = string.format("Quest: \"%s\"", questData.name or "")
    }
    local worldMarkerId = markerLib.addRecord{
        path = this.worldMarkerImageInfo.path,
        color = qTrackingInfo.color,
        textureShiftX = this.worldMarkerImageInfo.shiftX,
        textureShiftY = this.worldMarkerImageInfo.shiftY,
        scale = this.worldMarkerImageInfo.scale,
        name = object.name,
        description = string.format("Quest: \"%s\"", questData.name or "")
    }
    local localDoorMarkerId

    if not localMarkerId and not worldMarkerId then return end

    for _, positionData in pairs(objectPositions) do
        if localMarkerId then
            if positionData.type == 1 then
                markerLib.addLocalMarker{
                    id = localMarkerId,
                    -- cellName = positionData.grid == nil and positionData.name or nil,
                    -- x = positionData.position[1],
                    -- y = positionData.position[2],
                    -- z = positionData.position[3],
                    objectId = objectId,
                }
            elseif positionData.type == 2 then
                markerLib.addLocalMarker{
                    id = localMarkerId,
                    objectId = positionData.id,
                    itemId = objectId,
                }
            elseif positionData.type == 4 then
                markerLib.addLocalMarker{
                    id = localMarkerId,
                    objectId = positionData.id,
                }
            end
        end

        if positionData.grid then

            if worldMarkerId then
                markerLib.addWorldMarker{
                    id = worldMarkerId,
                    x = positionData.position[1],
                    y = positionData.position[2],
                }
            end

        else
            local cell = tes3.getCell{id = positionData.name}
            if cell then

                local exitPos, path = cellLib.findExitPos(cell)

                if exitPos and worldMarkerId then
                    markerLib.addWorldMarker{
                        id = worldMarkerId,
                        x = exitPos.x,
                        y = exitPos.y,
                    }
                end

                if path then
                    localDoorMarkerId = markerLib.addRecord{
                        path = this.localDoorMarkerImageInfo.path,
                        color = qTrackingInfo.color,
                        textureShiftX = this.localDoorMarkerImageInfo.shiftX,
                        textureShiftY = this.localDoorMarkerImageInfo.shiftY,
                        scale = this.localDoorMarkerImageInfo.scale,
                        name = object.name,
                        description = string.format("Quest: \"%s\"", questData.name or "")
                    }

                    if localDoorMarkerId then
                        for i = #path, 1, -1 do
                            local node = path[i]
                            local markerPos = node.marker.position
                            markerLib.addLocalMarker{
                                id = localDoorMarkerId,
                                cellName = node.cell.isInterior == true and node.cell.name or nil,
                                x = markerPos.x,
                                y = markerPos.y,
                                z = markerPos.z,
                            }
                        end
                    end
                end
            end
        end
    end

    this.markerByObjectId[objectId] = {
        questId = params.questId,
        questStage = params.questStage,
        localMarkerId = localMarkerId,
        localDoorMarkerId = localDoorMarkerId,
        worldMarkerId = worldMarkerId,
    }

    this.trackedObjectsByQuestId[params.questId] = qTrackingInfo
    return true
end

function this.updateMarkers()
    markerLib.updateLocalMarkers()
    markerLib.updateWorldMarkers()
end

return this