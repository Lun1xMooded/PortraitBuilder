-- plugins/CutsceneControlPlugin.lua
-- Полная свобода в любых катсценах DOORS: ходьба, спринт, обзор мышью без лица перед камерой + видимость всех игроков

return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local enabled = false
    local mainGameEnv = nil

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

    -- Скрываем только голову/лицо и шапки локального игрока от первого лица, чтобы не мешали обзору
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

    local function enforceFreedom()
        local mg = getMainGameTable()
        if mg then
            if mg.stopcam == true then mg.stopcam = false end
            if mg.freemouse == true then mg.freemouse = false end
            if mg.incutscene == true then mg.incutscene = false end
            if mg.disableMovement == true then mg.disableMovement = false end
            if mg.camlock ~= nil then mg.camlock = nil end
            if mg.stunned == true then mg.stunned = false end

            if mg.hideplayers ~= 0 then
                mg.hideplayers = 0
                if type(mg.update) == "function" then
                    pcall(mg.update)
                end
            end
        end

        local char = LocalPlayer.Character
        if char then
            -- Снимаем серверные/клиентские блокировки движения из Movement DOORS
            if char:GetAttribute("RestrictMovement") then char:SetAttribute("RestrictMovement", nil) end
            if char:GetAttribute("InCutscene") then char:SetAttribute("InCutscene", nil) end
            if char:GetAttribute("AnimatingClient") then char:SetAttribute("AnimatingClient", nil) end
            if char:GetAttribute("Stunned") then char:SetAttribute("Stunned", nil) end
            if char:GetAttribute("CantHoldItems") then char:SetAttribute("CantHoldItems", nil) end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not char:GetAttribute("Hiding") then
                local wantSprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and (hum.MoveDirection.Magnitude > 0.1)
                local targetSpeed = wantSprint and 24 or 15
                if hum.WalkSpeed < targetSpeed then
                    hum.WalkSpeed = targetSpeed
                end
            end

            -- Убираем твоё лицо из камеры от первого лица (если не включён Freecam)
            local cam = workspace.CurrentCamera
            local head = char:FindFirstChild("Head")
            if cam and head and (cam.CFrame.Position - head.Position).Magnitude < 2.2 then
                hideFirstPersonHead(char)
            end
        end
    end

    local function setEnabled(state)
        enabled = state == true
        if enabled then
            -- Приоритет 90 срабатывает ДО caminit (95) и ДО movement (101) DOORS!
            RunService:BindToRenderStep("MemeActorCutsceneFreedom", 90, enforceFreedom)
            print("[CutsceneControl] Свобода в катсценах: ВКЛ (ходьба, спринт, камера без лица в экране + видимость игроков!)")
        else
            RunService:UnbindFromRenderStep("MemeActorCutsceneFreedom")
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
