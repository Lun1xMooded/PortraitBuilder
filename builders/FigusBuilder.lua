-- builders/FigusBuilder.lua
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local FIGUS_PARTS = {
    -- Промежуточный корень Root (обязателен для иерархии HumanoidRootPart -> Root -> Torso!)
    ["Root"]           = { MeshId = "", Size = Vector3.new(2.0, 2.0, 1.0), Color = Color3.fromRGB(120, 82, 84), Mat = Enum.Material.SmoothPlastic, Transp = 1.00, CF = CFrame.new(0, 0, 0) },

    ["Torso"]          = { MeshId = "rbxassetid://10494023258", Size = Vector3.new(1.9891, 3.3459, 1.2096), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.0015, 0.0585, -0.0512) },
    ["RibCage"]        = { MeshId = "rbxassetid://10493991658", Size = Vector3.new(2.1772, 1.6896, 1.5890), Color = Color3.fromRGB(175, 155, 146), Mat = Enum.Material.Salt,  Transp = 0.00, CF = CFrame.new(0.0000, 0.5086, -0.0781, 1.0000, 0.0000, 0.0000, 0.0000, 0.9996, -0.0295, -0.0000, 0.0295, 0.9996) },
    ["LeftMiddleLeg"]  = { MeshId = "rbxassetid://10494026105", Size = Vector3.new(0.7077, 2.2821, 0.7260), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-0.4458, -3.6759, -0.0938) },
    ["Blister"]        = { MeshId = "rbxassetid://10494027006", Size = Vector3.new(0.1824, 1.0968, 0.2607), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(-0.3537, -3.8209, -0.4178) },
    ["Head"]           = { MeshId = "rbxassetid://10494022570", Size = Vector3.new(1.7143, 1.7005, 1.6019), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.0083, 2.2868, -0.2368) },
    ["Blisters"]       = { MeshId = "rbxassetid://10494023013", Size = Vector3.new(1.6170, 0.8067, 0.4763), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(0.0180, 2.2972, 0.0188) },
    ["Gums"]           = { MeshId = "rbxassetid://10494022876", Size = Vector3.new(1.3421, 1.1621, 0.4219), Color = Color3.fromRGB(131, 93, 80),   Mat = Enum.Material.Sand,  Transp = 0.00, CF = CFrame.new(-0.0209, 2.2652, -0.8048) },
    ["Veins"]          = { MeshId = "rbxassetid://10494023182", Size = Vector3.new(1.2128, 1.3620, 1.0061), Color = Color3.fromRGB(165, 113, 116), Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.0896, 2.3566, -0.3064) },
    ["Teeth"]          = { MeshId = "rbxassetid://10494022710", Size = Vector3.new(1.1802, 1.0273, 0.4487), Color = Color3.fromRGB(198, 175, 166), Mat = Enum.Material.Sand,  Transp = 0.00, CF = CFrame.new(-0.0043, 2.2686, -0.8299) },
    ["LeftUpperArm"]   = { MeshId = "rbxassetid://10494024471", Size = Vector3.new(2.8290, 0.6818, 0.7498), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-1.8829, 0.8898, -0.0343) },
    ["RightUpperArm"]  = { MeshId = "rbxassetid://10494024735", Size = Vector3.new(2.8290, 0.6820, 0.7500), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(1.8605, 0.8190, -0.1636) },
    ["Blister_2"]      = { MeshId = "rbxassetid://10494023534", Size = Vector3.new(0.8640, 0.2018, 0.1404), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(2.1527, 1.1078, -0.3055) },
    ["RightUpperLeg"]  = { MeshId = "rbxassetid://10494025881", Size = Vector3.new(0.8070, 1.5830, 0.7080), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.4030, -1.9566, -0.1069) },
    ["LeftUpperLeg"]   = { MeshId = "rbxassetid://10494025735", Size = Vector3.new(0.8073, 1.5830, 0.7078), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-0.3884, -2.0109, -0.0562) },
    ["Blister_3"]      = { MeshId = "rbxassetid://10494025608", Size = Vector3.new(0.1670, 0.8716, 0.1919), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(-0.6643, -1.9603, 0.0729) },
    ["LeftHand"]       = { MeshId = "rbxassetid://10494023744", Size = Vector3.new(1.2690, 1.0120, 0.9920), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-8.3011, 0.8927, 0.0112) },
    ["LeftLowerArm"]   = { MeshId = "rbxassetid://10494023932", Size = Vector3.new(2.5596, 0.6590, 0.8050), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-6.8074, 0.8991, 0.0183) },
    ["Blister_4"]      = { MeshId = "rbxassetid://10494024108", Size = Vector3.new(1.4987, 0.2127, 0.1603), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(-6.6816, 1.2121, 0.0040) },
    ["LeftMiddleArm"]  = { MeshId = "rbxassetid://10494024216", Size = Vector3.new(3.2218, 0.6757, 0.6518), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-4.3549, 0.9431, -0.0343) },
    ["Blister_5"]      = { MeshId = "rbxassetid://10494024341", Size = Vector3.new(1.0406, 0.2600, 0.1404), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(-4.5734, 0.6570, -0.0002) },
    ["RightHand"]      = { MeshId = "rbxassetid://10494025102", Size = Vector3.new(1.2690, 1.0120, 0.9920), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(8.3919, 0.8244, -0.2614) },
    ["RightLowerArm"]  = { MeshId = "rbxassetid://10494024975", Size = Vector3.new(2.5600, 0.6590, 0.8050), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(6.9524, 0.8309, -0.2414) },
    ["Blister_6"]      = { MeshId = "rbxassetid://10494025231", Size = Vector3.new(1.5837, 0.2244, 0.1483), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(6.8914, 1.1451, -0.2612) },
    ["RightMiddleArm"] = { MeshId = "rbxassetid://10494024868", Size = Vector3.new(3.2220, 0.6760, 0.6520), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(4.4366, 0.8566, -0.2090) },
    ["RightFoot"]      = { MeshId = "rbxassetid://10494026632", Size = Vector3.new(1.2780, 1.3380, 1.5920), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.3576, -6.6583, -0.1179) },
    ["RightLowerLeg"]  = { MeshId = "rbxassetid://10494026427", Size = Vector3.new(0.8800, 2.2010, 0.8800), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.3504, -5.4361, -0.1243) },
    ["Blister_7"]      = { MeshId = "rbxassetid://10494027198", Size = Vector3.new(0.1675, 1.6270, 0.1988), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(0.5729, -5.5593, 0.2319) },
    ["RightMiddleLeg"] = { MeshId = "rbxassetid://10494025972", Size = Vector3.new(0.7080, 2.2820, 0.7260), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(0.4091, -3.5007, -0.1619) },
    ["Blister_8"]      = { MeshId = "rbxassetid://10494027087", Size = Vector3.new(0.1715, 1.1167, 0.2324), Color = Color3.fromRGB(122, 106, 98),  Mat = Enum.Material.Foil,  Transp = 0.35, CF = CFrame.new(0.3921, -3.3343, -0.4694) },
    ["LeftFoot"]       = { MeshId = "rbxassetid://10494026794", Size = Vector3.new(1.2782, 1.3380, 1.5916), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-0.4982, -6.6843, -0.0617) },
    ["LeftLowerLeg"]   = { MeshId = "rbxassetid://10494026266", Size = Vector3.new(0.7142, 2.2312, 0.7314), Color = Color3.fromRGB(120, 82, 84),   Mat = Enum.Material.Slate, Transp = 0.00, CF = CFrame.new(-0.4782, -5.6263, -0.0681) },
}

-- Точная 3-уровневая иерархия из дампа: HumanoidRootPart (ActualRoot) -> Root -> Torso -> конечности!
local FIGUS_JOINTS = {
    { Name = "Root",           Part0 = "HumanoidRootPart", Part1 = "Root",           C0 = CFrame.new(0, 0, 0),                        C1 = CFrame.new(0, 0, 0) },
    { Name = "Torso",          Part0 = "Root",             Part1 = "Torso",          C0 = CFrame.new(0, 0, 0),                        C1 = CFrame.new(-0.0015, -0.0585, 0.0512) },
    { Name = "Head",           Part0 = "Torso",            Part1 = "Head",           C0 = CFrame.new(0.0069, 2.2283, -0.1856),        C1 = CFrame.new(0, 0, 0) },
    { Name = "LeftUpperArm",   Part0 = "Torso",            Part1 = "LeftUpperArm",   C0 = CFrame.new(-0.8844, 0.8313, 0.0170),       C1 = CFrame.new(1.0000, 0, 0) },
    { Name = "LeftMiddleArm",  Part0 = "LeftUpperArm",     Part1 = "LeftMiddleArm",  C0 = CFrame.new(-1.0220, 0.0533, 0),            C1 = CFrame.new(1.4500, 0, 0) },
    { Name = "LeftLowerArm",   Part0 = "LeftMiddleArm",    Part1 = "LeftLowerArm",   C0 = CFrame.new(-1.4525, -0.0439, 0.0526),      C1 = CFrame.new(1.0000, 0, 0) },
    { Name = "LeftHand",       Part0 = "LeftLowerArm",     Part1 = "LeftHand",       C0 = CFrame.new(-1.0937, -0.0065, -0.0071),     C1 = CFrame.new(0.4000, 0, 0) },
    { Name = "RightUpperArm",  Part0 = "Torso",            Part1 = "RightUpperArm",  C0 = CFrame.new(0.7091, 0.7605, -0.1123),       C1 = CFrame.new(-1.1500, 0, 0) },
    { Name = "RightMiddleArm", Part0 = "RightUpperArm",    Part1 = "RightMiddleArm", C0 = CFrame.new(1.2261, 0.0376, -0.0455),       C1 = CFrame.new(-1.3500, 0, 0) },
    { Name = "RightLowerArm",  Part0 = "RightMiddleArm",   Part1 = "RightLowerArm",  C0 = CFrame.new(1.4158, -0.0257, -0.0324),      C1 = CFrame.new(-1.1000, 0, 0) },
    { Name = "RightHand",      Part0 = "RightLowerArm",    Part1 = "RightHand",      C0 = CFrame.new(0.9895, -0.0065, -0.0200),      C1 = CFrame.new(-0.4500, 0, 0) },
    { Name = "LeftUpperLeg",   Part0 = "Torso",            Part1 = "LeftUpperLeg",   C0 = CFrame.new(-0.5292, -1.4694, -0.0049),     C1 = CFrame.new(-0.1393, 0.6000, 0) },
{ Name = "LeftMiddleLeg",  Part0 = "LeftUpperLeg",     Part1 = "LeftMiddleLeg",  C0 = CFrame.new(-0.0574, -0.6650, -0.0376),     C1 = CFrame.new(0, 1.0000, 0) },
{ Name = "LeftLowerLeg",   Part0 = "LeftMiddleLeg",    Part1 = "LeftLowerLeg",   C0 = CFrame.new(-0.0323, -0.9505, 0.0257),      C1 = CFrame.new(0, 1.0000, 0) },
{ Name = "LeftFoot",       Part0 = "LeftLowerLeg",     Part1 = "LeftFoot",       C0 = CFrame.new(-0.0201, -0.6580, 0.0064),      C1 = CFrame.new(0, 0.4000, 0) },
{ Name = "RightUpperLeg",  Part0 = "Torso",            Part1 = "RightUpperLeg",  C0 = CFrame.new(0.4015, -1.4651, -0.0557),      C1 = CFrame.new(0, 0.5500, 0) },
{ Name = "RightMiddleLeg", Part0 = "RightUpperLeg",    Part1 = "RightMiddleLeg", C0 = CFrame.new(0.0061, -0.5942, -0.0550),      C1 = CFrame.new(0, 0.9500, 0) },
{ Name = "RightLowerLeg",  Part0 = "RightMiddleLeg",   Part1 = "RightLowerLeg",  C0 = CFrame.new(-0.0587, -0.9853, 0.0376),      C1 = CFrame.new(0, 0.9500, 0) },
{ Name = "RightFoot",      Part0 = "RightLowerLeg",    Part1 = "RightFoot",      C0 = CFrame.new(0.0073, -0.8223, 0.0064),       C1 = CFrame.new(0, 0.4000, 0) },
}
local FIGUS_WELDS = {
{ Part0 = "Torso",          Part1 = "RibCage" },
{ Part0 = "Head",           Part1 = "Blisters" },
{ Part0 = "Head",           Part1 = "Gums" },
{ Part0 = "Head",           Part1 = "Veins" },
{ Part0 = "Head",           Part1 = "Teeth" },
{ Part0 = "LeftMiddleLeg",  Part1 = "Blister" },
{ Part0 = "RightUpperArm",  Part1 = "Blister_2" },
{ Part0 = "LeftUpperLeg",   Part1 = "Blister_3" },
{ Part0 = "LeftLowerArm",   Part1 = "Blister_4" },
{ Part0 = "LeftMiddleArm",  Part1 = "Blister_5" },
{ Part0 = "RightLowerArm",  Part1 = "Blister_6" },
{ Part0 = "RightLowerLeg",  Part1 = "Blister_7" },
{ Part0 = "RightMiddleLeg", Part1 = "Blister_8" },
}
local function createMeshPart(name, data)
local part = nil
if data.MeshId and data.MeshId ~= "" then
local ok, mp = pcall(function()
return InsertService:CreateMeshPartAsync(data.MeshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Automatic)
end)
if ok and mp then part = mp end
end
if not part then part = Instance.new("Part") end
part.Name = name
part.Size = data.Size
part.Color = data.Color
part.Material = data.Mat
part.MaterialVariant = ""
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
local function buildFigusModel()
local model = Instance.new("Model")
model.Name = "Figus_MemeClone"
model:SetAttribute("RootOffset", 7.15)
model:SetAttribute("NoTools", true)
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2.0, 2.0, 1.0)
hrp.Transparency = 1
hrp.CanCollide = false
hrp.CanTouch = false
hrp.CanQuery = false
hrp.Anchored = true
hrp.CFrame = CFrame.new(0, 0, 0)
hrp.Parent = model
model.PrimaryPart = hrp
local parts = { HumanoidRootPart = hrp }
for key, data in pairs(FIGUS_PARTS) do
local p = createMeshPart(key, data)
p.Parent = model
parts[key] = p
end
for _, j in ipairs(FIGUS_JOINTS) do
local p0 = parts[j.Part0]
local p1 = parts[j.Part1]
if p0 and p1 then
local motor = Instance.new("Motor6D")
motor.Name = j.Name
motor.Part0 = p0
motor.Part1 = p1
motor.C0 = j.C0
motor.C1 = j.C1
motor.Parent = p0
end
end
for _, w in ipairs(FIGUS_WELDS) do
local p0 = parts[w.Part0]
local p1 = parts[w.Part1]
if p0 and p1 then
local weld = Instance.new("Weld")
weld.Name = w.Part1 .. "Weld"
weld.Part0 = p0
weld.Part1 = p1
weld.C0 = p0.CFrame:ToObjectSpace(p1.CFrame)
weld.C1 = CFrame.new(0, 0, 0)
weld.Parent = p0
end
end
if parts.Head then
local mouthAtt = Instance.new("Attachment")
mouthAtt.Name = "MouthLight"
mouthAtt.Position = Vector3.new(0, -0.05, -0.6)
mouthAtt.Parent = parts.Head




local spot = Instance.new("SpotLight")
spot.Color = Color3.fromRGB(255, 200, 137)
spot.Range = 35.0
spot.Brightness = 1.6
spot.Angle = 65
spot.Face = Enum.NormalId.Front
spot.Parent = mouthAtt
end
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HipHeight = 5.15
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
addAnim("idle",   "rbxassetid://18539828651")
addAnim("walk",   "rbxassetid://18539834115")
addAnim("sprint", "rbxassetid://8465893113")
local stepSound = Instance.new("Sound")
stepSound.Name = "FigusFootstep"
stepSound.SoundId = "rbxassetid://8465836233"
stepSound.Volume = 0.45
stepSound.Parent = hrp
local lastPos = hrp.Position
local stepDist = 0
local stepConn
stepConn = RunService.Heartbeat:Connect(function()
if not model.Parent or not hrp.Parent then
if stepConn then stepConn:Disconnect() end
return
end
local curPos = hrp.Position
local moved = ((curPos - lastPos) * Vector3.new(1, 0, 1)).Magnitude
lastPos = curPos
if moved > 0.005 and moved < 5.0 then
stepDist = stepDist + moved
if stepDist >= 5.2 then
stepDist = 0
stepSound.PlaybackSpeed = 0.95 + math.random() * 0.15
stepSound:Play()
end
end
for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
if tr.WeightTarget <= 0.05 and tr.WeightCurrent > 0 then
tr:AdjustWeight(0, 0)
end
end
end)
return model
end
if type(getgenv) == "function" then
getgenv().BuildFigusRig = buildFigusModel
end
return buildFigusModel