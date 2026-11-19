-- plugins/CombatPlugin.lua
return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local CombatLib = API.Import("libs/CombatLib.lua")
    if not CombatLib then return end

    local comboIdx = 1

    API.RegisterAction("Punch", function()
        task.spawn(function()
            local clone = API.GetClone()
            if not clone then return end
            local cTool = clone:FindFirstChildOfClass("Tool")
            local mTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if (not cTool or cTool.Name ~= "BoxingGloves") and mTool and mTool.Name == "BoxingGloves" then
                API.AttachTool(false, false)
                task.wait(0.18)
            end
            comboIdx = CombatLib.PlayCloneSwing(clone, comboIdx)
        end)
    end)

    local disconnectPunch = CombatLib.BindPlayerPunch(function()
        local mode = API.GetActiveMode()
        if mode and mode.Name == "HardcoreChase" then return end
        local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
        if not myRoot then return end

        for _, entry in ipairs(API.GetAllClones()) do
            if entry.model and entry.model.Parent and not entry.isRagdoll and entry.cframe then
                local toC = (entry.cframe.Position - myRoot.Position) * Vector3.new(1, 0, 1)
                if toC.Magnitude <= 10.0 then
                    entry.isRagdoll = true
                    local restoreFn = CombatLib.ApplyRagdoll(entry.model, toC.Unit, 45)
                    task.delay(2.0, function()
                        if restoreFn and entry.model and entry.model.Parent then
                            local lCF = restoreFn()
                            if lCF then
                                local nCF = CFrame.lookAt(lCF.Position, Vector3.new(myRoot.Position.X, lCF.Y, myRoot.Position.Z))
                                entry.cframe = nCF
                                if entry.model == API.GetClone() then API.SetCFrame(nCF) end
                            end
                        end
                        entry.isRagdoll = false
                    end)
                end
            end
        end
    end)

    API.OnCleanup(function()
        if disconnectPunch then disconnectPunch() end
    end)
end