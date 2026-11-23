-- modes/StatueMode.lua
-- Режим статуи [H] (бежит, когда игрок отворачивается)

return function(API)
    local Config = API.Config

    return {
        Name = "Statue",

        OnActivate = function() end,

        OnDeactivate = function()
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprintPace)
            local cam = workspace.CurrentCamera
            local toClone = (cloneCFrame.Position - cam.CFrame.Position)

            -- Если игрок смотрит на статую — замираем
            if cam.CFrame.LookVector:Dot(toClone.Unit) > 0.45 then
                API.UpdateAnimation(0, false)
                return
            end

            if myRoot then
                local flat = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
                if flat.Magnitude > 4 then
                    local speed = isSprintPace and Config.SprintSpeed or Config.WalkSpeed
                    API.UpdateAnimation(speed, isSprintPace)
                    local nextPos = cloneCFrame.Position + flat.Unit * speed * dt
                    local floorY = API.GetFloorY(nextPos, refY, false)
                    local newCF = CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z))
                    API.SetCFrame(newCF)
                else
                    API.UpdateAnimation(0, false)
                end
            end
        end
    }
end
