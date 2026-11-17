-- libs/PathfindLib.lua
-- Настоящий ортографический вид сверху (ViewportFrame) на текущую комнату DOORS + 2D/3D точки маршрута

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local PathfindLib = {
    Nodes = {},
    ShowMarkers = true,
    LoopPath = true,
    SprintPath = false,
}

local markerFolder = nil
local mapGui = nil
local mapRenderConn = nil

function PathfindLib.GetCurrentRoom()
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return nil end

    local gd = ReplicatedStorage:FindFirstChild("GameData")
    local latest = gd and gd:FindFirstChild("LatestRoom") and gd.LatestRoom.Value
    if latest ~= nil and currentRooms:FindFirstChild(tostring(latest)) then
        return currentRooms[tostring(latest)]
    end

    local children = currentRooms:GetChildren()
    return children[#children]
end

function PathfindLib.RefreshMarkers()
    if markerFolder then markerFolder:Destroy(); markerFolder = nil end
    if not PathfindLib.ShowMarkers or #PathfindLib.Nodes == 0 then return end

    markerFolder = Instance.new("Folder")
    markerFolder.Name = "MemeActorPathMarkers"
    markerFolder.Parent = workspace

    for i, pos in ipairs(PathfindLib.Nodes) do
        local p = Instance.new("Part")
        p.Name = "Node_" .. i
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(1.1, 1.1, 1.1)
        p.Position = pos + Vector3.new(0, 0.55, 0)
        p.Color = (i == 1) and Color3.fromRGB(95, 255, 130) or Color3.fromRGB(255, 222, 189)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.Parent = markerFolder

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 56, 0, 22)
        bb.StudsOffset = Vector3.new(0, 1.3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = p

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Oswald
        lbl.Text = "NODE " .. i
        lbl.TextColor3 = Color3.fromRGB(255, 222, 189)
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
    PathfindLib.RefreshMarkers()
end

function PathfindLib.ClearNodes()
    table.clear(PathfindLib.Nodes)
    PathfindLib.RefreshMarkers()
end

-- Точный поиск высоты пола в точке (X, Z) комнаты
local function getExactFloorY(room, x, z, fallbackY)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Include
    rp.FilterDescendantsInstances = { room }
    local hit = workspace:Raycast(Vector3.new(x, fallbackY + 12, z), Vector3.new(0, -30, 0), rp)
    return hit and hit.Position.Y or fallbackY
end

function PathfindLib.GetRoomBounds(room)
    room = room or PathfindLib.GetCurrentRoom()
    if not room then return nil end

    local parts = room:FindFirstChild("Parts")
    local floor = parts and parts:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        -- Учитываем поворот CFrame пола для точного мирового размера по X и Z!
        local cf, sz = floor.CFrame, floor.Size
        local _, _, _, r00, _, r02, _, _, _, r20, _, r22 = cf:GetComponents()
        local worldX = math.abs(r00) * sz.X + math.abs(r02) * sz.Z
        local worldZ = math.abs(r20) * sz.X + math.abs(r22) * sz.Z
        return {
            Room = room,
            Center = cf.Position,
            SizeX = worldX,
            SizeZ = worldZ,
            FloorY = cf.Position.Y + sz.Y * 0.5,
        }
    end

    local cf, sz = room:GetBoundingBox()
    return {
        Room = room,
        Center = cf.Position,
        SizeX = sz.X,
        SizeZ = sz.Z,
        FloorY = cf.Position.Y - sz.Y * 0.2,
    }
end

function PathfindLib.AutoGenerateFromCarpet()
    local bounds = PathfindLib.GetRoomBounds()
    if not bounds then return end
    local room = bounds.Room
    PathfindLib.ClearNodes()

    local entrance = room:FindFirstChild("RoomEntrance", true)
    local exitPart = room:FindFirstChild("RoomExit", true)
    if entrance and entrance:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(entrance.Position.X, bounds.FloorY, entrance.Position.Z))
    end

    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name == "Carpet" then
            local fy = getExactFloorY(room, desc.Position.X, desc.Position.Z, bounds.FloorY)
            PathfindLib.AddNode(Vector3.new(desc.Position.X, fy, desc.Position.Z))
        end
    end

    if #PathfindLib.Nodes <= 1 then
        local pf = room:FindFirstChild("PathfindNodes")
        if pf then
            local list = pf:GetChildren()
            table.sort(list, function(a, b) return a.Name < b.Name end)
            for _, n in ipairs(list) do
                if n:IsA("BasePart") then
                    PathfindLib.AddNode(Vector3.new(n.Position.X, bounds.FloorY, n.Position.Z))
                end
            end
        end
    end

    if exitPart and exitPart:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(exitPart.Position.X, bounds.FloorY, exitPart.Position.Z))
    end
end

local function closeMap()
    if mapRenderConn then mapRenderConn:Disconnect(); mapRenderConn = nil end
    if mapGui then mapGui:Destroy(); mapGui = nil end
end

function PathfindLib.OpenLayoutMap()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    closeMap()

    local bounds = PathfindLib.GetRoomBounds()
    if not bounds then return end
    local room = bounds.Room

    mapGui = Instance.new("ScreenGui")
    mapGui.Name = "MemeActorRoomMap"
    mapGui.DisplayOrder = 30
    mapGui.ResetOnSpawn = false
    mapGui.Parent = pgui

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 520, 0, 560)
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
    hdr.Size = UDim2.new(1, -56, 0, 30)
    hdr.BackgroundTransparency = 1
    hdr.Font = Enum.Font.Oswald
    hdr.Text = "3D-КАРТА КОМНАТЫ #" .. room.Name .. " (КЛИКНИ ПО ПОЛУ ДЛЯ ТОЧКИ)"
    hdr.TextColor3 = Color3.fromRGB(255, 222, 189)
    hdr.TextScaled = true
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = frame

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

    -- ViewportFrame с реальным видом сверху на геометрию комнаты (без потолка и скайбоксов!)
    local vp = Instance.new("ViewportFrame")
    vp.Position = UDim2.new(0, 14, 0, 44)
    vp.Size = UDim2.new(1, -28, 1, -132)
    vp.BackgroundColor3 = Color3.fromRGB(18, 11, 10)
    vp.Ambient = Color3.fromRGB(210, 200, 190)
    vp.LightColor = Color3.fromRGB(255, 245, 235)
    vp.LightDirection = Vector3.new(-0.3, -1, -0.3)
    vp.Parent = frame
    Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 8)
    local vpStroke = Instance.new("UIStroke", vp)
    vpStroke.Color = Color3.fromRGB(110, 92, 82)
    vpStroke.Thickness = 2

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = vp

    -- Копируем только нужную геометрию комнаты (пол, ковры, мебель, двери), отрезая потолок и небо
    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Transparency < 0.95 then
            local low = desc.Name:lower()
            local isCeiling = low:find("ceiling") or low:find("rafter") or low:find("skybox") or low:find("dust")
            if not isCeiling and desc.Position.Y <= bounds.FloorY + 9.5 then
                local cp = desc:Clone()
                cp:ClearAllChildren()
                cp.Anchored = true
                cp.CanCollide = false
                cp.Parent = worldModel
            end
        end
    end

    -- Ортографическая камера сверху (FOV = 1 градус убирает перспективные искажения!)
    local vpCam = Instance.new("Camera")
    vpCam.FieldOfView = 1
    vpCam.Parent = vp
    vp.CurrentCamera = vpCam

    local maxSpan = math.max(bounds.SizeX, bounds.SizeZ) * 1.06
    local camDist = (maxSpan * 0.5) / math.tan(math.rad(0.5))
    -- UpVector = (0, 0, -1), чтобы ось +X была строго вправо, а +Z строго вниз
    vpCam.CFrame = CFrame.lookAt(bounds.Center + Vector3.new(0, camDist, 0), bounds.Center, Vector3.new(0, 0, -1))

    -- Прозрачный слой кликов и 2D-оверлеев строго поверх ViewportFrame
    local overlay = Instance.new("TextButton")
    overlay.Position = vp.Position
    overlay.Size = vp.Size
    overlay.BackgroundTransparency = 1
    overlay.ClipsDescendants = true
    overlay.Text = ""
    overlay.Parent = frame

    -- Точный перевод 3D <-> 2D через WorldToViewportPoint самой камеры ViewportFrame!
local function worldToOverlay(pos)
local screenPos, onScreen = vpCam:WorldToViewportPoint(pos)
return UDim2.new(screenPos.X, 0, screenPos.Y, 0), onScreen
end
local function redrawOverlays()
if not overlay or not overlay.Parent then return end
overlay:ClearAllChildren()
-- Линии и номера точек PathfindNodes
local prevPx = nil
local absSize = overlay.AbsoluteSize
for idx, nPos in ipairs(PathfindLib.Nodes) do
local ud, _ = worldToOverlay(nPos)
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
local dot = Instance.new("TextLabel")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = ud
dot.Size = UDim2.new(0, 22, 0, 22)
dot.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
dot.Font = Enum.Font.Oswald
dot.Text = tostring(idx)
dot.TextColor3 = Color3.fromRGB(20, 12, 11)
dot.TextSize = 15
dot.ZIndex = 5
dot.Parent = overlay
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end
-- Живая метка игрока "ТЫ"
local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
if myRoot then
local ud = worldToOverlay(myRoot.Position)
local meDot = Instance.new("TextLabel")
meDot.AnchorPoint = Vector2.new(0.5, 0.5)
meDot.Position = ud
meDot.Size = UDim2.new(0, 32, 0, 18)
meDot.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
meDot.Font = Enum.Font.Oswald
meDot.Text = "ТЫ"
meDot.TextColor3 = Color3.new(1, 1, 1)
meDot.TextSize = 13
meDot.ZIndex = 6
meDot.Parent = overlay
Instance.new("UICorner", meDot).CornerRadius = UDim.new(0, 4)
end
-- Живая метка клона "КЛОН"
local clone = getgenv().ActiveActorClone
if clone and clone.PrimaryPart then
local ud = worldToOverlay(clone.PrimaryPart.Position)
local cDot = Instance.new("TextLabel")
cDot.AnchorPoint = Vector2.new(0.5, 0.5)
cDot.Position = ud
cDot.Size = UDim2.new(0, 40, 0, 18)
cDot.BackgroundColor3 = Color3.fromRGB(255, 195, 65)
cDot.Font = Enum.Font.Oswald
cDot.Text = "КЛОН"
cDot.TextColor3 = Color3.fromRGB(30, 17, 16)
cDot.TextSize = 13
cDot.ZIndex = 6
cDot.Parent = overlay
Instance.new("UICorner", cDot).CornerRadius = UDim.new(0, 4)
end
end
-- Клик по 3D-карте переводится через ViewportPointToRay в точные мировые координаты пола!
overlay.MouseButton1Click:Connect(function()
local mPos = UserInputService:GetMouseLocation()
local relX = (mPos.X - overlay.AbsolutePosition.X) / overlay.AbsoluteSize.X
local relY = (mPos.Y - 36 - overlay.AbsolutePosition.Y) / overlay.AbsoluteSize.Y
local ray = vpCam:ViewportPointToRay(relX, relY, 0)
-- Пересекаем луч с горизонтальной плоскостью пола bounds.FloorY
if math.abs(ray.Direction.Y) > 0.001 then
local t = (bounds.FloorY - ray.Origin.Y) / ray.Direction.Y
local hitPos = ray.Origin + ray.Direction * t
local exactY = getExactFloorY(room, hitPos.X, hitPos.Z, bounds.FloorY)
PathfindLib.AddNode(Vector3.new(hitPos.X, exactY, hitPos.Z))
redrawOverlays()
end
end)
-- Кнопки управления внизу окна
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
makeBtn("АВТО-ПУТЬ ПО КОВРУ (CARPET)", UDim2.new(0, 14, 1, -80), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(255, 222, 189), Color3.fromRGB(39, 20, 17), function()
PathfindLib.AutoGenerateFromCarpet()
redrawOverlays()
end)
local hideBtn
hideBtn = makeBtn(PathfindLib.ShowMarkers and "СПРЯТАТЬ ТОЧКИ (3D: ВКЛ)" or "ПОКАЗАТЬ ТОЧКИ (3D: ВЫКЛ)",
UDim2.new(0.52, 0, 1, -80), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(98, 145, 204), Color3.fromRGB(255, 255, 255), function()
PathfindLib.SetMarkersVisible(not PathfindLib.ShowMarkers)
hideBtn.Text = PathfindLib.ShowMarkers and "СПРЯТАТЬ ТОЧКИ (3D: ВКЛ)" or "ПОКАЗАТЬ ТОЧКИ (3D: ВЫКЛ)"
end)
makeBtn("УДАЛИТЬ ПОСЛЕДНЮЮ ТОЧКУ", UDim2.new(0, 14, 1, -42), UDim2.new(0.48, -4, 0, 32),
Color3.fromRGB(145, 103, 92), Color3.fromRGB(255, 222, 189), function()
if #PathfindLib.Nodes > 0 then
table.remove(PathfindLib.Nodes)
PathfindLib.RefreshMarkers()
redrawOverlays()
end
end)
makeBtn("ОЧИСТИТЬ ВСЕ ТОЧКИ", UDim2.new(0.52, 0, 1, -42), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(204, 68, 26), Color3.fromRGB(255, 222, 189), function()
PathfindLib.ClearNodes()
redrawOverlays()
end)
-- Обновляем позиции "ТЫ" и "КЛОН" на карте 10 раз в секунду
local acc = 0
mapRenderConn = RunService.Heartbeat:Connect(function(dt)
acc = acc + dt
if acc >= 0.1 then
acc = 0
redrawOverlays()
end
end)
task.defer(redrawOverlays)
end
return PathfindLib