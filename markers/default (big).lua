---@type questGuider.markers.data
return {
    ---@type string
    name = "default (big)",
    ---@type { marker : questGuider.ui.markerImage }
    journal = {
        marker = { path = "diject\\quest guider\\circleMarker16x16.dds", shiftX = -6, shiftY = 6, scale = 0.75 },
    },
    ---@type { localMarker : questGuider.tracking.markerImage, doorMarker : questGuider.tracking.markerImage, worldMarker : questGuider.tracking.markerImage, questGiverMarker : questGuider.tracking.markerImage }
    tracking = {
        ---@type questGuider.tracking.markerImage
        localMarker = { path = "diject\\quest guider\\circleMarker16x16.dds", pathAbove = "diject\\quest guider\\circleMarkerUp16x16.dds",
            pathBelow = "diject\\quest guider\\circleMarkerDown16x16.dds", shiftX = -6, shiftY = 6, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        doorMarker = { path = "diject\\quest guider\\circleMarker16x16.dds", pathAbove = "diject\\quest guider\\circleMarkerUp16x16.dds",
            pathBelow = "diject\\quest guider\\circleMarkerDown16x16.dds", shiftX = -6, shiftY = 6, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        worldMarker = { path = "diject\\quest guider\\circleMarker16x16.dds", pathAbove = "diject\\quest guider\\circleMarkerUp16x16.dds",
            pathBelow = "diject\\quest guider\\circleMarkerDown16x16.dds", shiftX = -6, shiftY = 6, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        questGiverMarker = { path = "diject\\quest guider\\exclamationMark16x32.dds", pathAbove = "diject\\quest guider\\exclamationMarkUp32x32.dds",
            pathBelow = "diject\\quest guider\\exclamationMarkDown32x32.dds", shiftX = -5, shiftY = 18, scale = 0.6 },
    },
}