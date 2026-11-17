-- core/MainEngine.lua (Pure Modular Core v0.7.1 — Global BoxingGloves Knockback + Action4 Punch)
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
    local CombatLib  = Import("libs/CombatLib.lua")
    if not Registry or not MirrorLib or not EffectsLib or not RigLib or not CombatLib then
        warn("[MemeActor] Не удалось загрузить библиотеки из core/ или libs/!")
        return
    end

    local BuildPortraitRig = ENV.BuildPortraitRig or Import("builders/PortraitBuilder.lua")
    if type(BuildPortraitRig) == "function" then ENV.BuildPortraitRig = BuildPortraitRig end

    local CustomBuildersCache = {}

    local function resolveKey(info)
        local k = Config.Keys and Config.Keys[info.ConfigKey]
        return (k and Enum.KeyCode[k]) or info.Fallback
    end

    local ACTOR_LIST = Registry.ActorList or {
        { Id = "PortraitLight", Label = "Portrait Белый", Type = "Portrait",      Variant = "PortraitLight" },
        { Id = "PortraitDark",  Label = "Portrait Чёрный", Type = "Portrait",      Variant = "PortraitDark" },
        { Id = "LocalAvatar",   Label = "Мой аватар",      Type = "CustomBuilder", Path = "builders/LocalAvatarBuilder.lua" },
    }

    local modeIdx = 1
    local comboIdx = 1
    local multiCloneMode = false
    local isSprint, isCrouching, jitterOn, headLookOn, faceCam = false, false, false, false, false

    local allClones = {}
    local activeClone, cloneCF, activeMode, activeSub = nil, nil, nil, nil
    local tracks = {}
    local cachedToolSyncs = {}
    local lastFloorPos, cachedFloorY, rootOffset = nil, nil, 3.55

    local rayParams = RaycastParams.new()
    rayParams.FilterType, rayParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true

    local function getFloorY(pos, refY, force)
        if not force and lastFloorPos and cachedFloorY and (Vector3.new(pos.X, 0, pos.Z) - lastFloorPos).Magnitude < 0.25 then
            return cachedFloorY
        end
        local ignore = {}
        for _, entry in ipairs(allClones) do
            if entry.model then table.insert(ignore, entry.model) end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignore, p.Character) end
        end
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
        for _, entry in ipairs(allClones) do
            local tr = entry.tracks and entry.tracks.crouch
            if tr then
                if isCrouching then
                    if not tr.IsPlaying then tr:Play(0.2, 1, 0) end
                elseif tr.IsPlaying then
                    tr:Stop(0.2)
                end
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

    local function removeAllClones()
        if activeMode and activeMode.OnDeactivate then activeMode.OnDeactivate() end
        activeMode, activeSub, cloneCF, lastFloorPos, cachedFloorY = nil, nil, nil, nil, nil
        table.clear(cachedToolSyncs)

        for _, entry in ipairs(allClones) do
            if entry.tracks then
                for _, t in pairs(entry.tracks) do pcall(function() t:Stop() end) end
            end
            if entry.model then entry.model:Destroy() end
        end
        table.clear(allClones)

        tracks = {}
        activeClone = nil
        ENV.ActiveActorClone = nil
    end

    local function spawnClone(dist, preserve, customCF)
        local sCF = customCF or (preserve and cloneCF or nil)
        local sMode = preserve and activeMode or nil
        local sSub = preserve and activeSub or nil
        local sCrouch = preserve and isCrouching or false

        if not multiCloneMode then
            removeAllClones()
        elseif activeMode and activeMode.OnDeactivate then
            activeMode.OnDeactivate()
            activeMode, activeSub = nil, nil
        end

        local actorInfo = ACTOR_LIST[modeIdx] or ACTOR_LIST
        local srcChar = LocalPlayer.Character
        local clone = nil

        if actorInfo.Type == "CustomBuilder" and actorInfo.Path then
            local builderFn = CustomBuildersCache[actorInfo.Path] or Import(actorInfo.Path)
            if type(builderFn) == "function" then
                CustomBuildersCache[actorInfo.Path] = builderFn
                clone = builderFn(actorInfo.Variant)
            end
        else
            if not BuildPortraitRig then return end
            clone = BuildPortraitRig(actorInfo.Variant or "PortraitLight")
        end

        if not clone then
            warn("[MemeActor] Не удалось создать облик:", actorInfo.Label)
            return
        end

        clone.Parent = workspace
        activeClone, ENV.ActiveActorClone = clone, clone

        local headPart = clone:FindFirstChild("FHead") or clone:FindFirstChild("Head")
        local neckMotor = nil
        for _, d in ipairs(clone:GetDescendants()) do
            if (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and d.Name == "Neck" then
                neckMotor = d
                break
            end
        end

        local isPortraitType = (actorInfo.Type == "Portrait")
        RigLib.AttachTool(clone, false, isPortraitType, MirrorLib, cachedToolSyncs)

        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
        rootOffset = isPortraitType and 3.65 or 3.55

if sCF then
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
table.insert(allClones, {
model = clone,
cframe = cloneCF,
head = headPart,
neck = neckMotor,
neckCF = nil,
jitter = EffectsLib.CacheJitterParts(clone),
tracks = tracks,
isRagdoll = false,
})
setCrouch(sCrouch)
if sMode then setMode(sMode, sSub) end
print(string.format("[MemeActor] Заспавнен: %s (Всего на сцене: %d)", actorInfo.Label, #allClones))
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
-- Глобальный обработчик твоего удара BoxingGloves по стоящим клонам (когда НЕ включён HardcoreChaseMode)
local globalPunchDisconnect = CombatLib.BindPlayerPunch(function()
if activeMode and activeMode.Name == "HardcoreChase" then return end
local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart)
if not myRoot then return end
for _, entry in ipairs(allClones) do
if entry.model and entry.model.Parent and not entry.isRagdoll and entry.cframe then
local toClone = (entry.cframe.Position - myRoot.Position) * Vector3.new(1, 0, 1)
if toClone.Magnitude <= 10 then
entry.isRagdoll = true
print("[MemeActor] Удар перчатками по манекену! Рэгдолл на 2.2 сек.")
local restoreFn = CombatLib.ApplyRagdoll(entry.model, toClone.Unit, 92)
task.delay(2.2, function()
if restoreFn and entry.model and entry.model.Parent then
local landedCF = restoreFn()
if landedCF then
local fy = getFloorY(landedCF.Position, myRoot.Position.Y, true)
local newCF = CFrame.lookAt(Vector3.new(landedCF.X, fy, landedCF.Z), Vector3.new(myRoot.Position.X, fy, myRoot.Position.Z))
entry.cframe = newCF
if entry.model == activeClone then cloneCF = newCF end
local r = entry.model.PrimaryPart or entry.model:FindFirstChild("HumanoidRootPart")
if r then r.CFrame = newCF end
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
local curInfo = ACTOR_LIST[modeIdx]
local isPort = curInfo and (curInfo.Type == "Portrait")
RigLib.AttachTool(activeClone, mirrored, isPort, MirrorLib, cachedToolSyncs)
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
if key == K.Spawn then
spawnClone(Config.SpawnDistanceFar, false)
elseif key == K.SpawnHere then
spawnAtPlayer()
elseif key == K.MultiToggle then
multiCloneMode = not multiCloneMode
print("[MemeActor] Режим толпы клонов [U]:", multiCloneMode and "ВКЛ (клоны не удаляются при новом спавне)" or "ВЫКЛ (одиночный клон)")
elseif key == K.SwitchActor then
local onlyPortraits = UserInputService:IsKeyDown(K.Spawn)
for _ = 1, #ACTOR_LIST do
modeIdx = (modeIdx % #ACTOR_LIST) + 1
if not onlyPortraits or ACTOR_LIST[modeIdx].Type == "Portrait" then break end
end
print("[MemeActor] Выбран облик:", ACTOR_LIST[modeIdx].Label)
if activeClone and not multiCloneMode then
spawnClone(Config.SpawnDistanceFar, true)
end
elseif key == K.PaceToggle then
isSprint = not isSprint
print("[MemeActor] Темп:", isSprint and "БЕГ" or "ХОДЬБА")
elseif key == K.Crouch then
if not activeClone then spawnClone(Config.SpawnDistanceClose, false) end
setCrouch(not isCrouching)
elseif key == K.JitterToggle then
jitterOn = not jitterOn
if not jitterOn then
for _, entry in ipairs(allClones) do EffectsLib.ResetJitter(entry.jitter) end
end
elseif key == K.HeadLook then
headLookOn = not headLookOn
for _, entry in ipairs(allClones) do entry.neckCF = nil end
print("[MemeActor] HeadLook 360°:", headLookOn and "ВКЛ" or "ВЫКЛ")
elseif key == K.Rotate then
faceCam = not faceCam
if activeClone and cloneCF then ModeAPI.SetCFrame(cloneCF * CFrame.Angles(0, math.pi, 0)) end
elseif key == K.PunchAction and activeClone then
local cloneTool = activeClone:FindFirstChildOfClass("Tool")
local myTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
if (not cloneTool or cloneTool.Name ~= "BoxingGloves") and myTool and myTool.Name == "BoxingGloves" then
ModeAPI.AttachTool(false, false)
task.wait(0.18)
end
comboIdx = CombatLib.PlayCloneSwing(activeClone, comboIdx)
print("[MemeActor] Удар BoxingGloves (Action4)!")
elseif key == K.Remove then
removeAllClones()
print("[MemeActor] Все клоны удалены.")
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
if #allClones == 0 then return end
if jitterOn then
for _, entry in ipairs(allClones) do
if entry.model and entry.model.Parent then
EffectsLib.UpdateJitter(entry.jitter, Config.JitterIntensity or 4.0)
end
end
end
if activeClone and cloneCF and activeMode and activeMode.OnStep then
local r = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
local myR = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
if r then
activeMode.OnStep(dt, cloneCF, r, myR, myR and myR.Position.Y or cloneCF.Position.Y, isSprint)
end
end
updateToolDrivers()
end)
local steppedConn = RunService.Stepped:Connect(function(_, dt)
if #allClones == 0 then return end
if activeMode and activeMode.OnStepped then activeMode.OnStepped(dt) end
updateToolDrivers()
if headLookOn then
for _, entry in ipairs(allClones) do
if entry.model and entry.model.Parent and not entry.isRagdoll then
solveHeadLookForEntry(entry, dt)
end
end
end
        for _, entry in ipairs(allClones) do
            if entry.model and not entry.isRagdoll and not entry.model:GetAttribute("IsRagdoll") then

for _, part in ipairs(entry.model:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then
part.CanCollide = false
end
end
end
end
end)
ENV.StopMemeActor = function()
ENV.GardenVisibilityPatch = nil
if globalPunchDisconnect then globalPunchDisconnect() end
removeAllClones()
if inputConn then inputConn:Disconnect() end
if renderConn then renderConn:Disconnect() end
if steppedConn then steppedConn:Disconnect() end
end
Registry.PrintStartupBanner(Config)
end