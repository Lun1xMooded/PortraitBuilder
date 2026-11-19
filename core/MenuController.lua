-- core/MenuController.lua
local MenuController = {}

function MenuController.Build(Import, Registry, Context)
    local Theme   = Import("ui/DoorsTheme.lua")
    local Builder = Import("ui/DoorsGuiBuilder.lua")
    if not Theme or not Builder or not Registry or not Registry.MenuCategories then
        return nil, {}
    end

    local toggles = {}
    local sliders = getgenv().MemeCustomSliders or {}
    local keybinds = getgenv().MemeCustomKeybinds or {}
    local uiWindow = Builder.Create(Import, Theme, "MEME ACTOR", "[ [ / ] ] Меню")

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
            elseif item.Type == "Toggle" and item.StateKey and Context.States[item.StateKey] then
                local st = Context.States[item.StateKey]
                toggles[item.StateKey] = catTab:AddToggle(item.Text, st.get(), function(val)
                    st.set(val)
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

    return uiWindow, toggles
end

return MenuController
