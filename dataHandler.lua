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

local isReady = false

---@return boolean
function this.init()
    isReady = false
    this.quests = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")
    this.questByText = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicText")
    this.questObjects = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjects")
    this.localVariablesByScriptId = json.loadfile("mods\\diject\\quest_guider\\Data\\localVariables")

    if this.quests and this.questObjects and this.questByText and this.localVariablesByScriptId then
        isReady = true
    else
        this.quests = this.quests or {}
        this.questObjects = this.questObjects or {}
        this.questByText = this.questByText or {}
        this.localVariablesByScriptId = this.localVariablesByScriptId or {}
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

return this