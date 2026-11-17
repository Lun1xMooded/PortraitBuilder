-- libs/DoorsMenuLib.lua
-- Модульное меню в точном стиле DOORS Admin Panel (открывается на [ или ])

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DoorsMenuLib = {}

-- Фирменная палитра из дампа DoorsAdmin
local THEME = {
    BgDark       = Color3.fromRGB(30, 17, 16),
    HeaderBg     = Color3.fromRGB(38, 25, 25),
    Cream        = Color3.fromRGB(255, 222, 189),
    CreamTextDk  = Color3.fromRGB(39, 20, 17),
    TabIconDk    = Color3.fromRGB(84, 68, 61),
    SubText      = Color3.fromRGB(145, 103, 92),
    ToggleTrack  = Color3.fromRGB(204, 147, 121),
    SliderBg     = Color3.fromRGB(111, 95, 86),
    SliderStroke = Color3.fromRGB(80, 68, 62),
    FontMain     = Enum.Font.Oswald,
}

local function addCorner(parent, radiusScale, radiusOffset)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(radiusScale or 0, radiusOffset or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Cream
    s.Thickness = thickness or 3
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function addPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 6)
    p.PaddingBottom = UDim.new(0, bottom or 6)
    p.PaddingLeft = UDim.new(0, left or 10)
    p.PaddingRight = UDim.new(0, right or 10)
    p.Parent = parent
    return p
end

function DoorsMenuLib.CreateWindow(titleText, subText)
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    local old = pgui:FindFirstChild("MemeActorDoorsUI")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MemeActorDoorsUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = pgui

    -- Главное окно (Container из дампа DOORS)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0, 680, 0, 460)
    container.BackgroundColor3 = THEME.BgDark
    container.BackgroundTransparency = 0.12
    container.Visible = false
    container.Parent = screenGui
    addCorner(container, 0.02, 0)
    addStroke(container, THEME.Cream, 3, 0)

    -- Перетаскивание окна за шапку
    local dragging, dragStart, startPos = false, nil, nil
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Position = UDim2.new(0, 14, 0, 10)
    header.Size = UDim2.new(1, -28, 0, 42)
    header.BackgroundTransparency = 1
    header.Parent = container

    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = container.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title_Store"
    titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = THEME.FontMain
    titleLabel.Text = string.upper(titleText or "MEME ACTOR PANEL")
    titleLabel.TextColor3 = THEME.Cream
    titleLabel.TextSize = 30
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "SubTitle"
    subLabel.Position = UDim2.new(0.45, 0, 0, 0)
    subLabel.Size = UDim2.new(0.45, 0, 1, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Font = THEME.FontMain
    subLabel.Text = subText or "[ [ / ] ] Открыть / Закрыть"
    subLabel.TextColor3 = THEME.SubText
    subLabel.TextSize = 18
    subLabel.TextXAlignment = Enum.TextXAlignment.Right
    subLabel.Parent = header

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = "rbxassetid://2195446979"
    closeBtn.ImageColor3 = THEME.Cream
    closeBtn.Parent = header

    -- Боковая панель категорий (TabButtons слева от основного окна, как в DOORS Admin)
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabButtons"
    tabBar.AnchorPoint = Vector2.new(1, 0)
    tabBar.Position = UDim2.new(0, -10, 0, 0)
    tabBar.Size = UDim2.new(0, 74, 1, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = container

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Vertical
    tabList.Padding = UDim.new(0, 10)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.Parent = tabBar

    -- Контейнер страниц (Pages)
    local pagesHolder = Instance.new("Frame")
    pagesHolder.Name = "Pages"
    pagesHolder.Position = UDim2.new(0, 14, 0, 58)
    pagesHolder.Size = UDim2.new(1, -28, 1, -70)
    pagesHolder.BackgroundTransparency = 1
    pagesHolder.Parent = container

    local Window = {
        Gui = screenGui,
        Container = container,
        Tabs = {},
        ActiveTab = nil,
    }

    function Window:Toggle(forceState)
        if forceState ~= nil then
            container.Visible = forceState
        else
            container.Visible = not container.Visible
        end
    end

    closeBtn.MouseButton1Click:Connect(function()
        Window:Toggle(false)
    end)

    -- =========================================================================
    -- TEMPLATE КАТЕГОРИИ (Боковая кнопка + Страница ScrollingFrame)
    -- =========================================================================
    function Window:AddCategory(catName, iconAssetId)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. catName
        tabBtn.Size = UDim2.new(0, 68, 0, 68)
        tabBtn.BackgroundColor3 = THEME.BgDark
        tabBtn.BackgroundTransparency = 0.1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabBar
        addCorner(tabBtn, 0.15, 0)
        local stroke = addStroke(tabBtn, THEME.Cream, 2.5, 0.35)

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.AnchorPoint = Vector2.new(0.5, 0)
        icon.Position = UDim2.new(0.5, 0, 0, 6)
        icon.Size = UDim2.new(0, 36, 0, 36)
        icon.BackgroundTransparency = 1
        icon.Image = iconAssetId or "rbxassetid://113075964705926"
        icon.ImageColor3 = THEME.Cream
        icon.Parent = tabBtn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Title"
        lbl.AnchorPoint = Vector2.new(0.5, 1)
        lbl.Position = UDim2.new(0.5, 0, 1, -4)
        lbl.Size = UDim2.new(1, -6, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Font = THEME.FontMain
        lbl.Text = string.upper(catName)
        lbl.TextColor3 = THEME.Cream
        lbl.TextSize = 13
        lbl.TextScaled = true
        lbl.Parent = tabBtn

        -- Страница категории (ScrollingFrame)
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. catName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 5
        page.ScrollBarImageColor3 = THEME.Cream
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pagesHolder
        addPadding(page, 4, 14, 4, 8)

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.FillDirection = Enum.FillDirection.Vertical
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        local Category = {
            Button = tabBtn,
            Page = page,
            Stroke = stroke,
            Icon = icon,
            Label = lbl,
            OrderCount = 0,
        }

        local function selectThisCategory()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = THEME.BgDark
                t.Stroke.Transparency = 0.45
                t.Icon.ImageColor3 = THEME.Cream
                t.Label.TextColor3 = THEME.Cream
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = THEME.Cream
            stroke.Transparency = 0
            icon.ImageColor3 = THEME.TabIconDk
            lbl.TextColor3 = THEME.TabIconDk
            Window.ActiveTab = Category
        end

        tabBtn.MouseButton1Click:Connect(selectThisCategory)
        table.insert(Window.Tabs, Category)
        if #Window.Tabs == 1 then
            selectThisCategory()
        end

        local function nextOrder()
            Category.OrderCount = Category.OrderCount + 1
            return Category.OrderCount
        end

        -- =====================================================================
        -- TEMPLATE ЗАГОЛОВКА СЕКЦИИ (SettingHeader из дампа DOORS)
-- =====================================================================
function Category:AddSection(sectionTitle)
local hdr = Instance.new("Frame")
hdr.Name = "Section_" .. sectionTitle
hdr.Size = UDim2.new(1, 0, 0, 32)
hdr.BackgroundColor3 = THEME.Cream
hdr.BackgroundTransparency = 0.55
hdr.LayoutOrder = nextOrder()
hdr.Parent = page
addCorner(hdr, 0, 8)
addPadding(hdr, 0, 0, 12, 12)
local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Font = THEME.FontMain
txt.Text = string.upper(sectionTitle)
txt.TextColor3 = THEME.Cream
txt.TextSize = 20
txt.TextXAlignment = Enum.TextXAlignment.Left
txt.Parent = hdr
end
-- =====================================================================
-- TEMPLATE КНОПКИ (Button из дампа DOORS: подложка 0.90 + кнопка EXECUTE)
-- =====================================================================
function Category:AddButton(actionText, btnLabel, callback, customBtnColor)
local row = Instance.new("Frame")
row.Name = "BtnRow_" .. actionText
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = THEME.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrder()
row.Parent = page
addCorner(row, 0, 8)
addPadding(row, 5, 5, 12, 8)
local nameLbl = Instance.new("TextLabel")
nameLbl.Name = "ActionName"
nameLbl.Size = UDim2.new(0.62, 0, 1, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.Font = THEME.FontMain
nameLbl.Text = actionText
nameLbl.TextColor3 = THEME.Cream
nameLbl.TextSize = 21
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = row
local btn = Instance.new("TextButton")
btn.Name = "Button"
btn.AnchorPoint = Vector2.new(1, 0.5)
btn.Position = UDim2.new(1, 0, 0.5, 0)
btn.Size = UDim2.new(0.34, 0, 1, 0)
btn.BackgroundColor3 = customBtnColor or THEME.Cream
btn.Font = THEME.FontMain
btn.Text = string.upper(btnLabel or "EXECUTE")
btn.TextColor3 = THEME.CreamTextDk
btn.TextSize = 19
btn.AutoButtonColor = true
btn.Parent = row
addCorner(btn, 0.45, 0)
btn.MouseButton1Click:Connect(function()
if callback then callback() end
end)
return btn
end
-- =====================================================================
-- TEMPLATE ПЕРЕКЛЮЧАТЕЛЯ (Switch из дампа DOORS)
-- =====================================================================
function Category:AddToggle(actionText, defaultState, callback)
local state = defaultState == true
local row = Instance.new("Frame")
row.Name = "ToggleRow_" .. actionText
row.Size = UDim2.new(1, 0, 0, 42)
row.BackgroundColor3 = THEME.Cream
row.BackgroundTransparency = 0.90
row.LayoutOrder = nextOrder()
row.Parent = page
addCorner(row, 0, 8)
addPadding(row, 6, 6, 12, 10)
local nameLbl = Instance.new("TextLabel")
nameLbl.Name = "ActionName"
nameLbl.Size = UDim2.new(0.75, 0, 1, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.Font = THEME.FontMain
nameLbl.Text = actionText
nameLbl.TextColor3 = THEME.Cream
nameLbl.TextSize = 21
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = row
local track = Instance.new("TextButton")
track.Name = "SwitchTrack"
track.AnchorPoint = Vector2.new(1, 0.5)
track.Position = UDim2.new(1, 0, 0.5, 0)
track.Size = UDim2.new(0, 56, 0, 26)
track.BackgroundColor3 = state and THEME.ToggleTrack or THEME.BgDark
track.BackgroundTransparency = 0.25
track.Text = ""
track.AutoButtonColor = false
track.Parent = row
addCorner(track, 1, 0)
addStroke(track, THEME.Cream, 2, 0.2)
local knob = Instance.new("Frame")
knob.Name = "Knob"
knob.AnchorPoint = Vector2.new(0, 0.5)
knob.Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
knob.Size = UDim2.new(0, 20, 0, 20)
knob.BackgroundColor3 = THEME.Cream
knob.Parent = track
addCorner(knob, 1, 0)
local function setState(newState, silent)
state = newState == true
TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
}):Play()
track.BackgroundColor3 = state and THEME.ToggleTrack or THEME.BgDark
if not silent and callback then
callback(state)
end
end
track.MouseButton1Click:Connect(function()
setState(not state, false)
end)
return {
Set = setState,
Get = function() return state end
}
end
return Category
end
return Window
end
return DoorsMenuLib