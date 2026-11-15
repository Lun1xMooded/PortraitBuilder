-- libs/CombatLib.lua
-- Надёжный отлов удара BoxingGloves, анимация удара клона и физическое отбрасывание

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CombatLib = {}

local SWING_IDS = {
    "rbxassetid://122067211304895", -- swing1
    "rbxassetid://98472295325859",  -- swing2
}

-- 1. Удар клона перчатками (останавливаем мешающий idle-трек инструмента на время хука!)
function CombatLib.PlayCloneSwing(clone, comboIndex)
    if not clone then return 1 end
    local hum = clone:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return comboIndex or 1 end

    -- Временно глушим все Action-анимации (включая idle перчаток), чтобы хук прошёл на 100%
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
    track:Play(0.05, 1, 1.2)

    return (idx == 1) and 2 or 1
end

-- 2. Надёжное отбрасывание локального игрока (через BodyVelocity на CollisionPart, как в Movement DOORS)
function CombatLib.KnockbackPlayer(fromPos, power)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local dir = (root.Position - fromPos) * Vector3.new(1, 0, 1)
    dir = (dir.Magnitude > 0.01) and dir.Unit or -root.CFrame.LookVector

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(15000, 15000, 15000)
    bv.Velocity = dir * (power or 52) + Vector3.new(0, 18, 0)
    bv.Parent = root

    task.delay(0.28, function()
        if bv and bv.Parent then bv:Destroy() end
    end)
end

-- 3. Рэгдолл + гарантированный отлёт клона по физической дуге (не ломается из-за Anchored Root!)
function CombatLib.ApplyRagdoll(clone, knockbackDir, power, getFloorYFn)
    if not clone then return nil end
    local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local savedMotors = {}
    local tempRagdoll = {}

    -- Заменяем суставы на BallSocketConstraint, чтобы конечности болтались при полёте
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
            socket.UpperAngle = 50
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

    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") and part ~= root then
            part.Anchored = false
            part.CanCollide = false
        end
    end

    -- Управляемая баллистика отлёта клона назад (Root остаётся Anchored и летит по дуге без провалов под пол)
    root.Anchored = true
    local dir = (knockbackDir * Vector3.new(1, 0, 1))
    dir = (dir.Magnitude > 0.01) and dir.Unit or Vector3.new(0, 0, 1)

    local vel = dir * (power or 42) + Vector3.new(0, 22, 0)
    local rotSpeed = Vector3.new(math.rad(-260), math.rad(math.random(-90, 90)), math.rad(math.random(-120, 120)))
    local curCF = root.CFrame
    local flying = true

    local flyConn = RunService.RenderStepped:Connect(function(dt)
        if not flying or not root or not root.Parent then return end
        vel = vel + Vector3.new(0, -68 * dt, 0) -- гравитация
        local nextPos = curCF.Position + vel * dt

        local floorLimit = getFloorYFn and (getFloorYFn(nextPos, curCF.Position.Y, false) - 2.3) or (curCF.Position.Y - 2.3)
        if nextPos.Y <= floorLimit and vel.Y < 0 then
            nextPos = Vector3.new(nextPos.X, floorLimit, nextPos.Z)
            vel = Vector3.new(vel.X * 0.72, 0, vel.Z * 0.72) -- скольжение по полу после падения
            rotSpeed = rotSpeed * 0.6
        end

        curCF = CFrame.new(nextPos) * curCF.Rotation * CFrame.Angles(rotSpeed.X * dt, rotSpeed.Y * dt, rotSpeed.Z * dt)
        root.CFrame = curCF
    end)

    return function()
        flying = false
        if flyConn then flyConn:Disconnect() end
        if not clone or not clone.Parent then return nil end

        for _, inst in ipairs(tempRagdoll) do
            if inst and inst.Parent then inst:Destroy() end
        end

        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end

        root.Anchored = true
        for _, mInfo in ipairs(savedMotors) do
            if mInfo.motor and mInfo.parent then
                mInfo.motor.Parent = mInfo.parent
            end
        end

        return root.CFrame
    end
end

-- 4. Надёжный отлов удара игрока (проверяет OnCooldown на Tool + клик мышью с BoxingGloves в руках)
function CombatLib.BindPlayerPunch(onPunchCallback)
    local activeToolConn = nil
    local charAddedConn = nil
    local childAddedConn = nil
    local lastPunchTick = 0

    local function trigger()
        if os.clock() - lastPunchTick > 0.25 then
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
