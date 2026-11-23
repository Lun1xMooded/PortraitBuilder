-- modes/ReplayActorMode.lua
-- Запись и воспроизведение сцен через родное меню DoorsGuiBuilder (без влияния на Honcho и Figus)

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local SAMPLE_RATE = 1 / 30

    local Recordings = { {}, {}, {}, {} }
    local activeSlot = 1
    local state = "IDLE" -- "IDLE" | "RECORDING" | "PLAYING"
    local recordTimer = 0
    local playTime = 0
    local loopPlayback = false
    local playAllSlots = false

    local neckCache = {}

    local function isHighCustomRig(model)
        if not model then return false end
        return model:FindFirstChild("CustomAnimations") ~= nil
            or model.Name:find("Honcho") ~= nil
            or model.Name:find("Figus") ~= nil
    end

    local function getNeckMotor(model)
        if neckCache[model] ~= nil then
            return neckCache[model] or nil
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Motor6D") and d.Name == "Neck" then
                neckCache[model] = d
                return d
            end
        end
        neckCache[model] = false
        return nil
    end

    local function stopAll()
        state = "IDLE"
        playTime = 0
        for model, neck in pairs(neckCache) do
            if neck and neck.Parent and not isHighCustomRig(model) then
                neck.Transform = CFrame.new()
            end
        end
        API.UpdateAnimation(0, false)
    end

    -- Спавн клона сразу на первой точке записи при нажатии PLAY REPLAY, если клона ещё нет
    API.RegisterSpawnOverride("ReplayActor", function()
        local frames = Recordings[activeSlot]
        if frames and #frames > 0 then
            return frames.cf
        end
        return nil
    end)

    -- Регистрируем действия и переключатели для DoorsGuiBuilder
    API.RegisterAction("ReplayToggleRecord", function()
        if state == "RECORDING" then
            stopAll()
            print(string.format("[Replay] Запись в Слот #%d завершена (кадров: %d)", activeSlot, #Recordings[activeSlot]))
        else
            Recordings[activeSlot] = {}
            recordTimer = 0
            playTime = 0
            state = "RECORDING"
            print(string.format("[Replay] ● Идёт запись в Слот #%d...", activeSlot))
        end
    end)

    API.RegisterAction("ReplayNextSlot", function()
        if state ~= "IDLE" then stopAll() end
        activeSlot = (activeSlot % 4) + 1
        print(string.format("[Replay] Выбран Слот #%d (кадров: %d)", activeSlot, #Recordings[activeSlot]))
    end)

    API.RegisterAction("ReplayClearSlot", function()
        if state ~= "IDLE" then stopAll() end
        Recordings[activeSlot] = {}
        print(string.format("[Replay] Слот #%d очищен", activeSlot))
    end)

    API.RegisterState("ReplayLoop",
        function() return loopPlayback end,
        function(v) loopPlayback = v end
    )

    API.RegisterState("ReplayAllSlots",
        function() return playAllSlots end,
        function(v) playAllSlots = v end
    )

    -- Фоновая запись работает даже если клон ещё не заспавнен
    local recordConn = RunService.RenderStepped:Connect(function(dt)
        if state ~= "RECORDING" then return end

        playTime = playTime + dt
        recordTimer = recordTimer + dt

        if recordTimer >= SAMPLE_RATE then
            recordTimer = recordTimer - SAMPLE_RATE
            local char = LocalPlayer.Character
            local root = char and (char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera

            if root and hum then
                local floorY = API.GetFloorY(root.Position, root.Position.Y, false, 3.0)
                local jumpH = math.max(0, root.Position.Y - floorY)
                local horizVel = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
                local isCrouch = char:GetAttribute("Crouching") == true

                local lookDir = cam and cam.CFrame.LookVector or root.CFrame.LookVector
                local localLook = root.CFrame.Rotation:ToObjectSpace(CFrame.lookAt(Vector3.zero, lookDir))
                local pitch, yaw = localLook:ToEulerAnglesYXZ()
                pitch = math.clamp(pitch, math.rad(-60), math.rad(60))
                yaw = math.clamp(yaw, math.rad(-80), math.rad(80))

                table.insert(Recordings[activeSlot], {
                    t = playTime,
                    cf = root.CFrame,
                    jumpHeight = jumpH,
                    speed = horizVel,
                    sprint = (not isCrouch) and horizVel >= 18.5,
                    crouch = isCrouch,
                    pitch = pitch,
                    yaw = yaw,
                })
            end
        end
    end)

    API.OnCleanup(function()
        if recordConn then recordConn:Disconnect() end
    end)

    local function sampleTrack(frames, t)
        if #frames == 0 then return nil end
        if t <= frames.t then return frames end
        if t >= frames[#frames].t then return frames[#frames] end

        for i = 1, #frames - 1 do
            local a, b = frames[i], frames[i + 1]
            if t >= a.t and t <= b.t then
                local alpha = (t - a.t) / math.max(0.0001, b.t - a.t)
                return {
                    cf = a.cf:Lerp(b.cf, alpha),
                    jumpHeight = a.jumpHeight + (b.jumpHeight - a.jumpHeight) * alpha,
                    speed = a.speed + (b.speed - a.speed) * alpha,
                    sprint = b.sprint,
                    crouch = b.crouch,
                    pitch = a.pitch + (b.pitch - a.pitch) * alpha,
                    yaw = a.yaw + (b.yaw - a.yaw) * alpha,
                }
            end
        end
        return frames[#frames]
    end

    local function applyFrameToClone(entry, sample, dt)
        local model = entry.model
        if not model or not model.Parent or not sample then return end
        local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local off = model:GetAttribute("RootOffset") or 3.65
        local groundY = API.GetFloorY(sample.cf.Position, sample.cf.Position.Y + off, false, off)
        local finalY = groundY + sample.jumpHeight
        local newCF = CFrame.new(sample.cf.X, finalY, sample.cf.Z) * sample.cf.Rotation

        entry.cframe = newCF
        root.CFrame = newCF
        if model == API.GetClone() then
            API.SetCFrame(newCF)
        end

        -- Присед и поворот головы работают ТОЛЬКО на Portrait / LocalAvatar (Honcho и Figus не трогаем)
        if not isHighCustomRig(model) then
            if model == API.GetClone() and API.IsCrouching() ~= sample.crouch then
                API.SetCrouch(sample.crouch)
            end
            local neck = getNeckMotor(model)
            if neck and neck.Parent then
                local targetRot = neck.C1 * CFrame.fromEulerAnglesYXZ(sample.pitch, sample.yaw, 0) * neck.C1:Inverse()
                entry.replayNeckCF = entry.replayNeckCF and entry.replayNeckCF:Lerp(targetRot, math.clamp(dt * 15, 0, 1)) or targetRot
                neck.Transform = entry.replayNeckCF
            end
        end

        if model == API.GetClone() then
            API.UpdateAnimation(sample.speed, sample.sprint)
        end
    end

    return {
        Name = "ReplayActor",

        OnActivate = function()
            table.clear(neckCache)
            if #Recordings[activeSlot] < 2 and not playAllSlots then
                print("[Replay] Слот #" .. activeSlot .. " пуст! Нажми REC / STOP [F3] для записи.")
                return
            end
            playTime = 0
            state = "PLAYING"
            print("[Replay] ▶ Воспроизведение запущено!")
        end,

        OnDeactivate = function()
            stopAll()
        end,

        OnStep = function(dt)
            if state ~= "PLAYING" then return end

            playTime = playTime + dt
            local allClones = API.GetAllClones()
            local anyActive = false

            if playAllSlots and #allClones > 1 then
                for idx, entry in ipairs(allClones) do
                    local frames = Recordings[idx]
                    if frames and #frames > 1 then
                        local maxT = frames[#frames].t
                        local t = loopPlayback and (playTime % maxT) or playTime
                        if t <= maxT then anyActive = true end
                        local sample = sampleTrack(frames, math.min(t, maxT))
                        applyFrameToClone(entry, sample, dt)
                    end
                end
            else
                local frames = Recordings[activeSlot]
                if frames and #frames > 1 then
                    local maxT = frames[#frames].t
                    local t = loopPlayback and (playTime % maxT) or playTime
                    if t <= maxT then anyActive = true end
                    local sample = sampleTrack(frames, math.min(t, maxT))
                    local mainClone = API.GetClone()
                    for _, entry in ipairs(allClones) do
                        if entry.model == mainClone then
                            applyFrameToClone(entry, sample, dt)
                            break
                        end
                    end
                end
            end

            if not loopPlayback and not anyActive then
                stopAll()
                print("[Replay] Воспроизведение завершено.")
            end
        end
    }
end