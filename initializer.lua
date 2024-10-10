local log = include("diject.quest_guider.utils.log")

local this = {}

this.logLevel = 0
-- TODO add file existence check
---@param async boolean|nil
---@return boolean res true if successful. If async always true
function this.runDataGeneration(async)
    local dir = string.format("%s\\Quest Guider", tes3.installDirectory)
    local outputDir = tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\Data"
    local command = string.format("start /B \"\" /D \"%s\" \"Quest Data Builder.exe\" -o \"%s\" -l %d", dir, outputDir, this.logLevel)
    if async then
        if os.execute(command) ~= 0 then
            return false
        end
    else
        local handle = io.popen(command)
        if not handle then
            log("Error in data generation")
            return false
        end
        local result = handle:read("*a")
        log("Data Generator Output:")
        log(result)
        handle:close()
    end
    return true
end

return this