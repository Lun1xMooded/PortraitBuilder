-- builders/HonchoBuilder.lua
local AssetService = game:GetService("AssetService")

local meshTemplateCache = {}
local function createScaledMeshPart(meshId, targetSize)
    if meshId and meshId ~= "" then
        if meshTemplateCache[meshId] == nil then
            local ok, mp = pcall(function()
                return AssetService:CreateMeshPartAsync(meshId, {
                    CollisionFidelity = Enum.CollisionFidelity.Box,
                    RenderFidelity = Enum.RenderFidelity.Automatic
                })
            end)
            meshTemplateCache[meshId] = (ok and mp) and mp or false
        end

        local tpl = meshTemplateCache[meshId]
        if tpl then
            local p = tpl:Clone()
            p.Size = targetSize
            return p
        end
    end

    local fallback = Instance.new("Part")
    fallback.Size = targetSize
    fallback.TopSurface = Enum.SurfaceType.Smooth
    fallback.BottomSurface = Enum.SurfaceType.Smooth
    return fallback
end

return function(variant, Import)
    local HonchoData = Import and Import("builders/honcho/HonchoData.lua")
    if not HonchoData then
        local url = "https://raw.githubusercontent.com/Lun1xMooded/PortraitBuilder/refs/heads/main/" .. tostring(os.time())
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and body and not body:find("404: Not Found") then
            local fn = loadstring(body, "@HonchoData.lua")
            if fn then HonchoData = fn() end
        end
    end
    if not HonchoData then
        warn("[HonchoBuilder] Не загрузился builders/honcho/HonchoData.lua! Проверь путь файла на GitHub.")
        return nil
    end


    local model = Instance.new("Model")
    model.Name = "HonchoActorClone"
    model:SetAttribute("RootOffset", 6.35)
    model:SetAttribute("NoTools", true)

    local parts = {}

    for _, info in ipairs(HonchoData.Parts) do
        local name, size, color, mat, transp, relCF, meshId = info, info, info, info, info, info, info
        local p = createScaledMeshPart(meshId, size)
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = mat
        p.Transparency = transp
        p.CFrame = relCF
        p.Anchored = false
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Massless = true
        p.Parent = model
        parts[name] = p
    end

    model.PrimaryPart = parts["RootPart"]

    for _, mInfo in ipairs(HonchoData.Motors) do
        local mName, p0Name, p1Name, c0, c1 = mInfo, mInfo, mInfo, mInfo, mInfo
        local p0, p1 = parts[p0Name], parts[p1Name]
        if p0 and p1 then
            local m = Instance.new("Motor6D")
            m.Name = mName
            m.Part0 = p0
            m.Part1 = p1
            m.C0 = c0
            m.C1 = c1
            m.Parent = p0
        end
    end

    for _, wInfo in ipairs(HonchoData.Welds) do
        local p0, p1 = parts[wInfo], parts[wInfo]
        if p0 and p1 then
            local w = Instance.new("WeldConstraint")
            w.Name = wInfo .. "Weld"
            w.Part0 = p0
            w.Part1 = p1
            w.Parent = p0
        end
    end

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