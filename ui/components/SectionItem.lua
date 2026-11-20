-- ui/components/SectionItem.lua
return function(page, Ctx, secText)
    local Theme = Ctx.Theme
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 32)
    hdr.BackgroundColor3 = Theme.Cream
    hdr.BackgroundTransparency = 0.55
    hdr.LayoutOrder = Ctx.NextOrder()
    hdr.Parent = page
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Position = UDim2.new(0, 12, 0.5, 0)
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = string.upper(secText)
    lbl.TextColor3 = Theme.Cream
    lbl.TextSize = 18
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = hdr
    return hdr
end
