-- ui/DoorsGuiBuilder.lua
-- Точная верстка DoorsAdmin из дампа + нативная разблокировка мышки DOORS ("UnlockMouseVisible")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local DoorsGuiBuilder = {}

local function corner(parent, scale, offset)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(scale or 0, offset or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick, transp)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick or 3
    s.Transparency = transp or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function DoorsGuiBuilder.Create(Theme, titleText, subText)
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    local old = pgui:FindFirstChild("MemeActorDoorsAdmin")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MemeActorDoorsAdmin"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pgui

    -- Главный Container из дампа DoorsAdmin (AspectRatio = 1.250, Pos = {0.5,0},{0,40}, Size = {0.9,0},{0.95,-40})
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0.62, 0, 0.72, 0)
    container.BackgroundColor3 = Theme.BgContainer
    container.BackgroundTransparency = 0.20
    container.Visible = false
    container.Parent = sg
    corner(container, 0.02, 0)
    stroke(container, Theme.Cream, 3, 0)

    -- Нативный тег DOORS: пока container.Visible == true, камера DOORS сама разблокирует мышку!
    CollectionService:AddTag(container, "UnlockMouseVisible")

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1.250
    aspect.Parent = container

    -- Шапка окна (Header) с перетаскиванием
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.AnchorPoint = Vector2.new(0.5, 0)
    header.Position = UDim2.new(0.5, 0, 0.02, 0)
    header.Size = UDim2.new(0.965, 0, 0.075, 0)
    header.BackgroundTransparency = 1
    header.Parent = container

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, inp.Position, container.Position
        end
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
    titleLbl.Name = "Title_Store"
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
    attrInfo.Name = "AttributeInformation"
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
    closeBtn.Name = "CloseButton"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0.95, 0, 0.95, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = Theme.IconClose
    closeBtn.ImageColor3 = Theme.Cream
    closeBtn.Parent = header
    local closeAsp = Instance.new("UIAspectRatioConstraint")
    closeAsp.AspectRatio = 1
    closeAsp.Parent = closeBtn

    -- Боковые вкладки слева от Container (TabButtons из дампа: Anchor=1,0, Pos={0,-6},{0,0}, Size={0.11,0},{1,0})
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.AnchorPoint = Vector2.new(1, 0)
    tabButtons.Position = UDim2.new(0, -8, 0, 0)
    tabButtons.Size = UDim2.new(0.11, 0, 1, 0)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = container

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Vertical
    tabList.Padding = UDim.new(0.02, 0)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tabList.Parent = tabButtons

    local pagesFolder = Instance.new("Folder")
    pagesFolder.Name = "Pages"
    pagesFolder.Parent = container

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
        tabBtn.Name = "TabButton_" .. catTitle
        tabBtn.Size = UDim2.new(1, 0, 0.14, 0)
        tabBtn.BackgroundColor3 = Theme.BgContainer
        tabBtn.BackgroundTransparency = 0.15
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabButtons
        corner(tabBtn, 0.15, 0)
        local tabStroke = stroke(tabBtn, Theme.Cream, 3, 0)

        local tabAsp = Instance.new("UIAspectRatioConstraint")
        tabAsp.AspectRatio = 1.05
        tabAsp.Parent = tabBtn

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.new(0.5, 0, 0.42, 0)
        icon.Size = UDim2.new(0.62, 0, 0.62, 0)
        icon.BackgroundTransparency = 1
        icon.Image = iconAsset or "rbxassetid://113075964705926"
        icon.ImageColor3 = Theme.Cream
        icon.Parent = tabBtn

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AnchorPoint = Vector2.new(0.5, 1)
        title.Position = UDim2.new(0.5, 0, 0.96, 0)
        title.Size = UDim2.new(0.92, 0, 0.24, 0)
        title.BackgroundTransparency = 1
        title.FontFace = Theme.FontTabHeavy
        title.Text = string.upper(catTitle)
        title.TextColor3 = Theme.Cream
        title.TextScaled = true
        title.Parent = tabBtn

        -- Страница категории (Page из дампа: Anchor=0.5,1, Pos={0.5,0},{0.98,0}, Size={0.965,0},{0.885,0})
        local page = Instance.new("ScrollingFrame")
        page.Name = catTitle
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

        local pPad = Instance.new("UIPadding")
        pPad.PaddingRight = UDim.new(0.015, 0)
        pPad.Parent = page

        local pList = Instance.new("UIListLayout")
        pList.FillDirection = Enum.FillDirection.Vertical
        pList.Padding = UDim.new(0, 8)
        pList.SortOrder = Enum.SortOrder.LayoutOrder
        pList.Parent = page

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

        -- SettingHeader из дампа DoorsAdmin
        function Cat:AddSection(secText)
            local hdr = Instance.new("Frame")
            hdr.Name = "SettingHeader"
            hdr.Size = UDim2.new(1, 0, 0, 34)
            hdr.BackgroundColor3 = Theme.Cream
            hdr.BackgroundTransparency = 0.50
            hdr.LayoutOrder = nextOrd()
            hdr.Parent = page
            corner(hdr, 0, 8)

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
local cIcon = Instance.new("ImageLabel")
cIcon.AnchorPoint = Vector2.new(1, 0.5)
cIcon.Position = UDim2.new(0.985, 0, 0.5, 0)
cIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
cIcon.BackgroundTransparency = 1
cIcon.Image = Theme.IconCollapse
cIcon.ImageColor3 = Theme.Cream
cIcon.Parent = hdr
local cAsp = Instance.new("UIAspectRatioConstraint")
cAsp.AspectRatio = 1.2
cAsp.Parent = cIcon
end
-- Строка с кнопкой EXECUTE (Bg = RGB(255,222,189), Tr = 0.90 + кнопка Radius(0.5, 1))
function Cat:AddButton(actionText, btnText, callback, customColor)
local row = Instance.new("Frame")
row.Name = "ButtonRow"
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = Theme.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrd()
row.Parent = page
corner(row, 0, 8)
local lbl = Instance.new("TextLabel")
lbl.Name = "ActionName"
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.62, 0, 0.75, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = actionText
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local btn = Instance.new("TextButton")
btn.Name = "Button"
btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(0.985, 0, 0.5, 0)
btn.Size = UDim2.new(0.32, 0, 0.78, 0)
btn.BackgroundColor3 = customColor or Theme.Cream
btn.FontFace = Theme.FontOswaldB
btn.Text = string.upper(btnText or "EXECUTE")
btn.TextColor3 = Theme.CreamDarkText
btn.TextScaled = true
btn.Parent = row
corner(btn, 0.5, 1)
btn.MouseButton1Click:Connect(function() if callback then callback() end end)
return btn
end
-- Switch из дампа DoorsAdmin (Bg = RGB(204,147,121) Tr=0.35 + Stroke RGB(216,225,239) + круглый ползунок)
function Cat:AddToggle(actionText, defaultState, callback)
local state = defaultState == true
local row = Instance.new("Frame")
row.Name = "SwitchRow"
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = Theme.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrd()
row.Parent = page
corner(row, 0, 8)
local lbl = Instance.new("TextLabel")
lbl.Name = "ActionName"
lbl.AnchorPoint = Vector2.new(0, 0.5)
lbl.Position = UDim2.new(0.015, 0, 0.5, 0)
lbl.Size = UDim2.new(0.75, 0, 0.75, 0)
lbl.BackgroundTransparency = 1
lbl.FontFace = Theme.FontOswald
lbl.Text = actionText
lbl.TextColor3 = Theme.Cream
lbl.TextScaled = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = row
local btn = Instance.new("TextButton")
btn.Name = "Button"
btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(0.985, 0, 0.5, 0)
btn.Size = UDim2.new(0, 56, 0, 26)
btn.BackgroundColor3 = state and Theme.SwitchOnBg or Theme.BgContainer
btn.BackgroundTransparency = 0.35
btn.Text = ""
btn.AutoButtonColor = false
btn.Parent = row
corner(btn, 1, 0)
stroke(btn, Theme.SwitchStroke, 2.5, 0)
local knob = Instance.new("Frame")
knob.Name = "Switch"
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = state and UDim2.new(0.76, 0, 0.5, 0) or UDim2.new(0.24, 0, 0.5, 0)
knob.Size = UDim2.new(0.42, 0, 0.85, 0)
knob.BackgroundColor3 = Theme.Cream
knob.Parent = btn
corner(knob, 1, 0)
local kAsp = Instance.new("UIAspectRatioConstraint")
kAsp.AspectRatio = 1
kAsp.Parent = knob
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
return Cat
end
return Window
end
return DoorsGuiBuilder