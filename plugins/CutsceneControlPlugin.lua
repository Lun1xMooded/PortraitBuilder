-- plugins/CutsceneControlPlugin.lua
-- Позволяет во время любых катсцен DOORS (все этажи и FloorReplicated) свободно ходить, крутить камерой и видеть игроков,
-- при этом сами 3D-анимации сущностей в катсценах продолжают проигрываться!

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
    local mainGameEnv = nil
    local charAttrConns = {}

    -- Находим таблицу Main_Game (Parent из RemoteListener) через getgc или require
    local function getMainGameTable()
        if mainGameEnv and type(mainGameEnv) == "table" and mainGameEnv.cam then
            return mainGameEnv
        end

        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainUI = pgui and pgui:FindFirstChild("MainUI")
        local mainGameMod = mainUI and mainUI:FindFirstChild("Main_Game", true)
        if mainGameMod and mainGameMod:IsA("ModuleScript") then
            local ok, res = pcall(require, mainGameMod)
            if ok and type(res) == "table" then
                mainGameEnv = res
                return res
            end
        end

        if getgc then
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "stopcam") ~= nil and rawget(v, "hideplayers") ~= nil and rawget(v, "cam") ~= nil then
                    mainGameEnv = v
                    return v
                end
            end
        end
        return nil
    end

    local function enforceFreedom()
        local mg = getMainGameTable()
        if mg then
            -- Возвращаем управление камерой игроку, но НЕ останавливаем 3D-анимации монстров/дверей в катсцене!
            if mg.stopcam == true then mg.stopcam = false end
            if mg.freemouse == true then mg.freemouse = false end
            if mg.hideplayers ~= 0 then
                mg.hideplayers = 0
                if type(mg.update) == "function" then
                    pcall(mg.update)
                end
            end
            if mg.camlock ~= nil then mg.camlock = nil end
            if mg.stunned == true then mg.stunned = false end
        end

        -- Разблокируем движение персонажа во время катсцены
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.WalkSpeed < 10 and not char:GetAttribute("Hiding") then
                hum.WalkSpeed = 15
            end
            if char:GetAttribute("Stunned") == true then
                char:SetAttribute("Stunned", false)
            end
            if char:GetAttribute("CantHoldItems") == true then
                char:SetAttribute("CantHoldItems", nil)
            end
        end
    end

    local function setEnabled(state)
        enabled = state == true
        if enabled then
            -- Приоритет 90 срабатывает прямо перед caminit DOORS (95), мгновенно отменяя блокировку камеры катсценой!
            RunService:BindToRenderStep("MemeActorCutsceneFreedom", 90, enforceFreedom)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (анимации катсцен играют, но камера, ходьба и игроки свободны!)")
        else
            RunService:UnbindFromRenderStep("MemeActorCutsceneFreedom")
            print("[CutsceneControl] Свобода в катсценах: ВЫКЛ (стандартные катсцены DOORS)")
        end
    end

    -- Регистрируем переключатель в едином ядре (MainEngine не трогаем!)
    API.RegisterState("CutsceneFreedom",
        function() return enabled end,
        function(v) setEnabled(v) end
    )

    API.OnCleanup(function()
        setEnabled(false)
        for _, c in ipairs(charAttrConns) do c:Disconnect() end
        table.clear(charAttrConns)
    end)
end
