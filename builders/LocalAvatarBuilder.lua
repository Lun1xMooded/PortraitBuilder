-- builders/LocalAvatarBuilder.lua
-- Автономный билдер твоего аватара (R15 + Shirt/Pants + PortraitHead с PBR SurfaceAppearance)

local InsertService = game:GetService("InsertService")
local ContentProvider = game:GetService("ContentProvider")

local BODY_PARTS = {
    LowerTorso    = { MeshId = "rbxassetid://532220036", Size = Vector3.new(2.0, 0.4, 1.0) },
    UpperTorso    = { MeshId = "rbxassetid://532220007", Size = Vector3.new(2.0, 1.6, 1.0) },
    RightUpperArm = { MeshId = "rbxassetid://532220004", Size = Vector3.new(1.0, 1.4, 1.0) },
    RightLowerArm = { MeshId = "rbxassetid://532219999", Size = Vector3.new(1.0, 1.2, 1.0) },
    RightHand     = { MeshId = "rbxassetid://532219997", Size = Vector3.new(1.0, 0.3, 1.0) },
    LeftUpperArm  = { MeshId = "rbxassetid://532219996", Size = Vector3.new(1.0, 1.4, 1.0) },
    LeftLowerArm  = { MeshId = "rbxassetid://532219991", Size = Vector3.new(1.0, 1.2, 1.0) },
    LeftHand      = { MeshId = "rbxassetid://532219986", Size = Vector3.new(1.0, 0.3, 1.0) },
    RightUpperLeg = { MeshId = "rbxassetid://532220031", Size = Vector3.new(1.0, 1.5, 1.0) },
    RightLowerLeg = { MeshId = "rbxassetid://532220027", Size = Vector3.new(1.0, 1.5, 1.0) },
    RightFoot     = { MeshId = "rbxassetid://532220020", Size = Vector3.new(1.0, 0.3, 1.0) },
    LeftUpperLeg  = { MeshId = "rbxassetid://532220018", Size = Vector3.new(1.0, 1.5, 1.0) },
    LeftLowerLeg  = { MeshId = "rbxassetid://532220017", Size = Vector3.new(1.0, 1.5, 1.0) },
    LeftFoot      = { MeshId = "rbxassetid://532220012", Size = Vector3.new(1.0, 0.3, 1.0) },
}

local JOINTS = {
    { Name = "Root",          Part0 = "HumanoidRootPart", Part1 = "LowerTorso",    C0 = CFrame.new(0, -0.65, 0),    C1 = CFrame.new(0, 0.15, 0) },
    { Name = "Waist",         Part0 = "LowerTorso",       Part1 = "UpperTorso",    C0 = CFrame.new(0, 0.55, 0),     C1 = CFrame.new(0, -0.45, 0) },
    { Name = "Neck",          Part0 = "UpperTorso",       Part1 = "Head",          C0 = CFrame.new(0, 0.80, 0),     C1 = CFrame.new(0, -0.50, 0) },
    { Name = "RightShoulder", Part0 = "UpperTorso",       Part1 = "RightUpperArm", C0 = CFrame.new(1.25, 0.55, 0),  C1 = CFrame.new(-0.25, 0.45, 0) },
    { Name = "RightElbow",    Part0 = "RightUpperArm",    Part1 = "RightLowerArm", C0 = CFrame.new(0, -0.20, 0),    C1 = CFrame.new(0, 0.25, 0) },
    { Name = "RightWrist",    Part0 = "RightLowerArm",    Part1 = "RightHand",     C0 = CFrame.new(0, -0.55, 0),    C1 = CFrame.new(0, 0.15, 0) },
    { Name = "LeftShoulder",  Part0 = "UpperTorso",       Part1 = "LeftUpperArm",  C0 = CFrame.new(-1.25, 0.55, 0), C1 = CFrame.new(0.25, 0.45, 0) },
    { Name = "LeftElbow",     Part0 = "LeftUpperArm",     Part1 = "LeftLowerArm",  C0 = CFrame.new(0, -0.20, 0),    C1 = CFrame.new(0, 0.25, 0) },
    { Name = "LeftWrist",     Part0 = "LeftLowerArm",     Part1 = "LeftHand",      C0 = CFrame.new(0, -0.55, 0),    C1 = CFrame.new(0, 0.15, 0) },
    { Name = "RightHip",      Part0 = "LowerTorso",       Part1 = "RightUpperLeg", C0 = CFrame.new(0.50, -0.20, 0), C1 = CFrame.new(0, 0.50, 0) },
    { Name = "RightKnee",     Part0 = "RightUpperLeg",    Part1 = "RightLowerLeg", C0 = CFrame.new(0, -0.30, 0),    C1 = CFrame.new(0, 0.25, 0) },
    { Name = "RightAnkle",    Part0 = "RightLowerLeg",    Part1 = "RightFoot",     C0 = CFrame.new(0, -0.75, 0),    C1 = CFrame.new(0, 0.05, 0) },
    { Name = "LeftHip",       Part0 = "LowerTorso",       Part1 = "LeftUpperLeg",  C0 = CFrame.new(-0.50, -0.20, 0),C1 = CFrame.new(0, 0.50, 0) },
    { Name = "LeftKnee",      Part0 = "LeftUpperLeg",     Part1 = "LeftLowerLeg",  C0 = CFrame.new(0, -0.30, 0),    C1 = CFrame.new(0, 0.25, 0) },
    { Name = "LeftAnkle",     Part0 = "LeftLowerLeg",     Part1 = "LeftFoot",      C0 = CFrame.new(0, -0.75, 0),    C1 = CFrame.new(0, 0.05, 0) },
}

local SKIN_COLOR  = Color3.new(0.639, 0.635, 0.647)
local TORSO_COLOR = Color3.new(0.431, 0.600, 0.792)

local function setupNoCollide(part)
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    pcall(function() part.CollisionGroup = "NoPlayer" end)
end

local function createMesh(name, meshId, size, color)
    local ok, part = pcall(function()
        return InsertService:CreateMeshPartAsync(meshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
    end)
    if not ok or not part then
        part = Instance.new("Part")
    end
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.Plastic
    part.Anchored = false
    setupNoCollide(part)
    return part
end

local function buildLocalAvatar()
    local model = Instance.new("Model")
    model.Name = "LocalAvatar_MemeClone"

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.Anchored = true
    setupNoCollide(hrp)
    hrp.Parent = model
    model.PrimaryPart = hrp

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Color = SKIN_COLOR
    head.Material = Enum.Material.Plastic
    head.Anchored = false
    setupNoCollide(head)
    head.Parent = model

    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    headMesh.Parent = head

    local parts = { HumanoidRootPart = hrp, Head = head }
    for partName, info in pairs(BODY_PARTS) do
        local isSkin = partName:find("Arm") or partName:find("Hand")
        local p = createMesh(partName, info.MeshId, info.Size, isSkin and SKIN_COLOR or TORSO_COLOR)
        p.Parent = model
        parts[partName] = p
    end

    for _, j in ipairs(JOINTS) do
        local p0 = parts[j.Part0]
        local p1 = parts[j.Part1]
        if p0 and p1 then
            local m = Instance.new("Motor6D")
            m.Name = j.Name
            m.Part0 = p0
            m.Part1 = p1
            m.C0 = j.C0
            m.C1 = j.C1
            m.Parent = p1
        end
    end

    -- BodyColors + Shirt & Pants с точными ID из дампа Studio
    local bc = Instance.new("BodyColors")
    bc.HeadColor3 = SKIN_COLOR
    bc.LeftArmColor3 = SKIN_COLOR
    bc.RightArmColor3 = SKIN_COLOR
    bc.TorsoColor3 = TORSO_COLOR
    bc.LeftLegColor3 = TORSO_COLOR
    bc.RightLegColor3 = TORSO_COLOR
    bc.Parent = model

    local shirt = Instance.new("Shirt")
    shirt.Name = "Shirt"
    shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=129095962205532"
    shirt.Parent = model

    local pants = Instance.new("Pants")
    pants.Name = "Pants"
    pants.PantsTemplate = "http://www.roblox.com/asset/?id=134295663430313"
    pants.Parent = model

    -- Аксессуар PortraitHead с точным PBR SurfaceAppearance (ColorMap + NormalMap + RoughnessMap)
    local accHead = createMesh("PortraitHeadHandle", "rbxassetid://81338776849113", Vector3.new(1.324, 1.372, 1.360), SKIN_COLOR)
    local sa = Instance.new("SurfaceAppearance")
    sa.ColorMap     = "rbxassetid://99378081396301"
    sa.NormalMap    = "rbxassetid://120313761509116"
    sa.RoughnessMap = "rbxassetid://139352842351623"
    sa.Parent = accHead
    accHead.Parent = model

    local headWeld = Instance.new("Weld")
    headWeld.Name = "PortraitHeadWeld"
    headWeld.Part0 = head
    headWeld.Part1 = accHead
    headWeld.C0 = CFrame.new(0, 0.05, 0)
    headWeld.Parent = accHead

    -- R15 Humanoid нужен для рендера Shirt и Pants на MeshPart'ах
    local hum = Instance.new("Humanoid")
    hum.RigType = Enum.HumanoidRigType.R15
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.HipHeight = 2.0
    hum.EvaluateStateMachine = false
    hum.Parent = model

    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({ shirt, pants, sa })
        end)
    end)

    return model
end

return buildLocalAvatar
