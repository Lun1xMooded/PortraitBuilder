-- plugins/ActorModsPlugin.lua
-- Глобальные модификаторы Portrait + бинды F1 (бег по точкам) и F2 (прямой рывок + удар + убийство/нокаут)

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
        KillOnHit = false,
        KnockoutPower = 90,
        AlwaysGloves = false,
        VanishOnHit = false,
        KeyPathRun = Enum.KeyCode.F1,
        KeyStraightRush = Enum.KeyCode.F2,
    }

    local Sliders = {
        CustomSpeed   = { get = function() return Mods.CustomSpeed end,   set = function(v) Mods.CustomSpeed = v end },
        KnockoutPower = { get = function() return Mods.KnockoutPower end, set = function(v) Mods.KnockoutPower = v end },
    }
    local Keybinds = {
        KeyPathRun      = { get = function() return Mods.KeyPathRun end,      set = function(k) Mods.KeyPathRun = k end },
        KeyStraightRush = { get = function() return Mods.KeyStraightRush end, set = function(k) Mods.KeyStraightRush = k end },
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
    API.RegisterState("KillOnHit",    function() return Mods.KillOnHit end,    function(v) Mods.KillOnHit = v end)
    API.RegisterState("AlwaysGloves", function() return Mods.AlwaysGloves end, function(v)
        Mods.AlwaysGloves = v
        if v and API.GetClone() then API.AttachTool(false, false) end
    end)
    API.RegisterState("VanishOnHit",  function() return Mods.VanishOnHit end,  function(v) Mods.VanishOnHit = v end)

    local lastHitTick = 0

    local function matchesBind(inp, bind)
        if not bind or typeof(bind) ~= "EnumItem" then return false end
        if bind.EnumType == Enum.KeyCode then
            return inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == bind
        elseif bind.EnumType == Enum.UserInputType then
            return inp.UserInputType == bind
        end
        return false
    end

    local function triggerStraightHitRush()
        Mods.UseCustomSpeed = true
        Mods.AutoKnockout = true
        Mods.AlwaysGloves = true

        -- Запускаем прямой бег ("Locomotion", "Straight") со своей скоростью из слайдера
        API.StartMode("Locomotion", "Straight", "Far")
        task.defer(function()
            API.AttachTool(false, false)
        end)
    end

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

        -- Проверка сближения: если возле игрока — бьёт, сносит с ног и (опционально) убивает
        if Mods.AutoKnockout and CombatLib and (tick() - lastHitTick > 1.5) then
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

                        if Mods.KillOnHit and myChar then
                            local hum = myChar:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                hum.Health = 0
                            end
                        end

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

    local keyConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or UserInputService:GetFocusedTextBox() then return end

        if matchesBind(inp, Mods.KeyPathRun) then
            API.StartMode("Pathfind", nil, "Close")
        elseif matchesBind(inp, Mods.KeyStraightRush) then
            triggerStraightHitRush()
        end
    end)

    API.OnCleanup(function()
        API.Config.WalkSpeed = baseWalk
        API.Config.SprintSpeed = baseSprint
        if stepConn then stepConn:Disconnect() end
        if keyConn then keyConn:Disconnect() end
    end)
end
