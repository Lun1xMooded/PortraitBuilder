-- libs/PathfindLib.lua
-- 3D-карта комнат с поддержкой персональных маршрутов, точкой в позиции игрока и спавном охотника в старте жертвы

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local CLONE_PALETTE = {
    Color3.fromRGB(95, 255, 130),  -- #1 Зелёный
    Color3.fromRGB(255, 145, 70),  -- #2 Оранжевый
    Color3.fromRGB(90, 195, 255),  -- #3 Голубой
    Color3.fromRGB(240, 110, 255), -- #4 Розовый
    Color3.fromRGB(255, 235, 85),  -- #5 Жёлтый
}

local PathfindLib = {
    Routes = {},
    SelectedClone = 1,
    ShowMarkers = true,
    LoopPath = true,
    SprintPath = false,
}

local mapGui = nil
local mapRenderConn = nil

function PathfindLib.GetRoute(idx)
    idx = idx or PathfindLib.SelectedClone or 1
    if not PathfindLib.Routes[idx] then
        PathfindLib.Routes[idx] = {
            Nodes = {},
            StartNodeIndex = 1,
            ChaseCloneIdx = nil,
            StartDelay = 0,
        }
    end
    return PathfindLib.Routes[idx]
end

setmetatable(PathfindLib, {
    __index = function(t, k)
        if k == "Nodes" then return t.GetRoute().Nodes end
        if k == "StartNodeIndex" then return t.GetRoute().StartNodeIndex end
    end
})

function PathfindLib.GetSortedRooms()
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return {} end
    local list = {}
    for _, r in ipairs(currentRooms:GetChildren()) do
        if r:IsA("Model") then
            table.insert(list, r)
        end
    end
    table.sort(list, function(a, b)
        return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
    end)
    return list
end

function PathfindLib.RefreshMarkers()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "MemeActorPathMarkers" then
            obj:Destroy()
        end
    end
    if not PathfindLib.ShowMarkers then return end

    local folder = Instance.new("Folder")
    folder.Name = "MemeActorPathMarkers"
    folder.Parent = workspace

    for cIdx, route in pairs(PathfindLib.Routes) do
        local col = CLONE_PALETTE[((cIdx - 1) % #CLONE_PALETTE) + 1]
        for i, pos in ipairs(route.Nodes) do
            local isStart = (i == route.StartNodeIndex)
            local p = Instance.new("Part")
            p.Name = "C" .. cIdx .. "_Node_" .. i
            p.Shape = Enum.PartType.Ball
            p.Size = isStart and Vector3.new(1.45, 1.45, 1.45) or Vector3.new(0.95, 0.95, 0.95)
            p.Position = pos + Vector3.new(0, 0.6, 0)
            p.Color = isStart and Color3.fromRGB(255, 225, 90) or col
            p.Material = Enum.Material.Neon
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.Parent = folder

            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 90, 0, 24)
            bb.StudsOffset = Vector3.new(0, 1.4, 0)
            bb.AlwaysOnTop = true
            bb.Parent = p

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Oswald
            lbl.Text = isStart and string.format("[#%d] START #%d", cIdx, i) or string.format("[#%d] NODE %d", cIdx, i)
            lbl.TextColor3 = p.Color
            lbl.TextStrokeTransparency = 0.2
            lbl.TextScaled = true
            lbl.Parent = bb
        end
    end
end

function PathfindLib.SetMarkersVisible(state)
    PathfindLib.ShowMarkers = state == true
    PathfindLib.RefreshMarkers()
end

function PathfindLib.AddNode(pos, cloneIdx)
    local route = PathfindLib.GetRoute(cloneIdx)
    table.insert(route.Nodes, pos)
    if #route.Nodes == 1 then
        route.StartNodeIndex = 1
    end
    PathfindLib.RefreshMarkers()
end

function PathfindLib.RemoveNodeAt(index, cloneIdx)
    local route = PathfindLib.GetRoute(cloneIdx)
    if index < 1 or index > #route.Nodes then return end
    table.remove(route.Nodes, index)
    if route.StartNodeIndex > #route.Nodes then
        route.StartNodeIndex = math.max(1, #route.Nodes)
    end
    PathfindLib.RefreshMarkers()
end

function PathfindLib.SetStartNode(index, cloneIdx)
    local cIdx = cloneIdx or PathfindLib.SelectedClone
    local route = PathfindLib.GetRoute(cIdx)
    if index < 1 or index > #route.Nodes then return end
    route.StartNodeIndex = index
    PathfindLib.RefreshMarkers()

    local allClones = getgenv().MemeAllClones or {}
    local entry = allClones[cIdx]
    local clone = entry and entry.model or (cIdx == 1 and getgenv().ActiveActorClone or nil)
    local pos = route.Nodes[index]

    if clone and pos then
        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
        local off = clone:GetAttribute("RootOffset") or 3.65
        if root then
            local nextPos = route.Nodes[(index % #route.Nodes) + 1] or (pos + root.CFrame.LookVector)
            local lookDir = ((nextPos - pos) * Vector3.new(1, 0, 1))
            lookDir = (lookDir.Magnitude > 0.01) and lookDir.Unit or root.CFrame.LookVector
            local newCF = CFrame.lookAt(pos + Vector3.new(0, off, 0), pos + Vector3.new(0, off, 0) + lookDir)
            root.CFrame = newCF
            if entry then entry.cframe = newCF end
        end
    end
end

function PathfindLib.ClearNodes(cloneIdx)
    if cloneIdx then
        local route = PathfindLib.GetRoute(cloneIdx)
        table.clear(route.Nodes)
        route.StartNodeIndex = 1
        route.ChaseCloneIdx = nil
    else
        table.clear(PathfindLib.Routes)
    end
    PathfindLib.RefreshMarkers()
end

-- Исправленный поиск пола: луч идёт с высоты +4.5 от пола (ниже крыши!) и игнорирует потолки
local function getExactFloorY(roomsList, x, z, fallbackY)
    local validParts = {}
    for _, r in ipairs(roomsList) do
        for _, desc in ipairs(r:GetDescendants()) do
            if desc:IsA("BasePart") and desc.CanCollide and desc.Transparency < 0.95 then
                local low = desc.Name:lower()
                if not (low:find("ceiling") or low:find("roof") or low:find("rafter") or low:find("skybox")) then
                    if desc.Position.Y <= fallbackY + 4.0 then
                        table.insert(validParts, desc)
                    end
                end
            end
        end
    end

    if #validParts > 0 then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Include
        rp.FilterDescendantsInstances = validParts
        local hit = workspace:Raycast(Vector3.new(x, fallbackY + 4.5, z), Vector3.new(0, -15, 0), rp)
        if hit then
            return hit.Position.Y
        end
    end
    return fallbackY
end

function PathfindLib.AddNodeAtPlayer(cloneIdx)
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("CollisionPart") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    if not root then return false end

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { char }
    for _, entry in ipairs(getgenv().MemeAllClones or {}) do
        if entry.model then table.insert(ignore, entry.model) end
    end
    rp.FilterDescendantsInstances = ignore

    local hit = workspace:Raycast(root.Position, Vector3.new(0, -15, 0), rp)
    local floorY = hit and hit.Position.Y or (root.Position.Y - 2.5)
    PathfindLib.AddNode(Vector3.new(root.Position.X, floorY, root.Position.Z), cloneIdx or PathfindLib.SelectedClone)
    return true
end

function PathfindLib.AutoGenerateFromCarpet(cloneIdx)
    local rooms = PathfindLib.GetSortedRooms()
    local room = rooms[#rooms]
    if not room then return end
    local cIdx = cloneIdx or PathfindLib.SelectedClone
    PathfindLib.ClearNodes(cIdx)

    local fl = room:FindFirstChild("Parts") and room.Parts:FindFirstChild("Floor")
    local fy = fl and (fl.Position.Y + fl.Size.Y * 0.5) or room:GetBoundingBox().Position.Y

    for _, d in ipairs(room:GetDescendants()) do
        if d:IsA("BasePart") and d.Name == "Carpet" then
            local exactY = getExactFloorY({ room }, d.Position.X, d.Position.Z, fy)
            PathfindLib.AddNode(Vector3.new(d.Position.X, exactY, d.Position.Z), cIdx)
        end
    end
end

local function closeMap()
    if mapRenderConn then mapRenderConn:Disconnect(); mapRenderConn = nil end
    if mapGui then mapGui:Destroy(); mapGui = nil end
end

function PathfindLib.OpenLayoutMap()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    closeMap()

    local allRooms = PathfindLib.GetSortedRooms()
    if #allRooms == 0 then return end

    local selectedIdx = #allRooms
    local zoomSpan = 95
    local camOffset = Vector3.zero

    mapGui = Instance.new("ScreenGui")
    mapGui.Name = "MemeActorRoomMap"
    mapGui.DisplayOrder = 30
    mapGui.ResetOnSpawn = false
    mapGui.Parent = pgui

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 580, 0, 650)
    frame.BackgroundColor3 = Color3.fromRGB(30, 17, 16)
    frame.BackgroundTransparency = 0.04
    frame.Parent = mapGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", frame)
    st.Color = Color3.fromRGB(255, 222, 189)
    st.Thickness = 3
    CollectionService:AddTag(frame, "UnlockMouseVisible")

    local hdr = Instance.new("TextLabel")
    hdr.Position = UDim2.new(0, 14, 0, 8)
    hdr.Size = UDim2.new(0.35, 0, 0, 30)
    hdr.BackgroundTransparency = 1
    hdr.Font = Enum.Font.Oswald
    hdr.Text = "КАРТА КОМНАТ"
    hdr.TextColor3 = Color3.fromRGB(255, 222, 189)
    hdr.TextScaled = true
hdr.TextXAlignment = Enum.TextXAlignment.Left
hdr.Parent = frame
local btnCloneSel = Instance.new("TextButton")
btnCloneSel.Position = UDim2.new(0.36, 0, 0, 8)
btnCloneSel.Size = UDim2.new(0.26, 0, 0, 30)
btnCloneSel.BackgroundColor3 = CLONE_PALETTE[1]
btnCloneSel.Font = Enum.Font.Oswald
btnCloneSel.TextColor3 = Color3.fromRGB(20, 12, 11)
btnCloneSel.TextScaled = true
btnCloneSel.Parent = frame
Instance.new("UICorner", btnCloneSel).CornerRadius = UDim.new(0, 6)
local btnPrevRoom = Instance.new("TextButton")
btnPrevRoom.Position = UDim2.new(0.63, 0, 0, 8)
btnPrevRoom.Size = UDim2.new(0.13, 0, 0, 30)
btnPrevRoom.BackgroundColor3 = Color3.fromRGB(84, 68, 61)
btnPrevRoom.Font = Enum.Font.Oswald
btnPrevRoom.Text = "< ПРЕД"
btnPrevRoom.TextColor3 = Color3.fromRGB(255, 222, 189)
btnPrevRoom.TextScaled = true
btnPrevRoom.Parent = frame
Instance.new("UICorner", btnPrevRoom).CornerRadius = UDim.new(0, 6)
local btnNextRoom = Instance.new("TextButton")
btnNextRoom.Position = UDim2.new(0.77, 0, 0, 8)
btnNextRoom.Size = UDim2.new(0.13, 0, 0, 30)
btnNextRoom.BackgroundColor3 = Color3.fromRGB(84, 68, 61)
btnNextRoom.Font = Enum.Font.Oswald
btnNextRoom.Text = "СЛЕД >"
btnNextRoom.TextColor3 = Color3.fromRGB(255, 222, 189)
btnNextRoom.TextScaled = true
btnNextRoom.Parent = frame
Instance.new("UICorner", btnNextRoom).CornerRadius = UDim.new(0, 6)
local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 8)
close.Size = UDim2.new(0, 30, 0, 30)
close.BackgroundColor3 = Color3.fromRGB(204, 68, 26)
close.Font = Enum.Font.Oswald
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 222, 189)
close.TextScaled = true
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(closeMap)
local hint = Instance.new("TextLabel")
hint.Position = UDim2.new(0, 14, 0, 40)
hint.Size = UDim2.new(1, -28, 0, 20)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Oswald
hint.Text = "ЛКМ по полу: точка | ЛКМ по точке: СТАРТ | ПКМ по точке: удалить | Колёсико: ЗУМ | ПКМ+тянуть: сдвиг"
hint.TextColor3 = Color3.fromRGB(165, 130, 115)
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = frame
local vp = Instance.new("ViewportFrame")
vp.Position = UDim2.new(0, 14, 0, 64)
vp.Size = UDim2.new(1, -28, 1, -230)
vp.BackgroundColor3 = Color3.fromRGB(18, 11, 10)
vp.Ambient = Color3.fromRGB(215, 205, 195)
vp.LightColor = Color3.fromRGB(255, 245, 235)
vp.LightDirection = Vector3.new(-0.3, -1, -0.3)
vp.Parent = frame
Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 8)
local vpStroke = Instance.new("UIStroke", vp)
vpStroke.Color = Color3.fromRGB(110, 92, 82)
vpStroke.Thickness = 2
local worldModel = Instance.new("WorldModel")
worldModel.Parent = vp
local vpCam = Instance.new("Camera")
vpCam.FieldOfView = 1
vpCam.Parent = vp
vp.CurrentCamera = vpCam
local overlay = Instance.new("TextButton")
overlay.Position = vp.Position
overlay.Size = vp.Size
overlay.BackgroundTransparency = 1
overlay.ClipsDescendants = true
overlay.Text = ""
overlay.Parent = frame
local activeRooms = {}
local baseCenter = Vector3.zero
local baseFloorY = 0
local function getCloneDisplayName(cIdx)
local allClones = getgenv().MemeAllClones or {}
local entry = allClones[cIdx]
local rawName = entry and entry.model and entry.model.Name or ("Клон #" .. cIdx)
rawName = rawName:gsub("_MemeClone", "")
return string.format("КЛОН #%d (%s)", cIdx, rawName)
end
local btnRole, btnDelay
local function refreshControlButtons()
local cIdx = PathfindLib.SelectedClone
local col = CLONE_PALETTE[((cIdx - 1) % #CLONE_PALETTE) + 1]
btnCloneSel.BackgroundColor3 = col
btnCloneSel.Text = getCloneDisplayName(cIdx)
local route = PathfindLib.GetRoute(cIdx)
if btnRole then
if route.ChaseCloneIdx then
btnRole.Text = "ЦЕЛЬ: ДОГОНЯТЬ КЛОНА #" .. route.ChaseCloneIdx
btnRole.BackgroundColor3 = Color3.fromRGB(204, 68, 26)
btnRole.TextColor3 = Color3.fromRGB(255, 222, 189)
else
btnRole.Text = "ЦЕЛЬ: БЕГ ПО ТОЧКАМ (" .. #route.Nodes .. ")"
btnRole.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
btnRole.TextColor3 = Color3.fromRGB(39, 20, 17)
end
end
if btnDelay then
btnDelay.Text = (route.StartDelay > 0) and string.format("ЗАДЕРЖКА СТАРТА: %.1f СЕК", route.StartDelay) or "ЗАДЕРЖКА СТАРТА: 0 СЕК"
end
end
local function updateCamera()
local dist = (zoomSpan * 0.5) / math.tan(math.rad(0.5))
local target = baseCenter + camOffset
vpCam.CFrame = CFrame.lookAt(target + Vector3.new(0, dist, 0), target, Vector3.new(0, 0, -1))
end
local function loadRoomsPair(idx)
allRooms = PathfindLib.GetSortedRooms()
selectedIdx = math.clamp(idx, 1, math.max(1, #allRooms))
worldModel:ClearAllChildren()
table.clear(activeRooms)
local r1 = allRooms[selectedIdx]
local r2 = (selectedIdx > 1) and allRooms[selectedIdx - 1] or allRooms[selectedIdx + 1]
if r1 then table.insert(activeRooms, r1) end
if r2 and r2 ~= r1 then table.insert(activeRooms, r2) end
local names = {}
local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
baseFloorY = 0
for _, r in ipairs(activeRooms) do
table.insert(names, "#" .. r.Name)
local fl = r:FindFirstChild("Parts") and r.Parts:FindFirstChild("Floor")
local fy = fl and (fl.Position.Y + fl.Size.Y * 0.5) or r:GetBoundingBox().Position.Y
if r == r1 then baseFloorY = fy end
for _, desc in ipairs(r:GetDescendants()) do
if desc:IsA("BasePart") and desc.Transparency < 0.95 then
local low = desc.Name:lower()
local skip = low:find("ceiling") or low:find("roof") or low:find("rafter") or low:find("skybox") or low:find("dust")
if not skip and desc.Position.Y <= fy + 9.5 then
local cp = desc:Clone()
cp:ClearAllChildren()
cp.Anchored = true
cp.CanCollide = false
cp.Parent = worldModel
minX = math.min(minX, desc.Position.X - desc.Size.X * 0.5)
maxX = math.max(maxX, desc.Position.X + desc.Size.X * 0.5)
minZ = math.min(minZ, desc.Position.Z - desc.Size.Z * 0.5)
maxZ = math.max(maxZ, desc.Position.Z + desc.Size.Z * 0.5)
end
end
end
end
hdr.Text = "КОМНАТЫ: " .. table.concat(names, " + ")
if minX < maxX then
baseCenter = Vector3.new((minX + maxX) * 0.5, baseFloorY, (minZ + maxZ) * 0.5)
zoomSpan = math.max(maxX - minX, maxZ - minZ) * 1.05
end
camOffset = Vector3.zero
updateCamera()
end
local function worldToOverlay(pos)
local sp, onScr = vpCam:WorldToViewportPoint(pos)
return UDim2.new(sp.X, 0, sp.Y, 0), onScr
end
local function redrawOverlays()
if not overlay or not overlay.Parent then return end
overlay:ClearAllChildren()
local absSize = overlay.AbsoluteSize
for cIdx, route in pairs(PathfindLib.Routes) do
local isSelectedClone = (cIdx == PathfindLib.SelectedClone)
local col = CLONE_PALETTE[((cIdx - 1) % #CLONE_PALETTE) + 1]
local prevPx = nil
for idx, nPos in ipairs(route.Nodes) do
local ud = worldToOverlay(nPos)
local curPx = Vector2.new(ud.X.Scale * absSize.X, ud.Y.Scale * absSize.Y)
if prevPx then
local diff = curPx - prevPx
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0.5)
line.Position = UDim2.new(0, (prevPx.X + curPx.X) * 0.5, 0, (prevPx.Y + curPx.Y) * 0.5)
line.Size = UDim2.new(0, diff.Magnitude, 0, isSelectedClone and 2.5 or 1.5)
line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
line.BackgroundColor3 = col
line.BackgroundTransparency = isSelectedClone and 0 or 0.55
line.BorderSizePixel = 0
line.ZIndex = isSelectedClone and 4 or 2
line.Parent = overlay
end
prevPx = curPx
local isStart = (idx == route.StartNodeIndex)
local dot = Instance.new("TextButton")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = ud
dot.Size = isStart and UDim2.new(0, 28, 0, 28) or UDim2.new(0, 22, 0, 22)
dot.BackgroundColor3 = isStart and Color3.fromRGB(255, 225, 90) or col
dot.BackgroundTransparency = isSelectedClone and 0 or 0.45
dot.Font = Enum.Font.Oswald
dot.Text = isStart and ("S" .. idx) or tostring(idx)
dot.TextColor3 = Color3.fromRGB(20, 12, 11)
dot.TextSize = 14
dot.ZIndex = isSelectedClone and 6 or 3
dot.Parent = overlay
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
if isSelectedClone then
dot.MouseButton1Click:Connect(function()
PathfindLib.SetStartNode(idx, cIdx)
redrawOverlays()
end)
dot.MouseButton2Click:Connect(function()
PathfindLib.RemoveNodeAt(idx, cIdx)
refreshControlButtons()
redrawOverlays()
end)
end
end
end
local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
if myRoot then
local meDot = Instance.new("TextLabel")
meDot.AnchorPoint = Vector2.new(0.5, 0.5)
meDot.Position = worldToOverlay(myRoot.Position)
meDot.Size = UDim2.new(0, 32, 0, 18)
meDot.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
meDot.Font = Enum.Font.Oswald
meDot.Text = "ТЫ"
meDot.TextColor3 = Color3.new(1, 1, 1)
meDot.TextSize = 13
meDot.ZIndex = 7
meDot.Parent = overlay
Instance.new("UICorner", meDot).CornerRadius = UDim.new(0, 4)
end
local allClones = getgenv().MemeAllClones or {}
if #allClones > 0 then
for i, entry in ipairs(allClones) do
local m = entry.model
if m and m.Parent and m.PrimaryPart then
local cDot = Instance.new("TextLabel")
cDot.AnchorPoint = Vector2.new(0.5, 0.5)
cDot.Position = worldToOverlay(m.PrimaryPart.Position)
cDot.Size = UDim2.new(0, 56, 0, 18)
cDot.BackgroundColor3 = CLONE_PALETTE[((i - 1) % #CLONE_PALETTE) + 1]
cDot.Font = Enum.Font.Oswald
cDot.Text = "КЛОН #" .. i
cDot.TextColor3 = Color3.fromRGB(20, 12, 11)
cDot.TextSize = 13
cDot.ZIndex = 8
cDot.Parent = overlay
Instance.new("UICorner", cDot).CornerRadius = UDim.new(0, 4)
end
end
else
local clone = getgenv().ActiveActorClone
if clone and clone.PrimaryPart then
local cDot = Instance.new("TextLabel")
cDot.AnchorPoint = Vector2.new(0.5, 0.5)
cDot.Position = worldToOverlay(clone.PrimaryPart.Position)
cDot.Size = UDim2.new(0, 46, 0, 18)
cDot.BackgroundColor3 = CLONE_PALETTE[1]
cDot.Font = Enum.Font.Oswald
cDot.Text = "КЛОН #1"
cDot.TextColor3 = Color3.fromRGB(20, 12, 11)
cDot.TextSize = 13
cDot.ZIndex = 8
cDot.Parent = overlay
Instance.new("UICorner", cDot).CornerRadius = UDim.new(0, 4)
end
end
end
local panning, panStartMouse, panStartOffset = false, Vector2.zero, Vector3.zero
overlay.InputChanged:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseWheel then
zoomSpan = math.clamp(zoomSpan - inp.Position.Z * 10, 20, 240)
updateCamera()
redrawOverlays()
elseif panning and inp.UserInputType == Enum.UserInputType.MouseMovement then
local delta = Vector2.new(inp.Position.X, inp.Position.Y) - panStartMouse
local scale = zoomSpan / math.max(1, overlay.AbsoluteSize.X)
camOffset = panStartOffset + Vector3.new(-delta.X * scale, 0, -delta.Y * scale)
updateCamera()
redrawOverlays()
end
end)
overlay.InputBegan:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton2 then
panning = true
panStartMouse = Vector2.new(inp.Position.X, inp.Position.Y)
panStartOffset = camOffset
end
end)
overlay.InputEnded:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton2 then
panning = false
end
end)
overlay.MouseButton1Click:Connect(function()
local mPos = UserInputService:GetMouseLocation()
local relX = (mPos.X - overlay.AbsolutePosition.X) / overlay.AbsoluteSize.X
local relY = (mPos.Y - 36 - overlay.AbsolutePosition.Y) / overlay.AbsoluteSize.Y
local ray = vpCam:ViewportPointToRay(relX, relY, 0)
if math.abs(ray.Direction.Y) > 0.001 then
local t = (baseFloorY - ray.Origin.Y) / ray.Direction.Y
local hitPos = ray.Origin + ray.Direction * t
local exactY = getExactFloorY(activeRooms, hitPos.X, hitPos.Z, baseFloorY)
PathfindLib.AddNode(Vector3.new(hitPos.X, exactY, hitPos.Z), PathfindLib.SelectedClone)
refreshControlButtons()
redrawOverlays()
end
end)
btnCloneSel.MouseButton1Click:Connect(function()
local allClones = getgenv().MemeAllClones or {}
local maxClones = math.max(2, #allClones)
PathfindLib.SelectedClone = (PathfindLib.SelectedClone % maxClones) + 1
refreshControlButtons()
redrawOverlays()
end)
btnPrevRoom.MouseButton1Click:Connect(function() loadRoomsPair(selectedIdx - 1); redrawOverlays() end)
btnNextRoom.MouseButton1Click:Connect(function() loadRoomsPair(selectedIdx + 1); redrawOverlays() end)
local function makeBtn(text, pos, size, bg, fg, onClick)
local b = Instance.new("TextButton")
b.Position = pos
b.Size = size
b.BackgroundColor3 = bg
b.Font = Enum.Font.Oswald
b.Text = text
b.TextColor3 = fg
b.TextScaled = true
b.Parent = frame
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
b.MouseButton1Click:Connect(onClick)
return b
end
btnRole = makeBtn("ЦЕЛЬ: БЕГ ПО ТОЧКАМ", UDim2.new(0, 14, 1, -156), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(255, 222, 189), Color3.fromRGB(39, 20, 17), function()
local cIdx = PathfindLib.SelectedClone
local route = PathfindLib.GetRoute(cIdx)
local allClones = getgenv().MemeAllClones or {}
local maxClones = math.max(2, #allClones)
local nextTarget = (route.ChaseCloneIdx or 0) + 1
if nextTarget == cIdx then nextTarget = nextTarget + 1 end
route.ChaseCloneIdx = (nextTarget <= maxClones) and nextTarget or nil
refreshControlButtons()
end)
btnDelay = makeBtn("ЗАДЕРЖКА СТАРТА: 0 СЕК", UDim2.new(0.52, 0, 1, -156), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(111, 95, 86), Color3.fromRGB(255, 222, 189), function()
local route = PathfindLib.GetRoute(PathfindLib.SelectedClone)
local steps = { 0, 0.5, 1.0, 1.5, 2.5, 4.0 }
local nextVal = 0
for i, v in ipairs(steps) do
if math.abs(route.StartDelay - v) < 0.05 then
nextVal = steps[(i % #steps) + 1]
break
end
end
route.StartDelay = nextVal
refreshControlButtons()
end)
-- Кнопка установки точки ровно в позиции игрока!
makeBtn("+ ТОЧКА В МОЕЙ ПОЗИЦИИ", UDim2.new(0, 14, 1, -118), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(95, 210, 130), Color3.fromRGB(20, 12, 11), function()
if PathfindLib.AddNodeAtPlayer(PathfindLib.SelectedClone) then
refreshControlButtons()
redrawOverlays()
end
end)
makeBtn("+ СЕРЕДИНА КОВРА (CARPET)", UDim2.new(0.52, 0, 1, -118), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(255, 222, 189), Color3.fromRGB(39, 20, 17), function()
local r = select(1, unpack(activeRooms))
if r then
for _, d in ipairs(r:GetDescendants()) do
if d:IsA("BasePart") and d.Name == "Carpet" then
local fy = getExactFloorY(activeRooms, d.Position.X, d.Position.Z, baseFloorY)
PathfindLib.AddNode(Vector3.new(d.Position.X, fy, d.Position.Z), PathfindLib.SelectedClone)
end
end
refreshControlButtons()
redrawOverlays()
end
end)
local hideBtn
hideBtn = makeBtn(PathfindLib.ShowMarkers and "3D-ШАРЫ В КОМНАТЕ: ВКЛ" or "3D-ШАРЫ В КОМНАТЕ: СКРЫТЫ",
UDim2.new(0, 14, 1, -80), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(98, 145, 204), Color3.fromRGB(255, 255, 255), function()
PathfindLib.SetMarkersVisible(not PathfindLib.ShowMarkers)
hideBtn.Text = PathfindLib.ShowMarkers and "3D-ШАРЫ В КОМНАТЕ: ВКЛ" or "3D-ШАРЫ В КОМНАТЕ: СКРЫТЫ"
end)
makeBtn("СБРОС ЗУМА И ЦЕНТРА", UDim2.new(0.52, 0, 1, -80), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(111, 95, 86), Color3.fromRGB(255, 222, 189), function()
loadRoomsPair(selectedIdx)
redrawOverlays()
end)
makeBtn("УДАЛИТЬ ПОСЛЕДНЮЮ ТОЧКУ", UDim2.new(0, 14, 1, -42), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(145, 103, 92), Color3.fromRGB(255, 222, 189), function()
local route = PathfindLib.GetRoute(PathfindLib.SelectedClone)
PathfindLib.RemoveNodeAt(#route.Nodes, PathfindLib.SelectedClone)
refreshControlButtons()
redrawOverlays()
end)
makeBtn("ОЧИСТИТЬ МАРШРУТ КЛОНА", UDim2.new(0.52, 0, 1, -42), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(204, 68, 26), Color3.fromRGB(255, 222, 189), function()
PathfindLib.ClearNodes(PathfindLib.SelectedClone)
refreshControlButtons()
redrawOverlays()
end)
refreshControlButtons()
loadRoomsPair(selectedIdx)
local acc = 0
mapRenderConn = RunService.Heartbeat:Connect(function(dt)
acc = acc + dt
if acc >= 0.12 then acc = 0; redrawOverlays() end
end)
task.defer(redrawOverlays)
end
getgenv().MemePathfindLib = PathfindLib
return PathfindLib