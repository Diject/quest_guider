---@type questGuider.markers.data
return {
    ---@type string
    name = "Skyrim style (big)",
    ---@type { marker : questGuider.ui.markerImage }
    journal = {
        marker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", shiftX = -6, shiftY = 23, scale = 0.75 },
    },
    ---@type { localMarker : questGuider.tracking.markerImage, doorMarker : questGuider.tracking.markerImage, worldMarker : questGuider.tracking.markerImage, questGiverMarker : questGuider.tracking.markerImage }
    tracking = {
        ---@type questGuider.tracking.markerImage
        localMarker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimMarkerDown32x32.dds", shiftX = -6, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        doorMarker = { path = "diject\\quest guider\\skyrimDoorMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimDoorMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimDoorMarkerDown32x32.dds", shiftX = -6, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        worldMarker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimMarkerDown32x32.dds", shiftX = -6, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        questGiverMarker = { path = "diject\\quest guider\\skyrimExclamationMark16x32.dds", pathAbove = "diject\\quest guider\\skyrimExclamationMarkUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimExclamationMarkDown32x32.dds", shiftX = -5, shiftY = 18, scale = 0.6 },
    },
}