local this = {}

--- Returns string like ' "1", "2" and 3 more '
---@param tb table<any, string>
---@param max integer
---@param framePattern string|nil pattern with %s into which result will packed if max more than 0
---@return string
function this.getValueEnumString(tb, max, framePattern)
    local str = ""
    local count = 0

    if max <= 0 then
        return str
    end

    for _, value in pairs(tb) do
        if count >= max then
            str = string.format("%s and %d more", str, table.size(tb) - count)
            break
        end

        str = string.format("%s%s\"%s\"", str, str:len() ~= 0 and ", " or "", value)
        count = count + 1

    end

    if framePattern then
        return string.format(framePattern, str)
    end

    return str
end

return this