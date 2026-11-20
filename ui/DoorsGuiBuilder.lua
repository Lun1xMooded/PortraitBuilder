-- ui/DoorsGuiBuilder.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local DoorsGuiBuilder = {}

local MOUSE_LABELS = {
    [Enum.UserInputType.MouseButton2] = "RMB",
    [Enum.UserInputType.MouseButton3] = "MMB",
}

local function formatBind(bind)
    if not bind then return nil end
    if typeof(bind) == "EnumItem" then
        if bind.EnumType == Enum.KeyCode then return bind.Name end
        if bind.EnumType == Enum.UserInputType then return MOUSE_LABELS[bind] or bind.Name end
    end
    return tostring(bind)
end

local function listenForBind(onCaptured)
    task.defer(function()
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                if inp.KeyCode == Enum.KeyCode.Escape or inp.KeyCode == Enum.KeyCode.Backspace then
                    onCaptured(nil)
                else
                    onCaptured(inp.KeyCode)
                end
            elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect()
                onCaptured(inp.UserInputType)
            end
        end)
    end)
end

function DoorsGuiBuilder.Create(Import, Theme, titleText, subText)
    local SectionComp = Import("ui/components/SectionItem.lua")
    local ButtonComp  = Import("ui/components/ButtonItem.lua")
    local ToggleComp  = Import("ui/components/ToggleItem.lua")
    local SliderComp  = Import("ui/components/SliderItem.lua")
    local KeybindComp = Import("ui/components/KeybindItem.lua")

    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    local old = pgui:FindFirstChild("MemeActorDoorsAdmin")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MemeActorDoorsAdmin"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pgui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0.62, 0, 0.72, 0)
    container.BackgroundColor3 = Theme.BgContainer
    container.BackgroundTransparency = 0.20
    container.Visible = false
    container.Parent = sg
    Instance.new("UICorner", container).CornerRadius = UDim.new(0.02, 0)
    local st = Instance.new("UIStroke", container)
    st.Color = Theme.Cream
    st.Thickness = 3
    CollectionService:AddTag(container, "UnlockMouseVisible")
    Instance.new("UIAspectRatioConstraint", container).AspectRatio = 1.250

    local header = Instance.new("Frame")
    header.AnchorPoint = Vector2.new(0.5, 0)
    header.Position = UDim2.new(0.5, 0, 0.02, 0)
    header.Size = UDim2.new(0.965, 0, 0.075, 0)
    header.BackgroundTransparency = 1
    header.Parent = container

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging, dragStart, startPos = true, inp.Position, container.Position end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.AnchorPoint = Vector2.new(0, 0.5)
    titleLbl.Position = UDim2.new(0.005, 0, 0.5, 0)
    titleLbl.Size = UDim2.new(0.27, 0, 0.92, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.FontFace = Theme.FontOswald
    titleLbl.Text = string.upper(titleText or "MEME ACTOR")
    titleLbl.TextColor3 = Theme.Cream
    titleLbl.TextScaled = true
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    local attrInfo = Instance.new("TextLabel")
    attrInfo.AnchorPoint = Vector2.new(0, 0.5)
    attrInfo.Position = UDim2.new(0.28, 0, 0.54, 0)
    attrInfo.Size = UDim2.new(0.30, 0, 0.62, 0)
    attrInfo.BackgroundTransparency = 1
    attrInfo.FontFace = Theme.FontOswald
    attrInfo.Text = subText or "Menu"
    attrInfo.TextColor3 = Theme.SubTitleColor
    attrInfo.TextScaled = true
    attrInfo.TextXAlignment = Enum.TextXAlignment.Left
    attrInfo.Parent = header

    local closeBtn = Instance.new("ImageButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0.95, 0, 0.95, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = Theme.IconClose
    closeBtn.ImageColor3 = Theme.Cream
    closeBtn.Parent = header
    Instance.new("UIAspectRatioConstraint", closeBtn).AspectRatio = 1

    local tabButtons = Instance.new("Frame")
    tabButtons.AnchorPoint = Vector2.new(1, 0)
    tabButtons.Position = UDim2.new(0, -8, 0, 0)
    tabButtons.Size = UDim2.new(0.11, 0, 1, 0)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = container

    local tabList = Instance.new("UIListLayout", tabButtons)
    tabList.FillDirection = Enum.FillDirection.Vertical
    tabList.Padding = UDim.new(0.02, 0)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local pagesFolder = Instance.new("Folder", container)
    local Window = { Gui = sg, Container = container, Tabs = {}, BindSlots = {}, SyncGroups = {} }

    -- Единый менеджер биндов и визуальной синхронизации между вкладками
    local function registerBindSlot(syncGroup, defaultBind, callback, visualUpdater)
        if syncGroup and Window.SyncGroups[syncGroup] then
            local slot = Window.SyncGroups[syncGroup]
            if callback and not slot.callback then slot.callback = callback end
            if visualUpdater then table.insert(slot.updaters, visualUpdater) end
            return slot
        end

        local slot = {
            bind = defaultBind,
            callback = callback,
            updaters = visualUpdater and { visualUpdater } or {}
        }
        table.insert(Window.BindSlots, slot)
        if syncGroup then
            Window.SyncGroups[syncGroup] = slot
        end
        return slot
    end

    local function updateBindSlot(slot, newBind)
        if not slot then return end
        slot.bind = newBind
        for _, fn in ipairs(slot.updaters) do
            fn(newBind)
        end
    end

    local globalBindConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if UserInputService:GetFocusedTextBox() then return end
        for _, slot in ipairs(Window.BindSlots) do
            local b = slot.bind
            if b and slot.callback then
                local matched = false
                if b.EnumType == Enum.KeyCode and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == b and not gp then
                    matched = true
                elseif b.EnumType == Enum.UserInputType and inp.UserInputType == b then
                    matched = true
                end
                if matched then slot.callback() end
            end
        end
    end)

    sg.Destroying:Connect(function()
        if globalBindConn then globalBindConn:Disconnect() end
    end)

    function Window:Toggle(force)
        container.Visible = (force ~= nil) and force or (not container.Visible)
        if container.Visible then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    end
    closeBtn.MouseButton1Click:Connect(function() Window:Toggle(false) end)

    function Window:AddCategory(catTitle, iconAsset)
        local tabBtn = Instance.new("ImageButton")
        tabBtn.Size = UDim2.new(1, 0, 0.14, 0)
        tabBtn.BackgroundColor3 = Theme.BgContainer
        tabBtn.BackgroundTransparency = 0.15
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabButtons
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0.15, 0)
        local tabStroke = Instance.new("UIStroke", tabBtn)
        tabStroke.Color = Theme.Cream
        tabStroke.Thickness = 3
        Instance.new("UIAspectRatioConstraint", tabBtn).AspectRatio = 1.05

        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.new(0.5, 0, 0.42, 0)
        icon.Size = UDim2.new(0.62, 0, 0.62, 0)
        icon.BackgroundTransparency = 1
        icon.Image = iconAsset or "rbxassetid://113075964705926"
        icon.ImageColor3 = Theme.Cream
        icon.Parent = tabBtn

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 1)
        title.Position = UDim2.new(0.5, 0, 0.96, 0)
        title.Size = UDim2.new(0.92, 0, 0.24, 0)
        title.BackgroundTransparency = 1
        title.FontFace = Theme.FontTabHeavy
        title.Text = string.upper(catTitle)
        title.TextColor3 = Theme.Cream
        title.TextScaled = true
        title.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.AnchorPoint = Vector2.new(0.5, 1)
        page.Position = UDim2.new(0.5, 0, 0.98, 0)
        page.Size = UDim2.new(0.965, 0, 0.885, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 5
        page.ScrollBarImageColor3 = Theme.Cream
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pagesFolder

Instance.new("UIPadding", page).PaddingRight = UDim.new(0.015, 0)
local pList = Instance.new("UIListLayout", page)
pList.FillDirection = Enum.FillDirection.Vertical
pList.Padding = UDim.new(0, 8)
pList.SortOrder = Enum.SortOrder.LayoutOrder
local Cat = { Button = tabBtn, Page = page, Icon = icon, Title = title, Stroke = tabStroke, Order = 0 }
local Ctx = {
Theme = Theme,
NextOrder = function() Cat.Order = Cat.Order + 1; return Cat.Order end,
FormatBind = formatBind,
ListenForBind = listenForBind,
RegisterBindSlot = registerBindSlot,
UpdateBindSlot = updateBindSlot,
}
local function activate()
for _, t in ipairs(Window.Tabs) do
t.Page.Visible = false
t.Button.BackgroundColor3 = Theme.BgContainer
t.Button.BackgroundTransparency = 0.25
t.Icon.ImageColor3 = Theme.Cream
t.Title.TextColor3 = Theme.Cream
t.Stroke.Transparency = 0.4
end
page.Visible = true
tabBtn.BackgroundColor3 = Theme.Cream
tabBtn.BackgroundTransparency = 0
icon.ImageColor3 = Theme.TabDarkIcon
title.TextColor3 = Theme.TabDarkIcon
tabStroke.Transparency = 0
end
tabBtn.MouseButton1Click:Connect(activate)
table.insert(Window.Tabs, Cat)
if #Window.Tabs == 1 then activate() end
function Cat:AddSection(secText)                 return SectionComp(page, Ctx, secText) end
function Cat:AddButton(t, bt, cb, col, db, ob, sg) return ButtonComp(page, Ctx, t, bt, cb, col, db, ob, sg) end
function Cat:AddToggle(t, def, cb, db, ob, sg)     return ToggleComp(page, Ctx, t, def, cb, db, ob, sg) end
function Cat:AddSlider(t, mn, mx, d, cb)           return SliderComp(page, Ctx, t, mn, mx, d, cb) end
function Cat:AddKeybind(t, db, cb, sg)             return KeybindComp(page, Ctx, t, db, cb, sg) end
return Cat
end
return Window
end
return DoorsGuiBuilder