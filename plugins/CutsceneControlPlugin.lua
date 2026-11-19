-- plugins/CutsceneControlPlugin.lua
-- Чистая разблокировка катсцен DOORS: не ломает поворот тела (отдаёт поворот родному Movement DOORS)
-- и полностью уступает управление при открытии щитка (MinigameBackout) и шкафов (Hiding)!

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
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

    local function isInMinigameOrHiding(char, mg)
        if char:GetAttribute("Hiding") == true then return true end
        if char:GetAttribute("InMinigame") == true then return true end
        if char:GetAttribute("SeatedInSeat") == true then return true end
        if mg and (mg.minigaming == true or mg.camlock ~= nil) then return true end

        -- Проверка экрана щитка / пазлов (MainUI.MinigameBackout.Visible)
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainUI = pgui and pgui:FindFirstChild("MainUI")
        local backout = mainUI and mainUI:FindFirstChild("MinigameBackout")
        if backout and backout:IsA("GuiObject") and backout.Visible then
            return true
        end

        return false
    end

    local function stepUnlocker()
        if not enabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local mg = findMainGame()

        -- Если открыт щиток (MinigameBackout), шкаф (Hiding) или сиденье — полностью уступаем управление игре!
        if isInMinigameOrHiding(char, mg) then
            return
        end

        -- 1. Включаем контроллер WASD
        if PlayerControls and not PlayerControls.enabled then
            PlayerControls:Enable()
        end

        -- 2. Сбрасываем только флаги блокировки катсцены (сам Movement DOORS повернёт тело за камерой!)
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

        -- 3. Снимаем атрибуты заморозки с персонажа
        if char:GetAttribute("InCutscene") then char:SetAttribute("InCutscene", false) end
        if char:GetAttribute("RestrictMovement") then char:SetAttribute("RestrictMovement", false) end
        if char:GetAttribute("Animating") then char:SetAttribute("Animating", false) end
        if char:GetAttribute("AnimatingClient") then char:SetAttribute("AnimatingClient", false) end
        if char:GetAttribute("Confusion") then char:SetAttribute("Confusion", nil) end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = true
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
            -- Приоритет 100 срабатывает прямо перед родным movement (101) DOORS
            RunService:BindToRenderStep("MemeActorCutsceneUnlocker", 100, stepUnlocker)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (родной поворот тела + щиток и шкафы работают)")
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
