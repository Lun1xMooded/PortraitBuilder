-- ui/components/SectionItem.lua
return function(page, Ctx, secText)
    local Theme = Ctx.Theme or Ctx
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 34)
    hdr.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    hdr.BackgroundTransparency = 0.52
    hdr.LayoutOrder = Ctx.NextOrder and Ctx.NextOrder() or 1
    hdr.Parent = page
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Position = UDim2.new(0, 12, 0.5, 0)
    lbl.Size = UDim2.new(1, -24, 0.76, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = string.upper(secText)
    lbl.TextColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = hdr
    Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 22
    return hdr
end
