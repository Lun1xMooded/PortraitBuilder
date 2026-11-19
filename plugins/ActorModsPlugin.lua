-- plugins/ActorModsPlugin.lua
-- Глобальная кастомизация поведения Portrait поверх ЛЮБОГО режима:
-- кастомная скорость, нокауты в любом режиме, триггер открытия двери, скример-исчезновение и бинды F1 / F2

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local CombatLib = API.Import("libs/CombatLib.lua")

    local baseWalk = API.Config.WalkSpeed or 14
    local baseSprint = API.Config.SprintSpeed or 24

    local Mods = {
        UseCustomSpeed = false,
        CustomSpeed = 48,
        AutoKnockout = false,
        KnockoutPower = 85,
        AlwaysGloves = false,
        VanishOnHit = false,
        KeyPathRun = Enum.KeyCode.F1,
        KeyAmbushRush = Enum.KeyCode.F2,
    }

    local Sliders = {
        CustomSpeed   = { get = function() return Mods.CustomSpeed end,   set = function(v) Mods.CustomSpeed = v end },
        KnockoutPower = { get = function() return Mods.KnockoutPower end, set = function(v) Mods.KnockoutPower = v end },
    }
    local Keybinds = {
        KeyPathRun    = { get = function() return Mods.KeyPathRun end,    set = function(k) Mods.KeyPathRun = k end },
        KeyAmbushRush = { get = function() return Mods.KeyAmbushRush end, set = function(k) Mods.KeyAmbushRush = k end },
    }

    getgenv().MemeCustomSliders = Sliders
    getgenv().MemeCustomKeybinds = Keybinds

    API.RegisterState("UseCustomSpeed", function() return Mods.UseCustomSpeed end, function(v)
        Mods.UseCustomSpeed = v
        if not v then
            API.Config.WalkSpeed = baseWalk
            API.Config.SprintSpeed = baseSprint
        end
    end)
    API.RegisterState("AutoKnockout", function() return Mods.AutoKnockout end, function(v) Mods.AutoKnockout = v end)
    API.RegisterState("AlwaysGloves", function() return Mods.AlwaysGloves end, function(v)
        Mods.AlwaysGloves = v
        if v and API.GetClone() then API.AttachTool(false, false) end
    end)
    API.RegisterState("VanishOnHit", function() return Mods.VanishOnHit end, function(v) Mods.VanishOnHit = v end)

    local lastHitTick = 0

    -- Фоновый цикл: применяет кастомную скорость к любому режиму и проверяет авто-нокаут при сближении
    local stepConn = RunService.Heartbeat:Connect(function()
        if Mods.UseCustomSpeed then
            API.Config.WalkSpeed = Mods.CustomSpeed
            API.Config.SprintSpeed = Mods.CustomSpeed
        end

        local clone = API.GetClone()
        if not clone or not clone.Parent then return end

        if Mods.AlwaysGloves and not clone:FindFirstChildOfClass("Tool") then
            API.AttachTool(false, false)
        end

        if Mods.AutoKnockout and CombatLib and (tick() - lastHitTick > 1.6) then
            local cRoot = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
            local myChar = LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart)
            if cRoot and myRoot then
                local flatDist = ((myRoot.Position - cRoot.Position) * Vector3.new(1, 0, 1)).Magnitude
                if flatDist <= 5.5 then
                    lastHitTick = tick()
                    CombatLib.PlayCloneSwing(clone, 1)
                    task.delay(0.14, function()
                        CombatLib.KnockbackPlayer(cRoot.Position, Mods.KnockoutPower)
                        if Mods.VanishOnHit and clone and clone.Parent then
                            task.delay(0.35, function()
                                if clone and clone.Parent then clone:Destroy() end
                            end)
                        end
                    end)
                end
            end
        end
    end)

    -- Обработка горячих клавиш F1 (бег по точкам) и F2 (быстрый налёт с перчатками и нокаутом)
    local keyConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or UserInputService:GetFocusedTextBox() then return end

        if Mods.KeyPathRun and inp.KeyCode == Mods.KeyPathRun then
            API.StartMode("Pathfind", nil, "Close")
        elseif Mods.KeyAmbushRush and inp.KeyCode == Mods.KeyAmbushRush then
            -- Включаем кастомную скорость + перчатки + авто-нокаут и запускаем погоню на тебя!
            Mods.UseCustomSpeed = true
            Mods.AutoKnockout = true
            Mods.AlwaysGloves = true
            API.StartMode("Locomotion", "Chase", "Far")
            task.defer(function()
                API.AttachTool(false, false)
            end)
        end
    end)

    API.OnCleanup(function()
        API.Config.WalkSpeed = baseWalk
        API.Config.SprintSpeed = baseSprint
        if stepConn then stepConn:Disconnect() end
        if keyConn then keyConn:Disconnect() end
    end)
end
