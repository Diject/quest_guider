local config = include("diject.quest_guider.config")
local initializer = include("diject.quest_guider.initializer")
local dataHandler = include("diject.quest_guider.dataHandler")

local this = {}

local menuId = {
    main = "qGuider_dataGenerator",
    headerBlock = "qGuider_headerBlock",
    headerLabel = "qGuider_header",
    label1Block = "qGuider_label1Block",
    label1 = "qGuider_label1",
    label2 = "qGuider_label2",
    buttonBlock = "qGuider_buttons",
    generateBtn = "qGuider_generateBtn",
    skipBtn = "qGuider_skipBtn",
    disableBtn = "qGuider_disableBtn",
    cancelBtn = "qGuider_cancelBtn",
}

---@class questGuider.dataGenerator.createMenu.params
---@field dataChangedMessage boolean|nil
---@field dataNotExistsMessage boolean|nil

---@param params questGuider.dataGenerator.createMenu.params|nil
---@return tes3uiElement
function this.createMenu(params)
    if not params then params = {} end

    local menu = tes3ui.createMenu{ id = menuId.main, fixedFrame = true, }
    menu.autoHeight = true
    menu.width = 500
    menu.childAlignX = 0
    menu.alpha = 1

    local headerBlock = menu:createBlock{ id = menuId.headerBlock }
    headerBlock.autoHeight = true
    headerBlock.widthProportional = 1
    headerBlock.childAlignX = 0.5

    local headerLabel = headerBlock:createLabel{ id = menuId.headerLabel }
    headerLabel.text = "Quest Guider"
    headerLabel.font = 1
    headerLabel.borderBottom = 10

    if params.dataNotExistsMessage then
        local block = menu:createBlock{ id = menuId.label1Block }
        block.autoHeight = true
        block.autoWidth = true
        block.borderBottom = 5
        local label = block:createLabel{ id = menuId.label1 }
        label.text = "There is no data about quests. Would you like to generate it?"
        label.widthProportional = 1
        label.wrapText = true
    elseif params.dataChangedMessage then
        local block = menu:createBlock{ id = menuId.label1Block }
        block.autoHeight = true
        block.autoWidth = true
        block.borderBottom = 5
        local label = block:createLabel{ id = menuId.label1 }
        label.text = "Active game files have changed. Would you like to re-generate quest data?"
        label.widthProportional = 1
        label.wrapText = true
    end

    local warningLabel = menu:createLabel{ id = menuId.label2 }
    warningLabel.text = "Generation will take more than 10 seconds. The game will be frozen until it is completed."
    warningLabel.wrapText = true
    warningLabel.borderBottom = 10

    local buttonBlock = menu:createBlock{ id = menuId.buttonBlock }
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1
    buttonBlock.childAlignX = 0.5

    local generateBtn = buttonBlock:createButton{ id = menuId.generateBtn }
    generateBtn.text = "Generate"
    generateBtn:register(tes3.uiEvent.mouseClick, function (e)
        generateBtn.text = "Generating..."
        menu:getTopLevelMenu():updateLayout()
        if not initializer.runDataGeneration() then
            tes3ui.showNotifyMenu("Data generation failed. Info in MWSE.log")
            generateBtn.text = "Generate"
            menu:getTopLevelMenu():updateLayout()
            return
        end

        config.data.init.ignoreDataChanges = false
        config.save()
        dataHandler.init()

        if math.isclose(dataHandler.info.time or 0, os.time(), 10) then
            tes3ui.showNotifyMenu("Data generation completed successfully")
        else
            tes3ui.showNotifyMenu("Data generation failed")
        end

        menu:destroy()
    end)

    local disableBtn = buttonBlock:createButton{ id = menuId.disableBtn }
    disableBtn.text = "Disable the mod"
    disableBtn:register(tes3.uiEvent.mouseClick, function (e)
        config.data.main.enabled = false
        config.save()
        menu:destroy()
    end)

    if params.dataNotExistsMessage or params.dataChangedMessage then
        local laterBtn = buttonBlock:createButton{ id = menuId.skipBtn }
        laterBtn.text = "Don't ask again"
        laterBtn:register(tes3.uiEvent.mouseClick, function (e)
            config.data.init.ignoreDataChanges = true
            config.save()

            tes3ui.showNotifyMenu("You will be able to generate the data from the mod settings.")

            menu:destroy()
        end)
    end

    local cancelBtn = buttonBlock:createButton{ id = menuId.cancelBtn }
    cancelBtn.text = "Cancel"
    cancelBtn:register(tes3.uiEvent.mouseClick, function (e)
        menu:destroy()
    end)

    menu:getTopLevelMenu():updateLayout()

    return menu
end

return this