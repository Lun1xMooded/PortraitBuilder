-- libs/CombatLib.lua
-- Физический рэгдолл с CollisionGroup = "None" (как у мешей игрока в DOORS) + удар BoxingGloves

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CombatLib = {}

local SWING_IDS = {
    "rbxassetid://122067211304895", -- swing1
    "rbxassetid://98472295325859",  -- swing2
}

-- 1. Удар клона перчатками (перекрывает idle-стойку инструмента)
function CombatLib.PlayCloneSwing(clone, comboIndex)
    if not clone then return 1 end
    local hum = clone:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return comboIndex or 1 end

    for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
        if tr.Priority == Enum.AnimationPriority.Action4 or tr.Priority == Enum.AnimationPriority.Action3 then
            tr:Stop(0.05)
        end
    end

    local idx = comboIndex or 1
    local anim = Instance.new("Animation")
    anim.AnimationId = SWING_IDS[idx]

    local track = animator:LoadAnimation(anim)
    track.Looped = false
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0.05, 1, 1.25)

    return (idx == 1) and 2 or 1
end

-- 2. Жёсткое отбрасывание игрока при нокауте
function CombatLib.KnockbackPlayer(fromPos, power)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local dir = (root.Position - fromPos) * Vector3.new(1, 0, 1)
    dir = (dir.Magnitude > 0.01) and dir.Unit or -root.CFrame.LookVector

    local launchVel = dir * (power or 85) + Vector3.new(0, 32, 0)

    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 50000
    bv.Velocity = launchVel
    bv.Parent = root

    root.AssemblyLinearVelocity = launchVel
    root.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-6, 6), math.random(-10, 10))

    task.delay(0.32, function()
        if bv and bv.Parent then bv:Destroy() end
    end)

    task.delay(1.3, function()
        if hum and hum.Parent and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- 3. Физический рэгдолл клона: все руки, ноги и голова имеют CollisionGroup = "None" и лежат на полу
function CombatLib.ApplyRagdoll(clone, knockbackDir, power)
    if not clone then return nil end
    local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local startSafePos = root.Position
    local savedMotors = {}
    local tempRagdoll = {}

    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = true
    end

    -- Заменяем суставы Motor6D на BallSocketConstraint с естественными ограничениями углов
    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 and desc.Name ~= "Handle" and desc.Name ~= "LeftHandle" then
            local a0 = Instance.new("Attachment")
            a0.CFrame = desc.C0
            a0.Parent = desc.Part0

            local a1 = Instance.new("Attachment")
            a1.CFrame = desc.C1
            a1.Parent = desc.Part1

            local socket = Instance.new("BallSocketConstraint")
            socket.Attachment0 = a0
            socket.Attachment1 = a1
            socket.LimitsEnabled = true
            socket.TwistLimitsEnabled = true
            socket.UpperAngle = 55
            socket.TwistLowerAngle = -40
            socket.TwistUpperAngle = 40
            socket.Parent = desc.Part0

            table.insert(savedMotors, { motor = desc, parent = desc.Parent })
            table.insert(tempRagdoll, a0)
            table.insert(tempRagdoll, a1)
            table.insert(tempRagdoll, socket)

            desc.Parent = nil
        end
    end

    -- Включаем физику и CollisionGroup = "None" (как у мешей игрока в DOORS — твёрдо сталкивается с полом!)
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.Massless = false
            pcall(function() part.CollisionGroup = "None" end)
            if not part:FindFirstAncestorOfClass("Tool") and not part:FindFirstAncestorOfClass("Accessory") then
                part.CanCollide = true
            end
        end
    end

    local dir = (knockbackDir * Vector3.new(1, 0, 1))
    dir = (dir.Magnitude > 0.01) and dir.Unit or Vector3.new(0, 0, 1)

    local clampedPower = math.clamp(power or 58, 35, 68)
    local impulse = dir * clampedPower + Vector3.new(0, 28, 0)

    root.AssemblyLinearVelocity = impulse
    root.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-5, 5), math.random(-8, 8))

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.RespectCanCollide = true
    local ignoreList = { clone }
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(ignoreList, p.Character) end
    end
    rp.FilterDescendantsInstances = ignoreList

    -- Страховка от вылета за пределы карты или провала ниже уровня комнаты
    local guardConn = RunService.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        if (root.Position - startSafePos).Magnitude > 35 or root.Position.Y < startSafePos.Y - 12 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(startSafePos + Vector3.new(0, 2, 0))
        end
    end)

    return function()
        if guardConn then guardConn:Disconnect() end
        if not clone or not clone.Parent then return nil end

        local landedPos = root.Position

        for _, inst in ipairs(tempRagdoll) do
            if inst and inst.Parent then inst:Destroy() end
        end

        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Massless = true
                pcall(function() part.CollisionGroup = "None" end)
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end

        root.Anchored = true
        if hum then
            hum.PlatformStand = false
        end

        for _, mInfo in ipairs(savedMotors) do
            if mInfo.motor and mInfo.parent then
                mInfo.motor.Parent = mInfo.parent
            end
        end

        local checkHit = workspace:Raycast(Vector3.new(landedPos.X, landedPos.Y + 8, landedPos.Z), Vector3.new(0, -35, 0), rp)
        if checkHit then
            return CFrame.new(landedPos.X, checkHit.Position.Y + 3.6, landedPos.Z)
        else
            return CFrame.new(startSafePos.X, startSafePos.Y, startSafePos.Z)
        end
    end
end

-- 4. Отслеживание удара BoxingGloves локального игрока
function CombatLib.BindPlayerPunch(onPunchCallback)
    local activeToolConn = nil
    local charAddedConn = nil
    local childAddedConn = nil
    local lastPunchTick = 0

    local function trigger()
        if os.clock() - lastPunchTick > 0.22 then
            lastPunchTick = os.clock()
            onPunchCallback()
        end
    end

    local function hookTool(tool)
        if activeToolConn then
            activeToolConn:Disconnect()
            activeToolConn = nil
        end
        if tool and tool:IsA("Tool") and tool.Name == "BoxingGloves" then
            activeToolConn = tool:GetAttributeChangedSignal("OnCooldown"):Connect(function()
                if tool:GetAttribute("OnCooldown") == true then
                    trigger()
                end
            end)
        end
    end

    local function hookChar(char)
        if childAddedConn then childAddedConn:Disconnect() end
        if not char then return end
        hookTool(char:FindFirstChildOfClass("Tool"))
        childAddedConn = char.ChildAdded:Connect(hookTool)
    end

    hookChar(LocalPlayer.Character)
    charAddedConn = LocalPlayer.CharacterAdded:Connect(hookChar)

    return function()
        if activeToolConn then activeToolConn:Disconnect() end
        if childAddedConn then childAddedConn:Disconnect() end
        if charAddedConn then charAddedConn:Disconnect() end
    end
end

return CombatLib
