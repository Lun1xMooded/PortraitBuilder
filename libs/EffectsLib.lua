-- libs/EffectsLib.lua
local EffectsLib = {}
local rng = Random.new()

local JITTER_MIN = -0.006
local JITTER_MAX = 0.006

-- Собираем кэш частей тела для дрожания (как buildHauntJitter в PortraitClient)
function EffectsLib.CacheJitterParts(model)
    local cache = {}
    if not model then return cache end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
            local mesh = desc:FindFirstChildWhichIsA("DataModelMesh")
            table.insert(cache, {
                part = desc,
                baseSize = desc.Size,
                mesh = mesh,
                baseScale = mesh and mesh.Scale or nil
            })
        end
    end
    return cache
end

-- Применяем дрожание каждый кадр (scale: 1 = лёгкое, 5-10 = сильное)
function EffectsLib.UpdateJitter(cache, scale)
    if not cache or scale <= 0 then return end
    for _, item in ipairs(cache) do
        if item.part and item.part.Parent then
            local mult = Vector3.new(
                rng:NextNumber(1 + JITTER_MIN * scale, 1 + JITTER_MAX * scale),
                rng:NextNumber(1 + JITTER_MIN * scale, 1 + JITTER_MAX * scale),
                rng:NextNumber(1 + JITTER_MIN * scale, 1 + JITTER_MAX * scale)
            )
            item.part.Size = item.baseSize * mult
            if item.mesh and item.baseScale then
                item.mesh.Scale = item.baseScale * mult
            end
        end
    end
end

function EffectsLib.ResetJitter(cache)
    if not cache then return end
    for _, item in ipairs(cache) do
        if item.part and item.part.Parent then
            item.part.Size = item.baseSize
            if item.mesh and item.baseScale then
                item.mesh.Scale = item.baseScale
            end
        end
    end
end

-- Вспышка частиц Warp / Footsteps (emitFX из PortraitClient)
function EffectsLib.EmitAttachment(att, countOverride)
    if not att then return end
    for _, child in ipairs(att:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            local count = countOverride or child:GetAttribute("EmitCount") or 10
            child:Emit(count)
        end
    end
end

return EffectsLib
