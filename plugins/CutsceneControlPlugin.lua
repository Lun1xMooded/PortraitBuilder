-- plugins/CutsceneControlPlugin.lua
-- Идеальная свобода в катсценах DOORS: жесткая синхронизация тела с камерой через BodyGyro + прямое движение от камеры

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
    local MainGameState = nil
    local PlayerControls = nil
    local hbConn = nil

    task.spawn(function()
        local ps = LocalPlayer:WaitForChild("PlayerScripts", 5)
        local pm = ps and ps:WaitForChild("PlayerModule", 5)
        if pm then
            local ok, mod = pcall(require, pm)
            if ok and mod and mod.GetControls then
                PlayerControls = mod:GetControls()
            end
        end
    end)

    local function findMainGame()
        if MainGameState and type(MainGameState) == "table" and MainGameState.cam then
            return MainGameState
        end
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainUI = pgui and pgui:FindFirstChild("MainUI")
        local mgMod = mainUI and mainUI:FindFirstChild("Main_Game", true)
        if mgMod and mgMod:IsA("ModuleScript") then
            local ok, res = pcall(require, mgMod)
            if ok and type(res) == "table" then
                MainGameState = res
                return res
            end
        end
        if type(getgc) == "function" then
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "stopcam") ~= nil and rawget(v, "hideplayers") ~= nil then
                    MainGameState = v
                    return v
                end
            end
        end
        return nil
    end

    local function hideFirstPersonHead(char)
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            head.LocalTransparencyModifier = 1
            for _, d in ipairs(head:GetDescendants()) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    d.LocalTransparencyModifier = 1
                end
            end
        end
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                local isHeadAcc = handle and (handle:FindFirstChild("HatAttachment") or handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("FaceFrontAttachment") or handle:FindFirstChild("FaceCenterAttachment"))
                if isHeadAcc and handle:IsA("BasePart") then
                    handle.LocalTransparencyModifier = 1
                end
            end
        end
    end

    local function stepUnlocker()
        if not enabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local mg = findMainGame()

        -- Уступаем управление игре при решении щитка (camlock / InMinigame), в шкафу (Hiding) или сидя
        local isInteracting = (char:GetAttribute("InMinigame") == true)
            or (char:GetAttribute("Hiding") == true)
            or (char:GetAttribute("SeatedInSeat") == true)
            or (mg and mg.camlock ~= nil)

        if isInteracting then
            return
        end

        if PlayerControls and not PlayerControls.enabled then
            PlayerControls:Enable()
        end

        if mg then
            if mg.stopcam == true then mg.stopcam = false end
            if mg.freemouse == true then mg.freemouse = false end
            if mg.disableMovement == true then mg.disableMovement = false end
            if mg.incutscene == true then mg.incutscene = false end
            if mg.confusion == true then mg.confusion = false end

            if mg.hideplayers and mg.hideplayers ~= 0 and not mg.noclip then
                mg.hideplayers = 0
                if type(mg.update) == "function" then
                    pcall(mg.update)
                end
            end
        end

        if char:GetAttribute("InCutscene") then char:SetAttribute("InCutscene", false) end
        if char:GetAttribute("RestrictMovement") then char:SetAttribute("RestrictMovement", false) end
        if char:GetAttribute("Animating") then char:SetAttribute("Animating", false) end
        if char:GetAttribute("AnimatingClient") then char:SetAttribute("AnimatingClient", false) end
        if char:GetAttribute("Confusion") then char:SetAttribute("Confusion", nil) end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local col = char:FindFirstChild("CollisionPart")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hrp and hrp.Anchored then hrp.Anchored = false end
        if col and col.Anchored then col.Anchored = false end

        local cam = workspace.CurrentCamera
        if cam and col and not (mg and mg.freecam) then
            local flatLook = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
            local flatRight = cam.CFrame.RightVector * Vector3.new(1, 0, 1)

            if flatLook.Magnitude > 0.01 then
                flatLook = flatLook.Unit
                flatRight = (flatRight.Magnitude > 0.01) and flatRight.Unit or Vector3.new(-flatLook.Z, 0, flatLook.X)

                local lookCF = CFrame.lookAlong(col.Position, flatLook)
                col.CFrame = lookCF
                if hrp then
                    hrp.CFrame = CFrame.new(hrp.Position) * lookCF.Rotation
                end

                -- Усиливаем BodyGyro, чтобы физика не крутила тело в другую сторону
                local gyro = col:FindFirstChildOfClass("BodyGyro")
                if gyro then
                    gyro.MaxTorque = Vector3.new(0, 400000, 0)
                    gyro.P = 25000
                    gyro.CFrame = lookCF.Rotation
                end

                -- Вычисляем чистый вектор ходьбы от камеры (W = строго вперёд по взгляду)
                if hum and hum.Health > 0 then
                    hum.AutoRotate = false
                    if hum.PlatformStand then hum.PlatformStand = false end

                    local mv = PlayerControls and PlayerControls:GetMoveVector() or Vector3.zero
                    if mv.Magnitude > 0.05 then
                        local worldDir = (flatRight * mv.X - flatLook * mv.Z)
                        if worldDir.Magnitude > 0.01 then
                            hum:Move(worldDir.Unit, false)
                        end
                    end

                    local wantSprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and (mv.Magnitude > 0.1)
                    local targetSpeed = wantSprint and 24 or 15
                    if hum.WalkSpeed < targetSpeed then
                        hum.WalkSpeed = targetSpeed
                    end
                end
            end
        end

        local head = char:FindFirstChild("Head")
        if cam and head and (cam.CFrame.Position - head.Position).Magnitude < 2.2 then
            hideFirstPersonHead(char)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:GetAttribute("CutsceneHidden") then
                p.Character:SetAttribute("CutsceneHidden", false)
            end
        end
    end

    local function setEnabled(state)
        enabled = state == true
        if enabled then
            RunService:BindToRenderStep("MemeActorCutscenePreCam", 94, stepUnlocker)
            RunService:BindToRenderStep("MemeActorCutscenePostMove", 102, stepUnlocker)
            if hbConn then hbConn:Disconnect() end
            hbConn = RunService.Heartbeat:Connect(stepUnlocker)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (усиленный BodyGyro + движение от камеры)")
        else
            RunService:UnbindFromRenderStep("MemeActorCutscenePreCam")
            RunService:UnbindFromRenderStep("MemeActorCutscenePostMove")
            if hbConn then hbConn:Disconnect(); hbConn = nil end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
            print("[CutsceneControl] Свобода в катсценах: ВЫКЛ")
        end
    end

    API.RegisterState("CutsceneFreedom",
        function() return enabled end,
        function(v) setEnabled(v) end
    )

    API.OnCleanup(function()
        setEnabled(false)
    end)
end
