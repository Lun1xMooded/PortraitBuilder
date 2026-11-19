-- ui/components/KeybindItem.lua
-- Поддерживает привязку к любой клавише клавиатуры ИЛИ кнопке мыши (ПКМ, СКМ, MouseButton4/5)

local UserInputService = game:GetService("UserInputService")

local MOUSE_LABELS = {
    [Enum.UserInputType.MouseButton2] = "RMB (ПКМ)",
    [Enum.UserInputType.MouseButton3] = "MMB (СКМ)",
}

local function formatBind(bind)
    if not bind then return "NONE" end
    if typeof(bind) == "EnumItem" then
        if bind.EnumType == Enum.KeyCode then
            return bind.Name
        elseif bind.EnumType == Enum.UserInputType then
            return MOUSE_LABELS[bind] or bind.Name
        end
    end
    return tostring(bind)
end

return function(page, Theme, order, text, defaultBind, callback)
    local currentBind = defaultBind
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Theme.Cream
    row.BackgroundTransparency = 0.90
    row.LayoutOrder = order
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
