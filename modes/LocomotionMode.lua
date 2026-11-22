-- modes/LocomotionMode.lua
-- Прямой бег/ходьба [F] и преследование [N] для одного клона и всей толпы (MultiClone) с поддержкой маршрутов RoomMap

return function(API)
    local Config = API.Config
    local chaseVelocities = {}
    local waypointIndices = {}

    local function getActiveSpeed(isSprintPace)
        if API.IsCrouching() then
            return Config.CrouchSpeed or 10
        end
        return isSprintPace and (Config.SprintSpeed or 24) or (Config.WalkSpeed or 16)
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
            local w = isCustom and 1 or math.clamp(speed / (Config.WalkSpeed or 16), 0.05, 1)
            if isSprintPace and tr.sprint then
                tr.walk:AdjustWeight(0.001)
                tr.sprint:AdjustWeight(w)
                tr.sprint:AdjustSpeed(math.clamp(speed / (Config.SprintSpeed or 24), 0.65, 1.4))
            else
                if tr.sprint then tr.sprint:AdjustWeight(0.001) end
                tr.walk:AdjustWeight(w)
                tr.walk:AdjustSpeed(math.clamp(speed / (Config.WalkSpeed or 16), 0.55, 1.35))
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

    local function getRoomWaypoints()
        local rm = API.GetService("RoomMap") or getgenv().RoomMapService
        if rm and type(rm.GetWaypoints) == "function" then
            return rm.GetWaypoints() or {}
        end
        if type(getgenv().RoomMapPoints) == "table" then
            return getgenv().RoomMapPoints
        end
        return {}
    end

    return {
        Name = "Locomotion",

        OnActivate = function(subMode)
            table.clear(chaseVelocities)
            table.clear(waypointIndices)
            API.SetSubMode(subMode)
        end,

        OnDeactivate = function()
            table.clear(chaseVelocities)
            table.clear(waypointIndices)
            for _, entry in ipairs(API.GetAllClones()) do
                updateEntryTracks(entry, 0, false)
            end
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprintPace)
            local subMode = API.GetSubMode()
            local speed = getActiveSpeed(isSprintPace)
            local all = API.GetAllClones()
            local isMulti = API.IsMultiClone and API.IsMultiClone() or (#all > 1)

            -- Надёжный поиск корня игрока (даже если PrimaryPart у персонажа nil)
            local playerRoot = myRoot
            if not playerRoot then
                local ch = game:GetService("Players").LocalPlayer.Character
                playerRoot = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("CollisionPart") or ch.PrimaryPart)
            end

            local waypoints = getRoomWaypoints()

            -- Если активен режим толпы (MultiClone) и клонов > 1 — двигаем КАЖДОГО клона!
            if isMulti and #all > 1 then
                for idx, entry in ipairs(all) do
                    local m = entry.model
                    local r = m and (m.PrimaryPart or m:FindFirstChild("HumanoidRootPart"))
                    if m and m.Parent and r and entry.cframe then
                        local curCF = entry.cframe
                        local curPos = curCF.Position
                        local targetPos = nil

                        if subMode == "Straight" then
                            targetPos = curPos + curCF.LookVector * speed * dt * 2
                        elseif subMode == "Chase" then
                            if #waypoints >= 2 then
                                -- Клоны идут цепочкой по точкам маршрута RoomMap друг за другом!
                                local wpIdx = waypointIndices[entry] or (((idx - 1) % #waypoints) + 1)
                                waypointIndices[entry] = wpIdx
                                local wp = waypoints[wpIdx]
                                targetPos = wp
                                if ((wp - curPos) * Vector3.new(1, 0, 1)).Magnitude < 3.0 then
                                    waypointIndices[entry] = (wpIdx % #waypoints) + 1
                                end
                            elseif idx == 1 and playerRoot then
                                -- Первый клон догоняет игрока
                                targetPos = playerRoot.Position
                            elseif all[idx - 1] and all[idx - 1].cframe then
                                -- Второй и последующие клоны догоняют предыдущего клона!
                                targetPos = all[idx - 1].cframe.Position
                            elseif playerRoot then
                                targetPos = playerRoot.Position
                            end
                        end

                        if targetPos then
                            local toTarget = (targetPos - curPos) * Vector3.new(1, 0, 1)
                            local dist = toTarget.Magnitude
                            local stopDist = (subMode == "Straight") and 0.1 or (Config.ChaseStopDistance or 3.5)
                            local vel = chaseVelocities[entry] or Vector3.zero

                            if dist > stopDist then
                                local accel = math.clamp(dt * ((Config.ChaseAcceleration or 80) / 10), 0, 1)
                                vel = vel:Lerp(toTarget.Unit * speed, accel)
                            else
                                vel = vel:Lerp(Vector3.zero, math.clamp(dt * (Config.ChaseFriction or 10), 0, 1))
                            end
                            chaseVelocities[entry] = vel

                            local spd = vel.Magnitude
                            if spd > 0.3 then
                                updateEntryTracks(entry, spd, isSprintPace)
                                local nextPos = curPos + vel * dt
                                local off = m:GetAttribute("RootOffset") or 3.65
                                local floorY = API.GetFloorY(nextPos, curPos.Y, false) - (Config.RootOffset or 3.65) + off
                                local newCF = CFrame.lookAt(
                                    Vector3.new(nextPos.X, floorY, nextPos.Z),
                                    Vector3.new(nextPos.X + vel.X, floorY, nextPos.Z + vel.Z)
                                )
                                entry.cframe = newCF
                                r.CFrame = newCF
                                if m == API.GetClone() then
                                    API.SetCFrame(newCF)
                                end
                            else
                                updateEntryTracks(entry, 0, false)
                            end
                        end
                    end
                end
                return
            end

            -- Одиночный клон (стандартный режим)
            if subMode == "Straight" then
                API.UpdateAnimation(speed, isSprintPace)
                local nextPos = cloneCFrame.Position + cloneCFrame.LookVector * speed * dt
                local floorY = API.GetFloorY(nextPos, refY, false)
                API.SetCFrame(CFrame.new(nextPos.X, floorY, nextPos.Z) * cloneCFrame.Rotation)
                return
            end

            if subMode == "Chase" then
                local targetPos = nil
                if #waypoints >= 2 then
                    local wpIdx = waypointIndices[1] or 1
                    local wp = waypoints[wpIdx]
                    targetPos = wp
                    if ((wp - cloneCFrame.Position) * Vector3.new(1, 0, 1)).Magnitude < 3.0 then
                        waypointIndices[1] = (wpIdx % #waypoints) + 1
                    end
                elseif playerRoot then
                    targetPos = playerRoot.Position
                end

                if not targetPos then return end
                local toPlayer = (targetPos - cloneCFrame.Position) * Vector3.new(1, 0, 1)
                local dist = toPlayer.Magnitude
                local stopDist = Config.ChaseStopDistance or 3.5

                local vel = chaseVelocities[1] or Vector3.zero
                if dist > stopDist then
                    local accel = math.clamp(dt * ((Config.ChaseAcceleration or 80) / 10), 0, 1)
                    vel = vel:Lerp(toPlayer.Unit * speed, accel)
                else
                    vel = vel:Lerp(Vector3.zero, math.clamp(dt * (Config.ChaseFriction or 10), 0, 1))
                end
                chaseVelocities[1] = vel

                local spd = vel.Magnitude
                if spd > 0.3 then
                    API.UpdateAnimation(spd, isSprintPace)
                    local nextPos = cloneCFrame.Position + vel * dt
local floorY = API.GetFloorY(nextPos, refY, false)
API.SetCFrame(CFrame.lookAt(
Vector3.new(nextPos.X, floorY, nextPos.Z),
Vector3.new(nextPos.X + vel.X, floorY, nextPos.Z + vel.Z)
))
else
API.UpdateAnimation(0, false)
local lookTarget = Vector3.new(targetPos.X, cloneCFrame.Position.Y, targetPos.Z)
API.SetCFrame(cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 8, 0, 1)))
end
end
end
}
end