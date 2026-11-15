-- builders/LocalAvatarBuilder.lua
-- Автономный билдер твоего аватара с оригинальной текстурой PortraitHead и одеждой

local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer

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

local SKIN_COLOR  = Color3.new(0.639216, 0.635294, 0.647059)
local TORSO_COLOR = Color3.new(0.431373, 0.600000, 0.792157)

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
    part.Material = Enum.Material.SmoothPlastic
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Anchored = false
    return part
end

local function copyVisualsFromPlayer(model, head)
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return false end

    -- Копируем реальную одежду (Shirt/Pants) и BodyColors прямо с твоего персонажа в игре (уже предзагруженные!)
    local srcBC = char:FindFirstChildOfClass("BodyColors")
    if srcBC then srcBC:Clone().Parent = model end

    local srcShirt = char:FindFirstChildOfClass("Shirt")
    if srcShirt then srcShirt:Clone().Parent = model end

    local srcPants = char:FindFirstChildOfClass("Pants")
    if srcPants then srcPants:Clone().Parent = model end

    -- Копируем все аксессуары (включая PortraitHead со всеми SurfaceAppearance/TextureID)
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            acc.Archivable = true
            local cloneAcc = acc:Clone()
            acc.Archivable = false
            if cloneAcc then
                local h = cloneAcc:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    h.CanCollide = false
                    h.CanTouch = false
                    h.CanQuery = false
                    h.Massless = true
                    h.Anchored = false
                    h.LocalTransparencyModifier = 0
                    for _, w in ipairs(h:GetChildren()) do
                        if w:IsA("Weld") or w:IsA("Motor6D") then
                            w.Part0 = head
                            w.Part1 = h
                        end
                    end
                end
                cloneAcc.Parent = model
            end
        end
    end
    return true
end

local function buildLocalAvatar()
    local model = Instance.new("Model")
    model.Name = "LocalAvatar_MemeClone"

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.CanTouch = false
    hrp.CanQuery = false
    hrp.Anchored = true
    hrp.Parent = model
    model.PrimaryPart = hrp

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Color = SKIN_COLOR
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = false
    head.CanTouch = false
    head.CanQuery = false
    head.Massless = true
    head.Anchored = false
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

    local hum = Instance.new("Humanoid")
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.HipHeight = 2.0
    hum.EvaluateStateMachine = false
    hum.Parent = model

    -- Переносим уже загруженную в память текстуру одежды и головы PortraitHead с твоего персонажа
    if not copyVisualsFromPlayer(model, head) then
        local shirt = Instance.new("Shirt", model)
        shirt.ShirtTemplate = "rbxassetid://129095962205532"
        local pants = Instance.new("Pants", model)
        pants.PantsTemplate = "rbxassetid://134295663430313"
    end

    return model
end

return buildLocalAvatar
