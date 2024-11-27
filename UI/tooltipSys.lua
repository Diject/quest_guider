local tooltipMenu = {
    tooltipBlock = "qGuider_ts_block",
}

local this = {}

---@class questGuider.tooltipSys.tooltip
local tooltipClass = {}
tooltipClass.__index = tooltipClass

---@class questGuider.tooltipSys.tooltip.dataBlock
---@field name string?
---@field description string?

---@param params questGuider.tooltipSys.tooltip.dataBlock
function tooltipClass:add(params)
    table.insert(self.tooltipData.items, params)
end

function tooltipClass:destroy()
    self.parent:unregister(tes3.uiEvent.help)
end


---@class questGuider.tooltipSys.new.params
---@field parent tes3uiElement
---@field maxWidth integer?

---@param params questGuider.tooltipSys.new.params
function this.new(params)
    ---@class questGuider.tooltipSys.tooltip
    local self = setmetatable({}, tooltipClass)

    local parent = params.parent

    ---@class questGuider.tooltipSys.tooltipData
    local tooltipData = {items = {}}

    tooltipData.maxWidth = params.maxWidth

    self.parent = parent
    self.tooltipData = tooltipData

    parent:setLuaData("_tooltipData_", tooltipData)
    parent:setLuaData("_tooltipClass_", self)

    local function tooltipFunc(e)
        if not e.source then return end
        ---@type questGuider.tooltipSys.tooltipData
        local luaData = e.source:getLuaData("_tooltipData_")
        if not luaData then return end
        if #luaData.items == 0 then return end

        local tooltip = tes3ui.createTooltipMenu()

        local block
        local createDivider = false
        for i, rec in pairs(luaData.items) do

            block = tooltip:createBlock{id = tooltipMenu.tooltipBlock}
            block.flowDirection = tes3.flowDirection.topToBottom
            block.autoHeight = true
            block.autoWidth = true
            block.maxWidth = luaData.maxWidth or 350

            if createDivider then
                local divider = block:createDivider{}
            end

            if rec.name then
                local label = block:createLabel{id = tooltipMenu.tooltipName, text = rec.name}
                label.autoHeight = true
                label.widthProportional = 1
                label.maxWidth = luaData.maxWidth or 350
                label.wrapText = true
                label.justifyText = tes3.justifyText.center
            end

            if rec.description then
                local label = block:createLabel{id = tooltipMenu.tooltipDescription, text = rec.description}
                label.autoHeight = true
                label.autoWidth = true
                label.maxWidth = luaData.maxWidth or 350
                label.wrapText = true
                label.justifyText = tes3.justifyText.left
            end

            createDivider = true

            ::continue::
        end

        if block then
            block.borderBottom = 3
        end

        tooltip:getTopLevelMenu():updateLayout()
    end

    tooltipData.func = tooltipFunc
    parent:register(tes3.uiEvent.help, tooltipFunc)

    return self
end

return this