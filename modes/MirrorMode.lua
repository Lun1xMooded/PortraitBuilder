-- modes/MirrorMode.lua
-- Режим Зеркала [R] с точными поворотами таза/торса из Movement, без провалов и с синхроном руки+ключа

return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local MirrorLib  = API.Import("libs/MirrorLib.lua")
    local EffectsLib = API.Import("libs/EffectsLib.lua")

    local mirrorPlaneCF = nil
    local lastToolName = ""
    local stepAccum = 0
    local lastClonePos = nil
    local lockedFloorY = nil

    local smoothedSpeed = 0
    local smoothStrafeX = 0
    local sprintBlend = 0
    local armSyncPairs = {}

    local ARM_JOINTS = { RightShoulder = true, RightElbow = true, RightWrist = true }

    local function rebuildArmSync()
        table.clear(armSyncPairs)
        local myChar = LocalPlayer.Character
        local clone = API.GetClone()
        if not myChar or not clone then return end

        local srcMap = {}
        for _, d in ipairs(myChar:GetDescendants()) do
            if d:IsA("Motor6D") and ARM_JOINTS[d.Name] then
                srcMap[d.Name] = d
            end
        end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Motor6D") and ARM_JOINTS[d.Name] and srcMap[d.Name] then
                table.insert(armSyncPairs, { dst = d, src = srcMap[d.Name] })
            end
        end
    end

    return {
        Name = "Mirror",

        OnActivate = function()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart"))
            local cloneCF = API.GetCFrame()

            if myRoot and cloneCF then
                local midPos = (myRoot.Position + cloneCF.Position) * 0.5
                local normal = (myRoot.Position - cloneCF.Position) * Vector3.new(1, 0, 1)
                if normal.Magnitude < 0.01 then normal = -myRoot.CFrame.LookVector * Vector3.new(1, 0, 1) end
                mirrorPlaneCF = CFrame.lookAt(midPos, midPos + normal.Unit)
                lockedFloorY = cloneCF.Position.Y
            end

            API.AttachTool(true)
            lastToolName = (myChar and myChar:FindFirstChildOfClass("Tool") and myChar:FindFirstChildOfClass("Tool").Name) or ""
            rebuildArmSync()
            lastClonePos = cloneCF and cloneCF.Position or nil
            smoothedSpeed = 0
            smoothStrafeX = 0
            sprintBlend = 0
            stepAccum = 0
        end,

        OnDeactivate = function()
            mirrorPlaneCF = nil
            lockedFloorY = nil
            table.clear(armSyncPairs)
            API.SetCrouch(false)
            API.UpdateAnimation(0, false)
            API.AttachTool(false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot)
            local myChar = LocalPlayer.Character
            local realRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myRoot)
            if not realRoot or not mirrorPlaneCF then return end

            -- 1. Отражаем позицию и разворот, используя фиксированную высоту уровня пола (не проваливается при приседе!)
            local reflectedCF = MirrorLib.ReflectCFrame(mirrorPlaneCF, realRoot.CFrame)
            local floorY = API.GetFloorY(reflectedCF.Position, lockedFloorY or cloneCFrame.Position.Y, false)
            local newCF = CFrame.new(reflectedCF.X, floorY, reflectedCF.Z) * reflectedCF.Rotation
            API.SetCFrame(newCF)

            -- 2. Вычисляем скорость и направление стрейфа (влево/вправо)
            local movedVec = Vector3.zero
            if lastClonePos then
                movedVec = (newCF.Position - lastClonePos) * Vector3.new(1, 0, 1)
            end
            lastClonePos = newCF.Position

            local instantSpeed = (dt > 0) and (movedVec.Magnitude / dt) or 0
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            local moveMag = (hum and hum.MoveDirection.Magnitude > 0.05) and (hum.WalkSpeed or 14) or 0
            local targetSpeed = math.max(instantSpeed, moveMag)
            if targetSpeed < 0.5 then targetSpeed = 0 end
            smoothedSpeed = smoothedSpeed + (targetSpeed - smoothedSpeed) * math.clamp(dt * 12, 0, 1)

            local moveDir = (movedVec.Magnitude > 0.001) and movedVec.Unit or Vector3.zero
            local rawStrafe = newCF.RightVector:Dot(moveDir) * math.clamp(smoothedSpeed / 14, 0, 1)
            smoothStrafeX = smoothStrafeX + (rawStrafe - smoothStrafeX) * math.clamp(dt * 10, 0, 1)

            local playerCrouching = myChar:GetAttribute("Crouching") == true
            local playerSprinting = (myChar:GetAttribute("Sprinting") == true) or (smoothedSpeed > 16.5)
            sprintBlend = sprintBlend + ((playerSprinting and 1 or 0) - sprintBlend) * math.clamp(dt * 8, 0, 1)

            if API.IsCrouching() ~= playerCrouching then
                API.SetCrouch(playerCrouching)
            end
            API.UpdateAnimation(smoothedSpeed, playerSprinting)

            -- 3. Пыль из-под ног при ходьбе
            stepAccum = stepAccum + movedVec.Magnitude
            if stepAccum >= 4.5 then
                stepAccum = stepAccum - 4.5
                local clone = API.GetClone()
                local footAtt = clone and clone:FindFirstChild("Footsteps", true)
                if footAtt then EffectsLib.EmitAttachment(footAtt, 4) end
            end

            -- 4. Если взял ключ или другой предмет прямо во время режима зеркала
            local curTool = myChar:FindFirstChildOfClass("Tool")
            local curName = curTool and curTool.Name or ""
            if curName ~= lastToolName then
                lastToolName = curName
                API.AttachTool(true)
                rebuildArmSync()
            end
        end,

        OnStepped = function()
            local clone = API.GetClone()
            if not clone then return end

            -- 1. Точные встречные повороты таза и торса как в Movement DOORS (строки 1762-1772):
            -- Root поворачивается на -25° * X, Waist на +25° * X, плюс лёгкий наклон вперёд на бегу (-6°)
            local rootMotor = clone:FindFirstChild("Root", true)
            local waistMotor = clone:FindFirstChild("Waist", true)
            if rootMotor and rootMotor:IsA("Motor6D") then
                rootMotor.Transform = CFrame.Angles(math.rad(sprintBlend * -6), math.rad(smoothStrafeX * -25), 0) * rootMotor.Transform
            end
            if waistMotor and waistMotor:IsA("Motor6D") then
                waistMotor.Transform = CFrame.Angles(0, math.rad(smoothStrafeX * 25), 0) * waistMotor.Transform
            end

            -- 2. Если в руках есть предмет (ключ и др.), синхронизируем правую руку напрямую с рукой игрока,
            -- чтобы при осмотре (Inspect) и открывании двери рука двигалась вместе с ключом!
            if lastToolName ~= "" then
                for _, pair in ipairs(armSyncPairs) do
                    if pair.dst.Parent and pair.src.Parent then
                        pair.dst.Transform = pair.src.Transform
                    end
                end
            end
        end
    }
end