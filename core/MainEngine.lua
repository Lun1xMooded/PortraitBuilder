-- core/MainEngine.lua (Pure Modular Core v0.9 — Compact + MenuController)
return function(Import, Config)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local ENV = getgenv()

    if ENV.StopMemeActor then pcall(ENV.StopMemeActor) end
    ENV.GardenVisibilityPatch = true

    local Registry       = Import("core/Registry.lua")
    local MenuController = Import("core/MenuController.lua")
    local MirrorLib      = Import("libs/MirrorLib.lua")
    local EffectsLib     = Import("libs/EffectsLib.lua")
    local RigLib         = Import("libs/RigLib.lua")
    local CombatLib      = Import("libs/CombatLib.lua")
    local DoorsMenuLib   = Import("libs/DoorsMenuLib.lua")

    if not Registry or not MirrorLib or not EffectsLib or not RigLib or not CombatLib then
        warn("[MemeActor] Ошибка загрузки библиотек!")
        return
    end

    local BuildPortraitRig = ENV.BuildPortraitRig or Import("builders/PortraitBuilder.lua")
    if type(BuildPortraitRig) == "function" then ENV.BuildPortraitRig = BuildPortraitRig end

    local CustomBuildersCache = {}
    local function resolveKey(info)
        local k = Config.Keys and Config.Keys[info.ConfigKey]
        return (k and Enum.KeyCode[k]) or info.Fallback
    end

    local ACTOR_LIST = Registry.ActorList
    local modeIdx, comboIdx = 1, 1
    local multiCloneMode, isSprint, isCrouching, jitterOn, headLookOn, faceCam = false, false, false, false, false, false

    local allClones, tracks, cachedToolSyncs = {}, {}, {}
    local activeClone, cloneCF, activeMode, activeSub = nil, nil, nil, nil
    local lastFloorPos, cachedFloorY, rootOffset = nil, nil, 3.55
    local UIWindow, UIToggles = nil, {}

    local rayParams = RaycastParams.new()
    rayParams.FilterType, rayParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true

    local function getFloorY(pos, refY, force)
        if not force and lastFloorPos and cachedFloorY and (Vector3.new(pos.X, 0, pos.Z) - lastFloorPos).Magnitude < 0.25 then
            return cachedFloorY
        end
        local ignore = {}
        for _, entry in ipairs(allClones) do if entry.model then table.insert(ignore, entry.model) end end
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(Vector3.new(pos.X, (refY or pos.Y) + 2, pos.Z), Vector3.new(0, -30, 0), rayParams)
        local fy = hit and (hit.Position.Y + rootOffset) or (refY or pos.Y)
        lastFloorPos, cachedFloorY = Vector3.new(pos.X, 0, pos.Z), fy
        return fy
    end

    local function solveHeadLookForEntry(entry, dt)
        local neck, head = entry.neck, entry.head
        if not neck or not neck.Parent or not head or not head.Parent or not neck.Part0 then return end
        local baseW = neck.Part0.CFrame * neck.C0
        local headPos = (baseW * neck.C1:Inverse()).Position
        local toTarget = workspace.CurrentCamera.CFrame.Position - headPos
        if toTarget.Magnitude < 0.05 then return end
        local dir, up = toTarget.Unit, baseW.UpVector
        if math.abs(dir:Dot(up)) > 0.995 then up = baseW.RightVector end
        local rx, ry, rz = baseW.Rotation:ToObjectSpace(CFrame.lookAt(Vector3.zero, dir, up)):ToEulerAnglesYXZ()
        rx, rz = math.clamp(rx, math.rad(-65), math.rad(65)), math.clamp(rz, math.rad(-25), math.rad(25))
        local targetTr = neck.C1 * CFrame.fromEulerAnglesYXZ(rx, ry, rz) * neck.C1:Inverse()
        entry.neckCF = entry.neckCF and entry.neckCF:Lerp(targetTr, math.clamp((dt or 0.016) * 14, 0, 1)) or targetTr
        neck.Transform = entry.neckCF
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
        if UIToggles.Crouch then UIToggles.Crouch.Set(isCrouching, true) end
        for _, entry in ipairs(allClones) do
            local tr = entry.tracks and entry.tracks.crouch
            if tr then
                if isCrouching then if not tr.IsPlaying then tr:Play(0.2, 1, 0) end
                elseif tr.IsPlaying then tr:Stop(0.2) end
            end
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
            if tracks.sprint then tracks.sprint:AdjustWeight(0.001); tracks.sprint:AdjustSpeed(0.01) end
        end
    end

    local function setMode(modeObj, sub)
        if activeMode and activeMode ~= modeObj and activeMode.OnDeactivate then activeMode.OnDeactivate() end
        if activeMode == modeObj and activeSub == sub then
            if activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate() end
            activeMode, activeSub = nil, nil
            return
        end
        activeMode, activeSub = modeObj, sub
        if activeMode and activeMode.OnActivate then activeMode.OnActivate(sub) end
    end

    local function removeAllClones()
        if activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate() end
        activeMode, activeSub, cloneCF, lastFloorPos, cachedFloorY = nil, nil, nil, nil, nil
        table.clear(cachedToolSyncs)
        for _, entry in ipairs(allClones) do
            if entry.tracks then for _, t in pairs(entry.tracks) do pcall(function() t:Stop() end) end end
            if entry.model then entry.model:Destroy() end
        end
        table.clear(allClones)
        tracks, activeClone, ENV.ActiveActorClone = {}, nil, nil
    end

    local function spawnClone(dist, preserve, customCF)
        local sCF = customCF or (preserve and cloneCF or nil)
        local sMode, sSub, sCrouch = preserve and activeMode or nil, preserve and activeSub or nil, preserve and isCrouching or false

        if not multiCloneMode then removeAllClones()
        elseif activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate(); activeMode, activeSub = nil, nil end

        local actorInfo = ACTOR_LIST[modeIdx] or ACTOR_LIST
        local srcChar, clone = LocalPlayer.Character, nil

        if actorInfo.Type == "CustomBuilder" and actorInfo.Path then
            local bFn = CustomBuildersCache[actorInfo.Path] or Import(actorInfo.Path)
            if type(bFn) == "function" then CustomBuildersCache[actorInfo.Path] = bFn; clone = bFn(actorInfo.Variant) end
        else
            if not BuildPortraitRig then return end
            clone = BuildPortraitRig(actorInfo.Variant or "PortraitLight")
        end
        if not clone then return end

        clone.Parent = workspace
        activeClone, ENV.ActiveActorClone = clone, clone

        local headPart = clone:FindFirstChild("FHead") or clone:FindFirstChild("Head")
        local neckMotor = nil
        for _, d in ipairs(clone:GetDescendants()) do
            if (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and d.Name == "Neck" then neckMotor = d; break end
        end

        local isPort = (actorInfo.Type == "Portrait")
        RigLib.AttachTool(clone, false, isPort, MirrorLib, cachedToolSyncs)

        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
        rootOffset = isPort and 3.65 or 3.55

        if sCF then
            local gy = getFloorY(sCF.Position, sCF.Position.Y, true)
            cloneCF = CFrame.new(sCF.X, gy, sCF.Z) * sCF.Rotation
        else
            local cam = workspace.CurrentCamera
            local flat = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
            flat = (flat.Magnitude < 0.01) and Vector3.new(0, 0, -1) or flat.Unit
            local pos = cam.CFrame.Position + flat * (dist or Config.SpawnDistanceFar)
            local refY = (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart) and LocalPlayer.Character.PrimaryPart.Position.Y or cam.CFrame.Position.Y
            cloneCF = CFrame.new(pos.X, getFloorY(pos, refY, true), pos.Z) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z) + (faceCam and math.pi or 0), 0)
        end
        if root then root.CFrame = cloneCF end

tracks = RigLib.SetupAnimations(clone, srcChar)
table.insert(allClones, {
model = clone, cframe = cloneCF, head = headPart, neck = neckMotor,
jitter = EffectsLib.CacheJitterParts(clone), tracks = tracks, isRagdoll = false
})
setCrouch(sCrouch)
if sMode then setMode(sMode, sSub) end
end
local function spawnAtPlayer()
local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart"))
if not myRoot then return end
local look = myRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
look = (look.Magnitude < 0.01) and Vector3.new(0, 0, -1) or look.Unit
spawnClone(0, false, CFrame.lookAt(myRoot.Position, myRoot.Position + look))
if myChar:GetAttribute("Crouching") == true then setCrouch(true) end
end
local function doClonePunch()
if not activeClone then return end
local cTool = activeClone:FindFirstChildOfClass("Tool")
local mTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if (not cTool or cTool.Name ~= "BoxingGloves") and mTool and mTool.Name == "BoxingGloves" then
local info = ACTOR_LIST[modeIdx]
RigLib.AttachTool(activeClone, false, info and info.Type == "Portrait", MirrorLib, cachedToolSyncs)
RigLib.PlayToolTrack(activeClone, tracks, false)
updateToolDrivers()
task.wait(0.18)
end
comboIdx = CombatLib.PlayCloneSwing(activeClone, comboIdx)
end
local globalPunchDisconnect = CombatLib.BindPlayerPunch(function()
if activeMode and activeMode.Name == "HardcoreChase" then return end
local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
if not myRoot then return end
for _, entry in ipairs(allClones) do
if entry.model and entry.model.Parent and not entry.isRagdoll and entry.cframe then
local toC = (entry.cframe.Position - myRoot.Position) * Vector3.new(1, 0, 1)
if toC.Magnitude <= 10.0 then
entry.isRagdoll = true
local restoreFn = CombatLib.ApplyRagdoll(entry.model, toC.Unit, 45)
task.delay(2.0, function()
if restoreFn and entry.model and entry.model.Parent then
local lCF = restoreFn()
if lCF then
local nCF = CFrame.lookAt(lCF.Position, Vector3.new(myRoot.Position.X, lCF.Y, myRoot.Position.Z))
entry.cframe = nCF
if entry.model == activeClone then cloneCF = nCF end
local r = entry.model.PrimaryPart or entry.model:FindFirstChild("HumanoidRootPart")
if r then r.CFrame = nCF end
end
end
entry.isRagdoll = false
end)
end
end
end
end)
local ModeAPI = {
Config = Config, Import = Import,
GetClone = function() return activeClone end,
GetCFrame = function() return cloneCF end,
SetCFrame = function(cf)
cloneCF = cf
if #allClones > 0 then allClones[#allClones].cframe = cf end
local r = activeClone and (activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart"))
if r then r.CFrame = cf end
end,
GetFloorY = getFloorY, UpdateAnimation = updateAnim,
GetSubMode = function() return activeSub end, SetSubMode = function(s) activeSub = s end,
IsCrouching = function() return isCrouching end, SetCrouch = setCrouch,
IsHeadLookEnabled = function() return headLookOn end,
AttachTool = function(mirrored, skipTrack)
local info = ACTOR_LIST[modeIdx]
RigLib.AttachTool(activeClone, mirrored, info and info.Type == "Portrait", MirrorLib, cachedToolSyncs)
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
if MenuController and DoorsMenuLib then
UIWindow, UIToggles = MenuController.Build(DoorsMenuLib, Registry, {
Actions = {
SpawnFar = function() spawnClone(Config.SpawnDistanceFar, false) end,
SpawnHere = spawnAtPlayer,
SwitchActor = function()
modeIdx = (modeIdx % #ACTOR_LIST) + 1
if activeClone and not multiCloneMode then spawnClone(Config.SpawnDistanceFar, true) end
end,
Rotate = function()
faceCam = not faceCam
if activeClone and cloneCF then ModeAPI.SetCFrame(cloneCF * CFrame.Angles(0, math.pi, 0)) end
end,
RemoveAll = removeAllClones,
Punch = function() task.spawn(doClonePunch) end,
},
States = {
MultiClone = { get = function() return multiCloneMode end, set = function(v) multiCloneMode = v end },
Crouch     = { get = function() return isCrouching end, set = function(v) if not activeClone then spawnClone(Config.SpawnDistanceClose, false) end setCrouch(v) end },
HeadLook   = { get = function() return headLookOn end, set = function(v) headLookOn = v; for _, e in ipairs(allClones) do e.neckCF = nil end end },
Jitter     = { get = function() return jitterOn end, set = function(v) jitterOn = v; if not v then for _, e in ipairs(allClones) do EffectsLib.ResetJitter(e.jitter) end end end },
},
RunMode = function(mId, sub, autoSpawn)
if not LoadedModes[mId] then return end
if not activeClone then spawnClone((autoSpawn == "Close") and Config.SpawnDistanceClose or Config.SpawnDistanceFar, false) end
setMode(LoadedModes[mId], sub)
end
})
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
if key == Enum.KeyCode.RightBracket or key == Enum.KeyCode.LeftBracket then
if UIWindow then UIWindow:Toggle() end
return
end
if key == K.Spawn then spawnClone(Config.SpawnDistanceFar, false)
elseif key == K.SpawnHere then spawnAtPlayer()
elseif key == K.MultiToggle then multiCloneMode = not multiCloneMode; if UIToggles.MultiClone then UIToggles.MultiClone.Set(multiCloneMode, true) end
elseif key == K.SwitchActor then
modeIdx = (modeIdx % #ACTOR_LIST) + 1
if activeClone and not multiCloneMode then spawnClone(Config.SpawnDistanceFar, true) end
elseif key == K.PaceToggle then isSprint = not isSprint
elseif key == K.Crouch then if not activeClone then spawnClone(Config.SpawnDistanceClose, false) end setCrouch(not isCrouching)
elseif key == K.JitterToggle then
jitterOn = not jitterOn
if UIToggles.Jitter then UIToggles.Jitter.Set(jitterOn, true) end
if not jitterOn then for _, e in ipairs(allClones) do EffectsLib.ResetJitter(e.jitter) end end
elseif key == K.HeadLook then
headLookOn = not headLookOn
if UIToggles.HeadLook then UIToggles.HeadLook.Set(headLookOn, true) end
for _, e in ipairs(allClones) do e.neckCF = nil end
elseif key == K.Rotate then faceCam = not faceCam; if activeClone and cloneCF then ModeAPI.SetCFrame(cloneCF * CFrame.Angles(0, math.pi, 0)) end
elseif key == K.PunchAction then task.spawn(doClonePunch)
elseif key == K.Remove then removeAllClones()
else
for _, b in ipairs(Binds) do
if key == b.Key and LoadedModes[b.Id] then
if not activeClone then spawnClone((b.Spawn == "Close") and Config.SpawnDistanceClose or Config.SpawnDistanceFar, false) end
setMode(LoadedModes[b.Id], b.Sub); break
end
end
end
end)
local renderConn = RunService.RenderStepped:Connect(function(dt)
if #allClones == 0 then return end
if jitterOn then for _, e in ipairs(allClones) do if e.model and e.model.Parent then EffectsLib.UpdateJitter(e.jitter, Config.JitterIntensity or 4.0) end end end
if activeClone and cloneCF and activeMode and activeMode.OnStep then
local r = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
local myR = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
if r then activeMode.OnStep(dt, cloneCF, r, myR, myR and myR.Position.Y or cloneCF.Position.Y, isSprint) end
end
updateToolDrivers()
end)
local steppedConn = RunService.Stepped:Connect(function(_, dt)
if #allClones == 0 then return end
if activeMode and activeMode.OnStepped then activeMode.OnStepped(dt) end
updateToolDrivers()
for _, e in ipairs(allClones) do
if e.model and e.model.Parent and not e.isRagdoll and not e.model:GetAttribute("IsRagdoll") then
if headLookOn then solveHeadLookForEntry(e, dt) end
for _, part in ipairs(e.model:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
end
end
end)
ENV.StopMemeActor = function()
ENV.GardenVisibilityPatch = nil
if UIWindow and UIWindow.Gui then UIWindow.Gui:Destroy() end
if globalPunchDisconnect then globalPunchDisconnect() end
removeAllClones()
if inputConn then inputConn:Disconnect() end
if renderConn then renderConn:Disconnect() end
if steppedConn then steppedConn:Disconnect() end
end
Registry.PrintStartupBanner(Config)
end