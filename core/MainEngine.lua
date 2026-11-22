-- core/MainEngine.lua
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

    local Registry       = Import("core/Registry.lua")
    local MenuController = Import("core/MenuController.lua")
    local MirrorLib      = Import("libs/MirrorLib.lua")
    local EffectsLib     = Import("libs/EffectsLib.lua")
    local RigLib         = Import("libs/RigLib.lua")

    if not Registry or not MirrorLib or not EffectsLib or not RigLib then
        warn("[MemeActor] Отсутствуют базовые модули!")
        return
    end

    local BuildersCache = {}
    local function getBuilder(path)
        if not BuildersCache[path] then
            BuildersCache[path] = Import(path)
        end
        return BuildersCache[path]
    end

    local function resolveKey(info)
        local k = Config.Keys and Config.Keys[info.ConfigKey]
        return (k and Enum.KeyCode[k]) or info.Fallback
    end

    local ACTOR_LIST = Registry.ActorList
    local modeIdx = 1
    local multiCloneMode = false
    local isSprint = false
    local isCrouching = false
    local jitterOn = false
    local headLookOn = false
    local faceCam = false

    local allClones = {}
    local tracks = {}
    local cachedToolSyncs = {}
    local activeClone = nil
    local cloneCF = nil
    local activeMode = nil
    local activeSub = nil
    local lastFloorPos = nil
    local cachedFloorY = nil
    local rootOffset = 3.55
    local UIWindow = nil
    local UIToggles = {}
    local menuToggleConn = nil

    local Services = {}
    local ActionHandlers = {}
    local StateHandlers = {}
    local SpawnOverrides = {}
    local CleanupCallbacks = {}
    local LoadedModes = {}

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    local function getFloorY(pos, refY, force)
        if not force and lastFloorPos and cachedFloorY then
            local flatDist = (Vector3.new(pos.X, 0, pos.Z) - lastFloorPos).Magnitude
            if flatDist < 0.25 then
                return cachedFloorY
            end
        end
        local ignore = {}
        for _, entry in ipairs(allClones) do
            if entry.model then
                table.insert(ignore, entry.model)
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                table.insert(ignore, p.Character)
            end
        end
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(Vector3.new(pos.X, (refY or pos.Y) + 2, pos.Z), Vector3.new(0, -30, 0), rayParams)
        local fy = hit and (hit.Position.Y + rootOffset) or (refY or pos.Y)
        lastFloorPos = Vector3.new(pos.X, 0, pos.Z)
        cachedFloorY = fy
        return fy
    end

    local function solveHeadLookForEntry(entry, dt)
        local neck = entry.neck
        local head = entry.head
        if not neck or not neck.Parent or not head or not head.Parent or not neck.Part0 then
            return
        end
        local baseW = neck.Part0.CFrame * neck.C0
        local headPos = (baseW * neck.C1:Inverse()).Position
        local toTarget = workspace.CurrentCamera.CFrame.Position - headPos
        if toTarget.Magnitude < 0.05 then
            return
        end
        local dir = toTarget.Unit
        local up = baseW.UpVector
        if math.abs(dir:Dot(up)) > 0.995 then
            up = baseW.RightVector
        end
        local rx, ry, rz = baseW.Rotation:ToObjectSpace(CFrame.lookAt(Vector3.zero, dir, up)):ToEulerAnglesYXZ()
        rx = math.clamp(rx, math.rad(-65), math.rad(65))
        rz = math.clamp(rz, math.rad(-25), math.rad(25))
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
        if UIToggles.Crouch then
            UIToggles.Crouch.Set(isCrouching, true)
        end
        for _, entry in ipairs(allClones) do
            local tr = entry.tracks and entry.tracks.crouch
            if tr then
                if isCrouching then
                    if not tr.IsPlaying then
                        tr:Play(0.2, 1, 0)
                    end
                elseif tr.IsPlaying then
                    tr:Stop(0.2)
                end
            end
        end
    end

        local function updateAnim(speed, sprint)
        if isCrouching and tracks.crouch then
            if tracks.idle then tracks.idle:AdjustWeight(0.001) end
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
            if tracks.idle then tracks.idle:AdjustWeight(0.001) end
            local isCustom = activeClone and activeClone:FindFirstChild("CustomAnimations") ~= nil
            local moveWeight = isCustom and 1 or math.clamp(speed / Config.WalkSpeed, 0.05, 1)

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
            if tracks.idle then tracks.idle:AdjustWeight(1) end
            tracks.walk:AdjustWeight(0.001)
            tracks.walk:AdjustSpeed(0.01)
            if tracks.sprint then
                tracks.sprint:AdjustWeight(0.001)
                tracks.sprint:AdjustSpeed(0.01)
            end
        end
    end


    local function setMode(modeObj, sub)
        if activeMode and activeMode ~= modeObj and activeMode.OnDeactivate then
            activeMode.OnDeactivate()
        end
        if activeMode == modeObj and activeSub == sub then
            if activeMode and activeMode.OnDeactivate then
                activeMode.OnDeactivate()
            end
            activeMode = nil
            activeSub = nil
            return
        end
        activeMode = modeObj
        activeSub = sub
        if activeMode and activeMode.OnActivate then
            activeMode.OnActivate(sub)
        end
    end

    local function removeAllClones()
        if activeMode and activeMode.OnDeactivate then
            activeMode.OnDeactivate()
        end
        activeMode = nil
        activeSub = nil
        cloneCF = nil
        lastFloorPos = nil
        cachedFloorY = nil
        table.clear(cachedToolSyncs)
        for _, entry in ipairs(allClones) do
            if entry.tracks then
                for _, t in pairs(entry.tracks) do
                    pcall(function()
                        t:Stop()
                    end)
                end
            end
            if entry.model then
                entry.model:Destroy()
            end
        end
        table.clear(allClones)
        tracks = {}
        activeClone = nil
        ENV.ActiveActorClone = nil
    end

        local function setupRigTracks(clone)
        local customFolder = clone:FindFirstChild("CustomAnimations")
        if customFolder then
            local hum = clone:FindFirstChildOfClass("Humanoid")
            local anim = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
            local res = {}
            if anim then
                local prios = {
                    idle   = Enum.AnimationPriority.Idle,
                    walk   = Enum.AnimationPriority.Movement,
                    sprint = Enum.AnimationPriority.Movement,
                    crouch = Enum.AnimationPriority.Action,
                }
                for _, name in ipairs({ "idle", "walk", "sprint", "crouch" }) do
                    local a = customFolder:FindFirstChild(name, true)
                    if a and a:IsA("Animation") then
                        local tr = anim:LoadAnimation(a)
                        tr.Looped = true
                        tr.Priority = prios[name] or Enum.AnimationPriority.Movement
                        res[name] = tr
                    end
                end
                if res.idle then
                    res.idle:Play(0.1, 1, 1)
                end
                if res.walk then
                    res.walk:Play(0.1, 0.001, 0.01)
                end
                if res.sprint then
                    res.sprint:Play(0.1, 0.001, 0.01)
                end
            end
            return res
        end
        return RigLib.SetupAnimations(clone, LocalPlayer.Character)
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
            activeMode = nil
            activeSub = nil
        end

        local actorInfo = ACTOR_LIST[modeIdx] or ACTOR_LIST[1]
        local builderFn = getBuilder(actorInfo.Path or "builders/PortraitBuilder.lua")
        if type(builderFn) ~= "function" then
            return
        end

        local clone = builderFn(actorInfo.Variant)
        if not clone then
            return
        end

        clone.Parent = workspace
        activeClone = clone
        ENV.ActiveActorClone = clone

        local isPort = (clone:GetAttribute("IsPortrait") == true) or (actorInfo.Type == "Portrait") or (actorInfo.IsPortrait == true)
        clone:SetAttribute("IsPortrait", isPort)

        rootOffset = clone:GetAttribute("RootOffset") or actorInfo.RootOffset or (isPort and 3.65 or 3.55)

        local headPart = clone:FindFirstChild("FHead") or clone:FindFirstChild("Head")
        local neckMotor = nil
        for _, d in ipairs(clone:GetDescendants()) do
            if (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) and d.Name == "Neck" then
                neckMotor = d
                break
            end
        end

        if clone:GetAttribute("NoTools") ~= true then
            RigLib.AttachTool(clone, false, isPort, MirrorLib, cachedToolSyncs)
        end

        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
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
        if root then
            root.CFrame = cloneCF
        end

        tracks = setupRigTracks(clone)
        if clone:GetAttribute("NoTools") ~= true then
            RigLib.AttachTool(clone, false, isPort, MirrorLib, cachedToolSyncs, tracks, false)
        end

        table.insert(allClones, {
            model = clone,
            cframe = cloneCF,
            head = headPart,
            neck = neckMotor,
            jitter = EffectsLib.CacheJitterParts(clone),
            tracks = tracks,
            isRagdoll = false,
        })

        setCrouch(sCrouch)
        if sMode then
            setMode(sMode, sSub)
        end
    end

local function spawnAtPlayer()
local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart"))
if not myRoot then
return
end
local look = myRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
look = (look.Magnitude < 0.01) and Vector3.new(0, 0, -1) or look.Unit
spawnClone(0, false, CFrame.lookAt(myRoot.Position, myRoot.Position + look))
if myChar:GetAttribute("Crouching") == true then
setCrouch(true)
end
end
local function startModeById(mId, sub, autoSpawn)
if not LoadedModes[mId] then
return
end
if not activeClone then
local customCF = SpawnOverrides[mId] and SpawnOverridesmId or nil
if customCF then
spawnClone(0, false, customCF)
else
spawnClone((autoSpawn == "Close") and Config.SpawnDistanceClose or Config.SpawnDistanceFar, false)
end
end
setMode(LoadedModes[mId], sub)
end
local EngineAPI = {
Config = Config,
Import = Import,
GetClone = function()
return activeClone
end,
GetAllClones = function()
return allClones
end,
GetActiveMode = function()
return activeMode
end,
GetCFrame = function()
return cloneCF
end,
SetCFrame = function(cf)
cloneCF = cf
if #allClones > 0 then
allClones[#allClones].cframe = cf
end
local r = activeClone and (activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart"))
if r then
r.CFrame = cf
end
end,
GetFloorY = getFloorY,
UpdateAnimation = updateAnim,
GetSubMode = function()
return activeSub
end,
SetSubMode = function(s)
activeSub = s
end,
        IsCrouching = function()
            return isCrouching
        end,
        IsMultiClone = function()
            return multiCloneMode
        end,
        SetCrouch = setCrouch,

IsHeadLookEnabled = function()
return headLookOn
end,
SpawnClone = spawnClone,
StartMode = startModeById,
        AttachTool = function(mirrored, skipTrack)
            if not activeClone or activeClone:GetAttribute("NoTools") == true then
                return
            end
            local isPort = (activeClone:GetAttribute("IsPortrait") == true)
            RigLib.AttachTool(activeClone, mirrored, isPort, MirrorLib, cachedToolSyncs, tracks, skipTrack)
            updateToolDrivers()
        end,

StopAllTracks = function()
for _, t in pairs(tracks) do
if t.IsPlaying then
t:Stop(0.1)
end
end
end,
PlayIdle = function()
if tracks.idle then
tracks.idle:Play(0.1)
end
if tracks.tool then
tracks.tool:Play(0.1)
end
end,
RegisterService = function(name, svc)
Services[name] = svc
end,
GetService = function(name)
return Services[name]
end,
RegisterAction = function(name, fn)
ActionHandlers[name] = fn
end,
RegisterState = function(name, getFn, setFn)
StateHandlers[name] = { get = getFn, set = setFn }
end,
RegisterSpawnOverride = function(modeId, fn)
SpawnOverrides[modeId] = fn
end,
OnCleanup = function(fn)
table.insert(CleanupCallbacks, fn)
end,
}
EngineAPI.RegisterAction("SpawnFar", function()
spawnClone(Config.SpawnDistanceFar, false)
end)
EngineAPI.RegisterAction("SpawnHere", spawnAtPlayer)
EngineAPI.RegisterAction("SwitchActor", function()
modeIdx = (modeIdx % #ACTOR_LIST) + 1
print("[MemeActor] Облик:", ACTOR_LIST[modeIdx].Label)
if activeClone and not multiCloneMode then
spawnClone(Config.SpawnDistanceFar, true)
end
end)
EngineAPI.RegisterAction("Rotate", function()
faceCam = not faceCam
if activeClone and cloneCF then
EngineAPI.SetCFrame(cloneCF * CFrame.Angles(0, math.pi, 0))
end
end)
EngineAPI.RegisterAction("RemoveAll", removeAllClones)
EngineAPI.RegisterState("MultiClone", function()
return multiCloneMode
end, function(v)
multiCloneMode = v
end)
EngineAPI.RegisterState("Crouch", function()
return isCrouching
end, function(v)
if not activeClone then
spawnClone(Config.SpawnDistanceClose, false)
end
setCrouch(v)
end)
EngineAPI.RegisterState("HeadLook", function()
return headLookOn
end, function(v)
headLookOn = v
for _, e in ipairs(allClones) do
e.neckCF = nil
end
end)
EngineAPI.RegisterState("Jitter", function()
return jitterOn
end, function(v)
jitterOn = v
if not v then
for _, e in ipairs(allClones) do
EffectsLib.ResetJitter(e.jitter)
end
end
end)
for _, pluginPath in ipairs(Registry.Plugins or {}) do
local pInit = Import(pluginPath)
if type(pInit) == "function" then
pInit(EngineAPI)
end
end
for _, m in ipairs(Registry.ModeModules or {}) do
local f = Import(m.Path)
if type(f) == "function" then
LoadedModes[m.Id] = f(EngineAPI)
end
end
if MenuController then
UIWindow, UIToggles, menuToggleConn = MenuController.Build(Import, Registry, {
Actions = ActionHandlers,
States = StateHandlers,
RunMode = startModeById,
})
end
local SystemKeyActions = {
Spawn = function()
ActionHandlers.SpawnFar()
end,
SpawnHere = function()
ActionHandlers.SpawnHere()
end,
MultiToggle = function()
multiCloneMode = not multiCloneMode
if UIToggles.MultiClone then
UIToggles.MultiClone.Set(multiCloneMode, true)
end
end,
SwitchActor = function()
ActionHandlers.SwitchActor()
end,
PaceToggle = function()
isSprint = not isSprint
end,
Crouch = function()
StateHandlers.Crouch.set(not isCrouching)
end,
JitterToggle = function()
StateHandlers.Jitter.set(not jitterOn)
if UIToggles.Jitter then
UIToggles.Jitter.Set(jitterOn, true)
end
end,
HeadLook = function()
StateHandlers.HeadLook.set(not headLookOn)
if UIToggles.HeadLook then
UIToggles.HeadLook.Set(headLookOn, true)
end
end,
Rotate = function()
ActionHandlers.Rotate()
end,
PunchAction = function()
if ActionHandlers.Punch then
ActionHandlers.Punch()
end
end,
Remove = function()
ActionHandlers.RemoveAll()
end,
}
local KeyMap = {}
for name, info in pairs(Registry.SystemKeys) do
local kc = resolveKey(info)
if kc and SystemKeyActions[name] then
KeyMap[kc] = SystemKeyActions[name]
end
end
local Binds = {}
for _, b in ipairs(Registry.ModeBindings) do
table.insert(Binds, {
Key = resolveKey(b),
Id = b.ModuleId,
Sub = b.SubMode,
Spawn = b.AutoSpawn,
})
end
    local inputConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or UserInputService:GetFocusedTextBox() then
            return
        end
        local key = inp.KeyCode
        local actionFn = KeyMap[key]
        if actionFn then
            actionFn()
            return
        end
        for _, b in ipairs(Binds) do
            if key == b.Key then
                startModeById(b.Id, b.Sub, b.Spawn)
                break
            end
        end
    end)

local renderConn = RunService.RenderStepped:Connect(function(dt)
if #allClones == 0 then
return
end
if jitterOn then
for _, e in ipairs(allClones) do
if e.model and e.model.Parent then
EffectsLib.UpdateJitter(e.jitter, Config.JitterIntensity or 4.0)
end
end
end
        if activeClone and cloneCF and activeMode and activeMode.OnStep then
            local r = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
            local myChar = LocalPlayer.Character
            local myR = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("CollisionPart") or myChar.PrimaryPart)
            if r then
                activeMode.OnStep(dt, cloneCF, r, myR, myR and myR.Position.Y or cloneCF.Position.Y, isSprint)
            end
        end

updateToolDrivers()
end)
local steppedConn = RunService.Stepped:Connect(function(_, dt)
if #allClones == 0 then
return
end
if activeMode and activeMode.OnStepped then
activeMode.OnStepped(dt)
end
updateToolDrivers()
for _, e in ipairs(allClones) do
if e.model and e.model.Parent and not e.isRagdoll and not e.model:GetAttribute("IsRagdoll") then
if headLookOn then
solveHeadLookForEntry(e, dt)
end
for _, part in ipairs(e.model:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then
part.CanCollide = false
end
end
end
end
end)
ENV.StopMemeActor = function()
ENV.GardenVisibilityPatch = nil
for _, fn in ipairs(CleanupCallbacks) do
pcall(fn)
end
if menuToggleConn then
menuToggleConn:Disconnect()
end
if UIWindow and UIWindow.Gui then
UIWindow.Gui:Destroy()
end
removeAllClones()
if inputConn then
inputConn:Disconnect()
end
if renderConn then
renderConn:Disconnect()
end
if steppedConn then
steppedConn:Disconnect()
end
end
Registry.PrintStartupBanner(Config)
end