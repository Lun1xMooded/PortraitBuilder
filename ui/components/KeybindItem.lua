-- ui/components/KeybindItem.lua
local UserInputService = game:GetService("UserInputService")

return function(page, Theme, order, text, defaultKey, callback)
    local currentKey = defaultKey
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
    bindBtn.Text = currentKey and currentKey.Name or "NONE"
    bindBtn.TextColor3 = Theme.CreamDarkText
    bindBtn.TextScaled = true
    bindBtn.Parent = row
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0.45, 0)

    bindBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        bindBtn.Text = "[ ... ]"
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                listening = false
                if inp.KeyCode == Enum.KeyCode.Escape or inp.KeyCode == Enum.KeyCode.Backspace then
                    currentKey = nil
                    bindBtn.Text = "NONE"
                else
                    currentKey = inp.KeyCode
                    bindBtn.Text = currentKey.Name
                end
                if callback then callback(currentKey) end
            end
        end)
    end)
end
