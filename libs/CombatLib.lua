-- libs/CombatLib.lua
-- Жёсткий нокаут с рэгдоллом, баллистика с учётом перепадов высот DOORS и отлёт игрока

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

-- 2. Жёсткий нокаут и отлёт локального игрока назад
function CombatLib.KnockbackPlayer(fromPos, power)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local dir = (root.Position - fromPos) * Vector3.new(1, 0, 1)
    dir = (dir.Magnitude > 0.01) and dir.Unit or -root.CFrame.LookVector

    local launchVel = dir * (power or 85) + Vector3.new(0, 36, 0)

    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 50000
    bv.Velocity = launchVel
    bv.Parent = root

    root.AssemblyLinearVelocity = launchVel
    root.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-8, 8), math.random(-12, 12))

    task.delay(0.32, function()
        if bv and bv.Parent then bv:Destroy() end
    end)

    task.delay(1.3, function()
        if hum and hum.Parent and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- 3. Жёсткий нокаут клона: высокий подлёт, кувырки в воздухе, отскок от стен и защита от провала под карту
function CombatLib.ApplyRagdoll(clone, knockbackDir, power)
    if not clone then return nil end
    local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local savedMotors = {}
    local tempRagdoll = {}

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
            socket.UpperAngle = 65
            socket.TwistLowerAngle = -55
            socket.TwistUpperAngle = 55
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

    -- Настройка Raycast с учётом перепадов высот (лестницы, горки, разные уровни комнат DOORS)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.RespectCanCollide = true
    local ignoreList = { clone }
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(ignoreList, p.Character) end
    end
    rp.FilterDescendantsInstances = ignoreList

    root.Anchored = true
    local dir = (knockbackDir * Vector3.new(1, 0, 1))
    dir = (dir.Magnitude > 0.01) and dir.Unit or Vector3.new(0, 0, 1)

    -- Сочный апперкот: клон высоко подлетает и мощно улетает назад!
    local vel = dir * (power or 90) + Vector3.new(0, 42, 0)
    local rotSpeed = Vector3.new(math.rad(-480), math.rad(math.random(-180, 180)), math.rad(math.random(-240, 240)))
    local curCF = root.CFrame
    local flying = true

    local flyConn = RunService.RenderStepped:Connect(function(dt)
        if not flying or not root or not root.Parent then return end
        local stepDt = math.min(dt, 0.05)

        vel = vel + Vector3.new(0, -85 * stepDt, 0) -- сильная гравитация для резкого полёта
        local moveDelta = vel * stepDt

        -- 1. Проверка столкновения со стенами комнаты (чтобы не вылетал за карту)
        local flatMove = Vector3.new(moveDelta.X, 0, moveDelta.Z)
        if flatMove.Magnitude > 0.01 then
            local wallHit = workspace:Raycast(curCF.Position + Vector3.new(0, 1, 0), flatMove.Unit * (flatMove.Magnitude + 1.5), rp)
            if wallHit then
                -- Отскок от стены с потерей части скорости
                local n = wallHit.Normal
                vel = (vel - 2 * vel:Dot(n) * n) * 0.45
                moveDelta = vel * stepDt
            end
        end

        local nextPos = curCF.Position + moveDelta

        -- 2. Поиск пола сверху вниз (+18 стадов вверх до -100 вниз), чтобы ловить лестницы и перепады высот DOORS!
        local floorHit = workspace:Raycast(Vector3.new(nextPos.X, nextPos.Y + 18, nextPos.Z), Vector3.new(0, -118, 0), rp)
        local floorY = floorHit and (floorHit.Position.Y + 1.2) or (curCF.Position.Y - 2.0)

        if nextPos.Y <= floorY and vel.Y <= 0 then
            nextPos = Vector3.new(nextPos.X, floorY, nextPos.Z)
            -- Небольшой отскок от пола при первом ударе и скольжение
            if vel.Y < -18 then
                vel = Vector3.new(vel.X * 0.65, -vel.Y * 0.25, vel.Z * 0.65)
            else
                vel = Vector3.new(vel.X * 0.82, 0, vel.Z * 0.82)
                rotSpeed = rotSpeed * 0.75
            end
        end

        curCF = CFrame.new(nextPos) * curCF.Rotation * CFrame.Angles(rotSpeed.X * stepDt, rotSpeed.Y * stepDt, rotSpeed.Z * stepDt)
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

-- 4. Отслеживает удар игрока (OnCooldown на BoxingGloves + резерв по клику мыши)
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
