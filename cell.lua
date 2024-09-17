local this = {}

---@param cell tes3cell
---@return tes3vector3|nil
---@return string[]|nil
function this.findExitPos(cell, checked, path)
    if not checked then checked = {} end
    if not path then path = {} end

    local pathCopy = {}
    table.copy(path, pathCopy)
    table.insert(pathCopy, cell.editorName)

    if checked[cell] then return end
    checked[cell] = true
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                return door.destination.marker.position, pathCopy
            else
                local out = this.findExitPos(door.destination.cell, checked, pathCopy)
                if out then return out end
            end
        end
    end
    return nil
end

return this