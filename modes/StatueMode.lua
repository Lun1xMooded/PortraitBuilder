-- modes/StatueMode.lua
-- Режим статуи [H] (бежит, когда игрок отворачивается, с поддержкой высоких ригов и MultiClone)

return function(API)
    local Config = API.Config

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

    return {
        Name = "Statue",

        OnActivate = function() end,

        OnDeactivate = function()
            for _, entry in ipairs(API.GetAllClones()) do
                updateEntryTracks(entry, 0, false)
            end
            API.UpdateAnimation(0, false)
        end,

        OnStep = function(dt, cloneCFrame, root, myRoot, refY, isSprintPace)
            local cam = workspace.CurrentCamera
            if not cam or not myRoot then return end

            local all = API.GetAllClones()
            local isMulti = (API.IsMultiClone and API.IsMultiClone()) or (#all > 1)
            local speed = isSprintPace and (Config.SprintSpeed or 24) or (Config.WalkSpeed or 16)

            -- РЕЖИМ ТОЛПЫ (MultiClone): каждая статуя проверяет взгляд отдельно
            if isMulti and #all > 1 then
                for _, entry in ipairs(all) do
                    local m = entry.model
                    local r = m and (m.PrimaryPart or m:FindFirstChild("HumanoidRootPart"))
                    if m and m.Parent and r and entry.cframe then
                        local curCF = entry.cframe
                        local toClone = (curCF.Position - cam.CFrame.Position)

                        if toClone.Magnitude > 0.01 and cam.CFrame.LookVector:Dot(toClone.Unit) > 0.45 then
                            updateEntryTracks(entry, 0, false)
                        else
                            local flat = (myRoot.Position - curCF.Position) * Vector3.new(1, 0, 1)
                            if flat.Magnitude > 4 then
                                local off = m:GetAttribute("RootOffset") or 3.65
                                updateEntryTracks(entry, speed, isSprintPace)
                                local nextPos = curCF.Position + flat.Unit * speed * dt
                                local floorY = API.GetFloorY(nextPos, curCF.Position.Y, false, off)
                                local newCF = CFrame.lookAt(
                                    Vector3.new(nextPos.X, floorY, nextPos.Z),
                                    Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z)
                                )
                                entry.cframe = newCF
                                r.CFrame = newCF
                                if m == API.GetClone() then API.SetCFrame(newCF) end
                            else
                                updateEntryTracks(entry, 0, false)
                            end
                        end
                    end
                end
                return
            end

            -- ОДИНОЧНЫЙ КЛОН
            local toClone = (cloneCFrame.Position - cam.CFrame.Position)
            if toClone.Magnitude > 0.01 and cam.CFrame.LookVector:Dot(toClone.Unit) > 0.45 then
                API.UpdateAnimation(0, false)
                return
            end

            local flat = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
            if flat.Magnitude > 4 then
                local mainClone = API.GetClone()
                local mainOff = (mainClone and mainClone:GetAttribute("RootOffset")) or 3.65
                API.UpdateAnimation(speed, isSprintPace)

                local nextPos = cloneCFrame.Position + flat.Unit * speed * dt
                local floorY = API.GetFloorY(nextPos, cloneCFrame.Position.Y, false, mainOff)
                local newCF = CFrame.lookAt(
                    Vector3.new(nextPos.X, floorY, nextPos.Z),
                    Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z)
                )
                API.SetCFrame(newCF)
            else
                API.UpdateAnimation(0, false)
            end
        end
    }
end
