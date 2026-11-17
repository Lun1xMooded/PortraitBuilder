-- libs/PathfindLib.lua
-- Профессиональная 3D-карта двух комнат DOORS: зум, перетаскивание, выбор стартовой точки, удаление ПКМ, центр комнаты/ковра

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local PathfindLib = {
    Nodes = {},
    StartNodeIndex = 1,
    ShowMarkers = true,
    LoopPath = true,
    SprintPath = false,
}

local mapGui = nil
local mapRenderConn = nil

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
    if not PathfindLib.ShowMarkers or #PathfindLib.Nodes == 0 then return end

    local folder = Instance.new("Folder")
    folder.Name = "MemeActorPathMarkers"
    folder.Parent = workspace

    for i, pos in ipairs(PathfindLib.Nodes) do
        local isStart = (i == PathfindLib.StartNodeIndex)
        local p = Instance.new("Part")
        p.Name = "Node_" .. i
        p.Shape = Enum.PartType.Ball
        p.Size = isStart and Vector3.new(1.4, 1.4, 1.4) or Vector3.new(1.0, 1.0, 1.0)
        p.Position = pos + Vector3.new(0, 0.6, 0)
        p.Color = isStart and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(95, 255, 130)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.Parent = folder

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 74, 0, 24)
        bb.StudsOffset = Vector3.new(0, 1.4, 0)
        bb.AlwaysOnTop = true
        bb.Parent = p

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Oswald
        lbl.Text = isStart and ("START #" .. i) or ("NODE " .. i)
        lbl.TextColor3 = p.Color
        lbl.TextStrokeTransparency = 0.2
        lbl.TextScaled = true
        lbl.Parent = bb
    end
end

function PathfindLib.SetMarkersVisible(state)
    PathfindLib.ShowMarkers = state == true
    PathfindLib.RefreshMarkers()
end

function PathfindLib.AddNode(pos)
    table.insert(PathfindLib.Nodes, pos)
    if #PathfindLib.Nodes == 1 then
        PathfindLib.StartNodeIndex = 1
    end
    PathfindLib.RefreshMarkers()
end

function PathfindLib.RemoveNodeAt(index)
    if index < 1 or index > #PathfindLib.Nodes then return end
    table.remove(PathfindLib.Nodes, index)
    if PathfindLib.StartNodeIndex > #PathfindLib.Nodes then
        PathfindLib.StartNodeIndex = math.max(1, #PathfindLib.Nodes)
    end
    PathfindLib.RefreshMarkers()
end

function PathfindLib.SetStartNode(index)
    if index < 1 or index > #PathfindLib.Nodes then return end
    PathfindLib.StartNodeIndex = index
    PathfindLib.RefreshMarkers()

    -- Телепортируем активного клона на выбранную стартовую точку!
    local clone = getgenv().ActiveActorClone
    local pos = PathfindLib.Nodes[index]
    if clone and pos then
        local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart")
        if root then
            local nextPos = PathfindLib.Nodes[(index % #PathfindLib.Nodes) + 1] or (pos + root.CFrame.LookVector)
            local lookDir = ((nextPos - pos) * Vector3.new(1, 0, 1))
            lookDir = (lookDir.Magnitude > 0.01) and lookDir.Unit or root.CFrame.LookVector
            root.CFrame = CFrame.lookAt(pos + Vector3.new(0, 3.6, 0), pos + Vector3.new(0, 3.6, 0) + lookDir)
        end
    end
    print("[Pathfind] Стартовая позиция установлена на точку #" .. index)
end

function PathfindLib.ClearNodes()
    table.clear(PathfindLib.Nodes)
    PathfindLib.StartNodeIndex = 1
    PathfindLib.RefreshMarkers()
end

local function getExactFloorY(roomsList, x, z, fallbackY)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Include
    rp.FilterDescendantsInstances = roomsList
    local hit = workspace:Raycast(Vector3.new(x, fallbackY + 14, z), Vector3.new(0, -35, 0), rp)
    return hit and hit.Position.Y or fallbackY
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
    frame.Size = UDim2.new(0, 560, 0, 610)
    frame.BackgroundColor3 = Color3.fromRGB(30, 17, 16)
    frame.BackgroundTransparency = 0.04
    frame.Parent = mapGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", frame)
    st.Color = Color3.fromRGB(255, 222, 189)
    st.Thickness = 3
    CollectionService:AddTag(frame, "UnlockMouseVisible")

    -- Верхняя панель с переключением комнат
    local hdr = Instance.new("TextLabel")
    hdr.Position = UDim2.new(0, 14, 0, 8)
    hdr.Size = UDim2.new(0.56, 0, 0, 30)
    hdr.BackgroundTransparency = 1
    hdr.Font = Enum.Font.Oswald
    hdr.Text = "КАРТА (2 КОМНАТЫ)"
    hdr.TextColor3 = Color3.fromRGB(255, 222, 189)
    hdr.TextScaled = true
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = frame

    local btnPrevRoom = Instance.new("TextButton")
    btnPrevRoom.Position = UDim2.new(0.58, 0, 0, 8)
    btnPrevRoom.Size = UDim2.new(0.14, 0, 0, 30)
    btnPrevRoom.BackgroundColor3 = Color3.fromRGB(84, 68, 61)
    btnPrevRoom.Font = Enum.Font.Oswald
    btnPrevRoom.Text = "< ПРЕД"
    btnPrevRoom.TextColor3 = Color3.fromRGB(255, 222, 189)
    btnPrevRoom.TextScaled = true
    btnPrevRoom.Parent = frame
    Instance.new("UICorner", btnPrevRoom).CornerRadius = UDim.new(0, 6)

    local btnNextRoom = Instance.new("TextButton")
    btnNextRoom.Position = UDim2.new(0.73, 0, 0, 8)
    btnNextRoom.Size = UDim2.new(0.14, 0, 0, 30)
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
    hint.Text = "ЛКМ по полу: новая точка | ЛКМ по точке: СТАРТ | ПКМ по точке: удалить | Колёсико: ЗУМ | ПКМ+тянуть: сдвиг"
    hint.TextColor3 = Color3.fromRGB(165, 130, 115)
    hint.TextScaled = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Parent = frame

    local vp = Instance.new("ViewportFrame")
    vp.Position = UDim2.new(0, 14, 0, 64)
    vp.Size = UDim2.new(1, -28, 1, -192)
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
local skip = low:find("ceiling") or low:find("rafter") or low:find("skybox") or low:find("dust")
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
local prevPx = nil
local absSize = overlay.AbsoluteSize
for idx, nPos in ipairs(PathfindLib.Nodes) do
local ud = worldToOverlay(nPos)
local curPx = Vector2.new(ud.X.Scale * absSize.X, ud.Y.Scale * absSize.Y)
if prevPx then
local diff = curPx - prevPx
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0.5)
line.Position = UDim2.new(0, (prevPx.X + curPx.X) * 0.5, 0, (prevPx.Y + curPx.Y) * 0.5)
line.Size = UDim2.new(0, diff.Magnitude, 0, 2)
line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
line.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
line.BorderSizePixel = 0
line.ZIndex = 3
line.Parent = overlay
end
prevPx = curPx
local isStart = (idx == PathfindLib.StartNodeIndex)
local dot = Instance.new("TextButton")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = ud
dot.Size = isStart and UDim2.new(0, 28, 0, 28) or UDim2.new(0, 22, 0, 22)
dot.BackgroundColor3 = isStart and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(95, 255, 130)
dot.Font = Enum.Font.Oswald
dot.Text = isStart and ("S" .. idx) or tostring(idx)
dot.TextColor3 = Color3.fromRGB(20, 12, 11)
dot.TextSize = 14
dot.ZIndex = 6
dot.Parent = overlay
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
-- ЛКМ по точке = сделать стартовой, ПКМ по точке = удалить её вручную!
dot.MouseButton1Click:Connect(function()
PathfindLib.SetStartNode(idx)
redrawOverlays()
end)
dot.MouseButton2Click:Connect(function()
PathfindLib.RemoveNodeAt(idx)
redrawOverlays()
end)
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
local clone = getgenv().ActiveActorClone
if clone and clone.PrimaryPart then
local cDot = Instance.new("TextLabel")
cDot.AnchorPoint = Vector2.new(0.5, 0.5)
cDot.Position = worldToOverlay(clone.PrimaryPart.Position)
cDot.Size = UDim2.new(0, 40, 0, 18)
cDot.BackgroundColor3 = Color3.fromRGB(255, 195, 65)
cDot.Font = Enum.Font.Oswald
cDot.Text = "КЛОН"
cDot.TextColor3 = Color3.fromRGB(30, 17, 16)
cDot.TextSize = 13
cDot.ZIndex = 7
cDot.Parent = overlay
Instance.new("UICorner", cDot).CornerRadius = UDim.new(0, 4)
end
end
-- Зум колёсиком и перетаскивание карты правой кнопкой мыши
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
-- ЛКМ по пустому месту карты ставит новую точку на полу
overlay.MouseButton1Click:Connect(function()
local mPos = UserInputService:GetMouseLocation()
local relX = (mPos.X - overlay.AbsolutePosition.X) / overlay.AbsoluteSize.X
local relY = (mPos.Y - 36 - overlay.AbsolutePosition.Y) / overlay.AbsoluteSize.Y
local ray = vpCam:ViewportPointToRay(relX, relY, 0)
if math.abs(ray.Direction.Y) > 0.001 then
local t = (baseFloorY - ray.Origin.Y) / ray.Direction.Y
local hitPos = ray.Origin + ray.Direction * t
local exactY = getExactFloorY(activeRooms, hitPos.X, hitPos.Z, baseFloorY)
PathfindLib.AddNode(Vector3.new(hitPos.X, exactY, hitPos.Z))
redrawOverlays()
end
end)
btnPrevRoom.MouseButton1Click:Connect(function() loadRoomsPair(selectedIdx - 1); redrawOverlays() end)
btnNextRoom.MouseButton1Click:Connect(function() loadRoomsPair(selectedIdx + 1); redrawOverlays() end)
-- Нижние кнопки быстрых ориентиров (Середина комнаты, Середина ковра, Скрыть точки, Очистить)
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
-- Ряд 1: Середина комнаты / Середина ковра
makeBtn("+ СЕРЕДИНА КОМНАТЫ", UDim2.new(0, 14, 1, -118), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(255, 222, 189), Color3.fromRGB(39, 20, 17), function()
local r = activeRooms
local fl = r and r:FindFirstChild("Parts") and r.Parts:FindFirstChild("Floor")
if fl then
local fy = fl.Position.Y + fl.Size.Y * 0.5
PathfindLib.AddNode(Vector3.new(fl.Position.X, fy, fl.Position.Z))
redrawOverlays()
end
end)
makeBtn("+ СЕРЕДИНА КОВРА (CARPET)", UDim2.new(0.52, 0, 1, -118), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(255, 222, 189), Color3.fromRGB(39, 20, 17), function()
local r = activeRooms
if r then
for _, d in ipairs(r:GetDescendants()) do
if d:IsA("BasePart") and d.Name == "Carpet" then
local fy = getExactFloorY(activeRooms, d.Position.X, d.Position.Z, baseFloorY)
PathfindLib.AddNode(Vector3.new(d.Position.X, fy, d.Position.Z))
end
end
redrawOverlays()
end
end)
-- Ряд 2: Скрыть 3D-шары / Сброс зума
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
-- Ряд 3: Удалить последнюю / Очистить все
makeBtn("УДАЛИТЬ ПОСЛЕДНЮЮ", UDim2.new(0, 14, 1, -42), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(145, 103, 92), Color3.fromRGB(255, 222, 189), function()
PathfindLib.RemoveNodeAt(#PathfindLib.Nodes)
redrawOverlays()
end)
makeBtn("ОЧИСТИТЬ ВСЕ ТОЧКИ", UDim2.new(0.52, 0, 1, -42), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(204, 68, 26), Color3.fromRGB(255, 222, 189), function()
PathfindLib.ClearNodes()
redrawOverlays()
end)
loadRoomsPair(selectedIdx)
local acc = 0
mapRenderConn = RunService.Heartbeat:Connect(function(dt)
acc = acc + dt
if acc >= 0.12 then acc = 0; redrawOverlays() end
end)
task.defer(redrawOverlays)
end
return PathfindLib