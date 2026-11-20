-- ui/DoorsGuiBuilder.lua
-- Самодостаточный сборщик меню DoorsAdmin (Кнопки, Тумблеры, Слайдеры, Бинды + UnlockMouseVisible)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local DoorsGuiBuilder = {}

local MOUSE_LABELS = {
    [Enum.UserInputType.MouseButton2] = "RMB (ПКМ)",
    [Enum.UserInputType.MouseButton3] = "MMB (СКМ)",
}

local function formatBind(bind)
    if not bind then return "NONE" end
    if typeof(bind) == "EnumItem" then
        if bind.EnumType == Enum.KeyCode then return bind.Name end
        if bind.EnumType == Enum.UserInputType then return MOUSE_LABELS[bind] or bind.Name end
    end
    return tostring(bind)
end

function DoorsGuiBuilder.Create(arg1, arg2, arg3, arg4)
    local Theme = (type(arg1) == "table") and arg1 or arg2
    local titleText = (type(arg1) == "table") and arg2 or arg3
    local subText = (type(arg1) == "table") and arg3 or arg4

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
    titleLbl.Position = UDim2.new(0, 0, 0.5, 0)
    titleLbl.Size = UDim2.new(0.45, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.FontFace = Theme.FontOswald
    titleLbl.Text = string.upper(titleText or "MEME ACTOR")
    titleLbl.TextColor3 = Theme.Cream
    titleLbl.TextScaled = true
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    local attrInfo = Instance.new("TextLabel")
    attrInfo.AnchorPoint = Vector2.new(0, 0.5)
    attrInfo.Position = UDim2.new(0.36, 0, 0.5, 0)
    attrInfo.Size = UDim2.new(0.54, 0, 0.72, 0)
    attrInfo.BackgroundTransparency = 1
    attrInfo.FontFace = Theme.FontOswald
    attrInfo.Text = subText or "[ [ / ] ] Открыть / Закрыть"
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
    local Window = { Gui = sg, Container = container, Tabs = {} }

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
        local function nextOrd() Cat.Order = Cat.Order + 1; return Cat.Order end

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

        function Cat:AddSection(secText)
            local hdr = Instance.new("Frame")
            hdr.Size = UDim2.new(1, 0, 0, 34)
            hdr.BackgroundColor3 = Theme.Cream
            hdr.BackgroundTransparency = 0.50
            hdr.LayoutOrder = nextOrd()
            hdr.Parent = page
            Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 8)

            local lbl = Instance.new("TextLabel")
            lbl.AnchorPoint = Vector2.new(0, 0.5)
            lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
            lbl.Size = UDim2.new(0.9, 0, 0.72, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = Theme.FontOswald
            lbl.Text = string.upper(secText)
            lbl.TextColor3 = Theme.Cream
            lbl.TextScaled = true
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = hdr
        end

        function Cat:AddButton(text, btnText, callback, customColor)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundColor3 = Theme.Cream
            row.BackgroundTransparency = 0.90
            row.LayoutOrder = nextOrd()
            row.Parent = page
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.62, 0, 0.75, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = text
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(0.985, 0, 0.5, 0)
btn.Size = UDim2.new(0.32, 0, 0.78, 0)
btn.BackgroundColor3 = customColor or Theme.Cream
btn.FontFace = Theme.FontOswaldB
btn.Text = string.upper(btnText or "EXECUTE")
btn.TextColor3 = Theme.CreamDarkText
btn.TextScaled = true
btn.Parent = row
Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 1)
btn.MouseButton1Click:Connect(function() if callback then callback() end end)
return btn
end
function Cat:AddToggle(text, defaultState, callback)
local state = defaultState == true
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = Theme.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrd()
row.Parent = page
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
local lbl = Instance.new("TextLabel")
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.75, 0, 0.75, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = text
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(0.985, 0, 0.5, 0)
btn.Size = UDim2.new(0, 56, 0, 26)
btn.BackgroundColor3 = state and Theme.SwitchOnBg or Theme.BgContainer
btn.BackgroundTransparency = 0.35
btn.Text = ""
btn.AutoButtonColor = false
btn.Parent = row
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
local st = Instance.new("UIStroke", btn)
st.Color = Theme.SwitchStroke
st.Thickness = 2.5
local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = state and UDim2.new(0.76, 0, 0.5, 0) or UDim2.new(0.24, 0, 0.5, 0)
knob.Size = UDim2.new(0.42, 0, 0.85, 0)
knob.BackgroundColor3 = Theme.Cream
knob.Parent = btn
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
Instance.new("UIAspectRatioConstraint", knob).AspectRatio = 1
local function set(val, silent)
state = val == true
TweenService:Create(knob, TweenInfo.new(0.14), {
Position = state and UDim2.new(0.76, 0, 0.5, 0) or UDim2.new(0.24, 0, 0.5, 0)
}):Play()
btn.BackgroundColor3 = state and Theme.SwitchOnBg or Theme.BgContainer
if not silent and callback then callback(state) end
end
btn.MouseButton1Click:Connect(function() set(not state, false) end)
return { Set = set, Get = function() return state end }
end
function Cat:AddSlider(text, minVal, maxVal, defaultVal, callback)
local curVal = math.clamp(defaultVal or minVal, minVal, maxVal)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 44)
row.BackgroundColor3 = Theme.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrd()
row.Parent = page
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
local lbl = Instance.new("TextLabel")
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.54, 0, 0.72, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = text
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local valBox = Instance.new("TextLabel")
valBox.AnchorPoint = Vector2.new(1, 0.5)
valBox.Position = UDim2.new(0.67, 0, 0.5, 0)
valBox.Size = UDim2.new(0.11, 0, 0.68, 0)
valBox.BackgroundColor3 = Theme.Cream
valBox.BackgroundTransparency = 0.55
valBox.FontFace = Theme.FontOswald
valBox.Text = tostring(math.round(curVal))
valBox.TextColor3 = Theme.Cream
valBox.TextScaled = true
valBox.Parent = row
Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 6)
local track = Instance.new("TextButton")
track.AnchorPoint = Vector2.new(1, 0.5)
track.Position = UDim2.new(0.985, 0, 0.5, 0)
track.Size = UDim2.new(0.29, 0, 0.22, 0)
track.BackgroundColor3 = Color3.fromRGB(111, 95, 86)
track.Text = ""
track.AutoButtonColor = false
track.Parent = row
Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
local st = Instance.new("UIStroke", track)
st.Color = Color3.fromRGB(80, 68, 62)
st.Thickness = 2.5
local fill = Instance.new("Frame")
fill.Size = UDim2.new((curVal - minVal) / math.max(0.001, maxVal - minVal), 0, 1, 0)
fill.BackgroundColor3 = Theme.Cream
fill.BorderSizePixel = 0
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
knob.Size = UDim2.new(0, 12, 0, 22)
knob.BackgroundColor3 = Theme.Cream
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 4)
local sliding = false
local function updateFromX(mouseX)
local rel = math.clamp((mouseX - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
curVal = math.round(minVal + (maxVal - minVal) * rel)
fill.Size = UDim2.new(rel, 0, 1, 0)
knob.Position = UDim2.new(rel, 0, 0.5, 0)
valBox.Text = tostring(curVal)
if callback then callback(curVal) end
end
track.InputBegan:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; updateFromX(inp.Position.X) end
end)
UserInputService.InputChanged:Connect(function(inp)
if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(inp.Position.X) end
end)
UserInputService.InputEnded:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
end)
end
function Cat:AddKeybind(text, defaultBind, callback)
local currentBind = defaultBind
local listening = false
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = Theme.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrd()
row.Parent = page
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
local lbl = Instance.new("TextLabel")
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.65, 0, 0.75, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = text
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local bindBtn = Instance.new("TextButton")
bindBtn.AnchorPoint = Vector2.new(1, 0.5)
bindBtn.Position = UDim2.new(0.985, 0, 0.5, 0)
bindBtn.Size = UDim2.new(0.28, 0, 0.78, 0)
bindBtn.BackgroundColor3 = Theme.Cream
bindBtn.FontFace = Theme.FontOswaldB
bindBtn.Text = formatBind(currentBind)
bindBtn.TextColor3 = Theme.CreamDarkText
bindBtn.TextScaled = true
bindBtn.Parent = row
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0.45, 0)
bindBtn.MouseButton1Click:Connect(function()
if listening then return end
listening = true
bindBtn.Text = "[ ЖМИ КЛАВИШУ / ПКМ ]"
task.defer(function()
local conn
conn = UserInputService.InputBegan:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.Keyboard then
conn:Disconnect()
listening = false
if inp.KeyCode == Enum.KeyCode.Escape or inp.KeyCode == Enum.KeyCode.Backspace then
currentBind = nil
else
currentBind = inp.KeyCode
end
bindBtn.Text = formatBind(currentBind)
if callback then callback(currentBind) end
elseif inp.UserInputType == Enum.UserInputType.MouseButton2
or inp.UserInputType == Enum.UserInputType.MouseButton3 then
conn:Disconnect()
listening = false
currentBind = inp.UserInputType
bindBtn.Text = formatBind(currentBind)
if callback then callback(currentBind) end
end
end)
end)
end)
end
return Cat
end
return Window
end
return DoorsGuiBuilder