-- core/MainEngine.lua (v0.1)
return function(Import, Config)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local ENV = getgenv()

    if ENV.GardenVisibilityPatch then
        warn("[MemeActor] Скрипт уже запущен!")
        return
    end
    ENV.GardenVisibilityPatch = true

    -- Загружаем PortraitBuilder из папки builders/ репозитория
    local BuildPortraitRig = ENV.BuildPortraitRig or Import("builders/PortraitBuilder.lua")
    if type(BuildPortraitRig) == "function" then
        ENV.BuildPortraitRig = BuildPortraitRig
    else
        warn("[MemeActor] Ошибка загрузки builders/PortraitBuilder.lua!")
    end

    local function getKey(name, fallback)
        local keyStr = Config.Keys and Config.Keys[name]
        return (keyStr and Enum.KeyCode[keyStr]) or fallback
    end

    local KEY_SPAWN      = getKey("Spawn", Enum.KeyCode.Z)
    local KEY_SWITCH     = getKey("SwitchActor", Enum.KeyCode.G)
    local KEY_STRAIGHT   = getKey("StraightMove", Enum.KeyCode.F)
    local KEY_PACE       = getKey("PaceToggle", Enum.KeyCode.L)
    local KEY_CHASE      = getKey("Chase", Enum.KeyCode.N)
    local KEY_STATUE     = getKey("Statue", Enum.KeyCode.H)
    local KEY_HEADLOOK   = getKey("HeadLook", Enum.KeyCode.K)
    local KEY_ROTATE     = getKey("Rotate", Enum.KeyCode.B)
    local KEY_REMOVE     = getKey("Remove", Enum.KeyCode.V)

    local ACTOR_MODES = { "PortraitLight", "PortraitDark", "Player" }
    local ACTOR_MODE_LABELS = {
        PortraitLight = "Portrait Light (Белый - Сток)",
        PortraitDark  = "Portrait Dark (Чёрный)",
        Player        = "Клон друга"
    }
    local currentModeIndex = 1
    local isSprintPace = false

    -- ============================================
    -- HEADLOOK 360° (Без провала головы в тело)
    -- ============================================
    local currentNeckCFrame = nil

    local function solveHeadLook(neckMotor, headPart, targetPos, dt)
        if not neckMotor or not neckMotor.Parent or not headPart or not headPart.Parent then return end
        local part0 = neckMotor.Part0
        if not part0 then return end

        local baseWorld = part0.CFrame * neckMotor.C0
        local headCenterPos = (baseWorld * neckMotor.C1:Inverse()).Position
        local toTarget = targetPos - headCenterPos
        if toTarget.Magnitude < 0.05 then return end

        local lookDir = toTarget.Unit
        local upVec = baseWorld.UpVector
        if math.abs(lookDir:Dot(upVec)) > 0.995 then
            upVec = baseWorld.RightVector
        end

        local desiredWorld = CFrame.lookAt(Vector3.zero, lookDir, upVec)
        local localRot = baseWorld.Rotation:ToObjectSpace(desiredWorld)
        local rx, ry, rz = localRot:ToEulerAnglesYXZ()

        rx = math.clamp(rx, math.rad(-65), math.rad(65))
        rz = math.clamp(rz, math.rad(-25), math.rad(25))

        local cleanRot = CFrame.fromEulerAnglesYXZ(rx, ry, rz)
        local targetTransform = neckMotor.C1 * cleanRot * neckMotor.C1:Inverse()

        if not currentNeckCFrame then
            currentNeckCFrame = targetTransform
        else
            currentNeckCFrame = currentNeckCFrame:Lerp(targetTransform, math.clamp((dt or 0.016) * 14, 0, 1))
        end
        neckMotor.Transform = currentNeckCFrame
    end

    -- ============================================
    -- СОСТОЯНИЕ И ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ============================================
    local activeClone, cloneCFrame = nil, nil
    local cloneRunning, cloneChasing, angelMode, headLookEnabled, faceCamera = false, false, false, false, false
    local walkTrack, sprintTrack, idleTrack, toolTrack = nil, nil, nil, nil
    local rootToFeetOffset = 3.55
    local chaseVelocity = Vector3.zero

    local cachedNeckMotor, cachedHeadPart = nil, nil
    local lastFloorCheckPos, cachedFloorY = nil, nil

    local rayParams = RaycastParams.new()
    rayParams.FilterType, rayParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true

    local function getTargetPlayer()
        if Config.TargetPlayerName ~= "" and Config.TargetPlayerName ~= LocalPlayer.Name then
            local p = Players:FindFirstChild(Config.TargetPlayerName)
            if p and p.Character then return p end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then return p end
        end
        return LocalPlayer
    end

    local function getFloorY(pos, refY, forceUpdate)
        if not activeClone then return pos.Y end
        if not forceUpdate and lastFloorCheckPos and cachedFloorY then
            if (Vector3.new(pos.X, 0, pos.Z) - lastFloorCheckPos).Magnitude < 0.25 then
                return cachedFloorY
            end
        end

        local ignoreList = { activeClone }
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignoreList, p.Character) end
        end
        rayParams.FilterDescendantsInstances = ignoreList

        local startY = (refY or pos.Y) + 2.0
        local result = workspace:Raycast(Vector3.new(pos.X, startY, pos.Z), Vector3.new(0, -30, 0), rayParams)
        local finalY = refY or pos.Y
        if result then
            finalY = result.Position.Y + rootToFeetOffset
        end

        lastFloorCheckPos = Vector3.new(pos.X, 0, pos.Z)
        cachedFloorY = finalY
        return finalY
    end

    local function attachToolToRig(model, sourceChar)
        for _, oldTool in ipairs(model:GetChildren()) do
            if oldTool:IsA("Tool") then oldTool:Destroy() end
        end
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Motor6D") and desc.Name == "RightGrip" then desc:Destroy() end
        end

        if not sourceChar then return end
        local sourceTool = sourceChar:FindFirstChildOfClass("Tool")
        if not sourceTool then return end

        local targetHand = model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
        if not targetHand then return end

        local sourceHand = sourceChar:FindFirstChild("RightHand") or sourceChar:FindFirstChild("Right Arm")
        local origJoint, origPart1Name = nil, nil
        if sourceHand then
            for _, desc in ipairs(sourceChar:GetDescendants()) do
                if (desc:IsA("Motor6D") or desc:IsA("Weld")) then
                    if desc.Part0 == sourceHand and desc.Part1 and desc.Part1:IsDescendantOf(sourceTool) then
                        origJoint, origPart1Name = desc, desc.Part1.Name break
                    elseif desc.Part1 == sourceHand and desc.Part0 and desc.Part0:IsDescendantOf(sourceTool) then
                        origJoint, origPart1Name = desc, desc.Part0.Name break
                    end
                end
            end
        end

        sourceTool.Archivable = true
        local clonedTool = sourceTool:Clone()
        sourceTool.Archivable = false
        if not clonedTool then return end

        for _, d in ipairs(clonedTool:GetDescendants()) do
            if d:IsA("LocalScript") or d:IsA("Script") then d:Destroy()
            elseif d:IsA("BasePart") then
                d.CanCollide, d.CanTouch, d.CanQuery, d.Massless, d.Anchored, d.LocalTransparencyModifier = false, false, false, true, false, 0
            elseif d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
        end
        clonedTool.Parent = model

        local targetPart = (origPart1Name and clonedTool:FindFirstChild(origPart1Name, true))
            or clonedTool:FindFirstChild("Handle") or clonedTool:FindFirstChild("Main") or clonedTool:FindFirstChildWhichIsA("BasePart")
        if not targetPart then return end

        for _, j in ipairs(targetPart:GetChildren()) do
            if (j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("WeldConstraint")) then
                if not j.Part0 or not j.Part0:IsDescendantOf(clonedTool) or not j.Part1 or not j.Part1:IsDescendantOf(clonedTool) then j:Destroy() end
            end
        end

        local newJoint = Instance.new("Motor6D")
        if origJoint then
            newJoint.Name = origJoint.Name
            if origJoint.Part0 == sourceHand then newJoint.Part0, newJoint.Part1 = targetHand, targetPart
            else newJoint.Part0, newJoint.Part1 = targetPart, targetHand end
            newJoint.C0, newJoint.C1 = origJoint.C0, origJoint.C1
        else
            newJoint.Name, newJoint.Part0, newJoint.Part1 = "RightGrip", targetHand, targetPart
            newJoint.C0 = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            newJoint.C1 = clonedTool.Grip
        end
        newJoint.Parent = targetHand
    end

    local function cacheHeadRigParts(clone)
        cachedHeadPart = clone:FindFirstChild("FHead") or clone:FindFirstChild("Head")
        cachedNeckMotor, currentNeckCFrame = nil, nil
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("Motor6D") and desc.Name == "Neck" then
                cachedNeckMotor = desc
                break
            end
        end
    end

    local function playToolAnimation(clone, animator)
        local tool = clone:FindFirstChildOfClass("Tool")
        if not tool then return end
        local chosenAnim = nil
        for _, desc in ipairs(tool:GetDescendants()) do
            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                local n = desc.Name:lower()
                if (n:find("idle") or n:find("hold")) and not n:find("equip") then chosenAnim = desc break end
            end
        end
        if not chosenAnim then
            chosenAnim = Instance.new("Animation")
            chosenAnim.AnimationId = "rbxassetid://507768375"
        end
        toolTrack = animator:LoadAnimation(chosenAnim)
toolTrack.Looped, toolTrack.Priority = true, Enum.AnimationPriority.Action2
toolTrack:Play(0.1)
end
local function updateLocomotionAnimation(speed, forceSprint)
if not walkTrack then return end
if speed > 0.8 then
local useSprint = (forceSprint == true) and (sprintTrack ~= nil)
if useSprint then
if walkTrack.IsPlaying then walkTrack:Stop(0.15) end
if not sprintTrack.IsPlaying then sprintTrack:Play(0.15, 1, math.clamp(speed / Config.SprintSpeed, 0.75, 1.4))
else sprintTrack:AdjustSpeed(math.clamp(speed / Config.SprintSpeed, 0.75, 1.4)) end
else
if sprintTrack and sprintTrack.IsPlaying then sprintTrack:Stop(0.15) end
if not walkTrack.IsPlaying then walkTrack:Play(0.15, 1, math.clamp(speed / Config.WalkSpeed, 0.65, 1.35))
else walkTrack:AdjustSpeed(math.clamp(speed / Config.WalkSpeed, 0.65, 1.35)) end
end
else
if walkTrack.IsPlaying then walkTrack:Stop(0.18) end
if sprintTrack and sprintTrack.IsPlaying then sprintTrack:Stop(0.18) end
end
end
local function removeClone()
cloneRunning, cloneChasing, angelMode = false, false, false
cloneCFrame, chaseVelocity = nil, Vector3.zero
lastFloorCheckPos, cachedFloorY = nil, nil
cachedNeckMotor, cachedHeadPart, currentNeckCFrame = nil, nil, nil
for _, track in ipairs({ walkTrack, sprintTrack, idleTrack, toolTrack }) do
if track then pcall(function() track:Stop() end) end
end
walkTrack, sprintTrack, idleTrack, toolTrack = nil, nil, nil, nil
if activeClone then activeClone:Destroy() activeClone = nil end
ENV.ActiveActorClone = nil
end
local function spawnCloneAtCamera(customDistance, preserveTransform)
local savedCFrame = preserveTransform and cloneCFrame or nil
local wasRunning = preserveTransform and cloneRunning or false
local wasChasing = preserveTransform and cloneChasing or false
local wasAngel = preserveTransform and angelMode or false
removeClone()
local spawnDist = customDistance or Config.SpawnDistanceFar
local currentMode = ACTOR_MODES[currentModeIndex]
local target = getTargetPlayer()
local sourceChar = (target and target.Character) or LocalPlayer.Character
local clone = nil
if currentMode == "Player" then
if not sourceChar then return end
sourceChar.Archivable = true
clone = sourceChar:Clone()
sourceChar.Archivable = false
if not clone then return end
clone.Name = (target and target.Name or LocalPlayer.Name) .. "_MemeClone"
for _, desc in ipairs(clone:GetDescendants()) do
if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("Animator") then desc:Destroy() end
end
local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
for _, part in ipairs(clone:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide, part.Massless = false, true
part.Anchored = (part == root or part.Name == "CollisionPart" or part.Name == "HumanoidRootPart")
part.LocalTransparencyModifier = 0
elseif part:IsA("Decal") then part.LocalTransparencyModifier = 0 end
end
attachToolToRig(clone, sourceChar)
else
if not BuildPortraitRig then return end
clone = BuildPortraitRig(currentMode)
if sourceChar then attachToolToRig(clone, sourceChar) end
end
clone.Parent = workspace
activeClone = clone
ENV.ActiveActorClone = clone
cacheHeadRigParts(clone)
local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
rootToFeetOffset = (currentMode == "Player") and 3.55 or 3.65
if savedCFrame then
cloneCFrame = savedCFrame
else
local cam = workspace.CurrentCamera
local lookFlat = (cam.CFrame.LookVector * Vector3.new(1, 0, 1))
if lookFlat.Magnitude < 0.01 then lookFlat = Vector3.new(0, 0, -1) else lookFlat = lookFlat.Unit end
local spawnPos = cam.CFrame.Position + lookFlat * spawnDist
local refY = (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart) and LocalPlayer.Character.PrimaryPart.Position.Y or cam.CFrame.Position.Y
local groundY = getFloorY(spawnPos, refY, true)
local yaw = math.atan2(-lookFlat.X, -lookFlat.Z) + (faceCamera and math.pi or 0)
cloneCFrame = CFrame.new(spawnPos.X, groundY, spawnPos.Z) * CFrame.Angles(0, yaw, 0)
end
if root then root.CFrame = cloneCFrame end
local humanoid = clone:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.EvaluateStateMachine = false
humanoid.PlatformStand = false
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local animSourceChar = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Animations")) and LocalPlayer.Character or sourceChar
local animFolder = animSourceChar and animSourceChar:FindFirstChild("Animations")
if animFolder then
local idleAnim = animFolder:FindFirstChild("Idle")
if idleAnim and idleAnim:IsA("Animation") then
idleTrack = animator:LoadAnimation(idleAnim)
idleTrack.Looped, idleTrack.Priority = true, Enum.AnimationPriority.Idle
idleTrack:Play(0.1)
end
local forwardAnim = animFolder:FindFirstChild("Forward")
if forwardAnim and forwardAnim:IsA("Animation") then
walkTrack = animator:LoadAnimation(forwardAnim)
walkTrack.Looped, walkTrack.Priority = true, Enum.AnimationPriority.Action
end
local sprintingAnim = animFolder:FindFirstChild("Sprinting")
if sprintingAnim and sprintingAnim:IsA("Animation") then
sprintTrack = animator:LoadAnimation(sprintingAnim)
sprintTrack.Looped, sprintTrack.Priority = true, Enum.AnimationPriority.Action
end
end
if not walkTrack then
local fallbackAnim = Instance.new("Animation")
fallbackAnim.AnimationId = "rbxassetid://913376220"
walkTrack = animator:LoadAnimation(fallbackAnim)
walkTrack.Looped, walkTrack.Priority = true, Enum.AnimationPriority.Action
end
playToolAnimation(clone, animator)
end
cloneRunning, cloneChasing, angelMode = wasRunning, wasChasing, wasAngel
print("[MemeActor] Клон создан:", ACTOR_MODE_LABELS[currentMode])
end
-- ============================================
-- УПРАВЛЕНИЕ
-- ============================================
UserInputService.InputBegan:Connect(function(input, gp)
if gp or UserInputService:GetFocusedTextBox() then return end
local key = input.KeyCode
if key == KEY_SPAWN then
spawnCloneAtCamera(Config.SpawnDistanceFar, false)
elseif key == KEY_SWITCH then
local onlyPortraits = UserInputService:IsKeyDown(KEY_SPAWN)
for _ = 1, #ACTOR_MODES do
currentModeIndex = (currentModeIndex % #ACTOR_MODES) + 1
if not onlyPortraits or ACTOR_MODES[currentModeIndex] ~= "Player" then break end
end
print("[MemeActor] Облик:", ACTOR_MODE_LABELS[ACTOR_MODES[currentModeIndex]])
if activeClone then spawnCloneAtCamera(Config.SpawnDistanceFar, true) end
elseif key == KEY_PACE then
isSprintPace = not isSprintPace
print("[MemeActor] Темп:", isSprintPace and "БЕГ (Sprinting)" or "ХОДЬБА (Forward)")
elseif key == KEY_STRAIGHT then
if not activeClone then spawnCloneAtCamera(Config.SpawnDistanceClose, false) end
cloneRunning = not cloneRunning
if cloneRunning then
cloneChasing, angelMode = false, false
else
updateLocomotionAnimation(0, false)
end
print("[MemeActor] Прямое движение [F]:", cloneRunning and "ВКЛ" or "ВЫКЛ")
elseif key == KEY_CHASE then
if not activeClone then spawnCloneAtCamera(Config.SpawnDistanceFar, false) end
cloneChasing = not cloneChasing
if cloneChasing then
cloneRunning, angelMode, chaseVelocity = false, false, Vector3.zero
else
updateLocomotionAnimation(0, false)
end
elseif key == KEY_STATUE then
if not activeClone then spawnCloneAtCamera(Config.SpawnDistanceFar, false) end
angelMode = not angelMode
if angelMode then
cloneRunning, cloneChasing = false, false
else
updateLocomotionAnimation(0, false)
end
elseif key == KEY_HEADLOOK then
headLookEnabled = not headLookEnabled
currentNeckCFrame = nil
print("[MemeActor] HeadLook 360° [K]:", headLookEnabled and "ВКЛ" or "ВЫКЛ")
elseif key == KEY_ROTATE then
faceCamera = not faceCamera
if activeClone and cloneCFrame then
cloneCFrame = cloneCFrame * CFrame.Angles(0, math.pi, 0)
local root = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
if root then root.CFrame = cloneCFrame end
end
elseif key == KEY_REMOVE then
removeClone()
end
end)
-- ============================================
-- ЦИКЛ ДВИЖЕНИЯ И ВЗГЛЯДА
-- ============================================
RunService.RenderStepped:Connect(function(dt)
if not activeClone or not cloneCFrame then return end
local root = activeClone.PrimaryPart or activeClone:FindFirstChild("HumanoidRootPart")
if not root then return end
local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
local refY = myRoot and myRoot.Position.Y or cloneCFrame.Position.Y
if angelMode then
local cam = workspace.CurrentCamera
local toClone = (cloneCFrame.Position - cam.CFrame.Position)
if cam.CFrame.LookVector:Dot(toClone.Unit) > 0.45 then
updateLocomotionAnimation(0, false)
elseif myRoot then
local flat = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
if flat.Magnitude > 4 then
local speed = isSprintPace and Config.SprintSpeed or Config.WalkSpeed
updateLocomotionAnimation(speed, isSprintPace)
local nextPos = cloneCFrame.Position + flat.Unit * speed * dt
local floorY = getFloorY(nextPos, refY, false)
cloneCFrame = CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(myRoot.Position.X, floorY, myRoot.Position.Z))
root.CFrame = cloneCFrame
else
updateLocomotionAnimation(0, false)
end
end
return
end
if cloneChasing and myRoot then
local toPlayer = (myRoot.Position - cloneCFrame.Position) * Vector3.new(1, 0, 1)
local dist = toPlayer.Magnitude
local maxSpd = isSprintPace and Config.SprintSpeed or Config.WalkSpeed
if dist > Config.ChaseStopDistance then
chaseVelocity = chaseVelocity:Lerp(toPlayer.Unit * maxSpd, math.clamp(dt * (Config.ChaseAcceleration / 10), 0, 1))
else
chaseVelocity = chaseVelocity:Lerp(Vector3.zero, math.clamp(dt * Config.ChaseFriction, 0, 1))
end
local spd = chaseVelocity.Magnitude
if spd > 0.3 then
updateLocomotionAnimation(spd, isSprintPace)
local nextPos = cloneCFrame.Position + chaseVelocity * dt
local floorY = getFloorY(nextPos, refY, false)
cloneCFrame = CFrame.lookAt(Vector3.new(nextPos.X, floorY, nextPos.Z), Vector3.new(nextPos.X + chaseVelocity.X, floorY, nextPos.Z + chaseVelocity.Z))
root.CFrame = cloneCFrame
else
updateLocomotionAnimation(0, false)
local lookTarget = Vector3.new(myRoot.Position.X, cloneCFrame.Position.Y, myRoot.Position.Z)
cloneCFrame = cloneCFrame:Lerp(CFrame.lookAt(cloneCFrame.Position, lookTarget), math.clamp(dt * 8, 0, 1))
root.CFrame = cloneCFrame
end
return
end
if cloneRunning then
local speed = isSprintPace and Config.SprintSpeed or Config.WalkSpeed
updateLocomotionAnimation(speed, isSprintPace)
local nextPos = cloneCFrame.Position + cloneCFrame.LookVector * speed * dt
local floorY = getFloorY(nextPos, refY, false)
cloneCFrame = CFrame.new(nextPos.X, floorY, nextPos.Z) * cloneCFrame.Rotation
root.CFrame = cloneCFrame
end
end)
RunService.Stepped:Connect(function(_, dt)
if not headLookEnabled or not activeClone or not cachedNeckMotor or not cachedHeadPart then return end
local camPos = workspace.CurrentCamera.CFrame.Position
solveHeadLook(cachedNeckMotor, cachedHeadPart, camPos, dt)
end)
print("[MemeActor v" .. tostring(Config.Version) .. "] Загружено! [Z] Спавн | [G] Облик | [F] Бег вперёд | [L] Темп | [N] Догонялки | [H] Статуя | [K] HeadLook 360° | [V] Удалить")
end