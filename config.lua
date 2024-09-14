local tableLib = include("diject.quest_guider.utils.table")

local storageName = "Quest_Guider_Config"

local this = {}

---@class questGuider.config
this.default = {
    enabled = true,

}

---@class questGuider.config
this.data = mwse.loadConfig(storageName)

if this.data then
    tableLib.addMissing(this.data, this.default)
else
    this.data = table.deepcopy(this.default)
    mwse.saveConfig(storageName, this.data)
end


function this.save()
    mwse.saveConfig(storageName, this.data)
end

return this