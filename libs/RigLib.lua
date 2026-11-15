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

function RigLib.AttachTool(clone, isMirrored, isPortraitRig, MirrorLib, cachedToolSyncs)
    currentAttachGen = currentAttachGen + 1
    local myGen = currentAttachGen

    clearOldTools(clone, cachedToolSyncs)
    if not clone then return end

    local sourceChar = LocalPlayer.Character
    if not sourceChar then return end
    local sourceTool = sourceChar:FindFirstChildOfClass("Tool")
    if not sourceTool then return end

    task.spawn(function()
        -- Ждём появления хотя бы одного мотора хвата (Handle или LeftHandle)
        local srcMotors = {}
        for _ = 1, 30 do
            if myGen ~= currentAttachGen or not clone.Parent or not sourceTool.Parent then return end
            table.clear(srcMotors)
            for _, desc in ipairs(sourceChar:GetDescendants()) do
                if (desc:IsA("Motor6D") or desc:IsA("AnimationConstraint")) then
                    if desc.Name == "Handle" or desc.Name == "RightGrip" then
                        srcMotors.Handle = desc
                    elseif desc.Name == "LeftHandle" or desc.Name == "LeftGrip" then
                        srcMotors.LeftHandle = desc
                    end
                end
            end
            if srcMotors.Handle or srcMotors.LeftHandle then break end
            task.wait()
        end

        if myGen ~= currentAttachGen or not clone.Parent or not sourceTool.Parent then return end
        clearOldTools(clone, cachedToolSyncs)

        local leftHand  = clone:FindFirstChild("LeftHand") or clone:FindFirstChild("Left Arm")
        local rightHand = clone:FindFirstChild("RightHand") or clone:FindFirstChild("Right Arm")
        if not leftHand or not rightHand then return end

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
                table.insert(cachedToolSyncs, { dst = d, src = srcInnerMotors[d.Name], mirror = isMirrored })
            end
        end
        clonedTool.Parent = clone

        -- Удаляем внешние сварки, оставшиеся от оригинального персонажа
        for _, desc in ipairs(clonedTool:GetDescendants()) do
            if desc:IsA("Motor6D") or desc:IsA("Weld") or desc:IsA("WeldConstraint") then
                if not desc.Part0 or not desc.Part0:IsDescendantOf(clonedTool) or not desc.Part1 or not desc.Part1:IsDescendantOf(clonedTool) then
                    desc:Destroy()
                end
            end
        end

        -- Режим Зеркала (1:1 PortraitTwinTool с поддержкой Handle в левой руке и LeftHandle в правой)
        if isMirrored and (srcMotors.Handle or srcMotors.LeftHandle) then
            local gripOffset = sourceTool:GetAttribute("ToolGripOffset")
            local gripInv = (typeof(gripOffset) == "Vector3") and CFrame.new(gripOffset):Inverse() or nil

            local driverConfigs = {
                { key = "Handle",     hand = leftHand,  part = toolParts.Handle or toolParts.Main or clonedTool:FindFirstChildWhichIsA("BasePart") },
                { key = "LeftHandle", hand = rightHand, part = toolParts.LeftHandle },
            }

            for _, cfg in ipairs(driverConfigs) do
                local srcM = srcMotors[cfg.key]
                if srcM and cfg.part and cfg.hand then
                    cfg.part.Anchored = true
                    table.insert(cachedToolSyncs, {
                        isDriver = true,
                        part = cfg.part,
                        hand = cfg.hand,
                        src = srcM,
                        gripInv = (cfg.key == "Handle") and gripInv or nil
                    })
                end
            end
            return
        end

        -- Обычный режим (правая рука)
        local targetPart = toolParts.Handle or toolParts.Main or clonedTool:FindFirstChildWhichIsA("BasePart")
        if not targetPart then return end

        local newJoint = Instance.new("Motor6D")
        if srcMotors.Handle then
            newJoint.Name, newJoint.Part0, newJoint.Part1 = "Handle", rightHand, targetPart
            newJoint.C0, newJoint.C1 = srcMotors.Handle.C0, srcMotors.Handle.C1
            table.insert(cachedToolSyncs, { dst = newJoint, src = srcMotors.Handle, mirror = false })
        else
            newJoint.Name, newJoint.Part0, newJoint.Part1 = "Handle", rightHand, targetPart
            newJoint.C0 = CFrame.new(0, -0.15, 0)
            newJoint.C1 = clonedTool.Grip
        end
        newJoint.Parent = rightHand
    end)
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
