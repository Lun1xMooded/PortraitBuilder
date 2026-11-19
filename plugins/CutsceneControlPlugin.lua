-- plugins/CutsceneControlPlugin.lua
-- Нативная свобода в катсценах DOORS через _G.m:
-- отдаёт поворот тела и ходьбу родному Movement DOORS (не трогает CFrame и BodyGyro!),
-- но подавляет stopcam/freemouse катсцен до caminit (94) и movement (100) и не мешает щитку/шкафам.

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
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

    local function getM()
        if _G.m and type(_G.m) == "table" then
            return _G.m
        end
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainUI = pgui and pgui:FindFirstChild("MainUI")
        local mgMod = mainUI and mainUI:FindFirstChild("Main_Game", true)
        if mgMod and mgMod:IsA("ModuleScript") then
            local ok, res = pcall(require, mgMod)
            if ok and type(res) == "table" then
                _G.m = res
                return res
            end
        end
        return nil
    end

    local function isBusyInGame(char, m)
        if char:GetAttribute("Hiding") == true then return true end
        if char:GetAttribute("InMinigame") == true then return true end
        if char:GetAttribute("SeatedInSeat") == true then return true end
        if m and (m.minigaming == true or m.camlock ~= nil or m.hiding == true) then return true end

        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainUI = pgui and pgui:FindFirstChild("MainUI")
        local backout = mainUI and mainUI:FindFirstChild("MinigameBackout")
        if backout and backout:IsA("GuiObject") and backout.Visible then
            return true
        end

        return false
    end

    local function stepCutsceneFreedom()
        if not enabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local m = getM()

        -- Если игрок решает щиток (MinigameBackout), прячется в шкафу (Hiding) или сидит — не вмешиваемся!
        if isBusyInGame(char, m) then
            return
        end

        -- 1. Включаем стандартный контроллер WASD
        if PlayerControls and not PlayerControls.enabled then
            PlayerControls:Enable()
        end

        -- 2. Снимаем флаги заморозки из _G.m (дальше родной Movement DOORS сам повернёт тело за камерой!)
        if m then
            if m.stopcam == true then m.stopcam = false end
            if m.freemouse == true then m.freemouse = false end
            if m.disableMovement == true then m.disableMovement = false end
            if m.incutscene == true then m.incutscene = false end
            if m.confusion == true then m.confusion = false end

            if m.hideplayers ~= 0 and not m.noclip then
                m.hideplayers = 0
                if type(m.update) == "function" then
                    pcall(m.update)
                end
            end
        end

        -- 3. Снимаем атрибуты заморозки с персонажа (но НЕ трогаем CollisionPart.CFrame и BodyGyro!)
        if char:GetAttribute("InCutscene") then char:SetAttribute("InCutscene", false) end
        if char:GetAttribute("RestrictMovement") then char:SetAttribute("RestrictMovement", false) end
        if char:GetAttribute("Animating") then char:SetAttribute("Animating", false) end
        if char:GetAttribute("AnimatingClient") then char:SetAttribute("AnimatingClient", false) end
        if char:GetAttribute("Confusion") then char:SetAttribute("Confusion", nil) end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.WalkSpeed == 0 then hum.WalkSpeed = 15 end
        end

        local col = char:FindFirstChild("CollisionPart")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if col and col.Anchored then col.Anchored = false end
        if hrp and hrp.Anchored then hrp.Anchored = false end

        -- 4. Возвращаем видимость другим игрокам
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:GetAttribute("CutsceneHidden") then
                p.Character:SetAttribute("CutsceneHidden", false)
            end
        end
    end

    local function setEnabled(state)
        enabled = state == true
        if enabled then
            -- Срабатывает на 94 (прямо перед caminit 95) и на 100 (прямо перед movement 101)
            RunService:BindToRenderStep("MemeActorCutscenePreCam", 94, stepCutsceneFreedom)
            RunService:BindToRenderStep("MemeActorCutscenePreMove", 100, stepCutsceneFreedom)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (родной поворот Movement + щиток и шкафы работают)")
        else
            RunService:UnbindFromRenderStep("MemeActorCutscenePreCam")
            RunService:UnbindFromRenderStep("MemeActorCutscenePreMove")
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
