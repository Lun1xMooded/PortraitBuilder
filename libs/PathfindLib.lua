-- libs/PathfindLib.lua
-- Чистая схема комнаты DOORS (ClipsDescendants), отображение маршрута и кнопка скрытия 3D-точек

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local PathfindLib = {
    Nodes = {},
    ShowMarkers = true,
    LoopPath = true,
    SprintPath = false,
}

local markerFolder = nil
local mapGui = nil

local FURNITURE_STYLES = {
    Carpet    = { Color = Color3.fromRGB(145, 48, 44),   Alpha = 0.45, Z = 1, Label = false },
    Window    = { Color = Color3.fromRGB(95, 175, 240),  Alpha = 0.20, Z = 3, Label = true },
    Bed       = { Color = Color3.fromRGB(175, 105, 195), Alpha = 0.20, Z = 2, Label = true },
    Bookcase  = { Color = Color3.fromRGB(135, 92, 58),   Alpha = 0.15, Z = 2, Label = true },
    Dresser   = { Color = Color3.fromRGB(170, 120, 75),  Alpha = 0.15, Z = 2, Label = true },
    Fireplace = { Color = Color3.fromRGB(235, 110, 40),  Alpha = 0.15, Z = 3, Label = true },
    Wardrobe  = { Color = Color3.fromRGB(85, 155, 105),  Alpha = 0.15, Z = 2, Label = true },
    Door      = { Color = Color3.fromRGB(255, 222, 189), Alpha = 0.05, Z = 4, Label = true },
}

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

local function getCleanModelBounds(model)
    -- Для Window игнорируем уличный Skybox, берём размер Collision или Glass
    if model.Name:find("Window") then
        local col = model:FindFirstChild("Collision") or model:FindFirstChild("Glass")
        if col and col:IsA("BasePart") then
            return col.Position, col.Size
        end
    end
    local cf, sz = model:GetBoundingBox()
    return cf.Position, sz
end

function PathfindLib.ScanRoom(room)
    room = room or PathfindLib.GetCurrentRoom()
    if not room then return nil end

    local partsFolder = room:FindFirstChild("Parts")
    local floor = partsFolder and partsFolder:FindFirstChild("Floor")
    local minX, maxX, minZ, maxZ, floorY

    if floor and floor:IsA("BasePart") then
        floorY = floor.Position.Y + floor.Size.Y * 0.5
        minX, maxX = floor.Position.X - floor.Size.X * 0.5, floor.Position.X + floor.Size.X * 0.5
        minZ, maxZ = floor.Position.Z - floor.Size.Z * 0.5, floor.Position.Z + floor.Size.Z * 0.5
    else
        local cf, sz = room:GetBoundingBox()
        floorY = cf.Position.Y - sz.Y * 0.2
        minX, maxX = cf.Position.X - sz.X * 0.5, cf.Position.X + sz.X * 0.5
        minZ, maxZ = cf.Position.Z - sz.Z * 0.5, cf.Position.Z + sz.Z * 0.5
    end

    local items = {}
    local nativeNodes = {}

    local pfFolder = room:FindFirstChild("PathfindNodes")
    if pfFolder then
        local list = pfFolder:GetChildren()
        table.sort(list, function(a, b) return a.Name < b.Name end)
        for _, n in ipairs(list) do
            if n:IsA("BasePart") then
                table.insert(nativeNodes, Vector3.new(n.Position.X, floorY, n.Position.Z))
            end
        end
    end

    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("BasePart") and (desc.Name == "Carpet" or desc.Name == "CarpetLight") then
            table.insert(items, { Kind = "Carpet", Pos = desc.Position, Size = desc.Size })
        elseif desc:IsA("Model") then
            local k = nil
            if desc.Name:find("Window") then k = "Window"
            elseif desc.Name:find("Bed") then k = "Bed"
            elseif desc.Name:find("Bookcase") then k = "Bookcase"
            elseif desc.Name:find("Dresser") then k = "Dresser"
            elseif desc.Name:find("Fireplace") then k = "Fireplace"
            elseif desc.Name:find("Wardrobe") then k = "Wardrobe"
            elseif desc.Name == "Door" or desc.Name == "RoomEntrance" or desc.Name == "RoomExit" then k = "Door"
            end
            if k then
                local pos, sz = getCleanModelBounds(desc)
                table.insert(items, { Kind = k, Pos = pos, Size = sz })
            end
        end
    end

    return {
        Room = room,
        FloorY = floorY,
        MinX = minX, MaxX = maxX,
        MinZ = minZ, MaxZ = maxZ,
        Items = items,
        NativeNodes = nativeNodes,
    }
end

function PathfindLib.AutoGenerateFromCarpet()
    local scan = PathfindLib.ScanRoom()
    if not scan then return end
    PathfindLib.ClearNodes()

    local entrance = scan.Room:FindFirstChild("RoomEntrance", true)
    local exitPart = scan.Room:FindFirstChild("RoomExit", true)
    if entrance and entrance:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(entrance.Position.X, scan.FloorY, entrance.Position.Z))
    end

    for _, it in ipairs(scan.Items) do
        if it.Kind == "Carpet" then
            PathfindLib.AddNode(Vector3.new(it.Pos.X, scan.FloorY, it.Pos.Z))
        end
    end

    if #PathfindLib.Nodes <= 1 and #scan.NativeNodes > 0 then
        for _, p in ipairs(scan.NativeNodes) do
            PathfindLib.AddNode(p)
        end
    end

    if exitPart and exitPart:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(exitPart.Position.X, scan.FloorY, exitPart.Position.Z))
    end
end

function PathfindLib.OpenLayoutMap()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    if mapGui then mapGui:Destroy(); mapGui = nil end

    local scan = PathfindLib.ScanRoom()
    if not scan then return end

    mapGui = Instance.new("ScreenGui")
    mapGui.Name = "MemeActorRoomMap"
    mapGui.DisplayOrder = 25 -- Поверх основного меню DOORS!
    mapGui.ResetOnSpawn = false
    mapGui.Parent = pgui

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 500, 0, 540)
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
    hdr.Text = "СХЕМА КОМНАТЫ #" .. scan.Room.Name .. " — КЛИКНИ ПО ПОЛУ ДЛЯ ТОЧКИ"
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
    close.MouseButton1Click:Connect(function() if mapGui then mapGui:Destroy(); mapGui = nil end end)

    -- Холст комнаты с ClipsDescendants = true (ничто не вылезет за рамки!)
    local canvas = Instance.new("TextButton")
    canvas.Position = UDim2.new(0, 14, 0, 44)
    canvas.Size = UDim2.new(1, -28, 1, -132)
    canvas.BackgroundColor3 = Color3.fromRGB(22, 14, 13)
    canvas.ClipsDescendants = true
    canvas.Text = ""
    canvas.AutoButtonColor = false
    canvas.Parent = frame
    Instance.new("UICorner", canvas).CornerRadius = UDim.new(0, 8)
    local cStroke = Instance.new("UIStroke", canvas)
    cStroke.Color = Color3.fromRGB(110, 92, 82)
    cStroke.Thickness = 2

local spanX = math.max(10, scan.MaxX - scan.MinX)
local spanZ = math.max(10, scan.MaxZ - scan.MinZ)
local function toUV(pos)
return math.clamp((pos.X - scan.MinX) / spanX, 0.03, 0.97), math.clamp((pos.Z - scan.MinZ) / spanZ, 0.03, 0.97)
end
local function redraw()
canvas:ClearAllChildren()
-- 1. Мебель и ковры (с аккуратными пропорциями)
for _, it in ipairs(scan.Items) do
local style = FURNITURE_STYLES[it.Kind]
if style then
local u, v = toUV(it.Pos)
local w = math.clamp(it.Size.X / spanX, 0.04, 0.88)
local h = math.clamp(it.Size.Z / spanZ, 0.04, 0.88)
local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Position = UDim2.new(u, 0, v, 0)
box.Size = UDim2.new(w, 0, h, 0)
box.BackgroundColor3 = style.Color
box.BackgroundTransparency = style.Alpha
box.ZIndex = style.Z
box.Parent = canvas
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
local bStroke = Instance.new("UIStroke", box)
bStroke.Color = style.Color
bStroke.Thickness = 1.2
bStroke.Transparency = 0.3
if style.Label then
local tag = Instance.new("TextLabel")
tag.AnchorPoint = Vector2.new(0.5, 0.5)
tag.Position = UDim2.new(0.5, 0, 0.5, 0)
tag.Size = UDim2.new(0, 64, 0, 16)
tag.BackgroundTransparency = 1
tag.Font = Enum.Font.Oswald
tag.Text = it.Kind
tag.TextColor3 = Color3.new(1, 1, 1)
tag.TextStrokeTransparency = 0.3
tag.TextSize = 13
tag.ZIndex = style.Z + 1
tag.Parent = box
end
end
end
-- 2. Позиция игрока (синяя метка "ТЫ") и клона (жёлтая метка "КЛОН")
local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
if myRoot then
local u, v = toUV(myRoot.Position)
local meDot = Instance.new("TextLabel")
meDot.AnchorPoint = Vector2.new(0.5, 0.5)
meDot.Position = UDim2.new(u, 0, v, 0)
meDot.Size = UDim2.new(0, 34, 0, 18)
meDot.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
meDot.Font = Enum.Font.Oswald
meDot.Text = "ТЫ"
meDot.TextColor3 = Color3.new(1, 1, 1)
meDot.TextSize = 13
meDot.ZIndex = 6
meDot.Parent = canvas
Instance.new("UICorner", meDot).CornerRadius = UDim.new(0, 4)
end
local clone = getgenv().ActiveActorClone
if clone and clone.PrimaryPart then
local u, v = toUV(clone.PrimaryPart.Position)
local cDot = Instance.new("TextLabel")
cDot.AnchorPoint = Vector2.new(0.5, 0.5)
cDot.Position = UDim2.new(u, 0, v, 0)
cDot.Size = UDim2.new(0, 42, 0, 18)
cDot.BackgroundColor3 = Color3.fromRGB(255, 195, 65)
cDot.Font = Enum.Font.Oswald
cDot.Text = "КЛОН"
cDot.TextColor3 = Color3.fromRGB(30, 17, 16)
cDot.TextSize = 13
cDot.ZIndex = 6
cDot.Parent = canvas
Instance.new("UICorner", cDot).CornerRadius = UDim.new(0, 4)
end
-- 3. Линии и точки маршрута PathfindNodes
local prevPx = nil
for idx, nPos in ipairs(PathfindLib.Nodes) do
local u, v = toUV(nPos)
local curPx = Vector2.new(u * canvas.AbsoluteSize.X, v * canvas.AbsoluteSize.Y)
if prevPx then
local diff = curPx - prevPx
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0.5)
line.Position = UDim2.new(0, (prevPx.X + curPx.X) * 0.5, 0, (prevPx.Y + curPx.Y) * 0.5)
line.Size = UDim2.new(0, diff.Magnitude, 0, 2)
line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
line.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
line.BorderSizePixel = 0
line.ZIndex = 7
line.Parent = canvas
end
prevPx = curPx
local dot = Instance.new("TextLabel")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(u, 0, v, 0)
dot.Size = UDim2.new(0, 22, 0, 22)
dot.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
dot.Font = Enum.Font.Oswald
dot.Text = tostring(idx)
dot.TextColor3 = Color3.fromRGB(20, 12, 11)
dot.TextSize = 15
dot.ZIndex = 8
dot.Parent = canvas
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end
end
canvas.MouseButton1Click:Connect(function()
local mPos = UserInputService:GetMouseLocation()
local relX = math.clamp((mPos.X - canvas.AbsolutePosition.X) / canvas.AbsoluteSize.X, 0, 1)
local relY = math.clamp((mPos.Y - 36 - canvas.AbsolutePosition.Y) / canvas.AbsoluteSize.Y, 0, 1)
local worldPos = Vector3.new(scan.MinX + relX * spanX, scan.FloorY, scan.MinZ + relY * spanZ)
PathfindLib.AddNode(worldPos)
redraw()
end)
-- Нижняя панель управления (2 ряда аккуратных кнопок)
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
redraw()
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
redraw()
end
end)
makeBtn("ОЧИСТИТЬ ВСЕ ТОЧКИ", UDim2.new(0.52, 0, 1, -42), UDim2.new(0.48, -14, 0, 32),
Color3.fromRGB(204, 68, 26), Color3.fromRGB(255, 222, 189), function()
PathfindLib.ClearNodes()
redraw()
end)
task.defer(redraw)
end
return PathfindLib