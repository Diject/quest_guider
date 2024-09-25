local this = {}

---@param cell tes3cell
---@return tes3vector3|nil
---@return tes3travelDestinationNode[]|nil
function this.findExitPos(cell, path, checked)
    if not checked then checked = {} end
    if not path then path = {} end

    if checked[cell] then return end
    checked[cell] = true
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            ---@type tes3travelDestinationNode[]
            local pathCopy = {}
            table.copy(path, pathCopy)
            table.insert(pathCopy, door.destination)
            if not door.destination.cell.isInterior then
                return door.destination.marker.position, pathCopy
            else
                local out, cellPath = this.findExitPos(door.destination.cell, pathCopy, checked)
                if out then return out, cellPath end
            end
        end
    end
    return nil
end

return this