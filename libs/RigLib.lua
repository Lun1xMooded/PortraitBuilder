-- libs/RigLib.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RigLib = {}
local currentAttachGen = 0

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

local function clearOldTools(clone, cachedToolSyncs)
    table.clear(cachedToolSyncs)
    if not clone then return end
    for _, oldTool in ipairs(clone:GetChildren()) do
        if oldTool:IsA("Tool") or oldTool.Name == "MirrorTool" then
            oldTool:Destroy()
        end
    end
    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Motor6D") and (desc.Name == "RightGrip" or desc.Name == "LeftGrip" or desc.Name == "Handle" or desc.Name == "LeftHandle") then
            desc:Destroy()
        end
    end
end

function RigLib.PlayToolTrack(clone, tracks, skipToolTrack)
    if not tracks then return end
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
    local fallbackAnim = nil

    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("Animation") and d.AnimationId ~= "" then
            local n = d.Name:lower()
            if (n:find("idle") or n:find("hold")) and not n:find("equip") then
                chosen = d
                break
            elseif not n:find("equip") and not n:find("use") and not n:find("swing") and not fallbackAnim then
                fallbackAnim = d
            end
        end
    end

    chosen = chosen or fallbackAnim
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

function RigLib.AttachTool(clone, isMirrored, isPortraitRig, MirrorLib, cachedToolSyncs, tracks, skipToolTrack)
    currentAttachGen = currentAttachGen + 1
    local myGen = currentAttachGen

    clearOldTools(clone, cachedToolSyncs)
    if not clone then return end

    local sourceChar = LocalPlayer.Character
    if not sourceChar then return end
    local sourceTool = sourceChar:FindFirstChildOfClass("Tool")
    if not sourceTool then return end

    local srcRightHand = sourceChar:FindFirstChild("RightHand") or sourceChar:FindFirstChild("Right Arm")
    local srcLeftHand  = sourceChar:FindFirstChild("LeftHand") or sourceChar:FindFirstChild("Left Arm")

    task.spawn(function()
        task.wait(0.12)
        if myGen ~= currentAttachGen or not clone.Parent or not sourceTool.Parent then return end

        local handDrivers = {}
        for _, desc in ipairs(sourceChar:GetDescendants()) do
            if (desc:IsA("Motor6D") or desc:IsA("AnimationConstraint")) and desc.Part0 and desc.Part1 then
                local isToolPart = desc.Part1:IsDescendantOf(sourceTool) or desc.Name == "Handle" or desc.Name == "LeftHandle"
                if isToolPart then
                    if desc.Part0 == srcRightHand then
                        table.insert(handDrivers, { side = "Right", motor = desc, partName = desc.Part1.Name })
                    elseif desc.Part0 == srcLeftHand then
                        table.insert(handDrivers, { side = "Left", motor = desc, partName = desc.Part1.Name })
                    end
                end
            end
        end

        clearOldTools(clone, cachedToolSyncs)

        local dstLeftHand  = clone:FindFirstChild("LeftHand") or clone:FindFirstChild("Left Arm")
        local dstRightHand = clone:FindFirstChild("RightHand") or clone:FindFirstChild("Right Arm")
        if not dstLeftHand or not dstRightHand then return end

        sourceTool.Archivable = true
        local clonedTool = sourceTool:Clone()
        sourceTool.Archivable = false
        if not clonedTool then return end

        local srcInnerMotors = {}
        for _, d in ipairs(sourceTool:GetDescendants()) do
            if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
                srcInnerMotors[d.Name] = d
            end
        end

        local toolParts = {}
        for _, d in ipairs(clonedTool:GetDescendants()) do
            if d:IsA("LocalScript") or d:IsA("Script") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.CanCollide, d.CanTouch, d.CanQuery, d.Massless, d.Anchored, d.LocalTransparencyModifier = false, false, false, true, false, 0
                toolParts[d.Name] = d
                if isMirrored and isPortraitRig then
                    d.Color = Color3.fromRGB(169, 167, 180)
                    d.Material = Enum.Material.Marble
                    d.MaterialVariant = "MarbleSlab"
                    if d:IsA("MeshPart") then d.TextureID = "" end
                end
            elseif d:IsA("Decal") then
                d.LocalTransparencyModifier = 0
            elseif (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and srcInnerMotors[d.Name] then
                table.insert(cachedToolSyncs, { dst = d, src = srcInnerMotors[d.Name], mirror = false })
            end
        end
        clonedTool.Parent = clone

        for _, desc in ipairs(clonedTool:GetDescendants()) do
            if desc:IsA("Motor6D") or desc:IsA("Weld") or desc:IsA("WeldConstraint") then
                if not desc.Part0 or not desc.Part0:IsDescendantOf(clonedTool) or not desc.Part1 or not desc.Part1:IsDescendantOf(clonedTool) then
                    desc:Destroy()
                end
            end
        end

        for _, drv in ipairs(handDrivers) do
            local targetPart = toolParts[drv.partName] or clonedTool:FindFirstChild(drv.partName, true)
            local targetHand = isMirrored
                and (drv.side == "Right" and dstLeftHand or dstRightHand)
                or  (drv.side == "Right" and dstRightHand or dstLeftHand)

            if targetPart and targetHand then
                local newJoint = Instance.new("Motor6D")
                newJoint.Name = drv.motor.Name
                newJoint.Part0 = targetHand
                newJoint.Part1 = targetPart
                newJoint.C0 = isMirrored and MirrorLib.MirrorJointCFrame(drv.motor.C0) or drv.motor.C0
                newJoint.C1 = isMirrored and MirrorLib.MirrorJointCFrame(drv.motor.C1) or drv.motor.C1
                newJoint.Parent = targetHand

                table.insert(cachedToolSyncs, {
                    dst = newJoint,
                    src = drv.motor,
                    mirror = isMirrored,
                    syncOffsets = true
                })
            end
        end

        -- Запускаем анимацию удержания предмета СТРОГО после того, как предмет прикрепился к руке!
        if tracks then
            RigLib.PlayToolTrack(clone, tracks, skipToolTrack)
        end
    end)
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
