-- libs/CombatLib.lua
-- Контролируемый жёсткий нокаут с рэгдоллом, защитой от вылета за стены/потолок и авто-возвратом в комнату

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

    local launchVel = dir * (power or 75) + Vector3.new(0, 30, 0)

    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 50000
    bv.Velocity = launchVel
    bv.Parent = root

    root.AssemblyLinearVelocity = launchVel
    root.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-6, 6), math.random(-10, 10))

    task.delay(0.3, function()
        if bv and bv.Parent then bv:Destroy() end
    end)

    task.delay(1.3, function()
        if hum and hum.Parent and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- 3. Нокаут клона с рэгдоллом: эффектный отлёт внутри комнаты без вылета за карту
function CombatLib.ApplyRagdoll(clone, knockbackDir, power)
    if not clone then return nil end
    local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local startSafeCF = root.CFrame
    local lastValidFloorPos = startSafeCF.Position

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
            socket.UpperAngle = 60
            socket.TwistLowerAngle = -45
            socket.TwistUpperAngle = 45
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

    -- Сбалансированная мощь нокаута: клон красиво отлетает на 12-16 стадов и кувыркается, не пробивая стены
    local clampedPower = math.clamp(power or 58, 35, 65)
    local vel = dir * clampedPower + Vector3.new(0, 26, 0)
    local pitchRotSpeed = math.rad(-380)
    local curCF = root.CFrame
    local flying = true
    local hitWallCount = 0

    local flyConn = RunService.RenderStepped:Connect(function(dt)
        if not flying or not root or not root.Parent then return end
        local stepDt = math.min(dt, 0.033)

        vel = vel + Vector3.new(0, -78 * stepDt, 0)
        local moveDelta = vel * stepDt

        -- 1. Проверка потолка (чтобы апперкот не выбрасывал клона на крышу комнаты)
        if vel.Y > 0 then
            local ceilHit = workspace:Raycast(curCF.Position, Vector3.new(0, moveDelta.Y + 3.5, 0), rp)
            if ceilHit then
                vel = Vector3.new(vel.X * 0.6, -math.abs(vel.Y) * 0.3, vel.Z * 0.6)
                moveDelta = vel * stepDt
            end
        end

        -- 2. Объёмная проверка стен (Blockcast 2x3x2), чтобы не пролетал сквозь тонкие стены и двери DOORS
        local flatMove = Vector3.new(moveDelta.X, 0, moveDelta.Z)
        if flatMove.Magnitude > 0.005 then
            local wallHit = workspace:Blockcast(
                CFrame.new(curCF.Position + Vector3.new(0, 0.5, 0)),
                Vector3.new(2.2, 3.0, 2.2),
                flatMove.Unit * (flatMove.Magnitude + 1.8),
                rp
            )
            if wallHit then
                hitWallCount = hitWallCount + 1
                local n = wallHit.Normal * Vector3.new(1, 0, 1)
                if n.Magnitude > 0.01 then n = n.Unit else n = -flatMove.Unit end
                -- Отскакиваем от стены внутрь комнаты и гасим скорость
                vel = (vel - 2 * vel:Dot(n) * n) * 0.35
                if hitWallCount >= 2 then
                    vel = Vector3.new(0, vel.Y, 0)
                end
                moveDelta = vel * stepDt
            end
        end

        local nextPos = curCF.Position + moveDelta

        -- 3. Поиск пола strictly под текущим уровнем комнаты (от +6 стадов над клоном до -25 вниз)
        local floorHit = workspace:Raycast(Vector3.new(nextPos.X, nextPos.Y + 6, nextPos.Z), Vector3.new(0, -31, 0), rp)
        if floorHit then
            local floorY = floorHit.Position.Y + 1.1
            lastValidFloorPos = Vector3.new(nextPos.X, floorY, nextPos.Z)

            if nextPos.Y <= floorY and vel.Y <= 0 then
                nextPos = Vector3.new(nextPos.X, floorY, nextPos.Z)
                if vel.Y < -14 then
                    vel = Vector3.new(vel.X * 0.55, -vel.Y * 0.22, vel.Z * 0.55)
                else
                    vel = Vector3.new(vel.X * 0.78, 0, vel.Z * 0.78)
                    pitchRotSpeed = pitchRotSpeed * 0.7
                end
            end
        else
            -- Если впереди пропасть/пустота за пределами карты — тормозим горизонтальный полёт
            vel = Vector3.new(0, vel.Y, 0)
            nextPos = Vector3.new(curCF.Position.X, math.max(nextPos.Y, lastValidFloorPos.Y), curCF.Position.Z)
        end

        curCF = CFrame.new(nextPos) * curCF.Rotation * CFrame.Angles(pitchRotSpeed * stepDt, 0, 0)
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

        -- Финальная проверка, что точка приземления находится на полу в комнате, а не под картой
        local checkHit = workspace:Raycast(Vector3.new(curCF.Position.X, curCF.Position.Y + 8, curCF.Position.Z), Vector3.new(0, -30, 0), rp)
        if checkHit then
            return CFrame.new(curCF.Position.X, checkHit.Position.Y + 3.6, curCF.Position.Z)
        else
            return CFrame.new(lastValidFloorPos.X, lastValidFloorPos.Y + 2.5, lastValidFloorPos.Z)
        end
    end
end

-- 4. Отслеживает удар игрока (OnCooldown на BoxingGloves)
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