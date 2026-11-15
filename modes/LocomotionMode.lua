-- modes/LocomotionMode.lua
-- Прямой бег/ходьба [F] и преследование с инерцией [N]

return function(API)
    local Config = API.Config
    local chaseVelocity = Vector3.zero

    return {
        Name = "Locomotion",

        OnActivate = function(subMode)
            -- subMode: "Straight" ([F]) или "Chase" ([N])
            chaseVelocity = Vector3.zero
            API.SetSubMode(subMode)
        end,

        OnDeactivate = function()
            chaseVelocity = Vector3.zero
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprintPace)
            local subMode = API.GetSubMode()
            local speed = isSprintPace and Config.SprintSpeed or Config.WalkSpeed

            -- 1. ПРЯМОЙ ХОД / БЕГ [F]
            if subMode == "Straight" then
                API.UpdateAnimation(speed, isSprintPace)
                local nextPos = cloneCFrame.Position + cloneCFrame.LookVector * speed * dt
                local floorY = API.GetFloorY(nextPos, refY, false)
                local newCF = CFrame.new(nextPos.X, floorY, nextPos.Z) * cloneCFrame.Rotation
                API.SetCFrame(newCF)
                return
            end

            -- 2. ПРЕСЛЕДОВАНИЕ / ДОГОНЯЛКИ [N]
            if subMode == "Chase" and myRoot then
                local toPlayer = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
                local dist = toPlayer.Magnitude

                if dist > Config.ChaseStopDistance then
                    chaseVelocity = chaseVelocity:Lerp(toPlayer.Unit * speed, math.clamp(dt * (Config.ChaseAcceleration / 10), 0, 1))
                else
                    chaseVelocity = chaseVelocity:Lerp(Vector3.zero, math.clamp(dt * Config.ChaseFriction, 0, 1))
                end

                local spd = chaseVelocity.Magnitude
                if spd > 0.3 then
                    API.UpdateAnimation(spd, isSprintPace)
                    local nextPos = cloneCFrame.Position + chaseVelocity * dt
                    local floorY = API.GetFloorY(nextPos, refY, false)
                    local newCF = CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(nextPos.X + chaseVelocity.X, floorY, nextPos.Z + chaseVelocity.Z))
                    API.SetCFrame(newCF)
                else
                    API.UpdateAnimation(0, false)
                    local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
                    local newCF = cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 8, 0, 1))
                    API.SetCFrame(newCF)
                end
            end
        end
    }
end
