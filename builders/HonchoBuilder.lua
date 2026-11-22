-- builders/HonchoBuilder.lua
-- Точный 3D-генератор Honcho с оригинальными MeshId, точным Scale и декалями из дампа

return function(variant)
    local model = Instance.new("Model")
    model.Name = "HonchoActorClone"
    model:SetAttribute("RootOffset", 6.35)
    model:SetAttribute("NoTools", true)

    local MESH_SCALES = {
        WoodHead   = Vector3.new(0.02581, 0.02581, 0.02581),
        Papers     = Vector3.new(0.02581, 0.02581, 0.02581),
        Face       = Vector3.new(0.02581, 0.02419, 0.02581),
        Expression = Vector3.new(0.02181, 0.01909, 0.02581),
    }
    local BODY_SCALE = Vector3.new(0.24308, 0.24308, 0.24308)

    local parts = {}

    local function P(name, size, color, material, transparency, relCF, meshId)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material
        p.Transparency = transparency
        p.CFrame = relCF
        p.Anchored = false
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Massless = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = model

        if meshId and meshId ~= "" then
            local sm = Instance.new("SpecialMesh")
            sm.MeshType = Enum.MeshType.FileMesh
            sm.MeshId = meshId
            sm.Scale = MESH_SCALES[name] or BODY_SCALE
            sm.Parent = p
        end

        parts[name] = p
        return p
    end

    local function M(name, p0Name, p1Name, c0, c1)
        local p0 = parts[p0Name]
        local p1 = parts[p1Name]
        if not p0 or not p1 then return end
        local m = Instance.new("Motor6D")
        m.Name = name
        m.Part0 = p0
        m.Part1 = p1
        m.C0 = c0
        m.C1 = c1
        m.Parent = p0
        return m
    end

    local function W(p0Name, p1Name)
        local p0 = parts[p0Name]
        local p1 = parts[p1Name]
        if not p0 or not p1 then return end
        local w = Instance.new("WeldConstraint")
        w.Name = p1Name .. "Weld"
        w.Part0 = p0
        w.Part1 = p1
        w.Parent = p0
    end

    local function addDecal(partName, decalName, texId, face)
        local p = parts[partName]
        if not p then return end
        local d = Instance.new("Decal")
        d.Name = decalName
        d.Texture = texId
        d.Face = face or Enum.NormalId.Front
        d.Transparency = 0
        d.Parent = p
    end

    -- 1. Базовые хитбоксы и R6-совместимость
    P("HumanoidRootPart", Vector3.new(1.89,1.89,0.94), Color3.fromRGB(0,0,0), Enum.Material.Plastic, 1.00, CFrame.new(0.000,0.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Torso", Vector3.new(2.00,2.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(0.000,0.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Head1", Vector3.new(2.00,1.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(0.000,1.500,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Right Arm", Vector3.new(1.00,2.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(1.500,0.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Left Arm", Vector3.new(1.00,2.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(-1.500,0.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Right Leg", Vector3.new(1.00,2.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(0.500,-2.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("Left Leg", Vector3.new(1.00,2.00,1.00), Color3.fromRGB(163,162,165), Enum.Material.Plastic, 1.00, CFrame.new(-0.500,-2.000,0.000,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))

    -- 2. Торс и брюки
    P("Pelvis", Vector3.new(2.88,0.86,0.24), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(0.000,-1.882,-0.100,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://118178032366130")
    P("PelvisLining", Vector3.new(2.41,0.34,0.24), Color3.fromRGB(60,58,81), Enum.Material.Fabric, 0.00, CFrame.new(0.000,-1.649,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://75488742733120")
    P("LowerTorso", Vector3.new(2.80,0.71,0.16), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(0.000,-1.267,-0.119,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://139835356304384")
    P("MiddleTorso", Vector3.new(2.80,1.51,0.47), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(0.000,-0.294,-0.111,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://70487070931077")
    P("UpperTorso", Vector3.new(2.80,1.57,0.73), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(0.000,0.873,-0.110,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://76105738314059")

    -- 3. Подтяжки
    P("LowerSuspenders", Vector3.new(1.97,0.30,0.30), Color3.fromRGB(191,128,128), Enum.Material.Cardboard, 0.00, CFrame.new(0.000,-1.110,-0.107,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://126199874864038")
    P("MiddleSuspenders", Vector3.new(1.99,1.29,0.53), Color3.fromRGB(191,128,128), Enum.Material.Cardboard, 0.00, CFrame.new(0.000,-0.348,-0.105,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://104657923149834")
    P("UpperSuspenders", Vector3.new(2.00,1.42,0.76), Color3.fromRGB(191,128,128), Enum.Material.Cardboard, 0.00, CFrame.new(0.000,0.969,-0.100,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://107318840825406")
    P("MiddleSuspenderRings", Vector3.new(0.89,0.23,0.10), Color3.fromRGB(179,148,112), Enum.Material.Glass, 0.00, CFrame.new(0.000,0.075,0.121,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://123853586133905")
    P("UpperSuspenderRings", Vector3.new(2.06,0.11,0.18), Color3.fromRGB(179,148,112), Enum.Material.Glass, 0.00, CFrame.new(0.000,0.661,-0.347,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://76698522685498")
    P("SuspenderJoint", Vector3.new(0.63,0.72,0.11), Color3.fromRGB(95,81,75), Enum.Material.Leather, 0.00, CFrame.new(0.000,-0.324,0.087,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://117948165283138")
    P("SuspenderClips", Vector3.new(2.00,0.36,0.30), Color3.fromRGB(179,148,112), Enum.Material.Glass, 0.00, CFrame.new(0.000,-1.398,-0.103,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://101871542369664")

    -- 4. Галстук
    P("TieTop", Vector3.new(0.59,0.49,0.11), Color3.fromRGB(89,89,138), Enum.Material.Leather, 0.00, CFrame.new(-0.000,1.230,-0.471,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://87178780263090")
    P("TieUpper", Vector3.new(0.50,0.63,0.09), Color3.fromRGB(89,89,138), Enum.Material.Leather, 0.00, CFrame.new(0.000,0.727,-0.471,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://103960932596077")
    P("TieMiddle", Vector3.new(0.63,0.63,0.09), Color3.fromRGB(89,89,138), Enum.Material.Leather, 0.00, CFrame.new(0.000,0.093,-0.471,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://129453078714949")
    P("TieLower", Vector3.new(0.64,0.63,0.09), Color3.fromRGB(89,89,138), Enum.Material.Leather, 0.00, CFrame.new(0.000,-0.540,-0.471,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://109245141563413")
    P("TieBottom", Vector3.new(0.64,0.58,0.09), Color3.fromRGB(89,89,138), Enum.Material.Leather, 0.00, CFrame.new(0.000,-1.145,-0.471,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://140719528715020")

    -- 5. Воротник, шея и голова-планшет с декалями лица
    P("NeckCuff", Vector3.new(1.85,0.58,0.99), Color3.fromRGB(183,185,193), Enum.Material.Fabric, 0.00, CFrame.new(0.000,1.541,-0.089,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://86130211772398")
    P("Neck", Vector3.new(1.22,0.29,0.72), Color3.fromRGB(0,0,0), Enum.Material.Neon, 0.00, CFrame.new(0.000,1.654,-0.094,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://75985353522068")
    P("Head", Vector3.new(1.76,1.77,0.24), Color3.fromRGB(17,17,17), Enum.Material.Neon, 0.00, CFrame.new(-0.000,2.719,-0.110,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000))
    P("WoodHead", Vector3.new(0.56,2.15,1.49), Color3.fromRGB(113,88,75), Enum.Material.Wood, 0.00, CFrame.new(0.070,2.521,-0.701,0.023,-0.030,-0.999,-0.004,1.000,-0.030,1.000,0.004,0.023), "rbxassetid://128318751187918")
    P("Face", Vector3.new(0.24,1.72,1.48), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(0.078,2.507,-0.947,0.023,-0.030,-0.999,-0.004,1.000,-0.030,1.000,0.004,0.023), "rbxassetid://75571226192230")
    P("Expression", Vector3.new(0.20,1.36,1.48), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 1.00, CFrame.new(0.080,2.406,-0.967,0.023,-0.030,-0.999,-0.004,1.000,-0.030,1.000,0.004,0.023), "rbxassetid://75571226192230")
    P("Papers", Vector3.new(0.44,1.80,1.77), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(0.067,2.462,-0.751,0.023,-0.030,-0.999,-0.004,1.000,-0.030,1.000,0.004,0.023), "rbxassetid://115303509304336")

    addDecal("Expression", "Eyes", "rbxassetid://139358064967650", Enum.NormalId.Right)
    addDecal("Expression", "Mouth", "rbxassetid://126379035605248", Enum.NormalId.Right)
    addDecal("Face", "Coffee", "rbxassetid://7759657445", Enum.NormalId.Right)

    -- 6. Левая и правая руки
    P("LeftShoulder", Vector3.new(1.79,1.11,0.15), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(-2.295,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://96019671780855")
P("LeftUpperArm", Vector3.new(2.25,1.11,0.15), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(-2.522,0.966,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://113166944665848")
P("LeftElbowCuff", Vector3.new(0.68,1.28,0.26), Color3.fromRGB(165,173,245), Enum.Material.Fabric, 0.00, CFrame.new(-3.268,0.968,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://117069753262347")
P("LeftUpperWrist", Vector3.new(1.14,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(-4.025,0.966,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://90409852703796")
P("LeftUpperWristLining", Vector3.new(0.63,0.72,0.20), Color3.fromRGB(165,163,167), Enum.Material.Concrete, 0.00, CFrame.new(-4.052,1.194,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://134132942960013")
P("LeftLowerWrist", Vector3.new(1.23,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(-5.012,0.966,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://105316643003545")
P("LeftLowerWristLining", Vector3.new(0.16,0.59,0.20), Color3.fromRGB(165,163,167), Enum.Material.Concrete, 0.00, CFrame.new(-4.757,1.260,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://126912919535520")
P("LeftHand", Vector3.new(0.64,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(-5.759,0.966,-0.104,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://72257926559459")
P("RightShoulder", Vector3.new(1.79,1.11,0.15), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(2.295,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://108517698783634")
P("RightUpperArm", Vector3.new(2.25,1.11,0.15), Color3.fromRGB(147,154,218), Enum.Material.Fabric, 0.00, CFrame.new(2.522,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://74666923510830")
P("RightElbowCuff", Vector3.new(0.68,1.28,0.26), Color3.fromRGB(165,173,245), Enum.Material.Fabric, 0.00, CFrame.new(3.268,0.968,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://118912955349603")
P("RightUpperWrist", Vector3.new(1.14,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(4.025,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://90384864687734")
P("RightUpperWristLining", Vector3.new(0.63,0.72,0.20), Color3.fromRGB(165,163,167), Enum.Material.Concrete, 0.00, CFrame.new(4.052,1.194,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://130119241089192")
P("RightLowerWrist", Vector3.new(1.23,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(5.012,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://100905147085345")
P("RightLowerWristLining", Vector3.new(0.16,0.59,0.20), Color3.fromRGB(165,163,167), Enum.Material.Concrete, 0.00, CFrame.new(4.757,1.260,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://117285548185022")
P("RightHand", Vector3.new(0.64,1.11,0.15), Color3.fromRGB(252,250,255), Enum.Material.Concrete, 0.00, CFrame.new(5.759,0.966,-0.104,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://108491148518063")
-- 7. Ноги и ботинки
P("LeftUpperLeg", Vector3.new(1.27,1.17,0.33), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(-0.788,-2.713,-0.040,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://104586561338241")
P("LeftMiddleLeg", Vector3.new(1.29,1.28,0.48), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(-0.785,-3.728,0.046,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://106917430543569")
P("LeftLowerLeg", Vector3.new(1.32,1.28,0.71), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(-0.785,-4.789,0.089,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://92848143588823")
P("LeftAnkle", Vector3.new(1.35,0.80,0.85), Color3.fromRGB(71,68,95), Enum.Material.Fabric, 0.00, CFrame.new(-0.785,-5.624,0.096,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://85152828861213")
P("LeftFoot", Vector3.new(1.21,0.45,0.64), Color3.fromRGB(95,73,60), Enum.Material.Concrete, 0.00, CFrame.new(-0.792,-6.114,-0.197,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://123176389836912")
P("LeftFootAccents", Vector3.new(1.21,0.59,1.10), Color3.fromRGB(70,54,44), Enum.Material.Concrete, 0.00, CFrame.new(0.792,-6.100,0.032,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://121793704163004")
P("RightUpperLeg", Vector3.new(1.27,1.17,0.33), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(0.788,-2.713,-0.040,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://138161724918325")
P("RightMiddleLeg", Vector3.new(1.29,1.28,0.48), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(0.785,-3.728,0.046,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://113421128299419")
P("RightLowerLeg", Vector3.new(1.32,1.28,0.71), Color3.fromRGB(77,74,103), Enum.Material.Fabric, 0.00, CFrame.new(0.785,-4.789,0.089,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://101888359550009")
P("RightAnkle", Vector3.new(1.35,0.80,0.85), Color3.fromRGB(71,68,95), Enum.Material.Fabric, 0.00, CFrame.new(0.785,-5.624,0.096,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://96516048576548")
P("RightFoot", Vector3.new(1.21,0.45,0.64), Color3.fromRGB(95,73,60), Enum.Material.Concrete, 0.00, CFrame.new(0.792,-6.114,-0.197,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://75280914215046")
P("RightFootAccents", Vector3.new(1.21,0.59,1.10), Color3.fromRGB(70,54,44), Enum.Material.Concrete, 0.00, CFrame.new(-0.792,-6.100,0.032,1.000,-0.000,0.000,-0.000,1.000,0.000,0.000,0.000,1.000), "rbxassetid://129579987929102")
model.PrimaryPart = parts["HumanoidRootPart"]
-- 8. Точные Motor6D суставы из дампа
M("Root Hip", "HumanoidRootPart", "Torso", CFrame.new(0.000,0.000,0.000,-1.000,0.000,0.000,0.000,0.000,1.000,0.000,1.000,-0.000), CFrame.new(0.000,0.000,0.000,-1.000,0.000,0.000,0.000,0.000,1.000,0.000,1.000,-0.000))
M("Pelvis", "HumanoidRootPart", "Pelvis", CFrame.new(0.000,-1.882,-0.100,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("Left Shoulder", "Torso", "Left Arm", CFrame.new(-1.000,0.500,0.000,-0.000,0.000,-1.000,0.000,1.000,0.000,1.000,0.000,-0.000), CFrame.new(0.500,0.500,0.000,-0.000,0.000,-1.000,0.000,1.000,0.000,1.000,0.000,-0.000))
M("NeckDummy", "Torso", "Head1", CFrame.new(0.000,1.000,0.000,-1.000,0.000,0.000,0.000,0.000,1.000,0.000,1.000,-0.000), CFrame.new(0.000,-0.500,0.000,-1.000,0.000,0.000,0.000,0.000,1.000,0.000,1.000,-0.000))
M("Right Shoulder", "Torso", "Right Arm", CFrame.new(1.000,0.500,0.000,-0.000,0.000,1.000,0.000,1.000,0.000,-1.000,0.000,-0.000), CFrame.new(-0.500,0.500,0.000,-0.000,0.000,1.000,0.000,1.000,0.000,-1.000,0.000,-0.000))
M("Right Hip", "Torso", "Right Leg", CFrame.new(1.000,-1.000,0.000,-0.000,0.000,1.000,0.000,1.000,0.000,-1.000,0.000,-0.000), CFrame.new(0.500,1.000,0.000,-0.000,0.000,1.000,0.000,1.000,0.000,-1.000,0.000,-0.000))
M("Left Hip", "Torso", "Left Leg", CFrame.new(-1.000,-1.000,0.000,-0.000,0.000,-1.000,0.000,1.000,0.000,1.000,0.000,-0.000), CFrame.new(-0.500,1.000,0.000,-0.000,0.000,-1.000,0.000,1.000,0.000,1.000,0.000,-0.000))
M("LowerTorso", "Pelvis", "LowerTorso", CFrame.new(0.000,0.355,-0.018,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,-0.259,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("MiddleTorso", "LowerTorso", "MiddleTorso", CFrame.new(0.000,0.290,0.008,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,-0.684,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("UpperTorso", "MiddleTorso", "UpperTorso", CFrame.new(0.000,0.577,0.001,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,-0.590,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("TieTop", "UpperTorso", "TieTop", CFrame.new(0.000,0.470,-0.361,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.113,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("TieUpper", "TieTop", "TieUpper", CFrame.new(0.000,-0.192,-0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.311,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("TieMiddle", "TieUpper", "TieMiddle", CFrame.new(0.000,-0.313,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.321,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("TieLower", "TieMiddle", "TieLower", CFrame.new(0.000,-0.313,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.321,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("TieBottom", "TieLower", "TieBottom", CFrame.new(0.000,-0.322,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.283,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("Neck", "UpperTorso", "Neck", CFrame.new(0.000,0.781,0.016,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("Head", "Neck", "Head", CFrame.new(-0.000,0.235,-0.015,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,-0.830,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightShoulder", "UpperTorso", "RightShoulder", CFrame.new(1.389,0.093,0.006,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(-0.905,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightUpperArm", "RightShoulder", "RightUpperArm", CFrame.new(0.001,0.000,0.000,0.866,0.354,0.354,-0.000,0.707,-0.707,-0.500,0.612,0.612), CFrame.new(-0.226,0.000,0.000,0.866,0.354,0.354,-0.000,0.707,-0.707,-0.500,0.612,0.612))
M("RightUpperWrist", "RightUpperArm", "RightUpperWrist", CFrame.new(1.032,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(-0.472,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightLowerWrist", "RightUpperWrist", "RightLowerWrist", CFrame.new(0.468,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(-0.519,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightHand", "RightLowerWrist", "RightHand", CFrame.new(0.529,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(-0.217,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftShoulder", "UpperTorso", "LeftShoulder", CFrame.new(-1.399,0.093,0.006,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.896,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftUpperArm", "LeftShoulder", "LeftUpperArm", CFrame.new(-0.020,0.000,0.000,0.707,-0.354,-0.612,0.000,0.866,-0.500,0.707,0.354,0.612), CFrame.new(0.207,0.000,0.000,0.707,-0.354,-0.612,0.000,0.866,-0.500,0.707,0.354,0.612))
M("LeftUpperWrist", "LeftUpperArm", "LeftUpperWrist", CFrame.new(-1.032,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.472,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftLowerWrist", "LeftUpperWrist", "LeftLowerWrist", CFrame.new(-0.468,0.000,-0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.519,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftHand", "LeftLowerWrist", "LeftHand", CFrame.new(-0.520,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.226,0.000,0.000,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightUpperLeg", "Pelvis", "RightUpperLeg", CFrame.new(0.788,-0.369,-0.015,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.462,-0.075,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightMiddleLeg", "RightUpperLeg", "RightMiddleLeg", CFrame.new(-0.004,-0.478,-0.065,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.538,-0.151,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightLowerLeg", "RightMiddleLeg", "RightLowerLeg", CFrame.new(0.000,-0.532,-0.146,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.528,-0.189,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightAnkle", "RightLowerLeg", "RightAnkle", CFrame.new(0.000,-0.515,-0.210,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.321,-0.217,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("RightFoot", "RightAnkle", "RightFoot", CFrame.new(0.008,-0.282,-0.227,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.208,0.066,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftUpperLeg", "Pelvis", "LeftUpperLeg", CFrame.new(-0.788,-0.369,-0.015,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.462,-0.075,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftMiddleLeg", "LeftUpperLeg", "LeftMiddleLeg", CFrame.new(0.004,-0.478,-0.065,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.538,-0.151,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftLowerLeg", "LeftMiddleLeg", "LeftLowerLeg", CFrame.new(0.000,-0.532,-0.146,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.528,-0.189,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftAnkle", "LeftLowerLeg", "LeftAnkle", CFrame.new(0.000,-0.515,-0.210,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000), CFrame.new(0.000,0.321,-0.217,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
M("LeftFoot", "LeftAnkle", "LeftFoot", CFrame.new(-0.008,-0.282,-0.237,1.000,0.000,0.000,0.000,1.000,0.000,0.000,
0.000,1.000), CFrame.new(0.000,0.208,0.057,1.000,0.000,0.000,0.000,1.000,0.000,0.000,0.000,1.000))
-- 9. Приварка декоративных деталей к костям
W("Pelvis", "PelvisLining")
W("LowerTorso", "LowerSuspenders")
W("LowerTorso", "SuspenderClips")
W("MiddleTorso", "MiddleSuspenders")
W("MiddleTorso", "MiddleSuspenderRings")
W("MiddleTorso", "SuspenderJoint")
W("UpperTorso", "UpperSuspenders")
W("UpperTorso", "UpperSuspenderRings")
W("UpperTorso", "NeckCuff")
W("Head", "WoodHead")
W("Head", "Face")
W("Head", "Expression")
W("Head", "Papers")
W("LeftUpperArm", "LeftElbowCuff")
W("LeftUpperWrist", "LeftUpperWristLining")
W("LeftLowerWrist", "LeftLowerWristLining")
W("RightUpperArm", "RightElbowCuff")
W("RightUpperWrist", "RightUpperWristLining")
W("RightLowerWrist", "RightLowerWristLining")
W("LeftFoot", "LeftFootAccents")
W("RightFoot", "RightFootAccents")
-- 10. Humanoid + Animator + родные анимации Honcho
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
hum.Parent = model
local animator = Instance.new("Animator")
animator.Parent = hum
local customAnims = Instance.new("Folder")
customAnims.Name = "CustomAnimations"
customAnims.Parent = model
local function addAnim(name, id)
local a = Instance.new("Animation")
a.Name = name
a.AnimationId = id
a.Parent = customAnims
end
addAnim("idle",   "rbxassetid://101907348895136")
addAnim("walk",   "rbxassetid://100466662502744")
addAnim("sprint", "rbxassetid://100466662502744")
return model
end