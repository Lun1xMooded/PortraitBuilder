-- PortraitBuilder.lua (Загрузить на GitHub и использовать Raw-ссылку)
local InsertService = game:GetService("InsertService")
local MaterialService = game:GetService("MaterialService")

local VARIANTS = {
    PortraitDark = { BodyColor = Color3.fromRGB(30, 0, 45), EyeColor = Color3.fromRGB(255, 85, 0) },
    PortraitLight = { BodyColor = Color3.fromRGB(182, 180, 194), EyeColor = Color3.fromRGB(0, 0, 0) }
}

local PARTS = {
    LowerTorso = { MeshId = "rbxassetid://85510166518718", Size = Vector3.new(2.0433, 0.5755, 1.1133) },
    UpperTorso = { MeshId = "rbxassetid://74526719630802", Size = Vector3.new(2.1801, 1.9414, 1.2325) },
    FHead = { MeshId = "rbxassetid://102429169478724", Size = Vector3.new(1.2031, 1.2467, 1.2360) },
    RightUpperArm = { MeshId = "rbxassetid://87218701043500", Size = Vector3.new(1.0114, 1.5885, 1.0410) },
    RightLowerArm = { MeshId = "rbxassetid://73176539710232", Size = Vector3.new(1.0361, 1.5272, 1.0689) },
    RightHand = { MeshId = "rbxassetid://88074548220386", Size = Vector3.new(0.9494, 0.3646, 1.0078) },
    LeftUpperArm = { MeshId = "rbxassetid://114118854954210", Size = Vector3.new(1.0258, 1.5862, 1.0470) },
    LeftLowerArm = { MeshId = "rbxassetid://73093746850864", Size = Vector3.new(1.0153, 1.5121, 1.0808) },
    LeftHand = { MeshId = "rbxassetid://122178226972767", Size = Vector3.new(0.9772, 0.3692, 1.0028) },
    RightUpperLeg = { MeshId = "rbxassetid://87544065239995", Size = Vector3.new(1.0005, 1.7826, 1.0224) },
    RightLowerLeg = { MeshId = "rbxassetid://88743735398175", Size = Vector3.new(1.0269, 1.8263, 1.0912) },
    RightFoot = { MeshId = "rbxassetid://77285271771414", Size = Vector3.new(0.9952, 0.3787, 1.0402) },
    LeftUpperLeg = { MeshId = "rbxassetid://76869681208412", Size = Vector3.new(0.9816, 1.7710, 1.0250) },
    LeftLowerLeg = { MeshId = "rbxassetid://78672915486440", Size = Vector3.new(1.0525, 1.8152, 1.0683) },
    LeftFoot = { MeshId = "rbxassetid://108152097548384", Size = Vector3.new(0.9994, 0.3696, 1.0374) },
}

local JOINTS = {
    { Name = "Root", Part0 = "HumanoidRootPart", Part1 = "LowerTorso", C0 = CFrame.new(0.0016, -1.2025, -0.0197), C1 = CFrame.new(0, -0.325, 0) },
    { Name = "Waist", Part0 = "LowerTorso", Part1 = "UpperTorso", C0 = CFrame.new(-0.0012, 0.2375, 0.0004), C1 = CFrame.new(0, -0.95, 0) },
    { Name = "Neck", Part0 = "UpperTorso", Part1 = "FHead", C0 = CFrame.new(0.0013, 0.9644, -0.0295), C1 = CFrame.new(0, -0.5, 0) },
    { Name = "RightShoulder", Part0 = "UpperTorso", Part1 = "RightUpperArm", C0 = CFrame.new(1.2755, 0.5764, -0.0047), C1 = CFrame.new(-0.25, 0.45, 0) },
    { Name = "RightElbow", Part0 = "RightUpperArm", Part1 = "RightLowerArm", C0 = CFrame.new(0.0044, -0.3219, 0.0001), C1 = CFrame.new(0, 0.25, 0) },
    { Name = "RightWrist", Part0 = "RightLowerArm", Part1 = "RightHand", C0 = CFrame.new(-0.0013, -0.6741, -0.0029), C1 = CFrame.new(0, 0.15, 0) },
    { Name = "LeftShoulder", Part0 = "UpperTorso", Part1 = "LeftUpperArm", C0 = CFrame.new(-1.2770, 0.5798, -0.0024), C1 = CFrame.new(0.25, 0.45, 0) },
    { Name = "LeftElbow", Part0 = "LeftUpperArm", Part1 = "LeftLowerArm", C0 = CFrame.new(0.0064, -0.3285, -0.0003), C1 = CFrame.new(0, 0.25, 0) },
    { Name = "LeftWrist", Part0 = "LeftLowerArm", Part1 = "LeftHand", C0 = CFrame.new(-0.0047, -0.6609, 0.0010), C1 = CFrame.new(0, 0.15, 0) },
    { Name = "RightHip", Part0 = "LowerTorso", Part1 = "RightUpperLeg", C0 = CFrame.new(0.4978, -0.2484, 0.0010), C1 = CFrame.new(0, 0.6, 0) },
    { Name = "RightKnee", Part0 = "RightUpperLeg", Part1 = "RightLowerLeg", C0 = CFrame.new(-0.0057, -0.3801, 0.0021), C1 = CFrame.new(0, 0.3, 0) },
    { Name = "RightAnkle", Part0 = "RightLowerLeg", Part1 = "RightFoot", C0 = CFrame.new(0.0071, -0.8033, -0.0065), C1 = CFrame.new(0, 0.15, 0) },
    { Name = "LeftHip", Part0 = "LowerTorso", Part1 = "LeftUpperLeg", C0 = CFrame.new(-0.4989, -0.2402, -0.0096), C1 = CFrame.new(0, 0.6, 0) },
    { Name = "LeftKnee", Part0 = "LeftUpperLeg", Part1 = "LeftLowerLeg", C0 = CFrame.new(-0.0028, -0.3854, 0.0044), C1 = CFrame.new(0, 0.3, 0) },
    { Name = "LeftAnkle", Part0 = "LeftLowerLeg", Part1 = "LeftFoot", C0 = CFrame.new(0.0000, -0.8005, -0.0035), C1 = CFrame.new(0, 0.15, 0) },
}

local marbleSlab = MaterialService:FindFirstChild("MarbleSlab", true)
local hasMarble = marbleSlab ~= nil and marbleSlab:IsA("MaterialVariant")

local function makeMesh(name, data, color)
    local ok, part = pcall(function()
        return InsertService:CreateMeshPartAsync(data.MeshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
    end)
    if not ok or not part then part = Instance.new("Part") end
    part.Name, part.Size, part.Color = name, data.Size, color
    part.Material = hasMarble and marbleSlab.BaseMaterial or Enum.Material.Marble
    part.MaterialVariant = hasMarble and marbleSlab.Name or ""
    part.CanCollide, part.CanTouch, part.CanQuery, part.Massless, part.Anchored = false, false, false, true, false
    return part
end

local function addEyeFX(att, eyeColor)
    local col = ColorSequence.new(eyeColor)
    for idx, tex in ipairs({ "rbxassetid://111549953554304", "rbxassetid://111549953554304", "rbxassetid://78216618922014" }) do
        local p = Instance.new("ParticleEmitter")
        p.Name, p.Texture = "EyeParticle" .. (idx == 1 and "" or tostring(idx)), tex
        p.FlipbookLayout = (idx < 3) and Enum.ParticleFlipbookLayout.Grid4x4 or Enum.ParticleFlipbookLayout.None
        if idx < 3 then p.FlipbookMode = Enum.ParticleFlipbookMode.OneShot end
        p.LockedToPart, p.EmissionDirection, p.Orientation = true, Enum.NormalId.Front, Enum.ParticleOrientation.VelocityPerpendicular
        p.ZOffset, p.Rate, p.Lifetime, p.Speed = 0.2, 4, NumberRange.new(1, 1), NumberRange.new(0.001, 0.001)
        p.Rotation, p.RotSpeed = NumberRange.new(-360, 360), NumberRange.new(idx == 3 and 50 or 0, idx == 3 and 50 or 0)
        p.Size = NumberSequence.new(idx == 2 and 0.2 or 0.15, idx == 3 and 0.1 or (idx == 2 and 0.2 or 0.15))
        p.Squash, p.Transparency, p.Color, p.Parent = NumberSequence.new(0.1), (idx == 2) and NumberSequence.new(0, 1) or NumberSequence.new(0), col, att
    end
end

local function build(variantKey)
    local style = VARIANTS[variantKey] or VARIANTS.PortraitLight
    local model = Instance.new("Model")
    model.Name = "Portrait_MemeClone"

    local hrp = Instance.new("Part")
    hrp.Name, hrp.Size = "HumanoidRootPart", Vector3.new(2, 2.4, 1)
    hrp.Transparency, hrp.CanCollide, hrp.CanTouch, hrp.CanQuery, hrp.Anchored, hrp.Parent = 1, false, false, false, true, model
    model.PrimaryPart = hrp

    local parts = { HumanoidRootPart = hrp }
    for name, data in pairs(PARTS) do
        local p = makeMesh(name, data, style.BodyColor)
        p.Parent = model
        parts[name] = p
    end

    for _, j in ipairs(JOINTS) do
        local p0, p1 = parts[j.Part0], parts[j.Part1]
        if p0 and p1 then
            local m = Instance.new("Motor6D")
            m.Name, m.Part0, m.Part1, m.C0, m.C1, m.Parent = j.Name, p0, p1, j.C0, j.C1, p1
        end
    end

    if parts.FHead then
        for side, x in pairs({ LeftEye = -0.2672, RightEye = 0.2458 }) do
            local att = Instance.new("Attachment")
            att.Name, att.CFrame, att.Parent = side, CFrame.new(x, 0.0413, -0.4524) * CFrame.Angles(0, math.rad(x < 0 and 10 or -10), 0), parts.FHead
            addEyeFX(att, style.EyeColor)
        end
    end

    if parts.UpperTorso then
        local shards = Instance.new("ParticleEmitter")
        shards.Name, shards.Texture, shards.LockedToPart, shards.LightInfluence, shards.Brightness = "RainbowShards", "rbxassetid://84621883263593", true, 0, 0
        shards.ZOffset, shards.Rate, shards.Lifetime, shards.Speed, shards.SpreadAngle = 2, 1, NumberRange.new(6, 6), NumberRange.new(0.01), Vector2.new(360, 360)
        shards.Rotation, shards.RotSpeed, shards.Size = NumberRange.new(-360, 360), NumberRange.new(-1, 1), NumberSequence.new(4)
        shards.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.65), NumberSequenceKeypoint.new(0.7, 0.67), NumberSequenceKeypoint.new(1, 1) })
        shards.Color, shards.Parent = ColorSequence.new(Color3.new(0, 0, 0)), parts.UpperTorso
    end

    local hum = Instance.new("Humanoid")
    hum.DisplayDistanceType, hum.HipHeight, hum.EvaluateStateMachine, hum.Parent = Enum.HumanoidDisplayDistanceType.None, 2.1, false, model

    return model
end

if getgenv then getgenv().BuildPortraitRig = build end
return build
