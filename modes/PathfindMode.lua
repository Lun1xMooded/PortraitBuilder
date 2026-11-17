-- modes/PathfindMode.lua
-- Движение клона строго по поставленным точкам из PathfindLib

return function(API)
    local PathfindLib = API.Import("libs/PathfindLib.lua")
    local currentIdx = 1
    local velocity = Vector3.zero

    return {
        Name = "Pathfind",

        OnActivate = function()
            currentIdx = 1
            velocity = Vector3.zero
            if #PathfindLib.Nodes == 0 then
                PathfindLib.AutoGenerateFromCarpet()
            end
            print("[PathfindMode] Старт движения по точкам. Всего точек:", #PathfindLib.Nodes)
        end,

        OnDeactivate = function()
            velocity = Vector3.zero
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprint)
            local nodes = PathfindLib.Nodes
            if #nodes == 0 or currentIdx > #nodes then
                API.UpdateAnimation(0, false)
                return
            end

            local targetPos = nodes[currentIdx]
            local flatDiff = (targetPos - cloneCFrame.Position) * Vector3.new(1, 0, 1)
            local dist = flatDiff.Magnitude

            if dist <= 1.2 then
                currentIdx = currentIdx + 1
                if currentIdx > #nodes then
                    if PathfindLib.LoopPath then
                        currentIdx = 1
                    else
                        API.UpdateAnimation(0, false)
                        return
                    end
                end
                return
            end

            local sprintNow = isSprint or PathfindLib.SprintPath
            local maxSpeed = API.IsCrouching() and API.Config.CrouchSpeed or (sprintNow and API.Config.SprintSpeed or API.Config.WalkSpeed)

            velocity = velocity:Lerp(flatDiff.Unit * maxSpeed, math.clamp(dt * 10, 0, 1))
            API.UpdateAnimation(velocity.Magnitude, sprintNow)

            local nextPos = cloneCFrame.Position + velocity * dt
            local floorY = API.GetFloorY(nextPos, targetPos.Y + 3.5, false)
            API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(nextPos.X + velocity.X, floorY, nextPos.Z + velocity.Z)))
        end
    }
end