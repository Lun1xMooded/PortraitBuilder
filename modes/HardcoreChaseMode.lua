-- modes/HardcoreChaseMode.lua
-- Хардкорные догонялки [Q]: скорость (WalkSpeed - 3), нокаут 2 сек, медленное подкрадывание во время форы и точный пол для высоких ригов

return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local CombatLib = API.Import("libs/CombatLib.lua")

    local velocity = Vector3.zero
    local wasHiding = false
    local graceTimer = 0
    local ragdollTimer = 0
    local restoreFromRagdoll = nil
    local killTriggered = false
    local lastCountdownInt = -1
    local punchDisconnect = nil
    local comboIdx = 1

    local KILL_DISTANCE = 3.5
    local PUNCH_HIT_RANGE = 10.0
    local RETREAT_DISTANCE = 12
    local GRACE_SECONDS = 5.0
    local RAGDOLL_SECONDS = 2.0
    local CREEP_SPEED = 3.5

    local function getCloneOffset(clone)
        return (clone and clone:GetAttribute("RootOffset")) or 3.65
    end

    local function smoothLookCF(currentCF, pos, lookDir, dt)
        local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z)
        if flatDir.Magnitude < 0.05 then
            return CFrame.new(pos) * currentCF.Rotation
        end
        local targetRot = CFrame.lookAt(Vector3.zero, flatDir.Unit, Vector3.yAxis)
        return CFrame.new(pos) * currentCF.Rotation:Lerp(targetRot, math.clamp(dt * 12, 0, 1))
    end

    local function triggerKill(myChar, clonePos)
        if killTriggered then return end
        killTriggered = true
        print("[HardcoreChase] НОКАУТ ИГРОКА! Смертельный удар.")

        CombatLib.KnockbackPlayer(clonePos, 85)

        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            task.delay(0.15, function()
                if hum and hum.Parent then hum.Health = 0 end
            end)
        end
    end

    local function onPlayerBoxingPunch()
        if ragdollTimer > 0 or killTriggered then return end
        local clone = API.GetClone()
        local cloneCF = API.GetCFrame()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart)
        if not clone or not cloneCF or not myRoot then return end

        local toClone = (cloneCF.Position - myRoot.Position) * Vector3.new(1, 0, 1)
        if toClone.Magnitude <= PUNCH_HIT_RANGE then
            print("[HardcoreChase] НОКАУТ! Рэгдолл 2 сек -> фора 5 сек!")
            API.UpdateAnimation(0, false)
            velocity = Vector3.zero
            ragdollTimer = RAGDOLL_SECONDS
            restoreFromRagdoll = CombatLib.ApplyRagdoll(clone, toClone.Unit, 55)
        end
    end

    return {
        Name = "HardcoreChase",

        OnActivate = function()
            velocity = Vector3.zero
            wasHiding = false
            graceTimer = 0
            ragdollTimer = 0
            restoreFromRagdoll = nil
            killTriggered = false
            lastCountdownInt = -1
            comboIdx = 1

            if punchDisconnect then punchDisconnect() end
            punchDisconnect = CombatLib.BindPlayerPunch(onPlayerBoxingPunch)

            print("[HardcoreChase] Режим АКТИВИРОВАН! Скорость = твоя - 3.")
        end,

        OnDeactivate = function()
            if punchDisconnect then
                punchDisconnect()
                punchDisconnect = nil
            end
            if restoreFromRagdoll then
                restoreFromRagdoll()
                restoreFromRagdoll = nil
            end
            velocity = Vector3.zero
            graceTimer = 0
            ragdollTimer = 0
            killTriggered = false
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot)
            local myChar = LocalPlayer.Character
            local clone = API.GetClone()
            if not myChar or not myRoot or not clone then return end

            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                API.UpdateAnimation(0, false)
                return
            end

            local off = getCloneOffset(clone)

            -- 0. РЭГДОЛЛ 2 СЕКУНДЫ ПОСЛЕ НОКАУТА
            if ragdollTimer > 0 then
                ragdollTimer = math.max(0, ragdollTimer - dt)
                if ragdollTimer <= 0 and restoreFromRagdoll then
                    local landedCF = restoreFromRagdoll()
                    restoreFromRagdoll = nil
                    if landedCF then
                        local exactY = API.GetFloorY(landedCF.Position, landedCF.Position.Y + off, true, off)
                        local fixedPos = Vector3.new(landedCF.X, exactY, landedCF.Z)
                        local flatLook = Vector3.new(myRoot.Position.X, exactY, myRoot.Position.Z)
                        API.SetCFrame(CFrame.lookAt(fixedPos, flatLook, Vector3.yAxis))
                    end
                    graceTimer = GRACE_SECONDS
                    lastCountdownInt = -1
                    print("[HardcoreChase] Клон встал! Фора 5 секунд (медленно подкрадывается)...")
                end
                return
            end

            local isHiding = myChar:GetAttribute("Hiding") == true
            local flatToPlayer = Vector3.new(myRoot.Position.X - cloneCFrame.Position.X, 0, myRoot.Position.Z - cloneCFrame.Position.Z)
            local dist = flatToPlayer.Magnitude
            local dirToPlayer = (dist > 0.01) and flatToPlayer.Unit or cloneCFrame.LookVector

            -- 1. ИГРОК ПРЯЧЕТСЯ В ШКАФУ / ПОД КРОВАТЬЮ
            if isHiding then
                wasHiding = true
                graceTimer = 0
                lastCountdownInt = -1

                if dist < RETREAT_DISTANCE then
                    velocity = velocity:Lerp(-dirToPlayer * 7, math.clamp(dt * 6, 0, 1))
                    API.UpdateAnimation(velocity.Magnitude, false)
                    local nextPos = cloneCFrame.Position + velocity * dt
                    local floorY = API.GetFloorY(nextPos, cloneCFrame.Position.Y, false, off)
                    API.SetCFrame(smoothLookCF(cloneCFrame, Vector3.new(nextPos.X, floorY, nextPos.Z), dirToPlayer, dt))
                else
                    velocity = velocity:Lerp(Vector3.zero, math.clamp(dt * 8, 0, 1))
                    API.UpdateAnimation(0, false)
                    local floorY = API.GetFloorY(cloneCFrame.Position, cloneCFrame.Position.Y, false, off)
                    API.SetCFrame(smoothLookCF(cloneCFrame, Vector3.new(cloneCFrame.X, floorY, cloneCFrame.Z), dirToPlayer, dt))
                end
                return
            end

            -- 2. ФОРА 5 СЕКУНД
            if wasHiding then
                wasHiding = false
                graceTimer = GRACE_SECONDS
                velocity = Vector3.zero
                lastCountdownInt = -1
                print("[HardcoreChase] Ты вышел из укрытия! Фора 5 секунд...")
            end

            if graceTimer > 0 then
                graceTimer = math.max(0, graceTimer - dt)

                if dist > KILL_DISTANCE + 1.0 then
                    velocity = velocity:Lerp(dirToPlayer * CREEP_SPEED, math.clamp(dt * 6, 0, 1))
                    API.UpdateAnimation(velocity.Magnitude, false)
                    local nextPos = cloneCFrame.Position + velocity * dt
                    local floorY = API.GetFloorY(nextPos, cloneCFrame.Position.Y, false, off)
                    API.SetCFrame(smoothLookCF(cloneCFrame, Vector3.new(nextPos.X, floorY, nextPos.Z), velocity, dt))
                else
                    API.UpdateAnimation(0, false)
                end

                local secLeft = math.ceil(graceTimer)
                if secLeft ~= lastCountdownInt and secLeft > 0 then
                    lastCountdownInt = secLeft
                    print("[HardcoreChase] Фора:", secLeft .. " сек...")
                end
                if graceTimer <= 0 then
                    print("[HardcoreChase] Фора закончилась! Возврат на полную скорость!")
                end
                return
            end

            -- 3. АКТИВНАЯ ХАРДКОРНАЯ ПОГОНЯ
            local playerWalkSpeed = (hum.WalkSpeed > 1) and hum.WalkSpeed or 15
            local cloneSpeed = math.max(4, playerWalkSpeed - 3)

            if dist <= KILL_DISTANCE then
                comboIdx = CombatLib.PlayCloneSwing(clone, comboIdx)
                triggerKill(myChar, cloneCFrame.Position)
                return
            end

            velocity = velocity:Lerp(dirToPlayer * cloneSpeed, math.clamp(dt * 8, 0, 1))
            API.UpdateAnimation(velocity.Magnitude, cloneSpeed >= 16)

            local nextPos = cloneCFrame.Position + velocity * dt
            local floorY = API.GetFloorY(nextPos, cloneCFrame.Position.Y, false, off)
            API.SetCFrame(smoothLookCF(cloneCFrame, Vector3.new(nextPos.X, floorY, nextPos.Z), velocity, dt))
        end
    }
end
