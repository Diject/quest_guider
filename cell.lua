local this = {}

---@param cell tes3cell
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cell[]|nil cellPath
---@return boolean|nil isExterior
---@return table<tes3cell,boolean>|nil checkedCells
function this.findExitPos(cell, path, checked, cellPath)
    if not checked then checked = {} end
    if not path then path = {} end
    if not cellPath then
        cellPath = {}
        table.insert(cellPath, cell)
    end

    if checked[cell] then return nil, nil, nil, nil, checked end
    checked[cell] = true
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then

            ---@type tes3travelDestinationNode[]
            local pathCopy = table.copy(path)
            table.insert(pathCopy, door.destination)

            local cellPathCopy = table.copy(cellPath)
            table.insert(cellPathCopy, door.destination.cell)

            if door.destination.cell.isOrBehavesAsExterior then
                return door.destination.marker.position, pathCopy, cellPathCopy, not door.destination.cell.isInterior
            else
                local out, destPath, cPath, isEx = this.findExitPos(door.destination.cell, pathCopy, checked, cellPathCopy)
                if out then return out, destPath, cPath, isEx, checked end
            end
        end
    end
    return nil, nil, nil, nil, checked
end

---@param node tes3travelDestinationNode
---@param cells table<string, tes3cell>? by editor name
---@return table<string, tes3cell>?
---@return boolean? hasExitToExterior
function this.findReachableCellsByNode(node, cells)
    if not cells then cells = {} end

    local hasExitToExterior = not node.cell.isInterior

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

            if not door.destination.cell.isInterior then
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


---@param cell tes3cell?
---@param position tes3vector3
---@return tes3reference?
function this.findNearestDoor(position, cell)
    if not cell then
        cell = tes3.getCell{position = position}
        if not cell then return end
    end
    local nearestDoor
    local nearestdist = math.huge
    if cell.isInterior then
        for doorRef in cell:iterateReferences(tes3.objectType.door) do
            local dist = doorRef.position:distance(position)
            if nearestdist > dist then
                nearestdist = dist
                nearestDoor = doorRef
            end
        end
    else
        for i = -1, 1 do
            for j = -1, 1 do
                local cl = tes3.getCell{x = cell.gridX + i, y = cell.gridY + j}
                if cl then
                    for doorRef in cl:iterateReferences(tes3.objectType.door) do
                        local dist = doorRef.position:distance(position)
                        if nearestdist > dist then
                            nearestdist = dist
                            nearestDoor = doorRef
                        end
                    end
                end
            end
        end
    end

    return nearestDoor
end

return this