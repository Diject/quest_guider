local this = {}

---@param cell tes3cell
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cell[]|nil cellPath
function this.findExitPos(cell, path, checked, cellPath)
    if not checked then checked = {} end
    if not path then path = {} end
    if not cellPath then
        cellPath = {}
        table.insert(cellPath, cell)
    end

    if checked[cell] then return end
    checked[cell] = true
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then

            ---@type tes3travelDestinationNode[]
            local pathCopy = table.copy(path)
            table.insert(pathCopy, door.destination)

            local cellPathCopy = table.copy(cellPath)
            table.insert(cellPathCopy, door.destination.cell)

            if not door.destination.cell.isInterior then
                return door.destination.marker.position, pathCopy, cellPathCopy
            else
                local out, destPath, cPath = this.findExitPos(door.destination.cell, pathCopy, checked, cellPathCopy)
                if out then return out, destPath, cPath end
            end
        end
    end
    return nil
end

return this