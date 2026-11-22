-- builders/HonchoBuilder.lua
-- Полный процедурный генератор модели Honcho с нуля (не требует наличия HonchoRig в плейсе!)

return function(variant)
    local model = Instance.new("Model")
    model.Name = "HonchoActorClone"
    model:SetAttribute("RootOffset", 5.05)
    model:SetAttribute("NoTools", true)

    local function makePart(name, size, color, material, transparency, shape)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color or Color3.fromRGB(163, 162, 165)
        p.Material = material or Enum.Material.SmoothPlastic
        p.Transparency = transparency or 0
        p.Shape = shape or Enum.PartType.Block
        p.Anchored = false
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Massless = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = model
        return p
    end

    local function weld(part0, part1, c0, c1)
        local w = Instance.new("Weld")
        w.Name = part1.Name .. "Weld"
        w.Part0 = part0
        w.Part1 = part1
        w.C0 = c0 or CFrame.new()
        w.C1 = c1 or CFrame.new()
        w.Parent = part0
        return w
    end

    local function motor(name, part0, part1, c0, c1)
        local m = Instance.new("Motor6D")
        m.Name = name
        m.Part0 = part0
        m.Part1 = part1
        m.C0 = c0 or CFrame.new()
        m.C1 = c1 or CFrame.new()
        m.Parent = part0
        return m
    end

    -- Палитра материалов Honcho (плоский картонно-бумажный стиль из дампа)
    local COL_SUIT      = Color3.fromRGB(72, 68, 76)
    local COL_SHIRT     = Color3.fromRGB(224, 218, 205)
    local COL_TIE       = Color3.fromRGB(145, 42, 42)
    local COL_SUSP      = Color3.fromRGB(132, 102, 74)
    local COL_RING      = Color3.fromRGB(215, 185, 95)
    local COL_WOOD      = Color3.fromRGB(138, 98, 64)
    local COL_PAPER     = Color3.fromRGB(238, 234, 224)
    local COL_SKIN_HAND = Color3.fromRGB(212, 198, 178)
    local COL_SHOE      = Color3.fromRGB(45, 42, 48)
    local COL_STAR_GLOW = Color3.fromRGB(255, 226, 120)

    -- 1. Корневой хитбокс (HumanoidRootPart)
    local hrp = makePart("HumanoidRootPart", Vector3.new(1.89, 1.89, 0.94), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    model.PrimaryPart = hrp

    -- Невидимые базовые R6-части для совместимости с Humanoid
    local dummyTorso = makePart("Torso", Vector3.new(2, 2, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    local dummyHead  = makePart("Head1", Vector3.new(2, 1, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    local dummyLArm  = makePart("Left Arm", Vector3.new(1, 2, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    local dummyRArm  = makePart("Right Arm", Vector3.new(1, 2, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    local dummyLLeg  = makePart("Left Leg", Vector3.new(1, 2, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)
    local dummyRLeg  = makePart("Right Leg", Vector3.new(1, 2, 1), Color3.new(1,1,1), Enum.Material.Plastic, 1)

    motor("Root Hip", hrp, dummyTorso, CFrame.new(), CFrame.new())
    motor("NeckDummy", dummyTorso, dummyHead, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    motor("Left Shoulder", dummyTorso, dummyLArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    motor("Right Shoulder", dummyTorso, dummyRArm, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    motor("Left Hip", dummyTorso, dummyLLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    motor("Right Hip", dummyTorso, dummyRLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

    -- 2. Таз и торс (Pelvis -> LowerTorso -> MiddleTorso -> UpperTorso)
    local pelvis      = makePart("Pelvis", Vector3.new(2.88, 0.86, 0.24), COL_SUIT, Enum.Material.Fabric)
    local pelvisLin   = makePart("PelvisLining", Vector3.new(2.41, 0.34, 0.26), COL_SUSP, Enum.Material.Fabric)
    local lowerTorso  = makePart("LowerTorso", Vector3.new(2.80, 0.71, 0.16), COL_SHIRT, Enum.Material.Fabric)
    local middleTorso = makePart("MiddleTorso", Vector3.new(2.80, 1.51, 0.47), COL_SHIRT, Enum.Material.Fabric)
    local upperTorso  = makePart("UpperTorso", Vector3.new(2.80, 1.57, 0.73), COL_SHIRT, Enum.Material.Fabric)

    motor("Pelvis", hrp, pelvis, CFrame.new(0, -0.4, 0), CFrame.new())
    weld(pelvis, pelvisLin, CFrame.new(0, 0.25, 0))
    motor("LowerTorso", pelvis, lowerTorso, CFrame.new(0, 0.43, 0), CFrame.new(0, -0.35, 0))
    motor("MiddleTorso", lowerTorso, middleTorso, CFrame.new(0, 0.35, 0), CFrame.new(0, -0.75, 0))
    motor("UpperTorso", middleTorso, upperTorso, CFrame.new(0, 0.75, 0), CFrame.new(0, -0.78, 0))

    -- Подтяжки (Suspenders)
    local lowSusp  = makePart("LowerSuspenders", Vector3.new(1.97, 0.30, 0.30), COL_SUSP, Enum.Material.Cardboard)
    local midSusp  = makePart("MiddleSuspenders", Vector3.new(1.99, 1.29, 0.53), COL_SUSP, Enum.Material.Cardboard)
    local upSusp   = makePart("UpperSuspenders", Vector3.new(2.00, 1.42, 0.76), COL_SUSP, Enum.Material.Cardboard)
    local midRings = makePart("MiddleSuspenderRings", Vector3.new(0.89, 0.23, 0.10), COL_RING, Enum.Material.Glass)
    local upRings  = makePart("UpperSuspenderRings", Vector3.new(2.06, 0.11, 0.18), COL_RING, Enum.Material.Glass)
    local clips    = makePart("SuspenderClips", Vector3.new(2.00, 0.36, 0.30), COL_RING, Enum.Material.Glass)

    weld(lowerTorso, lowSusp, CFrame.new(0, 0, -0.02))
    weld(lowerTorso, clips, CFrame.new(0, -0.2, -0.04))
    weld(middleTorso, midSusp, CFrame.new(0, 0, -0.02))
    weld(middleTorso, midRings, CFrame.new(0, 0.2, -0.26))
    weld(upperTorso, upSusp, CFrame.new(0, 0, -0.02))
    weld(upperTorso, upRings, CFrame.new(0, 0.45, -0.38))

    -- 3. Галстук (TieTop -> TieUpper -> TieMiddle -> TieLower -> TieBottom)
    local tieTop    = makePart("TieTop", Vector3.new(0.59, 0.49, 0.11), COL_TIE, Enum.Material.Leather)
    local tieUpper  = makePart("TieUpper", Vector3.new(0.50, 0.63, 0.09), COL_TIE, Enum.Material.Leather)
    local tieMiddle = makePart("TieMiddle", Vector3.new(0.63, 0.63, 0.09), COL_TIE, Enum.Material.Leather)
    local tieLower  = makePart("TieLower", Vector3.new(0.64, 0.63, 0.09), COL_TIE, Enum.Material.Leather)
    local tieBottom = makePart("TieBottom", Vector3.new(0.64, 0.58, 0.09), COL_TIE, Enum.Material.Leather)

    motor("TieTop", upperTorso, tieTop, CFrame.new(0, 0.55, -0.40), CFrame.new(0, 0.2, 0))
    motor("TieUpper", tieTop, tieUpper, CFrame.new(0, -0.24, 0), CFrame.new(0, 0.3, 0))
    motor("TieMiddle", tieUpper, tieMiddle, CFrame.new(0, -0.31, 0), CFrame.new(0, 0.31, 0))
    motor("TieLower", tieMiddle, tieLower, CFrame.new(0, -0.31, 0), CFrame.new(0, 0.31, 0))
    motor("TieBottom", tieLower, tieBottom, CFrame.new(0, -0.31, 0), CFrame.new(0, 0.28, 0))

    -- 4. Шея и Голова-планшет с бумагами (Neck -> Head + WoodHead + Face + Papers)
    local neckCuff   = makePart("NeckCuff", Vector3.new(1.85, 0.58, 0.99), COL_SHIRT, Enum.Material.Fabric)
    local neckPart   = makePart("Neck", Vector3.new(1.22, 0.29, 0.72), COL_STAR_GLOW, Enum.Material.Neon)
    local headPart   = makePart("Head", Vector3.new(1.76, 1.77, 0.24), COL_STAR_GLOW, Enum.Material.Neon)
    local woodHead   = makePart("WoodHead", Vector3.new(1.49, 2.15, 0.56), COL_WOOD, Enum.Material.Wood)
    local papers     = makePart("Papers", Vector3.new(1.77, 1.80, 0.44), COL_PAPER, Enum.Material.Concrete)
    local facePart   = makePart("Face", Vector3.new(1.48, 1.72, 0.24), COL_PAPER, Enum.Material.Concrete)
    local exprPart   = makePart("Expression", Vector3.new(1.48, 1.36, 0.20), Color3.fromRGB(35, 32, 38), Enum.Material.Concrete)

    weld(upperTorso, neckCuff, CFrame.new(0, 0.85, 0))
    motor("Neck", upperTorso, neckPart, CFrame.new(0, 0.95, 0), CFrame.new(0, -0.14, 0))
    motor("Head", neckPart, headPart, CFrame.new(0, 0.15, 0), CFrame.new(0, -0.95, 0))

    weld(headPart, woodHead, CFrame.new(0, 0.1, 0.12))
    weld(headPart, papers, CFrame.new(0, 0.18, -0.06))
    weld(headPart, facePart, CFrame.new(0, 0.05, -0.22))
    weld(headPart, exprPart, CFrame.new(0, 0.05, -0.26))

    -- 5. Функция сборки сегментированных рук Honcho (Shoulder -> UpperArm -> UpperWrist -> LowerWrist -> Hand)
    local function buildArm(isLeft)
        local side = isLeft and "Left" or "Right"
        local sign = isLeft and -1 or 1

        local sh = makePart(side .. "Shoulder", Vector3.new(1.79, 1.11, 0.15), COL_SHIRT, Enum.Material.Fabric)
        local ua = makePart(side .. "UpperArm", Vector3.new(2.25, 1.11, 0.15), COL_SHIRT, Enum.Material.Fabric)
        local cuff = makePart(side .. "ElbowCuff", Vector3.new(0.68, 1.28, 0.26), COL_SHIRT, Enum.Material.Fabric)
        local uw = makePart(side .. "UpperWrist", Vector3.new(1.14, 1.11, 0.15), COL_SKIN_HAND, Enum.Material.Concrete)
        local uwL = makePart(side .. "UpperWristLining", Vector3.new(0.63, 0.72, 0.20), COL_SHIRT, Enum.Material.Concrete)
        local lw = makePart(side .. "LowerWrist", Vector3.new(1.23, 1.11, 0.15), COL_SKIN_HAND, Enum.Material.Concrete)
        local lwL = makePart(side .. "LowerWristLining", Vector3.new(0.16, 0.59, 0.20), COL_SHIRT, Enum.Material.Concrete)
        local hand = makePart(side .. "Hand", Vector3.new(0.64, 1.11, 0.15), COL_SKIN_HAND, Enum.Material.Concrete)

        motor(side .. "Shoulder", upperTorso, sh, CFrame.new(sign * 1.40, 0.35, 0), CFrame.new(-sign * 0.89, 0, 0))
        motor(side .. "UpperArm", sh, ua, CFrame.new(sign * 0.89, 0, 0), CFrame.new(-sign * 1.12, 0, 0))
        weld(ua, cuff, CFrame.new(sign * 0.85, 0, 0))
        motor(side .. "UpperWrist", ua, uw, CFrame.new(sign * 1.12, 0, 0), CFrame.new(-sign * 0.57, 0, 0))
        weld(uw, uwL, CFrame.new(-sign * 0.3, 0, 0))
        motor(side .. "LowerWrist", uw, lw, CFrame.new(sign * 0.57, 0, 0), CFrame.new(-sign * 0.61, 0, 0))
        weld(lw, lwL, CFrame.new(0, 0, 0))
motor(side .. "Hand", lw, hand, CFrame.new(sign * 0.61, 0, 0), CFrame.new(-sign * 0.32, 0, 0))
end
buildArm(true)
buildArm(false)
-- 6. Функция сборки сегментированных ног Honcho (UpperLeg -> MiddleLeg -> LowerLeg -> Ankle -> Foot)
local function buildLeg(isLeft)
local side = isLeft and "Left" or "Right"
local sign = isLeft and -1 or 1
local ul = makePart(side .. "UpperLeg", Vector3.new(1.27, 1.17, 0.33), COL_SUIT, Enum.Material.Fabric)
local ml = makePart(side .. "MiddleLeg", Vector3.new(1.29, 1.28, 0.48), COL_SUIT, Enum.Material.Fabric)
local ll = makePart(side .. "LowerLeg", Vector3.new(1.32, 1.28, 0.71), COL_SUIT, Enum.Material.Fabric)
local an = makePart(side .. "Ankle", Vector3.new(1.35, 0.80, 0.85), COL_SUIT, Enum.Material.Fabric)
local ft = makePart(side .. "Foot", Vector3.new(1.21, 0.45, 0.64), COL_SHOE, Enum.Material.Concrete)
local ftAcc = makePart(side .. "FootAccents", Vector3.new(1.21, 0.59, 1.10), COL_SHOE, Enum.Material.Concrete)
motor(side .. "UpperLeg", pelvis, ul, CFrame.new(sign * 0.78, -0.43, 0), CFrame.new(0, 0.58, 0))
motor(side .. "MiddleLeg", ul, ml, CFrame.new(0, -0.58, 0), CFrame.new(0, 0.64, 0))
motor(side .. "LowerLeg", ml, ll, CFrame.new(0, -0.64, 0), CFrame.new(0, 0.64, 0))
motor(side .. "Ankle", ll, an, CFrame.new(0, -0.64, 0), CFrame.new(0, 0.40, 0))
motor(side .. "Foot", an, ft, CFrame.new(0, -0.40, -0.10), CFrame.new(0, 0.22, 0))
weld(ft, ftAcc, CFrame.new(0, 0.05, -0.22))
end
buildLeg(true)
buildLeg(false)
-- 7. Фирменная бутылка StarBottle на поясе Honcho
local bottle = makePart("StarBottle", Vector3.new(1.05, 1.64, 0.62), Color3.fromRGB(165, 225, 255), Enum.Material.Glass, 0.35)
local liquid = makePart("Liquid", Vector3.new(0.94, 1.06, 0.55), COL_STAR_GLOW, Enum.Material.Neon)
local star   = makePart("Star", Vector3.new(0.54, 0.54, 0.15), COL_STAR_GLOW, Enum.Material.Neon)
local cork   = makePart("Cork", Vector3.new(0.36, 0.27, 0.36), COL_WOOD, Enum.Material.Sand)
motor("StarBottle", hrp, bottle, CFrame.new(-1.85, -0.35, -0.15) * CFrame.Angles(0, 0, math.rad(12)), CFrame.new())
weld(bottle, liquid, CFrame.new(0, -0.2, 0))
weld(bottle, star, CFrame.new(0, -0.1, 0))
weld(bottle, cork, CFrame.new(0, 0.9, 0))
-- 8. Humanoid + Animator + родные анимации Honcho из твоего дампа
local hum = Instance.new("Humanoid")
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
hum.Parent = model
local animator = Instance.new("Animator")
animator.Parent = hum
local customAnims = Instance.new("Folder")
customAnims.Name = "CustomAnimations"
customAnims.Parent = model
local function addAnim(name, id)
local a = Instance.new("Animation")
a.Name = name
a.AnimationId = id
a.Parent = customAnims
end
addAnim("idle",   "rbxassetid://101907348895136")
addAnim("walk",   "rbxassetid://100466662502744")
addAnim("sprint", "rbxassetid://100466662502744")
return model
end