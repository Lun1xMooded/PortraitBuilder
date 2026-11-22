-- builders/HonchoBuilder.lua
-- Точная 3D-сборка Honcho по полному дампу (чёрная пиксельная голова + точные Weld C0/C1 ног и одежды)

local InsertService = game:GetService("InsertService")
local MaterialService = game:GetService("MaterialService")

local cashmereVar = MaterialService:FindFirstChild("Cashmere", true)
local hasCashmere = cashmereVar ~= nil and cashmereVar:IsA("MaterialVariant")

local HONCHO_PARTS = {
    -- Невидимые базовые R6-части
    Torso      = { MeshId = "", Size = Vector3.new(2.0000, 2.0000, 1.0000), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, MatVar = "", Transp = 1.00, CF = CFrame.new(0, 0, 0) },
    RightArmR6 = { Name = "Right Arm", MeshId = "", Size = Vector3.new(1.0000, 2.0000, 1.0000), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, MatVar = "", Transp = 1.00, CF = CFrame.new(1.5, 0, 0) },
    LeftArmR6  = { Name = "Left Arm",  MeshId = "", Size = Vector3.new(1.0000, 2.0000, 1.0000), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, MatVar = "", Transp = 1.00, CF = CFrame.new(-1.5, 0, 0) },
    RightLegR6 = { Name = "Right Leg", MeshId = "", Size = Vector3.new(1.0000, 2.0000, 1.0000), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, MatVar = "", Transp = 1.00, CF = CFrame.new(0.5, -2.0, 0) },
    LeftLegR6  = { Name = "Left Leg",  MeshId = "", Size = Vector3.new(1.0000, 2.0000, 1.0000), Color = Color3.fromRGB(163, 162, 165), Mat = Enum.Material.Plastic, MatVar = "", Transp = 1.00, CF = CFrame.new(-0.5, -2.0, 0) },

    -- Торс и брюки
    Pelvis       = { MeshId = "rbxassetid://118178032366130", Size = Vector3.new(2.8795, 0.8623, 0.2360), Color = Color3.fromRGB(77, 74, 103),   Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000, -1.8815, -0.1001) },
    PelvisLining = { MeshId = "rbxassetid://75488742733120",  Size = Vector3.new(2.4144, 0.3409, 0.2413), Color = Color3.fromRGB(60, 58, 81),    Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000, -1.6486, -0.1040) },
    LowerTorso   = { MeshId = "rbxassetid://139835356304384", Size = Vector3.new(2.7995, 0.7112, 0.1598), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000, -1.2672, -0.1185) },
    MiddleTorso  = { MeshId = "rbxassetid://70487070931077",  Size = Vector3.new(2.7995, 1.5106, 0.4703), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000, -0.2937, -0.1107) },
    UpperTorso   = { MeshId = "rbxassetid://76105738314059",  Size = Vector3.new(2.7995, 1.5687, 0.7337), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000,  0.8729, -0.1100) },

    -- Подтяжки
    LowerSuspenders      = { MeshId = "rbxassetid://126199874864038", Size = Vector3.new(1.9744, 0.3010, 0.3006), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -1.1098, -0.1072) },
    MiddleSuspenders     = { MeshId = "rbxassetid://104657923149834", Size = Vector3.new(1.9887, 1.2858, 0.5298), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -0.3481, -0.1053) },
    UpperSuspenders      = { MeshId = "rbxassetid://107318840825406", Size = Vector3.new(2.0038, 1.4207, 0.7646), Color = Color3.fromRGB(191, 128, 128), Mat = Enum.Material.Cardboard, MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  0.9689, -0.0999) },
    MiddleSuspenderRings = { MeshId = "rbxassetid://123853586133905", Size = Vector3.new(0.8880, 0.2305, 0.0966), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  0.0749,  0.1208) },
    UpperSuspenderRings  = { MeshId = "rbxassetid://76698522685498",  Size = Vector3.new(2.0648, 0.1063, 0.1817), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  0.6606, -0.3473) },
    SuspenderJoint       = { MeshId = "rbxassetid://117948165283138", Size = Vector3.new(0.6271, 0.7156, 0.1144), Color = Color3.fromRGB(95, 81, 75),    Mat = Enum.Material.Leather,   MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -0.3239,  0.0866) },
    SuspenderClips       = { MeshId = "rbxassetid://101871542369664", Size = Vector3.new(2.0016, 0.3631, 0.3044), Color = Color3.fromRGB(179, 148, 112), Mat = Enum.Material.Glass,     MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -1.3981, -0.1029) },

    -- Галстук
    TieTop    = { MeshId = "rbxassetid://87178780263090",  Size = Vector3.new(0.5879, 0.4887, 0.1091), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  1.2298, -0.4706) },
    TieUpper  = { MeshId = "rbxassetid://103960932596077", Size = Vector3.new(0.4982, 0.6337, 0.0858), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  0.7270, -0.4710) },
    TieMiddle = { MeshId = "rbxassetid://129453078714949", Size = Vector3.new(0.6347, 0.6337, 0.0860), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, MatVar = "", Transp = 0, CF = CFrame.new(0.0000,  0.0932, -0.4710) },
    TieLower  = { MeshId = "rbxassetid://109245141563413", Size = Vector3.new(0.6393, 0.6337, 0.0861), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -0.5405, -0.4710) },
    TieBottom = { MeshId = "rbxassetid://140719528715020", Size = Vector3.new(0.6393, 0.5760, 0.0861), Color = Color3.fromRGB(89, 89, 138), Mat = Enum.Material.Leather, MatVar = "", Transp = 0, CF = CFrame.new(0.0000, -1.1453, -0.4710) },

    -- Воротник, шея и чёрная пиксельная голова (1-в-1 из дампа!)
    NeckCuff = { MeshId = "rbxassetid://86130211772398", Size = Vector3.new(1.8523, 0.5783, 0.9915), Color = Color3.fromRGB(183, 185, 193), Mat = Enum.Material.Fabric, MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.0000, 1.5406, -0.0886) },
    Neck     = { MeshId = "rbxassetid://75985353522068", Size = Vector3.new(1.2216, 0.2854, 0.7238), Color = Color3.fromRGB(0, 0, 0),       Mat = Enum.Material.Neon,   MatVar = "",         Transp = 0, CF = CFrame.new(0.0000, 1.6543, -0.0945) },
    Head     = { MeshId = "",                            Size = Vector3.new(1.7574, 1.7685, 0.2358), Color = Color3.fromRGB(17, 17, 17),    Mat = Enum.Material.Neon,   MatVar = "",         Transp = 0, CF = CFrame.new(-0.0001, 2.7192, -0.1099) },

    -- Левая рука
    LeftShoulder         = { MeshId = "rbxassetid://96019671780855",  Size = Vector3.new(1.7907, 1.1136, 0.1511), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-2.2946, 0.9656, -0.1040) },
    LeftUpperArm         = { MeshId = "rbxassetid://113166944665848", Size = Vector3.new(2.2455, 1.1136, 0.1511), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-2.5220, 0.9656, -0.1040) },
    LeftElbowCuff        = { MeshId = "rbxassetid://117069753262347", Size = Vector3.new(0.6835, 1.2770, 0.2586), Color = Color3.fromRGB(165, 173, 245), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-3.2678, 0.9683, -0.1040) },
    LeftUpperWrist       = { MeshId = "rbxassetid://90409852703796",  Size = Vector3.new(1.1375, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-4.0253, 0.9656, -0.1040) },
    LeftUpperWristLining = { MeshId = "rbxassetid://134132942960013", Size = Vector3.new(0.6287, 0.7204, 0.1988), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-4.0519, 1.1935, -0.1039) },
    LeftLowerWrist       = { MeshId = "rbxassetid://105316643003545", Size = Vector3.new(1.2279, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-5.0122, 0.9656, -0.1040) },
    LeftLowerWristLining = { MeshId = "rbxassetid://126912919535520", Size = Vector3.new(0.1589, 0.5874, 0.1988), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-4.7565, 1.2600, -0.1040) },
    LeftHand             = { MeshId = "rbxassetid://72257926559459",  Size = Vector3.new(0.6372, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-5.7585, 0.9656, -0.1040) },

    -- Правая рука
    RightShoulder         = { MeshId = "rbxassetid://108517698783634", Size = Vector3.new(1.7907, 1.1136, 0.1511), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(2.2946, 0.9656, -0.1040) },
    RightUpperArm         = { MeshId = "rbxassetid://74666923510830",  Size = Vector3.new(2.2455, 1.1136, 0.1511), Color = Color3.fromRGB(147, 154, 218), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(2.5220, 0.9656, -0.1040) },
    RightElbowCuff        = { MeshId = "rbxassetid://118912955349603", Size = Vector3.new(0.6835, 1.2770, 0.2586), Color = Color3.fromRGB(165, 173, 245), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(3.2678, 0.9683, -0.1040) },
    RightUpperWrist       = { MeshId = "rbxassetid://90384864687734",  Size = Vector3.new(1.1375, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(4.0253, 0.9656, -0.1040) },
RightUpperWristLining = { MeshId = "rbxassetid://130119241089192", Size = Vector3.new(0.6287, 0.7204, 0.1988), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(4.0519, 1.1935, -0.1040) },
RightLowerWrist       = { MeshId = "rbxassetid://100905147085345", Size = Vector3.new(1.2279, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(5.0122, 0.9656, -0.1040) },
RightLowerWristLining = { MeshId = "rbxassetid://117285548185022", Size = Vector3.new(0.1589, 0.5874, 0.1988), Color = Color3.fromRGB(165, 163, 167), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(4.7565, 1.2600, -0.1040) },
RightHand             = { MeshId = "rbxassetid://108491148518063", Size = Vector3.new(0.6372, 1.1136, 0.1511), Color = Color3.fromRGB(252, 250, 255), Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(5.7585, 0.9656, -0.1040) },
-- Ноги и ботинки (точные координаты из дампа)
LeftUpperLeg    = { MeshId = "rbxassetid://104586561338241", Size = Vector3.new(1.2661, 1.1710, 0.3306), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-0.7883, -2.7130, -0.0396) },
LeftMiddleLeg   = { MeshId = "rbxassetid://106917430543569", Size = Vector3.new(1.2901, 1.2753, 0.4775), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-0.7846, -3.7282,  0.0461) },
LeftLowerLeg    = { MeshId = "rbxassetid://92848143588823",  Size = Vector3.new(1.3215, 1.2830, 0.7088), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-0.7846, -4.7887,  0.0890) },
LeftAnkle       = { MeshId = "rbxassetid://85152828861213",  Size = Vector3.new(1.3529, 0.8043, 0.8481), Color = Color3.fromRGB(71, 68, 95),  Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(-0.7846, -5.6244,  0.0960) },
LeftFoot        = { MeshId = "rbxassetid://123176389836912", Size = Vector3.new(1.2138, 0.4535, 0.6447), Color = Color3.fromRGB(95, 73, 60),  Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-0.7925, -6.1137, -0.1973) },
LeftFootAccents = { MeshId = "rbxassetid://121793704163004", Size = Vector3.new(1.2138, 0.5879, 1.1040), Color = Color3.fromRGB(70, 54, 44),  Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new( 0.7925, -6.0999,  0.0324) },
RightUpperLeg    = { MeshId = "rbxassetid://138161724918325", Size = Vector3.new(1.2661, 1.1710, 0.3306), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.7883, -2.7130, -0.0396) },
RightMiddleLeg   = { MeshId = "rbxassetid://113421128299419", Size = Vector3.new(1.2901, 1.2753, 0.4775), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.7846, -3.7282,  0.0461) },
RightLowerLeg    = { MeshId = "rbxassetid://101888359550009", Size = Vector3.new(1.3215, 1.2830, 0.7088), Color = Color3.fromRGB(77, 74, 103), Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.7846, -4.7887,  0.0890) },
RightAnkle       = { MeshId = "rbxassetid://96516048576548",  Size = Vector3.new(1.3529, 0.8043, 0.8481), Color = Color3.fromRGB(71, 68, 95),  Mat = Enum.Material.Fabric,   MatVar = "Cashmere", Transp = 0, CF = CFrame.new(0.7846, -5.6244,  0.0960) },
RightFoot        = { MeshId = "rbxassetid://75280914215046",  Size = Vector3.new(1.2138, 0.4535, 0.6447), Color = Color3.fromRGB(95, 73, 60),  Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(0.7925, -6.1137, -0.1973) },
RightFootAccents = { MeshId = "rbxassetid://129579987929102", Size = Vector3.new(1.2138, 0.5879, 1.1040), Color = Color3.fromRGB(70, 54, 44),  Mat = Enum.Material.Concrete, MatVar = "",         Transp = 0, CF = CFrame.new(-0.7925, -6.0999, 0.0324) },
}
-- Точные суставы Motor6D и Weld с C0/C1 из раздела 2 дампа!
local EXACT_JOINTS = {
{ Class = "Motor6D", Name = "Root Hip",       Part0 = "HumanoidRootPart", Part1 = "Torso",      C0 = CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), C1 = CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0) },
{ Class = "Motor6D", Name = "Pelvis",         Part0 = "HumanoidRootPart", Part1 = "Pelvis",     C0 = CFrame.new(0.0000,-1.8815,-0.1001), C1 = CFrame.new(0,0,0) },
{ Class = "Motor6D", Name = "Left Shoulder",  Part0 = "Torso",            Part1 = "Left Arm",   C0 = CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0), C1 = CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0) },
{ Class = "Motor6D", Name = "Right Shoulder", Part0 = "Torso",            Part1 = "Right Arm",  C0 = CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0), C1 = CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0) },
{ Class = "Motor6D", Name = "Right Hip",      Part0 = "Torso",            Part1 = "Right Leg",  C0 = CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0), C1 = CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0) },
{ Class = "Motor6D", Name = "Left Hip",       Part0 = "Torso",            Part1 = "Left Leg",   C0 = CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0), C1 = CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0) },
{ Class = "Motor6D", Name = "LowerTorso",     Part0 = "Pelvis",           Part1 = "LowerTorso",  C0 = CFrame.new(0.0000,0.3549,-0.0184), C1 = CFrame.new(0.0000,-0.2594,0.0000) },
{ Class = "Motor6D", Name = "MiddleTorso",    Part0 = "LowerTorso",       Part1 = "MiddleTorso", C0 = CFrame.new(0.0000,0.2897,0.0078),  C1 = CFrame.new(0.0000,-0.6838,0.0000) },
{ Class = "Motor6D", Name = "UpperTorso",     Part0 = "MiddleTorso",      Part1 = "UpperTorso",  C0 = CFrame.new(0.0000,0.5771,0.0007),  C1 = CFrame.new(0.0000,-0.5895,0.0000) },
{ Class = "Motor6D", Name = "TieTop",         Part0 = "UpperTorso",       Part1 = "TieTop",    C0 = CFrame.new(0.0000,0.4701,-0.3606), C1 = CFrame.new(0.0000,0.1132,0.0000) },
{ Class = "Motor6D", Name = "TieUpper",       Part0 = "TieTop",           Part1 = "TieUpper",  C0 = CFrame.new(0.0000,-0.1916,-0.0004), C1 = CFrame.new(0.0000,0.3113,0.0000) },
{ Class = "Motor6D", Name = "TieMiddle",      Part0 = "TieUpper",         Part1 = "TieMiddle", C0 = CFrame.new(0.0000,-0.3130,0.0000), C1 = CFrame.new(0.0000,0.3207,0.0000) },
{ Class = "Motor6D", Name = "TieLower",       Part0 = "TieMiddle",        Part1 = "TieLower",  C0 = CFrame.new(0.0000,-0.3130,0.0000), C1 = CFrame.new(0.0000,0.3207,0.0000) },
{ Class = "Motor6D", Name = "TieBottom",      Part0 = "TieLower",         Part1 = "TieBottom", C0 = CFrame.new(0.0000,-0.3219,0.0000), C1 = CFrame.new(0.0000,0.2830,0.0000) },
{ Class = "Motor6D", Name = "Neck",           Part0 = "UpperTorso",       Part1 = "Neck",      C0 = CFrame.new(0.0000,0.7814,0.0155),  C1 = CFrame.new(0,0,0) },
{ Class = "Motor6D", Name = "Head",           Part0 = "Neck",             Part1 = "Head",      C0 = CFrame.new(-0.0001,0.2349,-0.0154), C1 = CFrame.new(0.0000,-0.8300,0.0000) },
{ Class = "Motor6D", Name = "RightShoulder",   Part0 = "UpperTorso",      Part1 = "RightShoulder",   C0 = CFrame.new(1.3891,0.0927,0.0060), C1 = CFrame.new(-0.9054,0.0000,0.0000) },
{ Class = "Motor6D", Name = "RightUpperArm",   Part0 = "RightShoulder",   Part1 = "RightUpperArm",   C0 = CFrame.new(0.0010,0.0000,0.0000,0.8660,0.3536,0.3535,-0.0000,0.7071,-0.7071,-0.5000,0.6124,0.6124), C1 = CFrame.new(-0.2264,0.0000,0.0000,0.8660,0.3536,0.3535,-0.0000,0.7071,-0.7071,-0.5000,0.6124,0.6124) },
{ Class = "Motor6D", Name = "RightUpperWrist", Part0 = "RightUpperArm",   Part1 = "RightUpperWrist", C0 = CFrame.new(1.0317,0,0), C1 = CFrame.new(-0.4716,0,0) },
{ Class = "Motor6D", Name = "RightLowerWrist", Part0 = "RightUpperWrist", Part1 = "RightLowerWrist", C0 = CFrame.new(0.4682,0,0), C1 = CFrame.new(-0.5187,0,0) },
{ Class = "Motor6D", Name = "RightHand",       Part0 = "RightLowerWrist", Part1 = "RightHand",       C0 = CFrame.new(0.5293,0,0), C1 = CFrame.new(-0.2169,0,0) },
{ Class = "Motor6D", Name = "LeftShoulder",    Part0 = "UpperTorso",      Part1 = "LeftShoulder",    C0 = CFrame.new(-1.3985,0.0927,0.0060), C1 = CFrame.new(0.8961,0.0000,0.0000) },
{ Class = "Motor6D", Name = "LeftUpperArm",    Part0 = "LeftShoulder",    Part1 = "LeftUpperArm",    C0 = CFrame.new(-0.0199,0.0000,0.0000,0.7071,-0.3536,-0.6124,0.0000,0.8660,-0.5000,0.7071,0.3535,0.6124), C1 = CFrame.new(0.2075,0.0000,0.0000,0.7071,-0.3536,-0.6124,0.0000,0.8660,-0.5000,0.7071,0.3535,0.6124) },
{ Class = "Motor6D", Name = "LeftUpperWrist",  Part0 = "LeftUpperArm",    Part1 = "LeftUpperWrist",  C0 = CFrame.new(-1.0317,0,0), C1 = CFrame.new(0.4716,0,0) },
{ Class = "Motor6D", Name = "LeftLowerWrist",  Part0 = "LeftUpperWrist",  Part1 = "LeftLowerWrist",  C0 = CFrame.new(-0.4682,0,0), C1 = CFrame.new(0.5187,0,0) },
{ Class = "Motor6D", Name = "LeftHand",        Part0 = "LeftLowerWrist",  Part1 = "LeftHand",        C0 = CFrame.new(-0.5199,0,0), C1 = CFrame.new(0.2264,0,0) },
{ Class = "Motor6D", Name = "RightUpperLeg",   Part0 = "Pelvis",          Part1 = "RightUpperLeg",   C0 = CFrame.new(0.7883,-0.3693,-0.0149),  C1 = CFrame.new(0.0000,0.4622,-0.0754) },
{ Class = "Motor6D", Name = "RightMiddleLeg",  Part0 = "RightUpperLeg",   Part1 = "RightMiddleLeg",  C0 = CFrame.new(-0.0037,-0.4775,-0.0653), C1 = CFrame.new(0.0000,0.5376,-0.1509) },
{ Class = "Motor6D", Name = "RightLowerLeg",   Part0 = "RightMiddleLeg",  Part1 = "RightLowerLeg",   C0 = CFrame.new(0.0000,-0.5324,-0.1457),  C1 = CFrame.new(0.0000,0.5282,-0.1886) },
{ Class = "Motor6D", Name = "RightAnkle",      Part0 = "RightLowerLeg",   Part1 = "RightAnkle",      C0 = CFrame.new(0.0000,-0.5150,-0.2099),  C1 = CFrame.new(0.0000,0.3207,-0.2169) },
{ Class = "Motor6D", Name = "RightFoot",       Part0 = "RightAnkle",      Part1 = "RightFoot",       C0 = CFrame.new(0.0079,-0.2818,-0.2273),  C1 = CFrame.new(0.0000,0.2075,0.0660) },
{ Class = "Motor6D", Name = "LeftUpperLeg",    Part0 = "Pelvis",          Part1 = "LeftUpperLeg",    C0 = CFrame.new(-0.7883,-0.3693,-0.0149), C1 = CFrame.new(0.0000,0.4622,-0.0754) },
{ Class = "Motor6D", Name = "LeftMiddleLeg",   Part0 = "LeftUpperLeg",    Part1 = "LeftMiddleLeg",   C0 = CFrame.new(0.0037,-0.4775,-0.0653),  C1 = CFrame.new(0.0000,0.5376,-0.1509) },
{ Class = "Motor6D", Name = "LeftLowerLeg",    Part0 = "LeftMiddleLeg",   Part1 = "LeftLowerLeg",    C0 = CFrame.new(0.0000,-0.5324,-0.1457),  C1 = CFrame.new(0.0000,0.5282,-0.1886) },
{ Class = "Motor6D", Name = "LeftAnkle",       Part0 = "LeftLowerLeg",    Part1 = "LeftAnkle",       C0 = CFrame.new(0.0000,-0.5150,-0.2099),  C1 = CFrame.new(0.0000,0.3207,-0.2169) },
{ Class = "Motor6D", Name = "LeftFoot",        Part0 = "LeftAnkle",       Part1 = "LeftFoot",        C0 = CFrame.new(-0.0079,-0.2818,-0.2367), C1 = CFrame.new(0.0000,0.2075,0.0566) },
-- Точные Weld с C0/C1 из дампа (исправляют носки ботинок и подтяжки!)
{ Class = "Weld", Name = "PelvisLining",         Part0 = "Pelvis",          Part1 = "PelvisLining",         C0 = CFrame.new(0.0000,0.2329,-0.0039),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "LowerSuspenders",      Part0 = "LowerTorso",      Part1 = "LowerSuspenders",      C0 = CFrame.new(0.0000,0.1575,0.0113),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "SuspenderClips",       Part0 = "LowerTorso",      Part1 = "SuspenderClips",       C0 = CFrame.new(0.0000,-0.1309,0.0156), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "MiddleSuspenders",     Part0 = "MiddleTorso",     Part1 = "MiddleSuspenders",     C0 = CFrame.new(0.0000,-0.0544,0.0054), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "SuspenderJoint",       Part0 = "MiddleSuspenders",Part1 = "SuspenderJoint",       C0 = CFrame.new(0.0000,0.0242,0.1919),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "MiddleSuspenderRings", Part0 = "MiddleSuspenders",Part1 = "MiddleSuspenderRings", C0 = CFrame.new(0.0000,0.4230,0.2261),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "UpperSuspenders",      Part0 = "UpperTorso",      Part1 = "UpperSuspenders",      C0 = CFrame.new(0.0000,0.0960,0.0101),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "UpperSuspenderRings",  Part0 = "UpperSuspenders", Part1 = "UpperSuspenderRings",  C0 = CFrame.new(0.0000,-0.3083,-0.2474),C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "NeckCuff",             Part0 = "Neck",            Part1 = "NeckCuff",             C0 = CFrame.new(0.0000,-0.1138,0.0059), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "LeftElbowCuff",        Part0 = "LeftUpperArm",    Part1 = "LeftElbowCuff",        C0 = CFrame.new(-0.7459,0.0027,0.0000), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "LeftUpperWristLining", Part0 = "LeftUpperWrist",  Part1 = "LeftUpperWristLining", C0 = CFrame.new(-0.0266,0.2279,0.0000), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "LeftLowerWristLining", Part0 = "LeftLowerWrist",  Part1 = "LeftLowerWristLining", C0 = CFrame.new(0.2557,0.2944,0.0000),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "RightElbowCuff",       Part0 = "RightUpperArm",   Part1 = "RightElbowCuff",       C0 = CFrame.new(0.7459,0.0027,0.0000),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "RightUpperWristLining",Part0 = "RightUpperWrist", Part1 = "RightUpperWristLining",C0 = CFrame.new(0.0266,0.2279,0.0000),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "RightLowerWristLining",Part0 = "RightLowerWrist", Part1 = "RightLowerWristLining",C0 = CFrame.new(-0.2557,0.2944,0.0000), C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "LeftFootAccents",      Part0 = "RightFoot",       Part1 = "LeftFootAccents",      C0 = CFrame.new(0.0000,0.0138,0.2297),  C1 = CFrame.new(0,0,0) },
{ Class = "Weld", Name = "RightFootAccents",     Part0 = "LeftFoot",        Part1 = "RightFootAccents",     C0 = CFrame.new(0.0000,0.0138,0.2297),  C1 = CFrame.new(0,0,0) },
}
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
if data.MatVar == "Cashmere" and hasCashmere then
part.MaterialVariant = "Cashmere"
else
part.MaterialVariant = ""
end
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
-- Точные 5 эмиттеров чёрных пикселей на голове из дампа!
local function buildHeadParticles(headPart)
if not headPart then return end
local att = Instance.new("Attachment")
att.Name = "Attachment"
att.Parent = headPart
local blackCol = ColorSequence.new(Color3.fromRGB(0, 0, 0))
local solidTransp = NumberSequence.new(0)
local delayedTransp = NumberSequence.new({
NumberSequenceKeypoint.new(0.000, 1.000),
NumberSequenceKeypoint.new(0.578, 1.000),
NumberSequenceKeypoint.new(0.584, 0.000),
NumberSequenceKeypoint.new(1.000, 0.000),
})
local emitters = {
{ Name = "ParticleEmitter", Tex = "rbxassetid://135838365761108", Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.297, 0.472), NumberSequenceKeypoint.new(1, 1.297, 0.472) }), Life = NumberRange.new(1, 3), Speed = NumberRange.new(0, 0), Rate = 3.0, Drag = 1, Transp = solidTransp },
{ Name = "Sketches2",       Tex = "rbxassetid://107697998415989", Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.943, 0.825), NumberSequenceKeypoint.new(1, 0.943, 0.825) }), Life = NumberRange.new(0.1, 0.1), Speed = NumberRange.new(0, 0), Rate = 1.0, Drag = 1, Transp = solidTransp },
{ Name = "Sketches",        Tex = "rbxassetid://107697998415989", Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.943, 0.825), NumberSequenceKeypoint.new(1, 0.943, 0.825) }), Life = NumberRange.new(0.25, 0.25), Speed = NumberRange.new(0, 0), Rate = 3.0, Drag = 1, Transp = solidTransp },
{ Name = "Smaller2",        Tex = "rbxassetid://1195495135",      Size = NumberSequence.new(0.059), Life = NumberRange.new(2, 2), Speed = NumberRange.new(41.26, 41.26), Rate = 3.8, Drag = 40, Transp = delayedTransp },
{ Name = "Smaller",         Tex = "rbxassetid://1195495135",      Size = NumberSequence.new(0.236), Life = NumberRange.new(2, 2), Speed = NumberRange.new(41.26, 41.26), Rate = 3.0, Drag = 40, Transp = delayedTransp },
}
for _, cfg in ipairs(emitters) do
local pe = Instance.new("ParticleEmitter")
pe.Name = cfg.Name
pe.Texture = cfg.Tex
pe.Color = blackCol
pe.Size = cfg.Size
pe.Transparency = cfg.Transp
pe.Lifetime = cfg.Life
pe.Speed = cfg.Speed
pe.Rate = cfg.Rate
pe.Drag = cfg.Drag
pe.SpreadAngle = Vector2.new(360, 360)
pe.LockedToPart = true
pe.EmissionDirection = Enum.NormalId.Top
pe.Orientation = Enum.ParticleOrientation.FacingCamera
pe.LightInfluence = 0
pe.LightEmission = 0
pe.Parent = att
end
end
local function buildHonchoModel(variantName)
local model = Instance.new("Model")
model.Name = "Honcho_MemeClone"
model:SetAttribute("RootOffset", 6.35)
model:SetAttribute("NoTools", true)
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(1.8864, 1.8864, 0.9432)
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
local joint = Instance.new(j.Class)
joint.Name = j.Name
joint.Part0 = p0
joint.Part1 = p1
joint.C0 = j.C0
joint.C1 = j.C1
joint.Parent = p1
end
end
buildHeadParticles(parts.Head)
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HipHeight = 3.5
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