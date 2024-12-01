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

---@param node tes3travelDestinationNode
---@param cells table<string, tes3cell>? by editor name
---@return table<string, tes3cell>?
---@return boolean? hasExitToExterior
function this.findReachableCellsByNode(node, cells)
    if not cells then cells = {} end

    local hasExitToExterior = node.cell.isOrBehavesAsExterior

    if cells[node.cell.editorName] then
        return cells, false
    end

    if hasExitToExterior then
        return cells, true
    end

    cells[node.cell.editorName] = node.cell

    for door in node.cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            this.findReachableCellsByNode(door.destination, cells)

            if not door.destination.cell.isOrBehavesAsExterior then
                hasExitToExterior = true
            else
                local cls, hasExit = this.findReachableCellsByNode(door.destination, cells)
                hasExitToExterior = hasExitToExterior or hasExit
            end
        end
    end

    return cells, hasExitToExterior
end


---@param cell tes3cell
---@return tes3vector3[]?
function this.findExitPositions(cell, checked, res)
    if not checked then checked = {} end
    if not res then res = {} end
    if not cell.isInterior or checked[cell] then return end

    checked[cell] = true

    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                table.insert(res, door.destination.marker.position)
            else
                this.findExitPositions(door.destination.cell, checked, res)
            end
        end
    end

    return res
end

return this