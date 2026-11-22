-- modes/PathfindMode.lua
-- Одновременный запуск сценариев для всех клонов (спавн в одной точке + задержка старта + погоня друг за другом)

return function(API)
    local Players = game:GetService("Players")
    local PathfindLib = API.GetService("Pathfind") or API.Import("libs/PathfindLib.lua")

    local cloneStates = {}
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    local function getExactCloneFloorY(model, pos, fallbackY)
        local ignore = {}
        for _, entry in ipairs(API.GetAllClones()) do
            if entry.model then table.insert(ignore, entry.model) end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignore, p.Character) end
        end
        rayParams.FilterDescendantsInstances = ignore

        local off = model:GetAttribute("RootOffset") or 3.65
        local hit = workspace:Raycast(Vector3.new(pos.X, fallbackY + 3.5, pos.Z), Vector3.new(0, -30, 0), rayParams)
        return hit and (hit.Position.Y + off) or fallbackY
    end

    local function updateEntryTracks(entry, speed, isSprintPace)
        local tr = entry.tracks
        if not tr or not tr.walk then return end
        if API.IsCrouching() and tr.crouch then
            if tr.idle then tr.idle:AdjustWeight(0.001) end
            tr.walk:AdjustWeight(0.001)
            if tr.sprint then tr.sprint:AdjustWeight(0.001) end
            if not tr.crouch.IsPlaying then tr.crouch:Play(0.2, 1, 0) end
            tr.crouch:AdjustSpeed((speed > 0.4) and math.clamp(speed / 15, 0.35, 1.3) or 0)
            return
        end

        if not tr.walk.IsPlaying then tr.walk:Play(0.1, 0.001, 0.01) end
        if tr.sprint and not tr.sprint.IsPlaying then tr.sprint:Play(0.1, 0.001, 0.01) end

        if speed > 0.5 then
            if tr.idle then tr.idle:AdjustWeight(0.001) end
            local isCustom = entry.model and entry.model:FindFirstChild("CustomAnimations") ~= nil
            local w = isCustom and 1 or math.clamp(speed / (API.Config.WalkSpeed or 16), 0.05, 1)
            if isSprintPace and tr.sprint then
                tr.walk:AdjustWeight(0.001)
                tr.sprint:AdjustWeight(w)
                tr.sprint:AdjustSpeed(math.clamp(speed / (API.Config.SprintSpeed or 24), 0.65, 1.4))
            else
                if tr.sprint then tr.sprint:AdjustWeight(0.001) end
                tr.walk:AdjustWeight(w)
                tr.walk:AdjustSpeed(math.clamp(speed / (API.Config.WalkSpeed or 16), 0.55, 1.35))
            end
        else
            if tr.idle then tr.idle:AdjustWeight(1) end
            tr.walk:AdjustWeight(0.001)
            tr.walk:AdjustSpeed(0.01)
            if tr.sprint then
                tr.sprint:AdjustWeight(0.001)
                tr.sprint:AdjustSpeed(0.01)
            end
        end
    end

    local function smoothLookCF(currentCF, pos, lookDir, dt)
        local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z)
        if flatDir.Magnitude < 0.05 then
            return CFrame.new(pos) * currentCF.Rotation
        end
        local targetRot = CFrame.lookAt(Vector3.zero, flatDir.Unit, Vector3.yAxis)
        return CFrame.new(pos) * currentCF.Rotation:Lerp(targetRot, math.clamp(dt * 12, 0, 1))
    end

    return {
        Name = "Pathfind",

        OnActivate = function()
            PathfindLib = getgenv().MemePathfindLib or PathfindLib
            table.clear(cloneStates)
            local allClones = API.GetAllClones()
            getgenv().MemeAllClones = allClones

            for idx, entry in ipairs(allClones) do
                local route = PathfindLib and PathfindLib.GetRoute(idx)
                local st = {
                    currentIdx = 1,
                    velocity = Vector3.zero,
                    delayLeft = route and route.StartDelay or 0,
                }

                -- Если клон догоняет другого клона, берём стартовую точку того, кого он догоняет!
                local spawnRoute = route
                if route and #route.Nodes == 0 and route.ChaseCloneIdx then
                    spawnRoute = PathfindLib.GetRoute(route.ChaseCloneIdx)
                end

                if spawnRoute and #spawnRoute.Nodes > 0 then
                    local startIdx = math.clamp(spawnRoute.StartNodeIndex or 1, 1, #spawnRoute.Nodes)
                    local startPos = spawnRoute.Nodes[startIdx]
                    local nextIdx = (startIdx < #spawnRoute.Nodes) and (startIdx + 1) or (PathfindLib.LoopPath and 1 or startIdx)
                    local nextPos = spawnRoute.Nodes[nextIdx] or startPos

                    local floorY = getExactCloneFloorY(entry.model, startPos, startPos.Y + 3.5)
                    local lookFlat = (nextPos - startPos) * Vector3.new(1, 0, 1)
                    local spawnCF = (lookFlat.Magnitude > 0.05)
                        and CFrame.lookAt(Vector3.new(startPos.X, floorY, startPos.Z), Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.yAxis)
                        or CFrame.new(startPos.X, floorY, startPos.Z)

                    entry.cframe = spawnCF
                    local r = entry.model.PrimaryPart or entry.model:FindFirstChild("HumanoidRootPart")
                    if r then r.CFrame = spawnCF end
                    if entry.model == API.GetClone() then API.SetCFrame(spawnCF) end
                    st.currentIdx = nextIdx
                end

                cloneStates[entry] = st
            end
        end,

        OnDeactivate = function()
            table.clear(cloneStates)
            for _, entry in ipairs(API.GetAllClones()) do
                updateEntryTracks(entry, 0, false)
            end
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, _, _, _, _, isSprint)
            PathfindLib = getgenv().MemePathfindLib or PathfindLib
            if not PathfindLib then return end

            local allClones = API.GetAllClones()
            getgenv().MemeAllClones = allClones

            local sprintNow = isSprint or PathfindLib.SprintPath
            local maxSpeed = API.IsCrouching() and API.Config.CrouchSpeed or (sprintNow and API.Config.SprintSpeed or API.Config.WalkSpeed)

            for idx, entry in ipairs(allClones) do
                local m = entry.model
                local r = m and (m.PrimaryPart or m:FindFirstChild("HumanoidRootPart"))
                if m and m.Parent and r and entry.cframe then
                    local st = cloneStates[entry]
                    if not st then
                        st = { currentIdx = 1, velocity = Vector3.zero, delayLeft = 0 }
                        cloneStates[entry] = st
                    end

                    if st.delayLeft > 0 then
                        st.delayLeft = math.max(0, st.delayLeft - dt)
                        updateEntryTracks(entry, 0, false)
                        continue
                    end

                    local route = PathfindLib.GetRoute(idx)
                    local targetPos = nil
                    local stopDist = 1.3

                    if route.ChaseCloneIdx then
                        local targetEntry = allClones[route.ChaseCloneIdx]
                        if targetEntry and targetEntry.cframe then
                            targetPos = targetEntry.cframe.Position
                            stopDist = 3.2
                        end
                    else
                        local nodes = (#route.Nodes > 0) and route.Nodes or PathfindLib.GetRoute(1).Nodes
                        if nodes and #nodes > 0 and st.currentIdx <= #nodes then
                            targetPos = nodes[st.currentIdx]
                            local flatCheck = (targetPos - entry.cframe.Position) * Vector3.new(1, 0, 1)
                            if flatCheck.Magnitude <= 1.3 then
                                if st.currentIdx < #nodes then
                                    st.currentIdx = st.currentIdx + 1
                                elseif PathfindLib.LoopPath then
                                    st.currentIdx = 1
                                else
                                    updateEntryTracks(entry, 0, false)
                                    continue
                                end
                                targetPos = nodes[st.currentIdx]
                            end
                        end
                    end

                    if not targetPos then
                        updateEntryTracks(entry, 0, false)
                        continue
                    end

                    local flatDiff = Vector3.new(targetPos.X - entry.cframe.Position.X, 0, targetPos.Z - entry.cframe.Position.Z)
                    if flatDiff.Magnitude > stopDist then
                        st.velocity = st.velocity:Lerp(flatDiff.Unit * maxSpeed, math.clamp(dt * 12, 0, 1))
                    else
                        st.velocity = st.velocity:Lerp(Vector3.zero, math.clamp(dt * 12, 0, 1))
                    end

                    local spd = st.velocity.Magnitude
                    if spd > 0.35 then
                        updateEntryTracks(entry, spd, sprintNow)
                        local nextPos = entry.cframe.Position + st.velocity * dt
                        local floorY = getExactCloneFloorY(m, nextPos, entry.cframe.Position.Y)
                        local newCF = smoothLookCF(entry.cframe, Vector3.new(nextPos.X, floorY, nextPos.Z), st.velocity, dt)
                        entry.cframe = newCF
                        r.CFrame = newCF
                        if m == API.GetClone() then API.SetCFrame(newCF) end
                    else
                        updateEntryTracks(entry, 0, false)
                    end
                end
            end
        end
    }
end