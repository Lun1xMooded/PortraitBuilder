-- libs/RigLib.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RigLib = {}

function RigLib.GetTargetPlayer(targetName)
    if targetName ~= "" and targetName ~= LocalPlayer.Name then
        local p = Players:FindFirstChild(targetName)
        if p and p.Character then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then return p end
    end
    return LocalPlayer
end

function RigLib.AttachTool(clone, isMirrored, isPortraitRig, MirrorLib, cachedToolSyncs)
    table.clear(cachedToolSyncs)
    if not clone then return end

    local sourceChar = LocalPlayer.Character
    for _, oldTool in ipairs(clone:GetChildren()) do
        if oldTool:IsA("Tool") or oldTool.Name == "MirrorTool" then oldTool:Destroy() end
    end
    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Motor6D") and (desc.Name == "RightGrip" or desc.Name == "LeftGrip" or desc.Name == "Handle") then
            desc:Destroy()
        end
    end

    if not sourceChar then return end
    local sourceTool = sourceChar:FindFirstChildOfClass("Tool")
    if not sourceTool then return end

    local targetHand = isMirrored
        and (clone:FindFirstChild("LeftHand") or clone:FindFirstChild("Left Arm"))
        or (clone:FindFirstChild("RightHand") or clone:FindFirstChild("Right Arm"))
    if not targetHand then return end

    local srcHandleMotor = nil
    for _, desc in ipairs(sourceChar:GetDescendants()) do
        if (desc:IsA("Motor6D") or desc:IsA("AnimationConstraint")) and (desc.Name == "Handle" or desc.Name == "RightGrip") then
            srcHandleMotor = desc
            break
        end
    end

    sourceTool.Archivable = true
    local clonedTool = sourceTool:Clone()
    sourceTool.Archivable = false
    if not clonedTool then return end

    local srcToolMotors = {}
    for _, d in ipairs(sourceTool:GetDescendants()) do
        if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then srcToolMotors[d.Name] = d end
    end

    for _, d in ipairs(clonedTool:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("Script") then d:Destroy()
        elseif d:IsA("BasePart") then
            d.CanCollide, d.CanTouch, d.CanQuery, d.Massless, d.Anchored, d.LocalTransparencyModifier = false, false, false, true, false, 0
            if isMirrored and isPortraitRig then
                d.Color = Color3.fromRGB(169, 167, 180)
                d.Material = Enum.Material.Marble
                d.MaterialVariant = "MarbleSlab"
                if d:IsA("MeshPart") then d.TextureID = "" end
            end
        elseif d:IsA("Decal") then d.LocalTransparencyModifier = 0
        elseif (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and srcToolMotors[d.Name] then
            table.insert(cachedToolSyncs, { dst = d, src = srcToolMotors[d.Name], mirror = isMirrored })
        end
    end
    clonedTool.Parent = clone

    local targetPart = clonedTool:FindFirstChild("Handle") or clonedTool:FindFirstChild("Main") or clonedTool:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return end

    -- Удаляем внешние сварки, которые держали предмет в руке оригинала (из-за них предмет мог зависать в воздухе)
    for _, desc in ipairs(clonedTool:GetDescendants()) do
        if desc:IsA("Motor6D") or desc:IsA("Weld") or desc:IsA("WeldConstraint") then
            if not desc.Part0 or not desc.Part0:IsDescendantOf(clonedTool) or not desc.Part1 or not desc.Part1:IsDescendantOf(clonedTool) then
                desc:Destroy()
            end
        end
    end

    if isMirrored and srcHandleMotor then
        targetPart.Anchored = true
        local gripOffset = sourceTool:GetAttribute("ToolGripOffset")
        local gripInv = (typeof(gripOffset) == "Vector3") and CFrame.new(gripOffset):Inverse() or nil
        table.insert(cachedToolSyncs, {
            isDriver = true,
            part = targetPart,
            hand = targetHand,
            src = srcHandleMotor,
            gripInv = gripInv
        })
        return
    end

    local newJoint = Instance.new("Motor6D")
    if srcHandleMotor then
        newJoint.Name = "Handle"
        newJoint.Part0 = targetHand
        newJoint.Part1 = targetPart
        newJoint.C0 = srcHandleMotor.C0
        newJoint.C1 = srcHandleMotor.C1
        table.insert(cachedToolSyncs, { dst = newJoint, src = srcHandleMotor, mirror = false })
    else
        newJoint.Name, newJoint.Part0, newJoint.Part1 = "Handle", targetHand, targetPart
        newJoint.C0 = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        newJoint.C1 = clonedTool.Grip
    end
    newJoint.Parent = targetHand
end

function RigLib.PlayToolTrack(clone, tracks, skipToolTrack)
    if tracks.tool then
        pcall(function() tracks.tool:Stop(0.1) end)
        tracks.tool = nil
    end
    if skipToolTrack then return end

    local humanoid = clone and clone:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    local tool = clone and clone:FindFirstChildOfClass("Tool")
    if not animator or not tool then return end

    local chosen = nil
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("Animation") and d.AnimationId ~= "" then
            local n = d.Name:lower()
            if (n:find("idle") or n:find("hold")) and not n:find("equip") then
                chosen = d
                break
            end
        end
    end
    if not chosen then
        chosen = Instance.new("Animation")
        chosen.AnimationId = "rbxassetid://507768375"
    end

    local tr = animator:LoadAnimation(chosen)
    tr.Looped = true
    tr.Priority = Enum.AnimationPriority.Action4
    tr:Play(0.1)
    tracks.tool = tr
end

function RigLib.SetupAnimations(clone, sourceChar)
    local tracks = { walk = nil, sprint = nil, idle = nil, crouch = nil, tool = nil }
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if not humanoid then return tracks end

    humanoid.PlatformStand = false
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

    local animSourceChar = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Animations")) and LocalPlayer.Character or sourceChar
    local animFolder = animSourceChar and animSourceChar:FindFirstChild("Animations")

    if animFolder then
        local function load(name, prio, looped)
            local a = animFolder:FindFirstChild(name)
            if a and a:IsA("Animation") then
                local t = animator:LoadAnimation(a)
                t.Looped, t.Priority = looped, prio
                return t
            end
            return nil
        end
        tracks.idle   = load("Idle", Enum.AnimationPriority.Idle, true)
        tracks.walk   = load("Forward", Enum.AnimationPriority.Movement, true)
        tracks.sprint = load("Sprinting", Enum.AnimationPriority.Movement, true)
        tracks.crouch = load("Crouch", Enum.AnimationPriority.Action, true)
    end

    if not tracks.walk then
        local fb = Instance.new("Animation")
        fb.AnimationId = "rbxassetid://913376220"
        tracks.walk = animator:LoadAnimation(fb)
        tracks.walk.Looped, tracks.walk.Priority = true, Enum.AnimationPriority.Movement
    end

    if tracks.idle then tracks.idle:Play(0.1, 1, 0.75) end
    if tracks.walk then tracks.walk:Play(0.1, 0.001, 0.01) end
    if tracks.sprint then tracks.sprint:Play(0.1, 0.001, 0.01) end

    RigLib.PlayToolTrack(clone, tracks, false)
    return tracks
end

return RigLib
