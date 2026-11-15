-- modes/HardcoreChaseMode.lua
-- Режим хардкорных догонялок [J]: скорость (WalkSpeed - 5), отход при прятках в шкаф, фора 5 сек и смерть при касании

return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local velocity = Vector3.zero
    local wasHiding = false
    local graceTimer = 0
    local killTriggered = false
    local lastCountdownInt = -1

    local KILL_DISTANCE = 3.2
    local RETREAT_DISTANCE = 12
    local GRACE_SECONDS = 5.0

    local function triggerKill(myChar)
        if killTriggered then return end
        killTriggered = true
        print("[HardcoreChase] ПОЙМАН! Смертельный контакт.")

        -- Делаем локального персонажа смертным для обнуления HP
        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end

    return {
        Name = "HardcoreChase",

        OnActivate = function()
            velocity = Vector3.zero
            wasHiding = false
            graceTimer = 0
            killTriggered = false
            lastCountdownInt = -1
            print("[HardcoreChase] Режим АКТИВИРОВАН! Скорость клона = твоя скорость - 5. Прячься в шкаф при необходимости!")
        end,

        OnDeactivate = function()
            velocity = Vector3.zero
            graceTimer = 0
            killTriggered = false
            API.UpdateAnimation(0, false)
            print("[HardcoreChase] Режим остановлен.")
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY)
            local myChar = LocalPlayer.Character
            if not myChar or not myRoot then return end

            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                API.UpdateAnimation(0, false)
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

                -- Если клон слишком близко к шкафу — он отходит назад на безопасную дистанцию
                if dist < RETREAT_DISTANCE then
                    local retreatSpeed = 7
                    velocity = velocity:Lerp(-dirToPlayer * retreatSpeed, math.clamp(dt * 6, 0, 1))
                    API.UpdateAnimation(velocity.Magnitude, false)

                    local nextPos = cloneCFrame.Position + velocity * dt
                    local floorY = API.GetFloorY(nextPos, refY, false)
                    -- Отходит спиной или боком, но смотрит на шкаф
                    local lookTarget = Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z)
                    API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), lookTarget))
                else
                    -- Отошёл достаточно далеко — замирает и ждёт у шкафа
                    velocity = velocity:Lerp(Vector3.zero, math.clamp(dt * 8, 0, 1))
                    API.UpdateAnimation(0, false)
                    local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
                    API.SetCFrame(cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 6, 0, 1)))
                end
                return
            end

            -- 2. ИГРОК ТОЛЬКО ЧТО ВЫШЕЛ ИЗ ШКАФА -> ДАЁМ ФОРУ 5 СЕКУНД
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

                -- Медленно поворачивает голову/корпус в сторону игрока, пока идёт таймер форы
                local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
                API.SetCFrame(cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 4, 0, 1)))

                local secLeft = math.ceil(graceTimer)
                if secLeft ~= lastCountdownInt and secLeft > 0 then
                    lastCountdownInt = secLeft
                    print("[HardcoreChase] Фора:", secLeft .. " сек...")
                end
                if graceTimer <= 0 then
                    print("[HardcoreChase] Фора закончилась! Погоня возобновлена!")
                end
                return
            end

            -- 3. АКТИВНАЯ ХАРДКОРНАЯ ПОГОНЯ (Скорость = WalkSpeed игрока - 5)
            local playerWalkSpeed = hum.WalkSpeed or 15
            local cloneSpeed = math.max(3, playerWalkSpeed - 5)
            local isSprintingAnim = cloneSpeed >= 16

            -- Проверка на касание (смерть)
            if dist <= KILL_DISTANCE then
                triggerKill(myChar)
                return
            end

            velocity = velocity:Lerp(dirToPlayer * cloneSpeed, math.clamp(dt * 8, 0, 1))
            local spd = velocity.Magnitude
            API.UpdateAnimation(spd, isSprintingAnim)

            local nextPos = cloneCFrame.Position + velocity * dt
            local floorY = API.GetFloorY(nextPos, refY, false)
            local lookAtPos = Vector3.new(nextPos.X + velocity.X, floorY, nextPos.Z + velocity.Z)
            API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), lookAtPos))
        end
    }
end
