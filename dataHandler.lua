include("diject.quest_guider.Data.luaAnnotations")

local this = {}

---@type questDataGenerator.quests
this.quests = {}
---@type questDataGenerator.questByTopicText
this.questByText = {}
---@type table<string, questDataGenerator.objectInfo>
this.questObjects = {}
---@type questDataGenerator.localVariableByQuestId
this.localVariablesByScriptId = {}

local defaultInfo = {version = 0, files = {}, time = 0}
this.info = table.deepcopy(defaultInfo)

local isReady = false

---@return boolean
function this.init()
    isReady = false
    this.quests = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")
    this.questByText = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicText")
    this.questObjects = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjects")
    this.localVariablesByScriptId = json.loadfile("mods\\diject\\quest_guider\\Data\\localVariables")
    local infoData = loadfile(tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\Data\\info.lua")
    this.info = infoData and infoData() or nil

    if this.quests and this.questObjects and this.questByText and this.localVariablesByScriptId and this.info then
        isReady = true
    else
        this.quests = this.quests or {}
        this.questObjects = this.questObjects or {}
        this.questByText = this.questByText or {}
        this.localVariablesByScriptId = this.localVariablesByScriptId or {}
        this.info = this.info or table.deepcopy(defaultInfo)
    end

    return isReady
end

---@return boolean
function this.isReady()
    return isReady
end

function this.reset()
    this.quests = {}
    this.questObjects = {}
    this.questByText = {}
    this.localVariablesByScriptId = {}
end

---@return boolean ret returns true if the data changed
function this.compareGameFileData()
    if not isReady then return true end

    local activeMods = tes3.dataHandler.nonDynamicData.activeMods
    local files = this.info.files

    local activeFiles = {}

    for _, gameFile in ipairs(activeMods) do
        if gameFile.playerName == "" then
            table.insert(activeFiles, gameFile.filename:lower())
        end
    end

    if #activeFiles ~= #files then return true end

    for i, activeFile in ipairs(activeFiles) do
        if activeFile ~= files[i] then
            return true
        end
    end

    return false
end

function this.isGameFileDataEmpty()
    return #this.info.files == 0
end

return this