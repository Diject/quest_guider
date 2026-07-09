---@diagnostic disable: inject-field
local config = include("diject.quest_guider.config")
local stringLib = include("diject.quest_guider.utils.string")

local this = {}


this.exCenterCellByName = {}
do
    local exCellsByName = {}
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if not cell.isInterior and cell.name then
            local cellName = cell.name:lower()
            local cellNameWithoutComma = stringLib.getBeforeComma(cellName)

            exCellsByName[cellName] = exCellsByName[cellName] or {}
            table.insert(exCellsByName[cellName], cell)

            if cellNameWithoutComma ~= cellName then
                exCellsByName[cellNameWithoutComma] = exCellsByName[cellNameWithoutComma] or {}
                table.insert(exCellsByName[cellNameWithoutComma], cell)
            end
        end
    end

    for cellName, cells in pairs(exCellsByName) do
        local center = tes3vector3.new(0, 0, 0)
        for _, cell in pairs(cells) do
            center = center + tes3vector3.new(cell.gridX * 8192 + 4096, cell.gridY * 8192 + 4096, 0)
        end
        local cellCOunt = #cells
        center = tes3vector3.new(center.x / cellCOunt, center.y / cellCOunt, 0)
        this.exCenterCellByName[cellName] = tes3.getCell{position = center} or cells[1]
    end
end


function this.getCellByName(name)
    return this.exCenterCellByName[name:lower()]
end


function this.getCell(id)
    local cell = tes3.getCell{id = id}
    if cell then return cell end

    local exCell = this.getCellByName(id)
    if exCell then return exCell end

    return nil
end


---@param cell tes3cell
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cell[]|nil cellPath
---@return boolean|nil isExterior
---@return table<string,tes3cell>|nil checkedCells
---@return number|nil depth
function this.findExitPos(cell, path, checked, cellPath, depth)
    if not checked then checked = {} end
    if not path then path = {} end
    if not depth then depth = 1 end
    if not cellPath then
        cellPath = {}
        table.insert(cellPath, cell)
    end

    local maxDepth = config.data.tracking.maxCellDepth

    if not cell.id or (checked[cell.id] and checked[cell.id] < depth) or depth > maxDepth then
        return nil, nil, nil, nil, checked, depth
    end
    checked[cell.id] = math.min(checked[cell.id] or depth, depth)

    -- if depth == 1 then
    --     local cacheData = cacheLib.get("findExitPosCache", cell.id)
    --     if cacheData then
    --         return table.unpack(cacheData) ---@diagnostic disable-line: redundant-return-value
    --     end
    -- end

    local bestResult = nil

    for door in cell:iterateReferences(tes3.objectType.door) do
        if not door.destination or door.deleted or door.disabled then goto continue end

        local destCell = door.destination.cell
        local destPos = door.destination.marker.position

        if not destCell or not destPos then goto continue end

        if checked[destCell.id] and checked[destCell.id] < depth + 1 then goto continue end

        table.insert(path, {cell = destCell, dCId = cell.id, marker = {position = destPos}})
        table.insert(cellPath, destCell)

        local candidate
        if destCell.isOrBehavesAsExterior then
            candidate = {destPos:copy(), table.copy(path), table.copy(cellPath), not destCell.isInterior, checked, depth}
        else
            local out, destPath, cPath, isEx, ch, dp = this.findExitPos(destCell, path, checked, cellPath, depth + 1)
            if out then
                candidate = {out, destPath, cPath, isEx, checked, dp}
            end
        end

        table.remove(path)
        table.remove(cellPath)

        if candidate then
            if not bestResult or candidate[6] < bestResult[6] then
                bestResult = candidate
            end

            if bestResult[6] == 1 then break end
        end

        ::continue::
    end

    if bestResult then
        local res = bestResult
        for _, drData in pairs(res[2] or {}) do
            if drData.cell then
                if not drData.cell.isInterior then
                    local doorDestCell = this.findNearestDoor(drData.marker.position, drData.cell)

                    if doorDestCell and doorDestCell.id then
                        if doorDestCell.id == drData.dCId then
                            drData.pos = doorDestCell.destination.marker.position or drData.marker.position
                        else
                            drData.pos = drData.marker.position
                        end
                    else
                        drData.pos = drData.marker.position
                    end
                else
                    local door = this.findNearestDoor(drData.marker.position, drData.cell)
                    drData.pos = door and door.position or drData.marker.position
                end

                drData.cell = nil
                drData.dCId = nil ---@diagnostic disable-line: inject-field
            end
        end

        -- if depth == 1 then
        --     cacheLib.set("findExitPosCache", cell.id, {table.unpack(bestResult)})
        -- end

        return table.unpack(bestResult) ---@diagnostic disable-line: redundant-return-value
    end

    return nil, nil, nil, nil, checked, depth
end

---@param node tes3travelDestinationNode
---@param cells table<string, {cell : tes3cell, depth : integer}>? by editor name
---@return table<string, {cell : tes3cell, depth : integer}>?
---@return boolean hasExitToExterior
function this.findReachableCellsByNode(node, cells, depth)
    local maxDepth = config.data.tracking.maxCellDepth
    if not cells then cells = {} end
    if not depth then depth = 1 end

    local hasExitToExterior = not node.cell.isInterior

    local cellData = cells[node.cell.editorName]
    if (cellData and cellData.depth <= depth) or depth > maxDepth then
        return cells, false
    end

    if hasExitToExterior then
        return cells, true
    end

    if cellData then
        cellData.depth = depth
    else
        cells[node.cell.editorName] = {cell = node.cell, depth = depth}
    end

    for door in node.cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                hasExitToExterior = true
            else
                local cls, hasExit = this.findReachableCellsByNode(door.destination, cells, depth + 1)
                hasExitToExterior = hasExitToExterior or hasExit
            end
        end
    end

    return cells, hasExitToExterior
end


---@param cell tes3cell
---@return {pos : tes3vector3, depth : number}[]?
---@return table<string, tes3cell>?
---@return table<string, integer>? entranceCells
---@return number? lowestDepth
function this.findExitPositions(cell, checked, res, resCells, entranceCells, depth)
    if not cell.id then return end
    if not checked then checked = {} end
    if not entranceCells then entranceCells = {} end
    if not res then res = {} end
    if not depth then depth = 0 end

    if not cell.isInterior then
        resCells[cell.id] = cell
        return
    end
    if checked[cell.id] then
        checked[cell.id] = math.min(checked[cell.id], depth)
        if entranceCells[cell.id] then
            entranceCells[cell.id] = math.min(entranceCells[cell.id], depth)
        end
        return
    end

    -- local cachedVal = cacheLib.get("findExitPositions", cell.id)
    -- if cachedVal then
    --     return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    -- end

    checked[cell.id] = depth

    for door in cell:iterateReferences(tes3.objectType.door) do
        if not door.destination or door.deleted or door.disabled then goto continue end

        local destCell = door.destination.cell
        local destPos = door.destination.marker.position

        if not destCell or not destPos or not destCell.id then goto continue end

        if not destCell.isInterior then
            table.insert(res, {pos = destPos:copy(), depth = depth})
            entranceCells[cell.id] = depth
        else
            this.findExitPositions(destCell, checked, res, resCells, entranceCells, depth + 1)
        end

        ::continue::
    end

    local lowestDepth = 9999
    for _, dpt in pairs(entranceCells) do
        lowestDepth = math.min(lowestDepth, dpt)
    end

    -- if depth == 0 then
    --     cacheLib.set("findExitPositions", cell.id, {res, resCells, entranceCells, lowestDepth})
    -- end
    return res, resCells, entranceCells, lowestDepth
end


---@param cell tes3cell
---@return table<string, {cell : tes3cell, depth : integer}>?
function this.findExitCells(cell, checked, cells, depth)
    local maxDepth = config.data.tracking.maxCellDepth
    if not checked then checked = {} end
    if not cells then cells = {} end
    if not depth then depth = 0 end

    if checked[cell.editorName] and checked[cell.editorName] < depth then return end
    checked[cell.editorName] = depth

    if depth > maxDepth or not cell.isInterior then return cells end

    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            local destCell = door.destination.cell
            if not destCell.isInterior then
                local cellData = cells[cell.editorName] or {cell = cell}
                cellData.depth = math.min(depth, cellData.depth or depth)
                cells[cell.editorName] = cellData
            else
                this.findExitCells(destCell, checked, cells, depth + 1)
            end
        end
    end

    return cells
end


local findClosestExitPositionsCache = {}

---@param cell tes3cell
---@param onePerCell boolean?
---@return tes3vector3[]?
function this.findClosestExitPositions(cell, onePerCell)
    local cellRes = findClosestExitPositionsCache[cell] or this.findExitCells(cell)
    findClosestExitPositionsCache[cell] = cellRes
    if not cellRes then return end

    cellRes = table.values(cellRes, function (a, b)
        return a.depth < b.depth
    end)

    local lowestDepth
    ---@type tes3cell[]
    local cells = {}
    for _, dt in ipairs(cellRes) do
        if not lowestDepth then
            lowestDepth = dt.depth
        end

        if dt.depth == lowestDepth then
            table.insert(cells, dt.cell)
        else
            break
        end
    end

    local res = {}
    for _, cl in pairs(cells) do
        local dests = {}
        for door in cl:iterateReferences(tes3.objectType.door) do
            if door.destination and not door.deleted and not door.disabled and not door.destination.cell.isInterior then
                table.insert(dests, door.destination.marker.position:copy())
            end
        end

        if not next(dests) then goto continue end

        if onePerCell then
            local pos = table.choice(dests)
            table.insert(res, pos)
        else
            for _, pos in pairs(dests) do
                table.insert(res, pos)
            end
        end

        ::continue::
    end

    return res
end


local findNearestDoorCache = {}

---@param cell tes3cell?
---@param position tes3vector3
---@return tes3reference?
function this.findNearestDoor(position, cell)
    if not cell then
        cell = tes3.getCell{position = position}
        if not cell then return end
    end

    local hashVal = string.format("%d_%d_%d_%s", math.floor(position.x), math.floor(position.y), math.floor(position.z), cell.editorName)
    if findNearestDoorCache[hashVal] then
        return findNearestDoorCache[hashVal]
    end

    local nearestDoor
    local nearestdist = math.huge

    local function checkDoor(doorRef)
        if not doorRef.position then return end

        local dist = doorRef.position:distance(position)
        if nearestdist > dist then
            nearestdist = dist
            nearestDoor = doorRef
        end
    end

    if cell.isInterior then
        for doorRef in cell:iterateReferences(tes3.objectType.door) do
            checkDoor(doorRef)
        end
    else
        checkDoor(cell)
        if nearestdist > 500 then
            for i = -1, 1 do
                for j = -1, 1 do
                    local cl = tes3.getCell{x = cell.gridX + i, y = cell.gridY + j}
                    if cl then
                        for doorRef in cl:iterateReferences(tes3.objectType.door) do
                            checkDoor(doorRef)
                        end
                    end
                end
            end
        end
    end

    findNearestDoorCache[hashVal] = nearestDoor

    return nearestDoor
end

return this