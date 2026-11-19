-- ui/components/ButtonItem.lua
return function(page, Theme, order, text, btnText, callback, customColor)
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
