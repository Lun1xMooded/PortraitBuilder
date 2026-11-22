-- core/MenuController.lua
local UserInputService = game:GetService("UserInputService")
local MenuController = {}

function MenuController.Build(Import, Registry, Context)
    local Theme          = Import("ui/DoorsTheme.lua")
    local Builder        = Import("ui/DoorsGuiBuilder.lua")
    local KeybindStorage = Import("core/KeybindStorage.lua")

    if not Theme or not Builder or not Registry or not Registry.MenuCategories then
        warn("[MenuController] Не загрузились Theme или Builder!")
        return nil, {}, nil
    end

    -- 1. Собираем карту стандартных биндов по SyncId из всего меню
    local defaultBinds = {}
    for _, catData in ipairs(Registry.MenuCategories) do
        for _, item in ipairs(catData.Items) do
            local syncId = item.SyncId or item.Action or item.StateKey or (item.ModeId and (item.ModeId .. "_" .. tostring(item.SubMode)))
            if syncId and item.DefaultBind ~= nil then
                defaultBinds[syncId] = item.DefaultBind
            end
        end
    end

    -- 2. Загружаем сохранённые бинды из файла (если есть)
    local activeBinds = KeybindStorage and KeybindStorage.Load(defaultBinds) or defaultBinds

    -- Функция сохранения текущего состояния всех биндов
    local function saveAllBinds(uiWindow)
        if not KeybindStorage or not uiWindow or not uiWindow.SyncGroups then return end
        local currentMap = {}
        for syncId, slot in pairs(uiWindow.SyncGroups) do
            -- Сохраняем либо EnumItem, либо строку "NONE", чтобы пустой бинд не перезаписывался дефолтным
            currentMap[syncId] = slot.bind or "NONE"
        end
        KeybindStorage.Save(currentMap)
    end

    local toggles = {}
    local sliders = getgenv().MemeCustomSliders or {}
    local uiWindow = Builder.Create(Import, Theme, "MEME ACTOR", "Menu")

    -- Передаём в окно хук на автосохранение при любом изменении бинда (включая СКМ)
    uiWindow.OnBindUpdated = function()
        saveAllBinds(uiWindow)
    end

    for _, catData in ipairs(Registry.MenuCategories) do
        local catTab = uiWindow:AddCategory(catData.Title, catData.Icon)
        for _, item in ipairs(catData.Items) do
            local syncId = item.SyncId or item.Action or item.StateKey or (item.ModeId and (item.ModeId .. "_" .. tostring(item.SubMode)))
            -- Берём сохранённый бинд, если он есть (если "NONE" — ставим nil)
            local resolvedBind = item.DefaultBind
            if syncId and activeBinds[syncId] ~= nil then
                resolvedBind = (activeBinds[syncId] == "NONE") and nil or activeBinds[syncId]
            end

            if item.Type == "Section" then
                catTab:AddSection(item.Text)

            elseif item.Type == "Button" then
                local actFn = function()
                    if item.Action and Context.Actions[item.Action] then
                        Context.Actions[item.Action]()
                    elseif item.ModeId then
                        Context.RunMode(item.ModeId, item.SubMode, item.AutoSpawn)
                    end
                end
                catTab:AddButton(item.Text, item.ButtonText, actFn, item.Color, resolvedBind, function()
                    saveAllBinds(uiWindow)
                end, syncId)

            elseif item.Type == "Toggle" and item.StateKey then
                local st = Context.States[item.StateKey]
                local defVal = st and st.get() or false
                toggles[item.StateKey] = catTab:AddToggle(item.Text, defVal, function(val)
                    local curSt = Context.States[item.StateKey]
                    if curSt and curSt.set then curSt.set(val) end
                end, resolvedBind, function()
                    saveAllBinds(uiWindow)
                end, syncId)

            elseif item.Type == "Slider" and item.SettingKey and sliders[item.SettingKey] then
                local sl = sliders[item.SettingKey]
                catTab:AddSlider(item.Text, item.Min, item.Max, sl.get(), function(val)
                    sl.set(val)
                end)

            elseif item.Type == "Keybind" then
                catTab:AddKeybind(item.Text, resolvedBind, function(newBind)
                    if item.OnChange then item.OnChange(newBind) end
                    saveAllBinds(uiWindow)
                end, syncId)
            end
        end
    end

    local toggleKeys = Registry.MenuToggleKeys or { Enum.KeyCode.LeftBracket, Enum.KeyCode.RightBracket, Enum.KeyCode.RightShift }
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
