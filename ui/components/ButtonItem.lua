-- ui/components/ButtonItem.lua
return function(page, Ctx, text, btnText, callback, customColor, defaultBind, onBindChange, syncGroup)
    local Theme = Ctx.Theme or Ctx
    local baseTitle = string.upper(btnText or "EXECUTE")
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
    lbl.Size = UDim2.new(0.58, 0, 0.74, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = text
    lbl.TextColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 26

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.Size = UDim2.new(0.35, 0, 0.78, 0)
    btn.BackgroundColor3 = customColor or Theme.Cream or Color3.fromRGB(255, 222, 189)
    btn.FontFace = Theme.FontOswaldB
    btn.TextColor3 = Theme.CreamDarkText or Color3.fromRGB(39, 20, 17)
    btn.TextScaled = true
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 1)
    Instance.new("UITextSizeConstraint", btn).MaxTextSize = 24

    local function updateVisual(bind)
        local bStr = Ctx.FormatBind and Ctx.FormatBind(bind)
        btn.Text = bStr and (baseTitle .. " / [" .. bStr .. "]") or baseTitle
    end

    local bindSlot = Ctx.RegisterBindSlot(syncGroup, defaultBind, callback, updateVisual)
    updateVisual(bindSlot.bind)

    btn.MouseButton1Click:Connect(function()
        if not listening and callback then callback() end
    end)

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 and not listening then
            listening = true
            btn.Text = "[ ... ]"
            Ctx.ListenForBind(function(newBind)
                listening = false
                Ctx.UpdateBindSlot(bindSlot, newBind)
                if onBindChange then onBindChange(newBind) end
            end)
        end
    end)

    return btn
end
