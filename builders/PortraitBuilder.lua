-- builders/PortraitBuilder.lua
-- Полная сборка Portrait со всеми оригинальными эффектами для модульной архитектуры

local InsertService = game:GetService("InsertService")
local MaterialService = game:GetService("MaterialService")

local VARIANTS = {
    Dark         = { BodyColor = Color3.fromRGB(30, 0, 45),    EyeColor = Color3.fromRGB(255, 85, 0) },
    PortraitDark = { BodyColor = Color3.fromRGB(30, 0, 45),    EyeColor = Color3.fromRGB(255, 85, 0) },
    Light        = { BodyColor = Color3.fromRGB(182, 180, 194), EyeColor = Color3.fromRGB(0, 0, 0) },
    PortraitLight= { BodyColor = Color3.fromRGB(182, 180, 194), EyeColor = Color3.fromRGB(0, 0, 0) },
}

local PORTRAIT_PARTS = {
    LowerTorso     = { MeshId = "rbxassetid://85510166518718", Size = Vector3.new(2.0433, 0.5755, 1.1133) },
    UpperTorso     = { MeshId = "rbxassetid://74526719630802", Size = Vector3.new(2.1801, 1.9414, 1.2325) },
    FHead          = { MeshId = "rbxassetid://102429169478724", Size = Vector3.new(1.2031, 1.2467, 1.2360) },
    RightUpperArm  = { MeshId = "rbxassetid://87218701043500", Size = Vector3.new(1.0114, 1.5885, 1.0410) },
    RightLowerArm  = { MeshId = "rbxassetid://73176539710232", Size = Vector3.new(1.0361, 1.5272, 1.0689) },
    RightHand      = { MeshId = "rbxassetid://88074548220386", Size = Vector3.new(0.9494, 0.3646, 1.0078) },
    LeftUpperArm   = { MeshId = "rbxassetid://114118854954210", Size = Vector3.new(1.0258, 1.5862, 1.0470) },
    LeftLowerArm   = { MeshId = "rbxassetid://73093746850864", Size = Vector3.new(1.0153, 1.5121, 1.0808) },
    LeftHand       = { MeshId = "rbxassetid://122178226972767", Size = Vector3.new(0.9772, 0.3692, 1.0028) },
    RightUpperLeg  = { MeshId = "rbxassetid://87544065239995", Size = Vector3.new(1.0005, 1.7826, 1.0224) },
    RightLowerLeg  = { MeshId = "rbxassetid://88743735398175", Size = Vector3.new(1.0269, 1.8263, 1.0912) },
    RightFoot      = { MeshId = "rbxassetid://77285271771414", Size = Vector3.new(0.9952, 0.3787, 1.0402) },
    LeftUpperLeg   = { MeshId = "rbxassetid://76869681208412", Size = Vector3.new(0.9816, 1.7710, 1.0250) },
    LeftLowerLeg   = { MeshId = "rbxassetid://78672915486440", Size = Vector3.new(1.0525, 1.8152, 1.0683) },
    LeftFoot       = { MeshId = "rbxassetid://108152097548384", Size = Vector3.new(0.9994, 0.3696, 1.0374) },
}

local EXACT_JOINTS = {
    { Name = "Root",          Part0 = "HumanoidRootPart", Part1 = "LowerTorso",    C0 = CFrame.new(0.0016, -1.2025, -0.0197), C1 = CFrame.new(0.0000, -0.3250, 0.0000) },
    { Name = "Waist",         Part0 = "LowerTorso",       Part1 = "UpperTorso",    C0 = CFrame.new(-0.0012, 0.2375, 0.0004), C1 = CFrame.new(0.0000, -0.9500, 0.0000) },
    { Name = "Neck",          Part0 = "UpperTorso",       Part1 = "FHead",         C0 = CFrame.new(0.0013, 0.9644, -0.0295), C1 = CFrame.new(0.0000, -0.5000, 0.0000) },
    { Name = "RightShoulder", Part0 = "UpperTorso",       Part1 = "RightUpperArm", C0 = CFrame.new(1.2755, 0.5764, -0.0047), C1 = CFrame.new(-0.2500, 0.4500, 0.0000) },
    { Name = "RightElbow",    Part0 = "RightUpperArm",    Part1 = "RightLowerArm", C0 = CFrame.new(0.0044, -0.3219, 0.0001), C1 = CFrame.new(0.0000, 0.2500, 0.0000) },
    { Name = "RightWrist",    Part0 = "RightLowerArm",    Part1 = "RightHand",     C0 = CFrame.new(-0.0013, -0.6741, -0.0029), C1 = CFrame.new(0.0000, 0.1500, 0.0000) },
    { Name = "LeftShoulder",  Part0 = "UpperTorso",       Part1 = "LeftUpperArm",  C0 = CFrame.new(-1.2770, 0.5798, -0.0024), C1 = CFrame.new(0.2500, 0.4500, 0.0000) },
    { Name = "LeftElbow",     Part0 = "LeftUpperArm",     Part1 = "LeftLowerArm",  C0 = CFrame.new(0.0064, -0.3285, -0.0003), C1 = CFrame.new(0.0000, 0.2500, 0.0000) },
    { Name = "LeftWrist",     Part0 = "LeftLowerArm",     Part1 = "LeftHand",      C0 = CFrame.new(-0.0047, -0.6609, 0.0010), C1 = CFrame.new(0.0000, 0.1500, 0.0000) },
    { Name = "RightHip",      Part0 = "LowerTorso",       Part1 = "RightUpperLeg", C0 = CFrame.new(0.4978, -0.2484, 0.0010), C1 = CFrame.new(0.0000, 0.6000, 0.0000) },
    { Name = "RightKnee",     Part0 = "RightUpperLeg",    Part1 = "RightLowerLeg", C0 = CFrame.new(-0.0057, -0.3801, 0.0021), C1 = CFrame.new(0.0000, 0.3000, 0.0000) },
    { Name = "RightAnkle",    Part0 = "RightLowerLeg",    Part1 = "RightFoot",     C0 = CFrame.new(0.0071, -0.8033, -0.0065), C1 = CFrame.new(0.0000, 0.1500, 0.0000) },
    { Name = "LeftHip",       Part0 = "LowerTorso",       Part1 = "LeftUpperLeg",  C0 = CFrame.new(-0.4989, -0.2402, -0.0096), C1 = CFrame.new(0.0000, 0.6000, 0.0000) },
    { Name = "LeftKnee",      Part0 = "LeftUpperLeg",     Part1 = "LeftLowerLeg",  C0 = CFrame.new(-0.0028, -0.3854, 0.0044), C1 = CFrame.new(0.0000, 0.3000, 0.0000) },
    { Name = "LeftAnkle",     Part0 = "LeftLowerLeg",     Part1 = "LeftFoot",      C0 = CFrame.new(0.0000, -0.8005, -0.0035), C1 = CFrame.new(0.0000, 0.1500, 0.0000) },
}

local marbleSlabVariant = MaterialService:FindFirstChild("MarbleSlab", true)
local hasMarbleSlab = marbleSlabVariant ~= nil and marbleSlabVariant:IsA("MaterialVariant")

local function createMeshPart(name, data, bodyColor)
    local ok, part = pcall(function()
        return InsertService:CreateMeshPartAsync(data.MeshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
    end)
    if not ok or not part then
        part = Instance.new("Part")
    end

    part.Name = name
    part.Size = data.Size
    part.Color = bodyColor

    if hasMarbleSlab then
        part.Material = marbleSlabVariant.BaseMaterial
        part.MaterialVariant = marbleSlabVariant.Name
    else
        part.Material = Enum.Material.Marble
        part.MaterialVariant = ""
    end

    part.Reflectance = 0
    part.Transparency = 0
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Anchored = false
    return part
end

local function createExactEyeParticles(attachment, eyeColorRGB)
    local eyeColSeq = ColorSequence.new(eyeColorRGB)

    local p1 = Instance.new("ParticleEmitter")
    p1.Name = "EyeParticle"
    p1.Texture = "rbxassetid://111549953554304"
    p1.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
    p1.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
    p1.LockedToPart = true
    p1.EmissionDirection = Enum.NormalId.Front
    p1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    p1.LightInfluence = 1
    p1.ZOffset = 0.20
    p1.Rate = 4
    p1.Lifetime = NumberRange.new(1, 1)
    p1.Speed = NumberRange.new(0.001, 0.001)
    p1.Rotation = NumberRange.new(-360, 360)
    p1.Size = NumberSequence.new(0.150)
    p1.Squash = NumberSequence.new(0.100)
    p1.Transparency = NumberSequence.new(0)
    p1.Color = eyeColSeq
    p1.Parent = attachment

    local p2 = Instance.new("ParticleEmitter")
    p2.Name = "EyeParticle2"
    p2.Texture = "rbxassetid://111549953554304"
    p2.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
    p2.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
    p2.LockedToPart = true
    p2.EmissionDirection = Enum.NormalId.Front
    p2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    p2.LightInfluence = 1
    p2.ZOffset = 0.20
    p2.Rate = 4
    p2.Lifetime = NumberRange.new(1, 1)
    p2.Speed = NumberRange.new(0.001, 0.001)
    p2.Rotation = NumberRange.new(-360, 360)
    p2.Size = NumberSequence.new(0.200)
    p2.Squash = NumberSequence.new(0.100)
    p2.Transparency = NumberSequence.new(0, 1)
    p2.Color = eyeColSeq
    p2.Parent = attachment

    local p3 = Instance.new("ParticleEmitter")
    p3.Name = "EyeParticle3"
    p3.Texture = "rbxassetid://78216618922014"
    p3.LockedToPart = true
    p3.EmissionDirection = Enum.NormalId.Front
    p3.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    p3.LightInfluence = 1
    p3.ZOffset = 0.20
    p3.Rate = 4
    p3.Lifetime = NumberRange.new(1, 1)
    p3.Speed = NumberRange.new(0.001, 0.001)
    p3.Rotation = NumberRange.new(-360, 360)
    p3.RotSpeed = NumberRange.new(50, 50)
    p3.Size = NumberSequence.new(0.150, 0.100)
    p3.Squash = NumberSequence.new(0.100)
    p3.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.000, 1.000),
        NumberSequenceKeypoint.new(0.194, 0.506),
        NumberSequenceKeypoint.new(0.301, 0.631),
        NumberSequenceKeypoint.new(0.399, 0.169),
        NumberSequenceKeypoint.new(0.493, 0.794),
        NumberSequenceKeypoint.new(0.600, 0.294),
        NumberSequenceKeypoint.new(0.697, 0.681),
        NumberSequenceKeypoint.new(0.797, 0.494),
        NumberSequenceKeypoint.new(1.000, 1.000)
    })
    p3.Color = eyeColSeq
    p3.Parent = attachment
end

local function buildExactVisuals(parts, eyeColorRGB)
    local fHead = parts.FHead
    if fHead then
        local leftEye = Instance.new("Attachment")
        leftEye.Name = "LeftEye"
        leftEye.CFrame = CFrame.new(-0.2672, 0.0413, -0.4524) * CFrame.Angles(0, math.rad(10), 0)
        leftEye.Parent = fHead
        createExactEyeParticles(leftEye, eyeColorRGB)

        local rightEye = Instance.new("Attachment")
        rightEye.Name = "RightEye"
        rightEye.CFrame = CFrame.new(0.2458, 0.0413, -0.4524) * CFrame.Angles(0, math.rad(-10), 0)
        rightEye.Parent = fHead
        createExactEyeParticles(rightEye, eyeColorRGB)
    end

    local upperTorso = parts.UpperTorso
    if upperTorso then
        local shards = Instance.new("ParticleEmitter")
        shards.Name = "RainbowShards"
        shards.Texture = "rbxassetid://84621883263593"
        shards.LockedToPart = true
        shards.LightInfluence = 0
        shards.Brightness = 0
        shards.ZOffset = 2.00
        shards.Rate = 1
        shards.Lifetime = NumberRange.new(6, 6)
        shards.Speed = NumberRange.new(0.010, 0.010)
        shards.SpreadAngle = Vector2.new(360, 360)
        shards.Rotation = NumberRange.new(-360, 360)
        shards.RotSpeed = NumberRange.new(-1, 1)
        shards.Size = NumberSequence.new(4.000)
shards.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0.000, 1.000),
NumberSequenceKeypoint.new(0.300, 0.656),
NumberSequenceKeypoint.new(0.701, 0.669),
NumberSequenceKeypoint.new(1.000, 1.000)
})
shards.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
shards.Parent = upperTorso
local triangles = Instance.new("ParticleEmitter")
triangles.Name = "Triangles"
triangles.Texture = "rbxassetid://95034076317014"
triangles.LockedToPart = true
triangles.LightEmission = 1
triangles.LightInfluence = 0
triangles.Brightness = 5
triangles.ZOffset = -2.00
triangles.Rate = 15
triangles.Lifetime = NumberRange.new(1, 1)
triangles.Speed = NumberRange.new(0.010, 0.010)
triangles.SpreadAngle = Vector2.new(360, 360)
triangles.Rotation = NumberRange.new(-360, 360)
triangles.RotSpeed = NumberRange.new(-5, 5)
triangles.Size = NumberSequence.new(3.825, 0)
triangles.Squash = NumberSequence.new({
NumberSequenceKeypoint.new(0, -0.067, 0.269),
NumberSequenceKeypoint.new(1, 0, 0.054)
})
triangles.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0.000, 1.000),
NumberSequenceKeypoint.new(0.488, 0.988),
NumberSequenceKeypoint.new(1.000, 1.000)
})
triangles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
triangles.Parent = upperTorso
end
local hrp = parts.HumanoidRootPart
if hrp then
local warpCol = ColorSequence.new({
ColorSequenceKeypoint.new(0.000, Color3.fromRGB(244, 229, 255)),
ColorSequenceKeypoint.new(0.047, Color3.fromRGB(208, 196, 219)),
ColorSequenceKeypoint.new(0.118, Color3.fromRGB(183, 172, 194)),
ColorSequenceKeypoint.new(0.189, Color3.fromRGB(176, 169, 200)),
ColorSequenceKeypoint.new(0.301, Color3.fromRGB(150, 145, 166)),
ColorSequenceKeypoint.new(0.457, Color3.fromRGB(202, 195, 219)),
ColorSequenceKeypoint.new(0.801, Color3.fromRGB(179, 173, 193)),
ColorSequenceKeypoint.new(1.000, Color3.fromRGB(244, 224, 255))
})
local warpSize = NumberSequence.new({
NumberSequenceKeypoint.new(0.000, 0.656),
NumberSequenceKeypoint.new(0.006, 3.060),
NumberSequenceKeypoint.new(0.018, 3.610, 0.300),
NumberSequenceKeypoint.new(0.047, 3.220, 0.400),
NumberSequenceKeypoint.new(0.218, 2.950, 0.300),
NumberSequenceKeypoint.new(0.523, 1.694),
NumberSequenceKeypoint.new(1.000, 0.000)
})
local warpTransp = NumberSequence.new({
NumberSequenceKeypoint.new(0.000, 1.000),
NumberSequenceKeypoint.new(0.099, 0.619),
NumberSequenceKeypoint.new(0.857, 0.512),
NumberSequenceKeypoint.new(1.000, 1.000)
})
local warpAtt = Instance.new("Attachment")
warpAtt.Name = "Warp"
warpAtt.CFrame = CFrame.new(0, 0, 8.8778)
warpAtt.Parent = hrp
for _, item in ipairs({
{ Name = "Warp1", Tex = "rbxassetid://80980464895601" },
{ Name = "Warp2", Tex = "rbxassetid://85639742333380" },
{ Name = "Warp3", Tex = "rbxassetid://111534563454012" },
}) do
local w = Instance.new("ParticleEmitter")
w.Name = item.Name
w.Texture = item.Tex
w.Enabled = false
w.EmissionDirection = Enum.NormalId.Front
w.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
w.LightEmission = 0.70
w.LightInfluence = 0
w.Brightness = 0.12
w.Rate = 1
w.Lifetime = NumberRange.new(2, 5)
w.Speed = NumberRange.new(0.010, 0.010)
w.Rotation = NumberRange.new(-5, 5)
w.RotSpeed = NumberRange.new(-15, 15)
w.Size = warpSize
w.Transparency = warpTransp
w.Color = warpCol
w.Parent = warpAtt
end
local footAtt = Instance.new("Attachment")
footAtt.Name = "Footsteps"
footAtt.CFrame = CFrame.new(0.5006, -3.5092, -0.0232)
footAtt.Parent = hrp
local fs1 = Instance.new("ParticleEmitter")
fs1.Name = "ParticleEmitter"
fs1.Texture = "rbxassetid://95382003957804"
fs1.Enabled = false
fs1.LightInfluence = 0
fs1.Brightness = 0.60
fs1.Rate = 20
fs1.Lifetime = NumberRange.new(0.8, 1.5)
fs1.Speed = NumberRange.new(3, 4)
fs1.SpreadAngle = Vector2.new(-25, 25)
fs1.Acceleration = Vector3.new(0, -8, 0)
fs1.Rotation = NumberRange.new(-360, 360)
fs1.RotSpeed = NumberRange.new(-40, 40)
fs1.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.383, 0.109), NumberSequenceKeypoint.new(1, 0.219) })
fs1.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.806, 0.100),
NumberSequenceKeypoint.new(0.584, 0.788, 0.100),
NumberSequenceKeypoint.new(0.959, 0.825),
NumberSequenceKeypoint.new(1, 1)
})
fs1.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0.000, Color3.fromRGB(160, 153, 173)),
ColorSequenceKeypoint.new(0.638, Color3.fromRGB(210, 208, 254)),
ColorSequenceKeypoint.new(1.000, Color3.fromRGB(103, 103, 103))
})
fs1.Parent = footAtt
local fs2 = Instance.new("ParticleEmitter")
fs2.Name = "Warp2"
fs2.Texture = "rbxassetid://85639742333380"
fs2.Enabled = false
fs2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
fs2.LightEmission = 0.70
fs2.LightInfluence = 0
fs2.Brightness = 0.14
fs2.Rate = 1
fs2.Lifetime = NumberRange.new(1, 1)
fs2.Speed = NumberRange.new(0.010, 0.010)
fs2.Rotation = NumberRange.new(-5, 5)
fs2.RotSpeed = NumberRange.new(-15, 15)
fs2.Size = warpSize
fs2.Color = warpCol
fs2.Parent = footAtt
end
end
local function buildPortraitModel(variantName)
local style = VARIANTS[variantName] or VARIANTS.Light
local model = Instance.new("Model")
model.Name = "Portrait_MemeClone"
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2.0000, 2.4000, 1.0000)
hrp.Transparency = 1
hrp.CanCollide = false
hrp.CanTouch = false
hrp.CanQuery = false
hrp.Anchored = true
hrp.Parent = model
model.PrimaryPart = hrp
local parts = { HumanoidRootPart = hrp }
for partName, data in pairs(PORTRAIT_PARTS) do
local p = createMeshPart(partName, data, style.BodyColor)
p.Parent = model
parts[partName] = p
end
for _, j in ipairs(EXACT_JOINTS) do
local p0 = parts[j.Part0]
local p1 = parts[j.Part1]
if p0 and p1 then
local motor = Instance.new("Motor6D")
motor.Name = j.Name
motor.Part0 = p0
motor.Part1 = p1
motor.C0 = j.C0
motor.C1 = j.C1
motor.Parent = p1
end
end
buildExactVisuals(parts, style.EyeColor)
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HipHeight = 2.1
hum.EvaluateStateMachine = false
hum.Parent = model
return model
end
if type(getgenv) == "function" then
getgenv().BuildPortraitRig = buildPortraitModel
end
return buildPortraitModel