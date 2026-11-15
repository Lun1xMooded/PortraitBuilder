-- libs/CombatLib.lua
-- Библиотека ударов BoxingGloves (swing1 / swing2), рэгдолл клона и откидывание игрока

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CombatLib = {}

local SWING_IDS = {
    "rbxassetid://122067211304895", -- swing1
    "rbxassetid://98472295325859",  -- swing2
}

function CombatLib.PlayCloneSwing(clone, comboIndex)
    if not clone then return 1 end

    local hum = clone:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return comboIndex or 1 end

    local idx = comboIndex or 1
    local anim = Instance.new("Animation")
    anim.AnimationId = SWING_IDS[idx]

    local track = animator:LoadAnimation(anim)
    track.Looped = false
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0.05, 1, 1.15)

    return (idx == 1) and 2 or 1
end

-- Откидывание и временное падение локального игрока без риска кика от RemoteEvent
function CombatLib.KnockbackPlayer(fromPos, power)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local dir = (root.Position - fromPos) * Vector3.new(1, 0, 1)
    dir = (dir.Magnitude > 0.01) and dir.Unit or -root.CFrame.LookVector

    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    root.AssemblyLinearVelocity = dir * (power or 48) + Vector3.new(0, 22, 0)
    root.AssemblyAngularVelocity = Vector3.new(math.random(-5, 5), math.random(-3, 3), math.random(-5, 5))

    task.delay(1.1, function()
        if hum and hum.Parent and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

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
            socket.UpperAngle = 45
            socket.TwistLowerAngle = -35
            socket.TwistUpperAngle = 35
            socket.Parent = desc.Part0

            table.insert(savedMotors, { motor = desc, parent = desc.Parent })
            table.insert(tempRagdoll, a0)
            table.insert(tempRagdoll, a1)
            table.insert(tempRagdoll, socket)

            desc.Parent = nil
        end
    end

    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            if part ~= root and not part:FindFirstAncestorOfClass("Tool") then
                part.CanCollide = true
            end
        end
    end

    local dir = (knockbackDir * Vector3.new(1, 0, 1))
    dir = (dir.Magnitude > 0.01) and dir.Unit or Vector3.new(0, 0, 1)
    local impulse = dir * (power or 60) + Vector3.new(0, 26, 0)

    root.AssemblyLinearVelocity = impulse
    root.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-4, 4), math.random(-6, 6))

    return function()
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

-- Отслеживает удар BoxingGloves по запуску анимаций swing1 / swing2 в Animator игрока
function CombatLib.BindPlayerPunch(onPunchCallback)
    local animConn = nil
    local charAddedConn = nil
    local lastPunchTick = 0

    local function hookChar(char)
        if animConn then
            animConn:Disconnect()
            animConn = nil
        end
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 5)
        local animator = hum and hum:WaitForChild("Animator", 5)
        if not animator then return end

        animConn = animator.AnimationPlayed:Connect(function(track)
            local id = track.Animation and track.Animation.AnimationId or ""
            if id:find("122067211304895") or id:find("98472295325859") then
                if os.clock() - lastPunchTick > 0.25 then
                    lastPunchTick = os.clock()
                    onPunchCallback()
                end
            end
        end)
    end

    hookChar(LocalPlayer.Character)
    charAddedConn = LocalPlayer.CharacterAdded:Connect(hookChar)

    return function()
        if animConn then animConn:Disconnect() end
        if charAddedConn then charAddedConn:Disconnect() end
    end
end

return CombatLib
