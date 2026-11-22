-- modes/LocomotionMode.lua
-- Прямой бег/ходьба [F] и преследование [N] для одного клона и всей толпы (MultiClone)

return function(API)
    local Config = API.Config
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local chaseVelocities = {}
    local waypointIndices = {}
    local crowdAngles = {}

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

    -- Точный расчёт высоты пола без багов кэша и без левитации для любого типа рига
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
        local hit = workspace:Raycast(Vector3.new(pos.X, fallbackY + 3, pos.Z), Vector3.new(0, -30, 0), rayParams)
        return hit and (hit.Position.Y + off) or fallbackY
    end

    -- Плавный разворот только по оси Y (убирает рывки влево-вправо)
    local function smoothLookCF(currentCF, pos, lookDir, dt)
        local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z)
        if flatDir.Magnitude < 0.05 then
            return CFrame.new(pos) * currentCF.Rotation
        end
        local targetRot = CFrame.lookAt(Vector3.zero, flatDir.Unit, Vector3.yAxis)
        local alpha = math.clamp(dt * 12, 0, 1)
        return CFrame.new(pos) * currentCF.Rotation:Lerp(targetRot, alpha)
    end

    return {
        Name = "Locomotion",

        OnActivate = function(subMode)
            table.clear(chaseVelocities)
            table.clear(waypointIndices)
            table.clear(crowdAngles)
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
            local isMulti = (API.IsMultiClone and API.IsMultiClone()) or (#all > 1)

            local playerRoot = myRoot
            if not playerRoot then
                local ch = LocalPlayer.Character
                playerRoot = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("CollisionPart") or ch.PrimaryPart)
            end

            local waypoints = getRoomWaypoints()

            -- РЕЖИМ ТОЛПЫ (MultiClone)
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
                                local wpIdx = waypointIndices[entry] or (((idx - 1) % #waypoints) + 1)
                                waypointIndices[entry] = wpIdx
                                local wp = waypoints[wpIdx]
                                targetPos = wp
                                if ((wp - curPos) * Vector3.new(1, 0, 1)).Magnitude < 3.0 then
                                    waypointIndices[entry] = (wpIdx % #waypoints) + 1
                                end
                            elseif playerRoot then
                                -- Все клоны бегут за игроком, но занимают позиции веером вокруг него
                                if not crowdAngles[entry] then
                                    crowdAngles[entry] = (idx - 1) * 2.39996 -- золотой угол для равномерного кольца
                                end
                                local spreadRadius = math.min(2.2 + (#all * 0.25), 6.0)
                                local offset = Vector3.new(
                                    math.cos(crowdAngles[entry]) * spreadRadius,
                                    0,
                                    math.sin(crowdAngles[entry]) * spreadRadius
                                )
                                targetPos = playerRoot.Position + offset
                            end
                        end

                        if targetPos then
                            local toTarget = Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z)
                            local dist = toTarget.Magnitude
                            local stopDist = (subMode == "Straight") and 0.1 or (Config.ChaseStopDistance or 3.5)
                            local vel = chaseVelocities[entry] or Vector3.zero

                            if dist > stopDist then
                                local accel = math.clamp(dt * 10, 0, 1)
                                vel = vel:Lerp(toTarget.Unit * speed, accel)
                            else
                                vel = vel:Lerp(Vector3.zero, math.clamp(dt * 12, 0, 1))
                            end
                            chaseVelocities[entry] = vel

                            local spd = vel.Magnitude
                            if spd > 0.35 then
                                updateEntryTracks(entry, spd, isSprintPace)
                                local nextPos = curPos + vel * dt
                                local floorY = getExactCloneFloorY(m, nextPos, curPos.Y)
                                local newCF = smoothLookCF(curCF, Vector3.new(nextPos.X, floorY, nextPos.Z), vel, dt)
                                entry.cframe = newCF
                                r.CFrame = newCF
                                if m == API.GetClone() then
                                    API.SetCFrame(newCF)
                                end
                            else
                                updateEntryTracks(entry, 0, false)
                                if playerRoot then
                                    local lookToPlayer = Vector3.new(playerRoot.Position.X - curPos.X, 0, playerRoot.Position.Z - curPos.Z)
                                    local newCF = smoothLookCF(curCF, curPos, lookToPlayer, dt)
                                    entry.cframe = newCF
                                    r.CFrame = newCF
                                end
                            end
                        end
                    end
                end
                return
            end

            -- ОДИНОЧНЫЙ КЛОН
            if subMode == "Straight" then
                API.UpdateAnimation(speed, isSprintPace)
                local nextPos = cloneCFrame.Position + cloneCFrame.LookVector * speed * dt
                local floorY = getExactCloneFloorY(API.GetClone(), nextPos, refY)
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
local toPlayer = Vector3.new(targetPos.X - cloneCFrame.Position.X, 0, targetPos.Z - cloneCFrame.Position.Z)
local dist = toPlayer.Magnitude
local stopDist = Config.ChaseStopDistance or 3.5
local vel = chaseVelocities[1] or Vector3.zero
if dist > stopDist then
local accel = math.clamp(dt * 10, 0, 1)
vel = vel:Lerp(toPlayer.Unit * speed, accel)
else
vel = vel:Lerp(Vector3.zero, math.clamp(dt * 12, 0, 1))
end
chaseVelocities[1] = vel
local spd = vel.Magnitude
if spd > 0.35 then
API.UpdateAnimation(spd, isSprintPace)
local nextPos = cloneCFrame.Position + vel * dt
local floorY = getExactCloneFloorY(API.GetClone(), nextPos, refY)
API.SetCFrame(smoothLookCF(cloneCFrame, Vector3.new(nextPos.X, floorY, nextPos.Z), vel, dt))
else
API.UpdateAnimation(0, false)
API.SetCFrame(smoothLookCF(cloneCFrame, cloneCFrame.Position, toPlayer, dt))
end
end
end
}
end