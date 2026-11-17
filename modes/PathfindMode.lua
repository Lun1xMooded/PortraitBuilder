-- modes/PathfindMode.lua
-- Движение клона строго по точкам маршрута начиная со стартовой точки (StartNodeIndex)

return function(API)
    local PathfindLib = getgenv().MemePathfindLib or API.Import("libs/PathfindLib.lua")
    local currentIdx = 1
    local velocity = Vector3.zero

    return {
        Name = "Pathfind",

        OnActivate = function()
            PathfindLib = getgenv().MemePathfindLib or PathfindLib
            velocity = Vector3.zero

            if not PathfindLib or #PathfindLib.Nodes == 0 then
                warn("[PathfindMode] Нет точек маршрута! Сначала расставь точки на карте комнаты.")
                return
            end

            local startIdx = math.clamp(PathfindLib.StartNodeIndex or 1, 1, #PathfindLib.Nodes)
            local startPos = PathfindLib.Nodes[startIdx]
            local nextIdx = (startIdx < #PathfindLib.Nodes) and (startIdx + 1) or (PathfindLib.LoopPath and 1 or startIdx)
            local nextPos = PathfindLib.Nodes[nextIdx] or startPos

            local floorY = API.GetFloorY(startPos, startPos.Y + 3.5, true)
            local lookFlat = (nextPos - startPos) * Vector3.new(1, 0, 1)
            local spawnCF = (lookFlat.Magnitude > 0.05)
                and CFrame.lookAt(Vector3.new(startPos.X, floorY, startPos.Z), Vector3.new(nextPos.X, floorY, nextPos.Z))
                or CFrame.new(startPos.X, floorY, startPos.Z)

            API.SetCFrame(spawnCF)
            currentIdx = nextIdx
            print(string.format("[PathfindMode] Старт с точки #%d -> цель #%d (всего: %d)", startIdx, currentIdx, #PathfindLib.Nodes))
        end,

        OnDeactivate = function()
            velocity = Vector3.zero
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprint)
            PathfindLib = getgenv().MemePathfindLib or PathfindLib
            local nodes = PathfindLib and PathfindLib.Nodes
            if not nodes or #nodes == 0 or currentIdx > #nodes then
                API.UpdateAnimation(0, false)
                return
            end

            local targetPos = nodes[currentIdx]
            local flatDiff = (targetPos - cloneCFrame.Position) * Vector3.new(1, 0, 1)
            local dist = flatDiff.Magnitude

            if dist <= 1.3 then
                if currentIdx < #nodes then
                    currentIdx = currentIdx + 1
                elseif PathfindLib.LoopPath then
                    currentIdx = 1
                else
                    API.UpdateAnimation(0, false)
                    return
                end
                return
            end

            local sprintNow = isSprint or PathfindLib.SprintPath
            local maxSpeed = API.IsCrouching() and API.Config.CrouchSpeed or (sprintNow and API.Config.SprintSpeed or API.Config.WalkSpeed)

            velocity = velocity:Lerp(flatDiff.Unit * maxSpeed, math.clamp(dt * 12, 0, 1))
            API.UpdateAnimation(velocity.Magnitude, sprintNow)

            local nextPos = cloneCFrame.Position + velocity * dt
            local floorY = API.GetFloorY(nextPos, targetPos.Y + 3.5, false)
            API.SetCFrame(CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(nextPos.X + velocity.X, floorY, nextPos.Z + velocity.Z)))
        end
    }
end