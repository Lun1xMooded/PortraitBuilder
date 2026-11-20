-- ui/components/KeybindItem.lua
return function(page, Ctx, text, defaultBind, callback, syncGroup)
    local Theme = Ctx.Theme or Ctx
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    row.BackgroundTransparency = 0.90
    row.LayoutOrder = Ctx.NextOrder and Ctx.NextOrder() or 1
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Position = UDim2.new(0, 12, 0.5, 0)
    lbl.Size = UDim2.new(0.62, 0, 0.74, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = text
    lbl.TextColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 26

    local bindBtn = Instance.new("TextButton")
    bindBtn.AnchorPoint = Vector2.new(1, 0.5)
    bindBtn.Position = UDim2.new(1, -8, 0.5, 0)
    bindBtn.Size = UDim2.new(0.32, 0, 0.78, 0)
    bindBtn.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    bindBtn.FontFace = Theme.FontOswaldB
    bindBtn.TextColor3 = Theme.CreamDarkText or Color3.fromRGB(39, 20, 17)
    bindBtn.TextScaled = true
    bindBtn.Parent = row
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0.5, 1)
    Instance.new("UITextSizeConstraint", bindBtn).MaxTextSize = 24

    local function updateVisual(bind)
        local bStr = Ctx.FormatBind and Ctx.FormatBind(bind)
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
