-- modes/MirrorMode.lua
-- Режим Зеркала [R]: наклоны корпуса + пост-анимационная рука + дебаг принты

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
    local armMirrorPairs = {}
    local lastDebugTick = 0

    local ARM_SWAP = {
        LeftShoulder = "RightShoulder",
        LeftElbow    = "RightElbow",
        LeftWrist    = "RightWrist",
    }

    local function rebuildArmMirror()
        table.clear(armMirrorPairs)
        local myChar = LocalPlayer.Character
        local clone = API.GetClone()
        if not myChar or not clone then
            warn("[MirrorDebug] rebuildArmMirror: нет myChar или clone!")
            return
        end

        local srcMap = {}
        for _, d in ipairs(myChar:GetDescendants()) do
            if d:IsA("Motor6D") and not d:FindFirstAncestorOfClass("Tool") then
                srcMap[d.Name] = d
            end
        end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Motor6D") and ARM_SWAP[d.Name] then
                local srcJoint = srcMap[ARM_SWAP[d.Name]]
                if srcJoint then
                    table.insert(armMirrorPairs, {
                        name = d.Name,
                        dst = d,
                        src = srcJoint
                    })
                else
                    warn("[MirrorDebug] Не найден сустав у игрока:", ARM_SWAP[d.Name])
                end
            end
        end
        print("[MirrorDebug] Найдено пар суставов руки:", #armMirrorPairs)
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

            API.AttachTool(true, true)
            lastToolName = (myChar and myChar:FindFirstChildOfClass("Tool") and myChar:FindFirstChildOfClass("Tool").Name) or ""
            print("[MirrorDebug] Активация MirrorMode! Предмет в руках:", lastToolName ~= "" and lastToolName or "ПУСТО")
            rebuildArmMirror()

            lastClonePos = cloneCF and cloneCF.Position or nil
            smoothedSpeed = 0
            smoothStrafeX = 0
            stepAccum = 0
            lastDebugTick = os.clock()
        end,

        OnDeactivate = function()
            mirrorPlaneCF = nil
            lockedFloorY = nil
            table.clear(armMirrorPairs)
            API.SetCrouch(false)
            API.UpdateAnimation(0, false)
            API.AttachTool(false, false)
            print("[MirrorDebug] MirrorMode выключен.")
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot)
            local myChar = LocalPlayer.Character
            local realRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myRoot)
            if not realRoot or not mirrorPlaneCF then return end

            local reflectedCF = MirrorLib.ReflectCFrame(mirrorPlaneCF, realRoot.CFrame)
            local floorY = API.GetFloorY(reflectedCF.Position, lockedFloorY or cloneCFrame.Position.Y, false)
            local newCF = CFrame.new(reflectedCF.X, floorY, reflectedCF.Z) * reflectedCF.Rotation
            API.SetCFrame(newCF)

            local movedVec = Vector3.zero
            if lastClonePos then
                movedVec = (newCF.Position - lastClonePos) * Vector3.new(1, 0, 1)
            end
            lastClonePos = newCF.Position

            local hum = myChar:FindFirstChildOfClass("Humanoid")
            local isMoving = hum and (hum.MoveDirection.Magnitude > 0.05) or (movedVec.Magnitude > 0.01)
            local targetSpeed = isMoving and (hum and hum.WalkSpeed or 15) or 0
            smoothedSpeed = smoothedSpeed + (targetSpeed - smoothedSpeed) * math.clamp(dt * 12, 0, 1)

            local playerCrouching = myChar:GetAttribute("Crouching") == true
            local playerSprinting = (not playerCrouching) and isMoving and (hum ~= nil and hum.WalkSpeed >= 19.5)

            if API.IsCrouching() ~= playerCrouching then
                API.SetCrouch(playerCrouching)
            end
            API.UpdateAnimation(smoothedSpeed, playerSprinting)

            local moveDir = (movedVec.Magnitude > 0.001) and movedVec.Unit or Vector3.zero
            local rawStrafe = newCF.RightVector:Dot(moveDir) * (isMoving and 1 or 0)
            smoothStrafeX = smoothStrafeX + (rawStrafe - smoothStrafeX) * math.clamp(dt * 10, 0, 1)

            stepAccum = stepAccum + movedVec.Magnitude
            if stepAccum >= 4.5 then
                stepAccum = stepAccum - 4.5
                local clone = API.GetClone()
                local footAtt = clone and clone:FindFirstChild("Footsteps", true)
                if footAtt then EffectsLib.EmitAttachment(footAtt, 4) end
            end

            local curTool = myChar:FindFirstChildOfClass("Tool")
            local curName = curTool and curTool.Name or ""
            if curName ~= lastToolName then
                lastToolName = curName
                print("[MirrorDebug] Смена предмета ->", lastToolName ~= "" and lastToolName or "УБРАН")
                API.AttachTool(true, true)
                rebuildArmMirror()
            end
        end,

        OnStepped = function()
            local clone = API.GetClone()
            if not clone then return end

            -- 1. Возвращены наклоны и встречный поворот корпуса при движении влево/вправо!
            if math.abs(smoothStrafeX) > 0.01 then
                local rootMotor = clone:FindFirstChild("Root", true)
                local waistMotor = clone:FindFirstChild("Waist", true)
                if rootMotor and rootMotor:IsA("Motor6D") then
                    rootMotor.Transform = rootMotor.Transform * CFrame.Angles(0, math.rad(smoothStrafeX * -22), math.rad(smoothStrafeX * -8))
                end
                if waistMotor and waistMotor:IsA("Motor6D") then
                    waistMotor.Transform = waistMotor.Transform * CFrame.Angles(0, math.rad(smoothStrafeX * 22), math.rad(smoothStrafeX * -6))
                end
            end

            -- 2. Зеркалим правую руку игрока в левую руку клона на Heartbeat (после Animator)
            if lastToolName ~= "" then
                for _, pair in ipairs(armMirrorPairs) do
                    if pair.dst.Parent and pair.src.Parent then
                        pair.dst.Transform = MirrorLib.MirrorTransform(pair.src.Transform)
                    end
                end
            end

            -- 3. Дебаг-принт раз в 2 секунды, чтобы видеть реальные углы руки игрока и клона
            if os.clock() - lastDebugTick >= 2 then
                lastDebugTick = os.clock()
                local pInfo = "нет пар"
                if #armMirrorPairs > 0 then
                    local sh = armMirrorPairs[1]
                    local rx, ry, rz = sh.src.Transform:ToEulerAnglesXYZ()
                    pInfo = string.format("%s src=(%.1f, %.1f, %.1f)", sh.name, math.deg(rx), math.deg(ry), math.deg(rz))
                end
                print(string.format("[MirrorDebug] Tool='%s' | Pairs=%d | %s | Strafe=%.2f", lastToolName, #armMirrorPairs, pInfo, smoothStrafeX))
            end
        end
    }
end