include("diject.quest_guider.Data.luaAnnotations")

local this = {}

---@type questDataGenerator.quests
this.quests = {}
---@type questDataGenerator.questObjectPositions
this.positions = {}
---@type table<string, questDataGenerator.questObjectPositions>
this.positionsInCell = {}
---@type questDataGenerator.questByTopicText
this.questByText = {}
---@type questDataGenerator.questTopicInfo[]
this.questByTopicId = {}
---@type table<string, questDataGenerator.objectInfo>
this.questObjects = {}

local isReady = false

---@return boolean
function this.init()
    isReady = false
    this.quests = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")
    this.questByText = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicText")
    this.questByTopicId = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicId")
    this.questObjects = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjects")

    if this.quests and this.questObjects and this.questByText and this.questByTopicId then
        isReady = true
    else
        this.quests = this.quests or {}
        this.positions = this.positions or {}
        this.positionsInCell = this.positionsInCell or {}
        this.questByText = this.questByText or {}
        this.questByTopicId = this.questByTopicId or {}
    end

    return isReady
end

---@return boolean
function this.isReady()
    return isReady
end

return this