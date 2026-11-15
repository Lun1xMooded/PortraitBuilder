-- core/MainEngine.lua (Pure Modular Core v0.4.2 — SpawnAtPlayer [P])
return function(Import, Config)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local ENV = getgenv()

    if ENV.StopMemeActor then
        pcall(ENV.StopMemeActor)
    end
    ENV.GardenVisibilityPatch = true

    local Registry   = Import("core/Registry.lua")
    local MirrorLib  = Import("libs/MirrorLib.lua")
    local EffectsLib = Import("libs/EffectsLib.lua")
    local RigLib     = Import("libs/RigLib.lua")
    if not Registry or not MirrorLib or not EffectsLib or not RigLib then
        warn("[MemeActor] Не удалось загрузить библиотеки!")
        return
    end

    local BuildPortraitRig = ENV.BuildPortraitRig or Import("builders/PortraitBuilder.lua")
    if type(BuildPortraitRig) == "function" then ENV.BuildPortraitRig = BuildPortraitRig end

    local function resolveKey(info)
        local k = Config.Keys and Config.Keys[info.ConfigKey]
        return (k and Enum.KeyCode[k]) or info.Fallback
    end

    local ACTOR_MODES = { "PortraitLight", "PortraitDark", "Player" }
    local ACTOR_LABELS = { PortraitLight = "Portrait Белый", PortraitDark = "Portrait Чёрный", Player = "Клон друга" }
    local modeIdx, isSprint, isCrouching, jitterOn, headLookOn, faceCam = 1, false, false, false, false, false

    local activeClone, cloneCF, activeMode, activeSub = nil, nil, nil, nil
    local tracks = {}
    local cachedNeck, cachedHead, currentNeckCF = nil, nil, nil
    local cachedJitter, cachedToolSyncs = {}, {}
    local lastFloorPos, cachedFloorY, rootOffset = nil, nil, 3.55

    local rayParams = RaycastParams.new()
    rayParams.FilterType, rayParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true

    local function getFloorY(pos, refY, force)
        if not activeClone then return pos.Y end
        if not force and lastFloorPos and cachedFloorY and (Vector3.new(pos.X, 0, pos.Z) - lastFloorPos).Magnitude < 0.25 then
            return cachedFloorY
        end
        local ignore = { activeClone }
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(Vector3.new(pos.X, (refY or pos.Y) + 2, pos.Z), Vector3.new(0, -30, 0), rayParams)
        local fy = hit and (hit.Position.Y + rootOffset) or (refY or pos.Y)
        lastFloorPos, cachedFloorY = Vector3.new(pos.X, 0, pos.Z), fy
        return fy
    end

    local function solveHeadLook(dt)
        if not cachedNeck or not cachedNeck.Parent or not cachedHead or not cachedHead.Parent or not cachedNeck.Part0 then return end
        local baseW = cachedNeck.Part0.CFrame * cachedNeck.C0
        local headPos = (baseW * cachedNeck.C1:Inverse()).Position
        local toTarget = workspace.CurrentCamera.CFrame.Position - headPos
        if toTarget.Magnitude < 0.05 then return end
        local dir, up = toTarget.Unit, baseW.UpVector
        if math.abs(dir:Dot(up)) > 0.995 then up = baseW.RightVector end
        local rx, ry, rz = baseW.Rotation:ToObjectSpace(CFrame.lookAt(Vector3.zero, dir, up)):ToEulerAnglesYXZ()
        rx, rz = math.clamp(rx, math.rad(-65), math.rad(65)), math.clamp(rz, math.rad(-25), math.rad(25))
        local targetTr = cachedNeck.C1 * CFrame.fromEulerAnglesYXZ(rx, ry, rz) * cachedNeck.C1:Inverse()
        currentNeckCF = currentNeckCF and currentNeckCF:Lerp(targetTr, math.clamp((dt or 0.016) * 14, 0, 1)) or targetTr
        cachedNeck.Transform = currentNeckCF
    end

    local function updateToolDrivers()
        for _, s in ipairs(cachedToolSyncs) do
            if s.dst.Parent and s.src.Parent then
                if s.syncOffsets then
                    s.dst.C0 = s.mirror and MirrorLib.MirrorJointCFrame(s.src.C0) or s.src.C0
                    s.dst.C1 = s.mirror and MirrorLib.MirrorJointCFrame(s.src.C1) or s.src.C1
                end
                s.dst.Transform = s.mirror and MirrorLib.MirrorTransform(s.src.Transform) or s.src.Transform
            end
        end
    end

    local function setCrouch(state)
        isCrouching = state
        if not tracks.crouch then return end
        if isCrouching then
            if not tracks.crouch.IsPlaying then tracks.crouch:Play(0.2, 1, 0) end
        elseif tracks.crouch.IsPlaying then
            tracks.crouch:Stop(0.2)
        end
    end

    local function updateAnim(speed, sprint)
        if isCrouching and tracks.crouch then
            if tracks.walk then tracks.walk:AdjustWeight(0.001) end
            if tracks.sprint then tracks.sprint:AdjustWeight(0.001) end
            if not tracks.crouch.IsPlaying then tracks.crouch:Play(0.2, 1, 0) end
            tracks.crouch:AdjustSpeed((speed > 0.4) and math.clamp(speed / 15, 0.35, 1.3) or 0)
            return
        end

        if not tracks.walk then return end
        if not tracks.walk.IsPlaying then tracks.walk:Play(0.1, 0.001, 0.01) end
        if tracks.sprint and not tracks.sprint.IsPlaying then tracks.sprint:Play(0.1, 0.001, 0.01) end

        if speed > 0.5 then
            local moveWeight = math.clamp(speed / Config.WalkSpeed, 0.05, 1)
            if sprint and tracks.sprint then
                tracks.walk:AdjustWeight(0.001)
                tracks.sprint:AdjustWeight(moveWeight)
                tracks.sprint:AdjustSpeed(math.clamp(speed / Config.SprintSpeed, 0.65, 1.4))
            else
                if tracks.sprint then tracks.sprint:AdjustWeight(0.001) end
                tracks.walk:AdjustWeight(moveWeight)
                tracks.walk:AdjustSpeed(math.clamp(speed / Config.WalkSpeed, 0.55, 1.35))
            end
        else
            tracks.walk:AdjustWeight(0.001)
            tracks.walk:AdjustSpeed(0.01)
            if tracks.sprint then
                tracks.sprint:AdjustWeight(0.001)
                tracks.sprint:AdjustSpeed(0.01)
            end
        end
    end

    local function setMode(modeObj, sub)
        if activeMode and activeMode ~= modeObj and activeMode.OnDeactivate then activeMode.OnDeactivate() end
        if activeMode == modeObj and activeSub == sub then
            if activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate() end
            activeMode, activeSub = nil, nil
            print("[MemeActor] Режим: ВЫКЛ")
            return
        end
        activeMode, activeSub = modeObj, sub
        if activeMode and activeMode.OnActivate then activeMode.OnActivate(sub) end
        print("[MemeActor] Режим:", modeObj.Name, sub or "")
    end

    local function removeClone()
        if activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate() end
        activeMode, activeSub, cloneCF, lastFloorPos, cachedFloorY = nil, nil, nil, nil, nil
        cachedNeck, cachedHead, currentNeckCF = nil, nil, nil
        table.clear(cachedJitter)
        table.clear(cachedToolSyncs)
        for _, t in pairs(tracks) do pcall(function() t:Stop() end) end
        tracks = {}
        if activeClone then activeClone:Destroy() activeClone = nil end
        ENV.ActiveActorClone = nil
    end

    local function spawnClone(dist, preserve, customCF)
        local sCF = customCF or (preserve and cloneCF or nil)
        local sMode = preserve and activeMode or nil
        local sSub = preserve and activeSub or nil
        local sCrouch = preserve and isCrouching or false

        removeClone()
        local modeName = ACTOR_MODES[modeIdx]
        local target = RigLib.GetTargetPlayer(Config.TargetPlayerName)
        local srcChar = (target and target.Character) or LocalPlayer.Character

        local clone = nil
        if modeName == "Player" then
            if not srcChar then return end
            srcChar.Archivable = true; clone = srcChar:Clone(); srcChar.Archivable = false
            if not clone then return end
            clone.Name = (target and target.Name or LocalPlayer.Name) .. "_MemeClone"
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("LocalScript") or d:IsA("Script") or d:IsA("Animator") then d:Destroy()
                elseif d:IsA("BasePart") then
                    d.CanCollide, d.Massless = false, true
                    d.Anchored = (d.Name == "HumanoidRootPart" or d.Name == "CollisionPart")
                    d.LocalTransparencyModifier = 0
                elseif d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
            end
        else
            if not BuildPortraitRig then return end
            clone = BuildPortraitRig(modeName)
        end

        clone.Parent = workspace
        activeClone, ENV.ActiveActorClone = clone, clone
        cachedHead = clone:FindFirstChild("FHead") or clone:FindFirstChild("Head")
        for _, d in ipairs(clone:GetDescendants()) do
            if (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and d.Name == "Neck" then
                cachedNeck = d
                break
            end
        end
        cachedJitter = EffectsLib.CacheJitterParts(clone)
        RigLib.AttachTool(clone, false, modeName ~= "Player", MirrorLib, cachedToolSyncs)

        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
        rootOffset = (modeName == "Player") and 3.55 or 3.65

        if sCF then
            -- Если передали точную позицию игрока (кнопка [P]), выравниваем по полу
            local groundY = getFloorY(sCF.Position, sCF.Position.Y, true)
            cloneCF = CFrame.new(sCF.X, groundY, sCF.Z) * sCF.Rotation
        else
            local cam = workspace.CurrentCamera
            local flat = (cam.CFrame.LookVector * Vector3.new(1, 0, 1))
            flat = (flat.Magnitude < 0.01) and Vector3.new(0, 0, -1) or flat.Unit
local pos = cam.CFrame.Position + flat * (dist or Config.SpawnDistanceFar)
local refY = (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart) and LocalPlayer.Character.PrimaryPart.Position.Y or cam.CFrame.Position.Y
cloneCF = CFrame.new(pos.X, getFloorY(pos, refY, true), pos.Z) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z) + (faceCam and math.pi or 0), 0)
end
if root then root.CFrame = cloneCF end
tracks = RigLib.SetupAnimations(clone, srcChar)
setCrouch(sCrouch)
if sMode then setMode(sMode, sSub) end
print("[MemeActor] Заспавнен:", ACTOR_LABELS[modeName])
end
local function spawnAtPlayer()
local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart"))
if not myRoot then return end
local look = myRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) else look = look.Unit end
local exactCF = CFrame.lookAt(myRoot.Position, myRoot.Position + look)
spawnClone(0, false, exactCF)
if myChar:GetAttribute("Crouching") == true then
setCrouch(true)
end
end
local ModeAPI = {
Config = Config, Import = Import,
GetClone = function() return activeClone end,
GetCFrame = function() return cloneCF end,
SetCFrame = function(cf)
cloneCF = cf
local r = activeClone and (activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart"))
if r then r.CFrame = cf end
end,
GetFloorY = getFloorY, UpdateAnimation = updateAnim,
GetSubMode = function() return activeSub end, SetSubMode = function(s) activeSub = s end,
IsCrouching = function() return isCrouching end, SetCrouch = setCrouch,
IsHeadLookEnabled = function() return headLookOn end,
AttachTool = function(mirrored, skipTrack)
RigLib.AttachTool(activeClone, mirrored, ACTOR_MODES[modeIdx] ~= "Player", MirrorLib, cachedToolSyncs)
RigLib.PlayToolTrack(activeClone, tracks, skipTrack)
updateToolDrivers()
end,
StopAllTracks = function() for _, t in pairs(tracks) do if t.IsPlaying then t:Stop(0.1) end end end,
PlayIdle = function() if tracks.idle then tracks.idle:Play(0.1) end if tracks.tool then tracks.tool:Play(0.1) end end,
}
local LoadedModes = {}
for _, m in ipairs(Registry.ModeModules) do
local f = Import(m.Path)
if type(f) == "function" then LoadedModes[m.Id] = f(ModeAPI) end
end
local K = {}
for name, info in pairs(Registry.SystemKeys) do K[name] = resolveKey(info) end
local Binds = {}
for _, b in ipairs(Registry.ModeBindings) do
table.insert(Binds, { Key = resolveKey(b), Id = b.ModuleId, Sub = b.SubMode, Spawn = b.AutoSpawn })
end
local inputConn = UserInputService.InputBegan:Connect(function(inp, gp)
if gp or UserInputService:GetFocusedTextBox() then return end
local key = inp.KeyCode
if key == K.Spawn then spawnClone(Config.SpawnDistanceFar, false)
elseif key == K.SpawnHere then spawnAtPlayer()
elseif key == K.SwitchActor then
local onlyP = UserInputService:IsKeyDown(K.Spawn)
for _ = 1, #ACTOR_MODES do
modeIdx = (modeIdx % #ACTOR_MODES) + 1
if not onlyP or ACTOR_MODES[modeIdx] ~= "Player" then break end
end
print("[MemeActor] Облик:", ACTOR_LABELS[ACTOR_MODES[modeIdx]])
if activeClone then spawnClone(Config.SpawnDistanceFar, true) end
elseif key == K.PaceToggle then isSprint = not isSprint; print("[MemeActor] Темп:", isSprint and "БЕГ" or "ХОДЬБА")
elseif key == K.Crouch then if not activeClone then spawnClone(Config.SpawnDistanceClose, false) end setCrouch(not isCrouching)
elseif key == K.JitterToggle then jitterOn = not jitterOn; if not jitterOn then EffectsLib.ResetJitter(cachedJitter) end
elseif key == K.HeadLook then headLookOn = not headLookOn; currentNeckCF = nil; print("[MemeActor] HeadLook 360°:", headLookOn and "ВКЛ" or "ВЫКЛ")
elseif key == K.Rotate then faceCam = not faceCam; if activeClone and cloneCF then ModeAPI.SetCFrame(cloneCF * CFrame.Angles(0, math.pi, 0)) end
elseif key == K.Remove then removeClone()
else
for _, b in ipairs(Binds) do
if key == b.Key and LoadedModes[b.Id] then
if not activeClone then spawnClone((b.Spawn == "Close") and Config.SpawnDistanceClose or Config.SpawnDistanceFar, false) end
setMode(LoadedModes[b.Id], b.Sub)
break
end
end
end
end)
local renderConn = RunService.RenderStepped:Connect(function(dt)
if not activeClone or not cloneCF then return end
local r = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
if not r then return end
if jitterOn then EffectsLib.UpdateJitter(cachedJitter, Config.JitterIntensity or 4.0) end
if activeMode and activeMode.OnStep then
local myR = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
activeMode.OnStep(dt, cloneCF, r, myR, myR and myR.Position.Y or cloneCF.Position.Y, isSprint)
end
updateToolDrivers()
end)
local steppedConn = RunService.Stepped:Connect(function(_, dt)
if not activeClone then return end
if activeMode and activeMode.OnStepped then activeMode.OnStepped(dt) end
updateToolDrivers()
if headLookOn then solveHeadLook(dt) end
end)
ENV.StopMemeActor = function()
ENV.GardenVisibilityPatch = nil
removeClone()
if inputConn then inputConn:Disconnect() end
if renderConn then renderConn:Disconnect() end
if steppedConn then steppedConn:Disconnect() end
end
Registry.PrintStartupBanner(Config)
end