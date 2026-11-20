-- core/MenuController.lua
-- Собирает меню из Registry.MenuCategories и сам привязывает горячие клавиши открытия из Registry.MenuToggleKeys

local UserInputService = game:GetService("UserInputService")
local MenuController = {}

function MenuController.Build(Import, Registry, Context)
    local Theme   = Import("ui/DoorsTheme.lua")
    local Builder = Import("ui/DoorsGuiBuilder.lua")
    if not Theme or not Builder or not Registry or not Registry.MenuCategories then
        warn("[MenuController] Не загрузились Theme или Builder!")
        return nil, {}, nil
    end

    local toggles = {}
    local sliders = getgenv().MemeCustomSliders or {}
    local keybinds = getgenv().MemeCustomKeybinds or {}
    local uiWindow = Builder.Create(Theme, "MEME ACTOR", "[ [ / ] / RCtrl ] Меню")

    for _, catData in ipairs(Registry.MenuCategories) do
        local catTab = uiWindow:AddCategory(catData.Title, catData.Icon)
        for _, item in ipairs(catData.Items) do
            if item.Type == "Section" then
                catTab:AddSection(item.Text)
            elseif item.Type == "Button" then
                catTab:AddButton(item.Text, item.ButtonText, function()
                    if item.Action and Context.Actions[item.Action] then
                        Context.Actions[item.Action]()
                    elseif item.ModeId then
                        Context.RunMode(item.ModeId, item.SubMode, item.AutoSpawn)
                    end
                end, item.Color)
            elseif item.Type == "Toggle" and item.StateKey then
                local st = Context.States[item.StateKey]
                local defVal = st and st.get() or false
                toggles[item.StateKey] = catTab:AddToggle(item.Text, defVal, function(val)
                    local curSt = Context.States[item.StateKey]
                    if curSt and curSt.set then curSt.set(val) end
                end)
            elseif item.Type == "Slider" and item.SettingKey and sliders[item.SettingKey] then
                local sl = sliders[item.SettingKey]
                catTab:AddSlider(item.Text, item.Min, item.Max, sl.get(), function(val)
                    sl.set(val)
                end)
            elseif item.Type == "Keybind" and item.BindKey and keybinds[item.BindKey] then
                local kb = keybinds[item.BindKey]
                catTab:AddKeybind(item.Text, kb.get(), function(newKey)
                    kb.set(newKey)
                end)
            end
        end
    end

    -- Привязка клавиш открытия/закрытия меню напрямую из Registry.MenuToggleKeys (работает даже при gp == true!)
    local toggleKeys = Registry.MenuToggleKeys or { Enum.KeyCode.LeftBracket, Enum.KeyCode.RightBracket, Enum.KeyCode.RightControl }
    local toggleConn = UserInputService.InputBegan:Connect(function(inp)
        if UserInputService:GetFocusedTextBox() then return end
        for _, k in ipairs(toggleKeys) do
            if inp.KeyCode == k then
                uiWindow:Toggle()
                return
            end
        end
    end)

    return uiWindow, toggles, toggleConn
end

return MenuController
