-- plugins/CutsceneControlPlugin.lua
-- Полная свобода в катсценах DOORS: поворот тела + BodyGyro за камерой и полная совместимость со шкафами (Hiding)

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
    local MainGameState = nil
    local PlayerControls = nil

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

        -- Если игрок прячется в шкафу / под кроватью или сидит, НЕ вмешиваемся в камеру и camlock!
        local isHiding = char:GetAttribute("Hiding") == true
        local isSeated = char:GetAttribute("SeatedInSeat") == true

        if PlayerControls and not PlayerControls.enabled then
            PlayerControls:Enable()
        end

        local mg = findMainGame()
        if mg then
            mg.stopcam = false
            mg.freemouse = false
            mg.disableMovement = false
            mg.incutscene = false
            mg.confusion = false
            mg.chase = false
            mg.chaseMove = false

            -- Сбрасываем camlock ТОЛЬКО когда игрок НЕ в шкафу и НЕ сидит
            if not isHiding and not isSeated then
                mg.camlock = nil
            end

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

        if not isHiding and not isSeated then
            if hrp and hrp.Anchored then hrp.Anchored = false end
            if col and col.Anchored then col.Anchored = false end
        end

        if hum and hum.Health > 0 and not isHiding and not isSeated then
            hum.AutoRotate = false
            if hum.PlatformStand then hum.PlatformStand = false end
            local wantSprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and (hum.MoveDirection.Magnitude > 0.1)
            local targetSpeed = wantSprint and 24 or 15
            if hum.WalkSpeed < targetSpeed then
                hum.WalkSpeed = targetSpeed
            end
        end

        -- Поворачиваем и CollisionPart, и его BodyGyro за камерой (чтобы тело всегда крутилось синхронно с камерой!)
        local cam = workspace.CurrentCamera
        if cam and col and not (mg and mg.freecam) and not isHiding and not isSeated then
            local flatLook = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
            if flatLook.Magnitude > 0.01 then
                local lookCF = CFrame.lookAlong(col.Position, flatLook.Unit)
                col.CFrame = lookCF
                local gyro = col:FindFirstChildOfClass("BodyGyro")
                if gyro then
                    gyro.CFrame = lookCF.Rotation
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
            RunService:BindToRenderStep("MemeActorCutsceneUnlocker", 102, stepUnlocker)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (синхронный поворот тела + шкафы работают)")
        else
            RunService:UnbindFromRenderStep("MemeActorCutsceneUnlocker")
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
