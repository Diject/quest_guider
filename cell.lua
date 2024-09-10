local this = {}

---@param cell tes3cell
---@return tes3vector3|nil
function this.findExitPos(cell, checked)
    if not checked then checked = {} end
    if checked[cell] then return end
    checked[cell] = true
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not checked[door] and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                return door.destination.marker.position
            else
                local out = this.findExitPos(door.destination.cell, checked)
                if out then return out end
            end
        end
    end
    return nil
end

return this