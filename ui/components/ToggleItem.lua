-- ui/components/ToggleItem.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

return function(page, Ctx, text, defaultState, callback, defaultBind, onBindChange, syncGroup)
    local Theme = Ctx.Theme
    local state = defaultState == true
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
    lbl.Size = UDim2.new(0.75, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = Theme.FontOswald
    lbl.TextColor3 = Theme.Cream
    lbl.TextSize = 20
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -10, 0.5, 0)
    btn.Size = UDim2.new(0, 56, 0, 26)
    btn.BackgroundColor3 = state and Theme.SwitchOnBg or Theme.BgContainer
    btn.BackgroundTransparency = 0.35
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local st = Instance.new("UIStroke", btn)
    st.Color = Theme.SwitchStroke
    st.Thickness = 2.5

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = state and UDim2.new(0.76, 0, 0.5, 0) or UDim2.new(0.24, 0, 0.5, 0)
    knob.Size = UDim2.new(0.42, 0, 0.85, 0)
    knob.BackgroundColor3 = Theme.Cream
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    Instance.new("UIAspectRatioConstraint", knob).AspectRatio = 1

    local function set(val, silent)
        state = val == true
        TweenService:Create(knob, TweenInfo.new(0.14), {
            Position = state and UDim2.new(0.76, 0, 0.5, 0) or UDim2.new(0.24, 0, 0.5, 0)
        }):Play()
        btn.BackgroundColor3 = state and Theme.SwitchOnBg or Theme.BgContainer
        if not silent and callback then callback(state) end
    end

    local function updateVisual(bind)
        local bStr = Ctx.FormatBind(bind)
        lbl.Text = bStr and (text .. " / [" .. bStr .. "]") or text
    end

    local bindSlot = Ctx.RegisterBindSlot(syncGroup, defaultBind, function() set(not state, false) end, updateVisual)
    updateVisual(bindSlot.bind)

    btn.MouseButton1Click:Connect(function() set(not state, false) end)

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 and not listening then
            listening = true
            lbl.Text = text .. " / [ ... ]"
            Ctx.ListenForBind(function(newBind)
                listening = false
                Ctx.UpdateBindSlot(bindSlot, newBind)
                if onBindChange then onBindChange(newBind) end
            end)
        end
    end)

    return { Set = set, Get = function() return state end }
end
