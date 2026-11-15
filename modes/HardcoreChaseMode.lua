-- modes/HardcoreChaseMode.lua
-- Хардкорные догонялки [Q] + жёсткий нокаут перчатками BoxingGloves (для клона и игрока)

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
    local RAGDOLL_SECONDS = 2.4

    local function triggerKill(myChar, clonePos)
        if killTriggered then return end
        killTriggered = true
        print("[HardcoreChase] НОКАУТ ИГРОКА! Смертельный удар.")

        -- Жёстко отбрасываем игрока назад в полёт
        CombatLib.KnockbackPlayer(clonePos, 95)

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
            print("[HardcoreChase] ЖЁСТКИЙ НОКАУТ ПЕРЧАТКАМИ! Клон улетает в рэгдолл + фора 5 сек!")
            API.UpdateAnimation(0, false)
            velocity = Vector3.zero
            ragdollTimer = RAGDOLL_SECONDS
            restoreFromRagdoll = CombatLib.ApplyRagdoll(clone, toClone.Unit, 92)
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

            print("[HardcoreChase] Режим АКТИВИРОВАН! Скорость = твоя - 5. Бей BoxingGloves для жёсткого нокаута!")
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

        OnStep = function(dt, cloneCFrame, root, myRoot, refY)
            local myChar = LocalPlayer.Character
            if not myChar or not myRoot then return end

            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                API.UpdateAnimation(0, false)
                return
            end

            -- 0. КЛОН В ПОЛЁТЕ / РЭГДОЛЛЕ ПОСЛЕ НОКАУТА
            if ragdollTimer > 0 then
                ragdollTimer = math.max(0, ragdollTimer - dt)
                if ragdollTimer <= 0 and restoreFromRagdoll then
                    local landedCF = restoreFromRagdoll()
                    restoreFromRagdoll = nil
                    if landedCF then
                        local floorY = API.GetFloorY(landedCF.Position, landedCF.Position.Y + 5, true)
                        local flatLook = Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z)
                        API.SetCFrame(CFrame.lookAt(Vector3.new(landedCF.X, floorY, landedCF.Z), flatLook))
                    end
                    graceTimer = GRACE_SECONDS
                    lastCountdownInt = -1
                    print("[HardcoreChase] Клон встаёт после нокаута! Фора 5 секунд...")
                end
                return
            end

            local isHiding = myChar:GetAttribute("Hiding") == true
            local flatToPlayer = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
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
                    local floorY = API.GetFloorY(nextPos, refY, false)
                    local lookTarget = Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z)
                    API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), lookTarget))
                else
                    velocity = velocity:Lerp(Vector3.zero, math.clamp(dt * 8, 0, 1))
                    API.UpdateAnimation(0, false)
                    local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
                    API.SetCFrame(cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 6, 0, 1)))
                end
                return
            end

            -- 2. ФОРА 5 СЕКУНД ПОСЛЕ ВЫХОДА ИЗ ШКАФА
            if wasHiding then
                wasHiding = false
                graceTimer = GRACE_SECONDS
                velocity = Vector3.zero
                API.UpdateAnimation(0, false)
                print("[HardcoreChase] Ты вышел из укрытия! Фора 5 секунд...")
            end

            if graceTimer > 0 then
                graceTimer = math.max(0, graceTimer - dt)
                API.UpdateAnimation(0, false)
                local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
                API.SetCFrame(cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 4, 0, 1)))

                local secLeft = math.ceil(graceTimer)
                if secLeft ~= lastCountdownInt and secLeft > 0 then
                    lastCountdownInt = secLeft
                    print("[HardcoreChase] Фора:", secLeft .. " сек...")
                end
                return
            end

            -- 3. АКТИВНАЯ ХАРДКОРНАЯ ПОГОНЯ
            local playerWalkSpeed = hum.WalkSpeed or 15
            local cloneSpeed = math.max(3, playerWalkSpeed - 5)

            if dist <= KILL_DISTANCE then
                comboIdx = CombatLib.PlayCloneSwing(API.GetClone(), comboIdx)
                triggerKill(myChar, cloneCFrame.Position)
                return
            end

            velocity = velocity:Lerp(dirToPlayer * cloneSpeed, math.clamp(dt * 8, 0, 1))
            API.UpdateAnimation(velocity.Magnitude, cloneSpeed >= 16)

            local nextPos = cloneCFrame.Position + velocity * dt
            local floorY = API.GetFloorY(nextPos, refY, false)
            API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(nextPos.X + velocity.X, floorY, nextPos.Z + velocity.Z)))
        end
    }
end
