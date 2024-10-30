include("diject.quest_guider.Data.luaAnnotations")

local this = {}

---@type questDataGenerator.quests
this.quests = {}
---@type questDataGenerator.questByTopicText
this.questByText = {}
---@type table<string, questDataGenerator.objectInfo>
this.questObjects = {}
---@type questDataGenerator.localVariableByQuestId
this.localVariablesByQuestId = {}

local isReady = false

---@return boolean
function this.init()
    isReady = false
    this.quests = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")
    this.questByText = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicText")
    this.questObjects = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjects")
    this.localVariablesByQuestId = json.loadfile("mods\\diject\\quest_guider\\Data\\localVariables")

    if this.quests and this.questObjects and this.questByText and this.localVariablesByQuestId then
        isReady = true
    else
        this.quests = this.quests or {}
        this.questObjects = this.questObjects or {}
        this.questByText = this.questByText or {}
        this.localVariablesByQuestId = this.localVariablesByQuestId or {}
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
    this.localVariablesByQuestId = {}
end

return this