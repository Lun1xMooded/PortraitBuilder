-- ui/components/KeybindItem.lua
local UserInputService = game:GetService("UserInputService")

return function(page, Ctx, text, defaultBind, callback, syncGroup)
    local Theme = Ctx.Theme
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Theme.Cream
    row.BackgroundTransparency = 0.90
    row.LayoutOrder = Ctx.NextOrder()
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Position = UDim2.new(0, 12, 0.5, 0)
    lbl.Size = UDim2.new(0.62, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = text
    lbl.TextColor3 = Theme.Cream
    lbl.TextSize = 20
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local bindBtn = Instance.new("TextButton")
    bindBtn.AnchorPoint = Vector2.new(1, 0.5)
    bindBtn.Position = UDim2.new(1, -8, 0.5, 0)
    bindBtn.Size = UDim2.new(0.32, 0, 0.76, 0)
    bindBtn.BackgroundColor3 = Theme.Cream
    bindBtn.FontFace = Theme.FontOswaldB
    bindBtn.TextColor3 = Theme.CreamDarkText
    bindBtn.TextSize = 19
    bindBtn.Parent = row
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0.5, 1)

    local function updateVisual(bind)
        local bStr = Ctx.FormatBind(bind)
        bindBtn.Text = bStr and ("[" .. bStr .. "]") or "[ NONE ]"
    end

    local bindSlot = Ctx.RegisterBindSlot(syncGroup, defaultBind, nil, updateVisual)
    updateVisual(bindSlot.bind)

    local function startListen()
        if listening then return end
        listening = true
        bindBtn.Text = "[ ... ]"
        Ctx.ListenForBind(function(newBind)
            listening = false
            Ctx.UpdateBindSlot(bindSlot, newBind)
            if callback then callback(newBind) end
        end)
    end

    bindBtn.MouseButton1Click:Connect(startListen)
    bindBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 then
            startListen()
        end
    end)

    return bindBtn
end
