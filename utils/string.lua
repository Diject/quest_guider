local this = {}

--- Returns string like ' "1", "2" and 3 more '
---@param tb table<any, string>
---@param max integer
---@param framePattern string|nil pattern with %s into which result will packed if max more than 0
---@param returnTable boolean? return an array with values
---@param customNumber integer? number of elements in the table
---@return string|string[]|nil
function this.getValueEnumString(tb, max, framePattern, returnTable, customNumber)
    local str = returnTable and {} or ""
    local count = 0

    if max <= 0 then
        return str
    end

    for _, value in pairs(tb) do
        if count >= max then
            if returnTable then
                table.insert(str, string.format("and %d more", (customNumber or table.size(tb)) - count))
            else
                str = string.format("%s and %d more", str, (customNumber or table.size(tb)) - count)
            end
            break
        end

        if returnTable then
            table.insert(str, string.format(framePattern or "%s", value))
        else
            str = string.format("%s%s\"%s\"", str, str:len() ~= 0 and ", " or "", value)
        end
        count = count + 1

    end

    if framePattern and not returnTable then
        return string.format(framePattern, str)
    end

    return str
end


---@param name string
---@return string
function this.convertDialogueName(name)
    return string.sub(name, 7)
end


---@param data questGuider.quest.getRequirementPositionData.positionData
---@return string?
---@return string? backward
function this.getPathDescription(data)
    local descr
    local descrBack
    if not data.description then
        if data.pathFromPlayer then
            for _, cellName in ipairs(data.pathFromPlayer) do
                descr = descr and string.format("%s => \"%s\"", descr, cellName) or
                    string.format("\"%s\"", cellName)
                -- descrBack = descrBack and string.format("\"%s\" <= %s", cellName, descrBack) or
                --     string.format("\"%s\"", cellName)
            end

        elseif data.cellPath then
            for i = #data.cellPath, 1, -1 do
                descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].displayName) or
                    string.format("\"%s\"", data.cellPath[i].displayName)
                -- descrBack = descrBack and string.format("\"%s\" <= %s", data.cellPath[i].name, descrBack) or
                --     string.format("\"%s\"", data.cellPath[i].name)
            end

        elseif data.id then
            descr = string.format("\"%s\"", data.id)
            -- descrBack = descr

        else
            descr = "???"
            -- descrBack = "???"
        end
    else
        descr = data.description
    end

    return descr, descrBack
end


function this.getBeforeComma(str)
    local commaIndex = string.find(str, ",")
    if commaIndex then
        return string.sub(str, 1, commaIndex - 1)
    else
        return str
    end
end


return this