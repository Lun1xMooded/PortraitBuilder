-- modes/MirrorMode.lua
-- Режим Зеркала [R]: плавный цикл ног, наклоны при движении влево/вправо, приседания и рука с предметом

return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local MirrorLib  = API.Import("libs/MirrorLib.lua")
    local EffectsLib = API.Import("libs/EffectsLib.lua")

    local mirrorPlaneCF = nil
    local lastToolName = ""
    local stepAccum = 0
    local lastClonePos = nil
    local baseGroundY = nil

    local smoothedSpeed = 0
    local currentTilt = 0

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
                baseGroundY = cloneCF.Position.Y
            end

            API.AttachTool(true)
            lastToolName = (myChar and myChar:FindFirstChildOfClass("Tool") and myChar:FindFirstChildOfClass("Tool").Name) or ""
            lastClonePos = cloneCF and cloneCF.Position or nil
            smoothedSpeed = 0
            currentTilt = 0
            stepAccum = 0
        end,

        OnDeactivate = function()
            mirrorPlaneCF = nil
            baseGroundY = nil
            smoothedSpeed = 0
            currentTilt = 0
            API.SetCrouch(false)
            API.UpdateAnimation(0, false)
            API.AttachTool(false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot)
            local myChar = LocalPlayer.Character
            local realRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myRoot)
            if not realRoot or not mirrorPlaneCF then return end

            -- 1. Отражаем позицию и разворот через плоскость зеркала
            local reflectedCF = MirrorLib.ReflectCFrame(mirrorPlaneCF, realRoot.CFrame)
            local refY = baseGroundY or cloneCFrame.Position.Y
            local floorY = API.GetFloorY(reflectedCF.Position, refY, false)
            baseGroundY = floorY

            local newCF = CFrame.new(reflectedCF.X, floorY, reflectedCF.Z) * reflectedCF.Rotation
            API.SetCFrame(newCF)

            -- 2. Вычисляем плавную скорость без обрывов цикла ног
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

            local playerCrouching = myChar:GetAttribute("Crouching") == true
            local playerSprinting = (myChar:GetAttribute("Sprinting") == true) or (smoothedSpeed > 16.5)

            if API.IsCrouching() ~= playerCrouching then
                API.SetCrouch(playerCrouching)
            end
            API.UpdateAnimation(smoothedSpeed, playerSprinting)

            -- 3. Считаем целевой наклон корпуса при движении влево/вправо
            local moveDir = (movedVec.Magnitude > 0.001) and movedVec.Unit or Vector3.zero
            local strafeAmount = newCF.RightVector:Dot(moveDir) * math.clamp(smoothedSpeed / 14, 0, 1)
            local targetTilt = math.rad(-strafeAmount * 14)
            currentTilt = currentTilt + (targetTilt - currentTilt) * math.clamp(dt * 10, 0, 1)

            -- 4. Пыль из-под ног при ходьбе
            stepAccum = stepAccum + movedVec.Magnitude
            if stepAccum >= 4.5 then
                stepAccum = stepAccum - 4.5
                local clone = API.GetClone()
                local footAtt = clone and clone:FindFirstChild("Footsteps", true)
                if footAtt then EffectsLib.EmitAttachment(footAtt, 4) end
            end

            -- 5. Синхронизация предмета
            local curTool = myChar:FindFirstChildOfClass("Tool")
            local curName = curTool and curTool.Name or ""
            if curName ~= lastToolName then
                lastToolName = curName
                API.AttachTool(true)
            end
        end,

        -- Наклоняем корпус поверх анимации на Stepped (до HeadLook!)
        OnStepped = function()
            if math.abs(currentTilt) < 0.002 then return end
            local clone = API.GetClone()
            local waist = clone and clone:FindFirstChild("Waist", true)
            if waist and waist:IsA("Motor6D") then
                waist.Transform = waist.Transform * CFrame.Angles(0, 0, currentTilt)
            end
        end
    }
end
