-- core/MenuController.lua
-- Контроллер сборки меню DOORS из Registry.MenuCategories

local MenuController = {}

function MenuController.Build(DoorsMenuLib, Registry, Context)
    if not DoorsMenuLib or not Registry or not Registry.MenuCategories then
        return nil, {}
    end

    local toggles = {}
    local uiWindow = DoorsMenuLib.CreateWindow("MEME ACTOR PANEL", "[ [ / ] ] Меню")

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
            end
        end
    end

    return uiWindow, toggles
end

return MenuController
