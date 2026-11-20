-- ui/components/SliderItem.lua
local UserInputService = game:GetService("UserInputService")

return function(page, Ctx, text, minVal, maxVal, defaultVal, callback)
    local Theme = Ctx.Theme or Ctx
    local curVal = math.clamp(defaultVal or minVal, minVal, maxVal)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    row.BackgroundTransparency = 0.90
    row.LayoutOrder = Ctx.NextOrder and Ctx.NextOrder() or 1
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0, 0.5)
    lbl.Position = UDim2.new(0, 12, 0.5, 0)
    lbl.Size = UDim2.new(0.54, 0, 0.74, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.Text = text
    lbl.TextColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 26

    local valBox = Instance.new("TextLabel")
    valBox.AnchorPoint = Vector2.new(1, 0.5)
    valBox.Position = UDim2.new(0.67, 0, 0.5, 0)
    valBox.Size = UDim2.new(0.11, 0, 0.72, 0)
    valBox.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    valBox.BackgroundTransparency = 0.55
    valBox.FontFace = Theme.FontOswald
    valBox.Text = tostring(math.round(curVal))
    valBox.TextColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    valBox.TextScaled = true
    valBox.Parent = row
    Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 6)
    Instance.new("UITextSizeConstraint", valBox).MaxTextSize = 22

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -10, 0.5, 0)
    track.Size = UDim2.new(0.29, 0, 0.24, 0)
    track.BackgroundColor3 = Color3.fromRGB(111, 95, 86)
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

    local st = Instance.new("UIStroke", track)
    st.Color = Color3.fromRGB(80, 68, 62)
    st.Thickness = 2.5

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((curVal - minVal) / math.max(0.001, maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.Size = UDim2.new(0, 12, 0, 22)
    knob.BackgroundColor3 = Theme.Cream or Color3.fromRGB(255, 222, 189)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 4)

    local sliding = false
    local function updateFromX(mouseX)
        local rel = math.clamp((mouseX - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        curVal = math.round(minVal + (maxVal - minVal) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valBox.Text = tostring(curVal)
        if callback then callback(curVal) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; updateFromX(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
end
