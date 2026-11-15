-- modes/MirrorMode.lua
-- Режим Зеркала [R] на базе библиотек libs/MirrorLib, libs/PostureLib и libs/EffectsLib

return function(API)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local MirrorLib  = API.Import("libs/MirrorLib.lua")
    local PostureLib = API.Import("libs/PostureLib.lua")
    local EffectsLib = API.Import("libs/EffectsLib.lua")

    local mirrorPlaneCF = nil
    local jointCache = {}
    local postureState = PostureLib.NewState()
    local lastToolName = ""
    local stepAccum = 0
    local lastClonePos = nil

    return {
        Name = "Mirror",

        OnActivate = function()
            local clone = API.GetClone()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart"))
            local cloneCF = API.GetCFrame()

            if myRoot and cloneCF then
                local midPos = (myRoot.Position + cloneCF.Position) * 0.5
                local normal = (myRoot.Position - cloneCF.Position) * Vector3.new(1, 0, 1)
                if normal.Magnitude < 0.01 then normal = -myRoot.CFrame.LookVector * Vector3.new(1, 0, 1) end
                mirrorPlaneCF = CFrame.lookAt(midPos, midPos + normal.Unit)
            end

            API.StopAllTracks()
            API.AttachTool(true) -- Переносим предмет зеркально в левую руку
            lastToolName = (myChar and myChar:FindFirstChildOfClass("Tool") and myChar:FindFirstChildOfClass("Tool").Name) or ""
            jointCache = MirrorLib.BuildJointCache(myChar, clone)
            postureState = PostureLib.NewState()
            lastClonePos = cloneCF and cloneCF.Position or nil
            stepAccum = 0
        end,

        OnDeactivate = function()
            mirrorPlaneCF = nil
            table.clear(jointCache)
            API.AttachTool(false) -- Возвращаем предмет в правую руку
            API.PlayIdle()
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY)
            local myChar = LocalPlayer.Character
            local realRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myRoot)
            if not realRoot or not mirrorPlaneCF then return end

            -- 1. Отражаем позицию и разворот через плоскость зеркала
            local reflectedCF = MirrorLib.ReflectCFrame(mirrorPlaneCF, realRoot.CFrame)
            local floorY = API.GetFloorY(reflectedCF.Position, realRoot.Position.Y, false)
            local newCF = CFrame.new(reflectedCF.X, floorY, reflectedCF.Z) * reflectedCF.Rotation
            API.SetCFrame(newCF)

            -- 2. Эффект шагов из-под ног каждые 4.5 стада (как в PortraitTraversal)
            if lastClonePos then
                local moved = ((newCF.Position - lastClonePos) * Vector3.new(1, 0, 1)).Magnitude
                stepAccum = stepAccum + moved
                if stepAccum >= 4.5 then
                    stepAccum = stepAccum - 4.5
                    local clone = API.GetClone()
                    local footAtt = clone and clone:FindFirstChild("Footsteps", true)
                    if footAtt then EffectsLib.EmitAttachment(footAtt, 4) end
                end
            end
            lastClonePos = newCF.Position

            -- 3. Следим за сменой предмета в руках игрока
            local curTool = myChar:FindFirstChildOfClass("Tool")
            local curName = curTool and curTool.Name or ""
            if curName ~= lastToolName then
                lastToolName = curName
                API.AttachTool(true)
                jointCache = MirrorLib.BuildJointCache(myChar, API.GetClone())
            end
        end,

        -- Вызывается на RunService.Stepped (поверх Animator!)
        OnStepped = function(dt)
            local myChar = LocalPlayer.Character
            local clone = API.GetClone()
            if not myChar or not clone then return end

            -- Зеркалим позы всех суставов (шею оставляем свободной, если включен HeadLook)
            local skip = API.IsHeadLookEnabled() and { Neck = true } or nil
            MirrorLib.ApplyJointCache(jointCache, skip)

            -- Синхронизируем приседание через библиотеку PostureLib
            PostureLib.SyncCrouchWithCharacter(postureState, myChar, clone, dt)
        end
    }
end
