-- libs/CombatLib.lua
-- Библиотека анимаций ударов BoxingGloves (swing1 / swing2) и физического рэгдолла с отбрасыванием

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CombatLib = {}

local SWING_IDS = {
    "rbxassetid://122067211304895", -- swing1
    "rbxassetid://98472295325859",  -- swing2
}

-- Проигрывает удар swing1 / swing2 на клоне, если на нём надеты BoxingGloves
function CombatLib.PlayCloneSwing(clone, comboIndex)
    if not clone then return 1 end
    local tool = clone:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "BoxingGloves" then return comboIndex or 1 end

    local hum = clone:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return comboIndex or 1 end

    local idx = comboIndex or 1
    local anim = Instance.new("Animation")
    anim.AnimationId = SWING_IDS[idx]

    local track = animator:LoadAnimation(anim)
    track.Looped = false
    track.Priority = Enum.AnimationPriority.Action3
    track:Play(0.08, 1, 1.1)

    return (idx == 1) and 2 or 1
end

-- Включает настоящий рэгдолл (заменяет Motor6D на BallSocketConstraint) и отбрасывает клона назад
function CombatLib.ApplyRagdoll(clone, knockbackDir, power)
    if not clone then return end
    local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local savedMotors = {}
    local tempRagdoll = {}

    -- 1. Превращаем суставы Motor6D в гибкие BallSocketConstraint для реалистичного падения
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

    -- 2. Включаем физику и коллизию конечностей, отключаем якорь на Root
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            if part ~= root and not part:FindFirstAncestorOfClass("Tool") then
                part.CanCollide = true
            end
        end
    end

    -- 3. Задаём импульс отбрасывания назад и вверх
    local dir = (knockbackDir * Vector3.new(1, 0, 1))
    dir = (dir.Magnitude > 0.01) and dir.Unit or Vector3.new(0, 0, 1)
    local impulse = dir * (power or 55) + Vector3.new(0, 24, 0)

    root.AssemblyLinearVelocity = impulse
    root.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-4, 4), math.random(-6, 6))

    -- Возвращает функцию восстановления клона на ноги после рэгдолла
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

-- Подписка на удар BoxingGloves локального игрока
function CombatLib.BindPlayerPunch(onPunchCallback)
    local char = LocalPlayer.Character
    if not char then return nil end

    local activeToolConn = nil
    local function hookTool(tool)
        if activeToolConn then
            activeToolConn:Disconnect()
            activeToolConn = nil
        end
        if tool and tool:IsA("Tool") and tool.Name == "BoxingGloves" then
            activeToolConn = tool:GetAttributeChangedSignal("OnCooldown"):Connect(function()
                if tool:GetAttribute("OnCooldown") == true then
                    onPunchCallback()
                end
            end)
        end
    end

    hookTool(char:FindFirstChildOfClass("Tool"))
    local childConn = char.ChildAdded:Connect(hookTool)

    return function()
        if activeToolConn then activeToolConn:Disconnect() end
        if childConn then childConn:Disconnect() end
    end
end

return CombatLib
