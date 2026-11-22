-- plugins/ActorModsPlugin.lua
return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local CombatLib = API.Import("libs/CombatLib.lua")

    local baseWalk = API.Config.WalkSpeed or 14
    local baseSprint = API.Config.SprintSpeed or 24
    local baseCrouch = API.Config.CrouchSpeed or 10

    local Mods = {
        UseCustomSpeed = false,
        CustomSpeed = 48,
        AutoKnockout = false,
        KillOnHit = false,
        KnockoutPower = 90,
        AlwaysGloves = false,
        LowerTools = false,
        VanishOnHit = false,
    }

    getgenv().MemeLowerTools = false

    local Sliders = {
        CustomSpeed = {
            get = function() return Mods.CustomSpeed end,
            set = function(v)
                Mods.CustomSpeed = v
                if Mods.UseCustomSpeed then
                    API.Config.WalkSpeed = v
                    API.Config.SprintSpeed = v
                    API.Config.CrouchSpeed = v
                end
            end
        },
        KnockoutPower = {
            get = function() return Mods.KnockoutPower end,
            set = function(v) Mods.KnockoutPower = v end
        },
    }
    getgenv().MemeCustomSliders = Sliders

    API.RegisterState("UseCustomSpeed", function() return Mods.UseCustomSpeed end, function(v)
        Mods.UseCustomSpeed = v
        if v then
            API.Config.WalkSpeed = Mods.CustomSpeed
            API.Config.SprintSpeed = Mods.CustomSpeed
            API.Config.CrouchSpeed = Mods.CustomSpeed
        else
            API.Config.WalkSpeed = baseWalk
            API.Config.SprintSpeed = baseSprint
            API.Config.CrouchSpeed = baseCrouch
        end
    end)

    API.RegisterState("AutoKnockout", function() return Mods.AutoKnockout end, function(v)
        Mods.AutoKnockout = v
    end)

    API.RegisterState("KillOnHit", function() return Mods.KillOnHit end, function(v)
        Mods.KillOnHit = v
    end)

    API.RegisterState("AlwaysGloves", function() return Mods.AlwaysGloves end, function(v)
        Mods.AlwaysGloves = v
        if v and API.GetClone() then
            API.AttachTool(false, Mods.LowerTools)
        end
    end)

    API.RegisterState("LowerTools", function() return Mods.LowerTools end, function(v)
        Mods.LowerTools = v
        getgenv().MemeLowerTools = v
        if API.GetClone() then
            API.AttachTool(false, v)
        end
    end)

    API.RegisterState("VanishOnHit", function() return Mods.VanishOnHit end, function(v)
        Mods.VanishOnHit = v
    end)

    API.RegisterAction("StraightRush", function()
        Mods.UseCustomSpeed = true
        Mods.AutoKnockout = true
        Mods.AlwaysGloves = true
        API.Config.WalkSpeed = Mods.CustomSpeed
        API.Config.SprintSpeed = Mods.CustomSpeed
        API.Config.CrouchSpeed = Mods.CustomSpeed
        API.StartMode("Locomotion", "Straight", "Far")
        task.defer(function()
            API.AttachTool(false, Mods.LowerTools)
        end)
    end)

    local lastHitTick = 0

    local stepConn = RunService.Heartbeat:Connect(function()
        if Mods.UseCustomSpeed then
            API.Config.WalkSpeed = Mods.CustomSpeed
            API.Config.SprintSpeed = Mods.CustomSpeed
            API.Config.CrouchSpeed = Mods.CustomSpeed
        end

        local clone = API.GetClone()
        if not clone or not clone.Parent then return end

        if Mods.AlwaysGloves and not clone:FindFirstChildOfClass("Tool") then
            API.AttachTool(false, Mods.LowerTools)
        end

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

    API.OnCleanup(function()
        getgenv().MemeLowerTools = false
        API.Config.WalkSpeed = baseWalk
        API.Config.SprintSpeed = baseSprint
        API.Config.CrouchSpeed = baseCrouch
        if stepConn then stepConn:Disconnect() end
    end)
end
