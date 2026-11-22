-- builders/HonchoBuilder.lua
-- Полная сборка Honcho по технологии PortraitBuilder (InsertService:CreateMeshPartAsync)

local InsertService = game:GetService("InsertService")

local HONCHO_PARTS = {
    -- Базовые R6-совместимые невидимые хитбоксы
    Torso      = { MeshId = "", Size = Vector3.new(2.00, 2.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(0, 0, 0) },
    Head1      = { MeshId = "", Size = Vector3.new(2.00, 1.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(0, 1.5, 0) },
    RightArmR6 = { Name = "Right Arm", MeshId = "", Size = Vector3.new(1.00, 2.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(1.5, 0, 0) },
    LeftArmR6  = { Name = "Left Arm",  MeshId = "", Size = Vector3.new(1.00, 2.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(-1.5, 0, 0) },
    RightLegR6 = { Name = "Right Leg", MeshId = "", Size = Vector3.new(1.00, 2.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(0.5, -2, 0) },
    LeftLegR6  = { Name = "Left Leg",  MeshId = "", Size = Vector3.new(1.00, 2.00, 1.00), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, Transp = 1, CF = CFrame.new(-0.5, -2, 0) },

    -- Торс и брюки
    Pelvis       = { MeshId = "rbxassetid://118178032366130", Size = Vector3.new(2.88, 0.86, 0.24), Color = Color3.fromRGB(77, 74, 103),   Mat = Enum.Material.Fabric, Transp = 0, CF = CFrame.new(0.000, -1.882, -0.100) },
    PelvisLining = { MeshId = "rbxassetid://75488742733120",  Size = Vector3.new(2.41, 0.34, 0.24), Color = Color3.fromRGB(60, 58, 81),    Mat = Enum.Material.Fabric, Transp = 0, CF = CFrame.new(0.000, -1.649, -0.104) },
    LowerTorso   = { MeshId = "rbxassetid://139835356304384", Size = Vector3.new(2.80, 0.71, 0.16), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, Transp = 0, CF = CFrame.new(0.000, -1.267, -0.119) },
    MiddleTorso  = { MeshId = "rbxassetid://70487070931077",  Size = Vector3.new(2.80, 1.51, 0.47), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, Transp = 0, CF = CFrame.new(0.000, -0.294, -0.111) },
    UpperTorso   = { MeshId = "rbxassetid://76105738314059",  Size = Vector3.new(2.80, 1.57, 0.73), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, Transp = 0, CF = CFrame.new(0.000,  0.873, -0.110) },

    -- Подтяжки
    LowerSuspenders      = { MeshId = "rbxassetid://126199874864038", Size = Vector3.new(1.97, 0.30, 0.30), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, Transp = 0, CF = CFrame.new(0.000, -1.110, -0.107) },
    MiddleSuspenders     = { MeshId = "rbxassetid://104657923149834", Size = Vector3.new(1.99, 1.29, 0.53), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, Transp = 0, CF = CFrame.new(0.000, -0.348, -0.105) },
    UpperSuspenders      = { MeshId = "rbxassetid://107318840825406", Size = Vector3.new(2.00, 1.42, 0.76), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, Transp = 0, CF = CFrame.new(0.000,  0.969, -0.100) },
    MiddleSuspenderRings = { MeshId = "rbxassetid://123853586133905", Size = Vector3.new(0.89, 0.23, 0.10), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     Transp = 0, CF = CFrame.new(0.000,  0.075,  0.121) },
    UpperSuspenderRings  = { MeshId = "rbxassetid://76698522685498",  Size = Vector3.new(2.06, 0.11, 0.18), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     Transp = 0, CF = CFrame.new(0.000,  0.661, -0.347) },
    SuspenderJoint       = { MeshId = "rbxassetid://117948165283138", Size = Vector3.new(0.63, 0.72, 0.11), Color = Color3.fromRGB(95, 81, 75),    Mat = Enum.Material.Leather,   Transp = 0, CF = CFrame.new(0.000, -0.324,  0.087) },
    SuspenderClips       = { MeshId = "rbxassetid://101871542369664", Size = Vector3.new(2.00, 0.36, 0.30), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     Transp = 0, CF = CFrame.new(0.000, -1.398, -0.103) },

    -- Галстук
    TieTop    = { MeshId = "rbxassetid://87178780263090",  Size = Vector3.new(0.59, 0.49, 0.11), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, Transp = 0, CF = CFrame.new(0.000,  1.230, -0.471) },
    TieUpper  = { MeshId = "rbxassetid://103960932596077", Size = Vector3.new(0.50, 0.63, 0.09), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, Transp = 0, CF = CFrame.new(0.000,  0.727, -0.471) },
    TieMiddle = { MeshId = "rbxassetid://129453078714949", Size = Vector3.new(0.63, 0.63, 0.09), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, Transp = 0, CF = CFrame.new(0.000,  0.093, -0.471) },
    TieLower  = { MeshId = "rbxassetid://109245141563413", Size = Vector3.new(0.64, 0.63, 0.09), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, Transp = 0, CF = CFrame.new(0.000, -0.540, -0.471) },
    TieBottom = { MeshId = "rbxassetid://140719528715020", Size = Vector3.new(0.64, 0.58, 0.09), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, Transp = 0, CF = CFrame.new(0.000, -1.145, -0.471) },

    -- Шея и голова-планшет
    NeckCuff   = { MeshId = "rbxassetid://86130211772398",  Size = Vector3.new(1.85, 0.58, 0.99), Color = Color3.fromRGB(183, 185, 193), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(0.000, 1.541, -0.089) },
    Neck       = { MeshId = "rbxassetid://75985353522068",  Size = Vector3.new(1.22, 0.29, 0.72), Color = Color3.fromRGB(0, 0, 0),       Mat = Enum.Material.Neon,     Transp = 0, CF = CFrame.new(0.000, 1.654, -0.094) },
    Head       = { MeshId = "",                             Size = Vector3.new(1.76, 1.77, 0.24), Color = Color3.fromRGB(17, 17, 17),    Mat = Enum.Material.Neon,     Transp = 0, CF = CFrame.new(0.000, 2.719, -0.110) },
    WoodHead   = { MeshId = "rbxassetid://128318751187918", Size = Vector3.new(0.56, 2.15, 1.49), Color = Color3.fromRGB(113, 88, 75),   Mat = Enum.Material.Wood,     Transp = 0, CF = CFrame.new(0.070, 2.521, -0.701, 0.023, -0.030, -0.999, -0.004, 1.000, -0.030, 1.000, 0.004, 0.023) },
    Face       = { MeshId = "rbxassetid://75571226192230",  Size = Vector3.new(0.24, 1.72, 1.48), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(0.078, 2.507, -0.947, 0.023, -0.030, -0.999, -0.004, 1.000, -0.030, 1.000, 0.004, 0.023) },
    Expression = { MeshId = "rbxassetid://75571226192230",  Size = Vector3.new(0.20, 1.36, 1.48), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 1, CF = CFrame.new(0.080, 2.406, -0.967, 0.023, -0.030, -0.999, -0.004, 1.000, -0.030, 1.000, 0.004, 0.023) },
    Papers     = { MeshId = "rbxassetid://115303509304336", Size = Vector3.new(0.44, 1.80, 1.77), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(0.067, 2.462, -0.751, 0.023, -0.030, -0.999, -0.004, 1.000, -0.030, 1.000, 0.004, 0.023) },

    -- Левая рука
    LeftShoulder         = { MeshId = "rbxassetid://96019671780855",  Size = Vector3.new(1.79, 1.11, 0.15), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-2.295, 0.966, -0.104) },
    LeftUpperArm         = { MeshId = "rbxassetid://113166944665848", Size = Vector3.new(2.25, 1.11, 0.15), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-2.522, 0.966, -0.104) },
    LeftElbowCuff        = { MeshId = "rbxassetid://117069753262347", Size = Vector3.new(0.68, 1.28, 0.26), Color = Color3.fromRGB(165, 173, 245), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-3.268, 0.968, -0.104) },
    LeftUpperWrist       = { MeshId = "rbxassetid://90409852703796",  Size = Vector3.new(1.14, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-4.025, 0.966, -0.104) },
    LeftUpperWristLining = { MeshId = "rbxassetid://134132942960013", Size = Vector3.new(0.63, 0.72, 0.20), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-4.052, 1.194, -0.104) },
    LeftLowerWrist       = { MeshId = "rbxassetid://105316643003545", Size = Vector3.new(1.23, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-5.012, 0.966, -0.104) },
    LeftLowerWristLining = { MeshId = "rbxassetid://126912919535520", Size = Vector3.new(0.16, 0.59, 0.20), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-4.757, 1.260, -0.104) },
    LeftHand             = { MeshId = "rbxassetid://72257926559459",  Size = Vector3.new(0.64, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-5.759, 0.966, -0.104) },

    -- Правая рука
    RightShoulder         = { MeshId = "rbxassetid://108517698783634", Size = Vector3.new(1.79, 1.11, 0.15), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(2.295, 0.966, -0.104) },
    RightUpperArm         = { MeshId = "rbxassetid://74666923510830",  Size = Vector3.new(2.25, 1.11, 0.15), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(2.522, 0.966, -0.104) },
    RightElbowCuff        = { MeshId = "rbxassetid://118912955349603", Size = Vector3.new(0.68, 1.28, 0.26), Color = Color3.fromRGB(165, 173, 245), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(3.268, 0.968, -0.104) },
RightUpperWrist       = { MeshId = "rbxassetid://90384864687734",  Size = Vector3.new(1.14, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(4.025, 0.966, -0.104) },
RightUpperWristLining = { MeshId = "rbxassetid://130119241089192", Size = Vector3.new(0.63, 0.72, 0.20), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(4.052, 1.194, -0.104) },
RightLowerWrist       = { MeshId = "rbxassetid://100905147085345", Size = Vector3.new(1.23, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(5.012, 0.966, -0.104) },
RightLowerWristLining = { MeshId = "rbxassetid://117285548185022", Size = Vector3.new(0.16, 0.59, 0.20), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(4.757, 1.260, -0.104) },
RightHand             = { MeshId = "rbxassetid://108491148518063", Size = Vector3.new(0.64, 1.11, 0.15), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(5.759, 0.966, -0.104) },
-- Ноги и ботинки
LeftUpperLeg    = { MeshId = "rbxassetid://104586561338241", Size = Vector3.new(1.27, 1.17, 0.33), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-0.788, -2.713, -0.040) },
LeftMiddleLeg   = { MeshId = "rbxassetid://106917430543569", Size = Vector3.new(1.29, 1.28, 0.48), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-0.785, -3.728,  0.046) },
LeftLowerLeg    = { MeshId = "rbxassetid://92848143588823",  Size = Vector3.new(1.32, 1.28, 0.71), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-0.785, -4.789,  0.089) },
LeftAnkle       = { MeshId = "rbxassetid://85152828861213",  Size = Vector3.new(1.35, 0.80, 0.85), Color = Color3.fromRGB(71, 68, 95),  Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(-0.785, -5.624,  0.096) },
LeftFoot        = { MeshId = "rbxassetid://123176389836912", Size = Vector3.new(1.21, 0.45, 0.64), Color = Color3.fromRGB(95, 73, 60),  Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-0.792, -6.114, -0.197) },
LeftFootAccents = { MeshId = "rbxassetid://121793704163004", Size = Vector3.new(1.21, 0.59, 1.10), Color = Color3.fromRGB(70, 54, 44),  Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new( 0.792, -6.100,  0.032) },
RightUpperLeg    = { MeshId = "rbxassetid://138161724918325", Size = Vector3.new(1.27, 1.17, 0.33), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(0.788, -2.713, -0.040) },
RightMiddleLeg   = { MeshId = "rbxassetid://113421128299419", Size = Vector3.new(1.29, 1.28, 0.48), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(0.785, -3.728,  0.046) },
RightLowerLeg    = { MeshId = "rbxassetid://101888359550009", Size = Vector3.new(1.32, 1.28, 0.71), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(0.785, -4.789,  0.089) },
RightAnkle       = { MeshId = "rbxassetid://96516048576548",  Size = Vector3.new(1.35, 0.80, 0.85), Color = Color3.fromRGB(71, 68, 95),  Mat = Enum.Material.Fabric,   Transp = 0, CF = CFrame.new(0.785, -5.624,  0.096) },
RightFoot        = { MeshId = "rbxassetid://75280914215046",  Size = Vector3.new(1.21, 0.45, 0.64), Color = Color3.fromRGB(95, 73, 60),  Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(0.792, -6.114, -0.197) },
RightFootAccents = { MeshId = "rbxassetid://129579987929102", Size = Vector3.new(1.21, 0.59, 1.10), Color = Color3.fromRGB(70, 54, 44),  Mat = Enum.Material.Concrete, Transp = 0, CF = CFrame.new(-0.792, -6.100, 0.032) },
}
local EXACT_JOINTS = {
{ Name = "Root Hip",       Part0 = "HumanoidRootPart", Part1 = "Torso",      C0 = CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), C1 = CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0) },
{ Name = "Pelvis",         Part0 = "HumanoidRootPart", Part1 = "Pelvis",     C0 = CFrame.new(0.000,-1.882,-0.100), C1 = CFrame.new(0,0,0) },
{ Name = "Left Shoulder",  Part0 = "Torso",            Part1 = "Left Arm",   C0 = CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0), C1 = CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0) },
{ Name = "Right Shoulder", Part0 = "Torso",            Part1 = "Right Arm",  C0 = CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0), C1 = CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0) },
{ Name = "Right Hip",      Part0 = "Torso",            Part1 = "Right Leg",  C0 = CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0), C1 = CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0) },
{ Name = "Left Hip",       Part0 = "Torso",            Part1 = "Left Leg",   C0 = CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0), C1 = CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0) },
{ Name = "LowerTorso",     Part0 = "Pelvis",           Part1 = "LowerTorso",  C0 = CFrame.new(0.000,0.355,-0.018), C1 = CFrame.new(0.000,-0.259,0.000) },
{ Name = "MiddleTorso",    Part0 = "LowerTorso",       Part1 = "MiddleTorso", C0 = CFrame.new(0.000,0.290,0.008),  C1 = CFrame.new(0.000,-0.684,0.000) },
{ Name = "UpperTorso",     Part0 = "MiddleTorso",      Part1 = "UpperTorso",  C0 = CFrame.new(0.000,0.577,0.001),  C1 = CFrame.new(0.000,-0.590,0.000) },
{ Name = "TieTop",         Part0 = "UpperTorso",       Part1 = "TieTop",    C0 = CFrame.new(0.000,0.470,-0.361), C1 = CFrame.new(0.000,0.113,0.000) },
{ Name = "TieUpper",       Part0 = "TieTop",           Part1 = "TieUpper",  C0 = CFrame.new(0.000,-0.192,0.000), C1 = CFrame.new(0.000,0.311,0.000) },
{ Name = "TieMiddle",      Part0 = "TieUpper",         Part1 = "TieMiddle", C0 = CFrame.new(0.000,-0.313,0.000), C1 = CFrame.new(0.000,0.321,0.000) },
{ Name = "TieLower",       Part0 = "TieMiddle",        Part1 = "TieLower",  C0 = CFrame.new(0.000,-0.313,0.000), C1 = CFrame.new(0.000,0.321,0.000) },
{ Name = "TieBottom",      Part0 = "TieLower",         Part1 = "TieBottom", C0 = CFrame.new(0.000,-0.322,0.000), C1 = CFrame.new(0.000,0.283,0.000) },
{ Name = "Neck",           Part0 = "UpperTorso",       Part1 = "Neck",      C0 = CFrame.new(0.000,0.781,0.016),  C1 = CFrame.new(0,0,0) },
{ Name = "Head",           Part0 = "Neck",             Part1 = "Head",      C0 = CFrame.new(0.000,0.235,-0.015), C1 = CFrame.new(0.000,-0.830,0.000) },
{ Name = "RightShoulder",   Part0 = "UpperTorso",      Part1 = "RightShoulder",   C0 = CFrame.new(1.389,0.093,0.006), C1 = CFrame.new(-0.905,0.000,0.000) },
{ Name = "RightUpperArm",   Part0 = "RightShoulder",   Part1 = "RightUpperArm",   C0 = CFrame.new(0.001,0.000,0.000,0.866,0.354,0.354,0.000,0.707,-0.707,-0.500,0.612,0.612), C1 = CFrame.new(-0.226,0.000,0.000,0.866,0.354,0.354,0.000,0.707,-0.707,-0.500,0.612,0.612) },
{ Name = "RightUpperWrist", Part0 = "RightUpperArm",   Part1 = "RightUpperWrist", C0 = CFrame.new(1.032,0,0), C1 = CFrame.new(-0.472,0,0) },
{ Name = "RightLowerWrist", Part0 = "RightUpperWrist", Part1 = "RightLowerWrist", C0 = CFrame.new(0.468,0,0), C1 = CFrame.new(-0.519,0,0) },
{ Name = "RightHand",       Part0 = "RightLowerWrist", Part1 = "RightHand",       C0 = CFrame.new(0.529,0,0), C1 = CFrame.new(-0.217,0,0) },
{ Name = "LeftShoulder",    Part0 = "UpperTorso",      Part1 = "LeftShoulder",    C0 = CFrame.new(-1.399,0.093,0.006), C1 = CFrame.new(0.896,0.000,0.000) },
{ Name = "LeftUpperArm",    Part0 = "LeftShoulder",    Part1 = "LeftUpperArm",    C0 = CFrame.new(-0.020,0.000,0.000,0.707,-0.354,-0.612,0.000,0.866,-0.500,0.707,0.354,0.612), C1 = CFrame.new(0.207,0.000,0.000,0.707,-0.354,-0.612,0.000,0.866,-0.500,0.707,0.354,0.612) },
{ Name = "LeftUpperWrist",  Part0 = "LeftUpperArm",    Part1 = "LeftUpperWrist",  C0 = CFrame.new(-1.032,0,0), C1 = CFrame.new(0.472,0,0) },
{ Name = "LeftLowerWrist",  Part0 = "LeftUpperWrist",  Part1 = "LeftLowerWrist",  C0 = CFrame.new(-0.468,0,0), C1 = CFrame.new(0.519,0,0) },
{ Name = "LeftHand",        Part0 = "LeftLowerWrist",  Part1 = "LeftHand",        C0 = CFrame.new(-0.520,0,0), C1 = CFrame.new(0.226,0,0) },
{ Name = "RightUpperLeg",   Part0 = "Pelvis",          Part1 = "RightUpperLeg",   C0 = CFrame.new(0.788,-0.369,-0.015),  C1 = CFrame.new(0.000,0.462,-0.075) },
{ Name = "RightMiddleLeg",  Part0 = "RightUpperLeg",   Part1 = "RightMiddleLeg",  C0 = CFrame.new(-0.004,-0.478,-0.065), C1 = CFrame.new(0.000,0.538,-0.151) },
{ Name = "RightLowerLeg",   Part0 = "RightMiddleLeg",  Part1 = "RightLowerLeg",   C0 = CFrame.new(0.000,-0.532,-0.146),  C1 = CFrame.new(0.000,0.528,-0.189) },
{ Name = "RightAnkle",      Part0 = "RightLowerLeg",   Part1 = "RightAnkle",      C0 = CFrame.new(0.000,-0.515,-0.210),  C1 = CFrame.new(0.000,0.321,-0.217) },
{ Name = "RightFoot",       Part0 = "RightAnkle",      Part1 = "RightFoot",       C0 = CFrame.new(0.008,-0.282,-0.227),  C1 = CFrame.new(0.000,0.208,0.066) },
{ Name = "LeftUpperLeg",    Part0 = "Pelvis",          Part1 = "LeftUpperLeg",    C0 = CFrame.new(-0.788,-0.369,-0.015), C1 = CFrame.new(0.000,0.462,-0.075) },
{ Name = "LeftMiddleLeg",   Part0 = "LeftUpperLeg",    Part1 = "LeftMiddleLeg",   C0 = CFrame.new(0.004,-0.478,-0.065),  C1 = CFrame.new(0.000,0.538,-0.151) },
{ Name = "LeftLowerLeg",    Part0 = "LeftMiddleLeg",   Part1 = "LeftLowerLeg",    C0 = CFrame.new(0.000,-0.532,-0.146),  C1 = CFrame.new(0.000,0.528,-0.189) },
{ Name = "LeftAnkle",       Part0 = "LeftLowerLeg",    Part1 = "LeftAnkle",       C0 = CFrame.new(0.000,-0.515,-0.210),  C1 = CFrame.new(0.000,0.321,-0.217) },
{ Name = "LeftFoot",        Part0 = "LeftAnkle",       Part1 = "LeftFoot",        C0 = CFrame.new(-0.008,-0.282,-0.237), C1 = CFrame.new(0.000,0.208,0.057) },
}
local EXACT_WELDS = {
{ "Pelvis",          "PelvisLining" },
{ "LowerTorso",      "LowerSuspenders" },
{ "LowerTorso",      "SuspenderClips" },
{ "MiddleTorso",     "MiddleSuspenders" },
{ "MiddleTorso",     "MiddleSuspenderRings" },
{ "MiddleTorso",     "SuspenderJoint" },
{ "UpperTorso",      "UpperSuspenders" },
{ "UpperTorso",      "UpperSuspenderRings" },
{ "UpperTorso",      "NeckCuff" },
{ "Head",            "WoodHead" },
{ "Head",            "Face" },
{ "Head",            "Expression" },
{ "Head",            "Papers" },
{ "LeftUpperArm",    "LeftElbowCuff" },
{ "LeftUpperWrist",  "LeftUpperWristLining" },
{ "LeftLowerWrist",  "LeftLowerWristLining" },
{ "RightUpperArm",   "RightElbowCuff" },
{ "RightUpperWrist", "RightUpperWristLining" },
{ "RightLowerWrist", "RightLowerWristLining" },
{ "LeftFoot",        "LeftFootAccents" },
{ "RightFoot",       "RightFootAccents" },
}
-- Точная функция создания MeshPart как в PortraitBuilder!
local function createMeshPart(name, data)
local part = nil
if data.MeshId and data.MeshId ~= "" then
local ok, mp = pcall(function()
return InsertService:CreateMeshPartAsync(data.MeshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
end)
if ok and mp then
part = mp
end
end
if not part then
part = Instance.new("Part")
end
part.Name = data.Name or name
part.Size = data.Size
part.Color = data.Color
part.Material = data.Mat
part.Transparency = data.Transp
part.CFrame = data.CF
part.Reflectance = 0
part.CanCollide = false
part.CanTouch = false
part.CanQuery = false
part.Massless = true
part.Anchored = false
return part
end
local function buildHonchoModel(variantName)
local model = Instance.new("Model")
model.Name = "Honcho_MemeClone"
model:SetAttribute("RootOffset", 6.35)
model:SetAttribute("NoTools", true)
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(1.89, 1.89, 0.94)
hrp.Transparency = 1
hrp.CanCollide = false
hrp.CanTouch = false
hrp.CanQuery = false
hrp.Anchored = true
hrp.Parent = model
model.PrimaryPart = hrp
local parts = { HumanoidRootPart = hrp }
for key, data in pairs(HONCHO_PARTS) do
local p = createMeshPart(key, data)
p.Parent = model
parts[data.Name or key] = p
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
for _, w in ipairs(EXACT_WELDS) do
local p0 = parts[w[1]]
local p1 = parts[w[2]]
if p0 and p1 then
local weld = Instance.new("WeldConstraint")
weld.Name = w[2] .. "Weld"
weld.Part0 = p0
weld.Part1 = p1
weld.Parent = p1
end
end
local function addDecal(partName, decalName, texId)
local p = parts[partName]
if not p then return end
local d = Instance.new("Decal")
d.Name = decalName
d.Texture = texId
d.Face = Enum.NormalId.Right
d.Transparency = 0
d.Parent = p
end
addDecal("Expression", "Eyes", "rbxassetid://139358064967650")
addDecal("Expression", "Mouth", "rbxassetid://126379035605248")
addDecal("Face", "Coffee", "rbxassetid://7759657445")
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HipHeight = 2.1
hum.EvaluateStateMachine = false
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
if type(getgenv) == "function" then
getgenv().BuildHonchoRig = buildHonchoModel
end
return buildHonchoModel