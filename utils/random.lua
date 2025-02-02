local this = {}

local function getStringHash(str)
    if not str then return 0 end
    local ret = 0
    local length = #str
    for i = 1, length do
        local byte = string.byte(str, i)
        ret = ret + byte * i
    end
    return ret
end

---@param str string
function this.setSeedByStringHash(str)
    local playerHash = 0
    if tes3.player then
        playerHash = getStringHash(tes3.player.object.name)
    end
    local seed = getStringHash(str) + playerHash
    math.randomseed(seed % 1000000000)
end

function this.resetRandomSeed()
    math.randomseed(os.time())
end

return this