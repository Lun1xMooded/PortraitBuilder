-- libs/PathfindLib.lua
-- Сканирует текущую комнату DOORS (Carpet, PathfindNodes, Window, Bed, Bookcase, Dresser, Fireplace, Wardrobe)
-- и строит 2D-карту планировки + 3D-маркеры точек маршрута

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local PathfindLib = {
    Nodes = {},         -- Список Vector3 точек маршрута
    ShowMarkers = true,
    LoopPath = true,
    SprintPath = false,
}

local markerFolder = nil
local mapGui = nil

local FURNITURE_COLORS = {
    Carpet    = Color3.fromRGB(165, 58, 52),
    Window    = Color3.fromRGB(115, 195, 255),
    Bed       = Color3.fromRGB(190, 120, 210),
    Bookcase  = Color3.fromRGB(130, 88, 55),
    Dresser   = Color3.fromRGB(175, 125, 78),
    Fireplace = Color3.fromRGB(245, 120, 45),
    Wardrobe  = Color3.fromRGB(95, 165, 115),
    Door      = Color3.fromRGB(255, 222, 189),
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
        p.Size = Vector3.new(1.2, 1.2, 1.2)
        p.Position = pos + Vector3.new(0, 0.6, 0)
        p.Color = (i == 1) and Color3.fromRGB(95, 255, 130) or Color3.fromRGB(255, 222, 189)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.Parent = markerFolder

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 60, 0, 24)
        bb.StudsOffset = Vector3.new(0, 1.4, 0)
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

function PathfindLib.AddNode(pos)
    table.insert(PathfindLib.Nodes, pos)
    PathfindLib.RefreshMarkers()
    print(string.format("[Pathfind] Добавлена точка #%d (%.1f, %.1f, %.1f)", #PathfindLib.Nodes, pos.X, pos.Y, pos.Z))
end

function PathfindLib.ClearNodes()
    table.clear(PathfindLib.Nodes)
    PathfindLib.RefreshMarkers()
    print("[Pathfind] Все точки очищены.")
end

-- Сканирует комнату DOORS: находит Floor, Carpet, мебель (Window, Bed, Bookcase, Dresser, Fireplace, Wardrobe) и PathfindNodes
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

    -- 1. Собираем нативные PathfindNodes из комнаты DOORS (если есть)
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

    -- 2. Сканируем Carpet, Window, Bed, Bookcase, Dresser, Fireplace, Wardrobe и двери
    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("BasePart") and (desc.Name == "Carpet" or desc.Name == "CarpetLight") then
            table.insert(items, { Kind = "Carpet", Name = desc.Name, Pos = desc.Position, Size = desc.Size })
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
                local cf, sz = desc:GetBoundingBox()
                table.insert(items, { Kind = k, Name = desc.Name, Pos = cf.Position, Size = sz })
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

-- Автогенерация маршрута по коврам (Carpet) и нативным узлам DOORS
function PathfindLib.AutoGenerateFromCarpet()
    local scan = PathfindLib.ScanRoom()
    if not scan then return end
    PathfindLib.ClearNodes()

    local entrance = scan.Room:FindFirstChild("RoomEntrance", true)
    local exitPart = scan.Room:FindFirstChild("RoomExit", true)
    if entrance and entrance:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(entrance.Position.X, scan.FloorY, entrance.Position.Z))
    end

    -- Добавляем центры всех ковров (Carpet)
    for _, it in ipairs(scan.Items) do
        if it.Kind == "Carpet" then
            PathfindLib.AddNode(Vector3.new(it.Pos.X, scan.FloorY, it.Pos.Z))
        end
    end

    -- Если ковров в комнате нет, используем нативные PathfindNodes DOORS
    if #PathfindLib.Nodes <= 1 and #scan.NativeNodes > 0 then
        for _, p in ipairs(scan.NativeNodes) do
            PathfindLib.AddNode(p)
        end
    end

    if exitPart and exitPart:IsA("BasePart") then
        PathfindLib.AddNode(Vector3.new(exitPart.Position.X, scan.FloorY, exitPart.Position.Z))
    end
end

-- Отдельное окно визуальной карты планировки комнаты (нажми на карту в любом месте — поставится точка!)
function PathfindLib.OpenLayoutMap()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    if mapGui then mapGui:Destroy(); mapGui = nil end

    local scan = PathfindLib.ScanRoom()
    if not scan then
        warn("[Pathfind] Комната не найдена!")
        return
    end

    mapGui = Instance.new("ScreenGui")
    mapGui.Name = "MemeActorRoomMap"
    mapGui.ResetOnSpawn = false
    mapGui.Parent = pgui

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 460, 0, 500)
    frame.BackgroundColor3 = Color3.fromRGB(30, 17, 16)
    frame.BackgroundTransparency = 0.1
    frame.Parent = mapGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", frame)
    st.Color = Color3.fromRGB(255, 222, 189)
    st.Thickness = 3
    CollectionService:AddTag(frame, "UnlockMouseVisible")

    local hdr = Instance.new("TextLabel")
    hdr.Position = UDim2.new(0, 12, 0, 6)
    hdr.Size = UDim2.new(1, -50, 0, 32)
    hdr.BackgroundTransparency = 1
    hdr.Font = Enum.Font.Oswald
    hdr.Text = "ПЛАН КОМНАТЫ #" .. scan.Room.Name .. " (КЛИКНИ ПО КАРТЕ ДЛЯ ТОЧКИ)"
    hdr.TextColor3 = Color3.fromRGB(255, 222, 189)
    hdr.TextScaled = true
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = frame

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -8, 0, 6)
    close.Size = UDim2.new(0, 32, 0, 32)
    close.BackgroundColor3 = Color3.fromRGB(204, 68, 26)
    close.Font = Enum.Font.Oswald
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 222, 189)
    close.TextScaled = true
    close.Parent = frame
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
    close.MouseButton1Click:Connect(function() if mapGui then mapGui:Destroy(); mapGui = nil end end)

    local canvas = Instance.new("TextButton")
    canvas.Position = UDim2.new(0, 14, 0, 44)
    canvas.Size = UDim2.new(1, -28, 1, -94)
    canvas.BackgroundColor3 = Color3.fromRGB(20, 12, 11)
    canvas.Text = ""
    canvas.AutoButtonColor = false
    canvas.Parent = frame
    Instance.new("UICorner", canvas).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", canvas).Color = Color3.fromRGB(80, 68, 62)

    local spanX = math.max(10, scan.MaxX - scan.MinX)
    local spanZ = math.max(10, scan.MaxZ - scan.MinZ)

    local function toUV(pos)
return math.clamp((pos.X - scan.MinX) / spanX, 0.02, 0.98), math.clamp((pos.Z - scan.MinZ) / spanZ, 0.02, 0.98)
end
local function redraw()
canvas:ClearAllChildren()
-- Отрисовка ковров (Carpet) и мебели (Window, Bed, Bookcase, Dresser, Fireplace, Wardrobe)
for _, it in ipairs(scan.Items) do
local u, v = toUV(it.Pos)
local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Position = UDim2.new(u, 0, v, 0)
box.Size = UDim2.new(math.clamp(it.Size.X / spanX, 0.04, 0.9), 0, math.clamp(it.Size.Z / spanZ, 0.04, 0.9), 0)
box.BackgroundColor3 = FURNITURE_COLORS[it.Kind] or Color3.fromRGB(140, 140, 140)
box.BackgroundTransparency = (it.Kind == "Carpet") and 0.55 or 0.25
box.ZIndex = (it.Kind == "Carpet") and 1 or 2
box.Parent = canvas
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
if it.Kind ~= "Carpet" then
local tag = Instance.new("TextLabel")
tag.Size = UDim2.new(1, 0, 1, 0)
tag.BackgroundTransparency = 1
tag.Font = Enum.Font.Oswald
tag.Text = it.Kind
tag.TextColor3 = Color3.new(1, 1, 1)
tag.TextScaled = true
tag.ZIndex = 3
tag.Parent = box
end
end
-- Отрисовка поставленных точек PathfindNodes
for idx, nPos in ipairs(PathfindLib.Nodes) do
local u, v = toUV(nPos)
local dot = Instance.new("TextLabel")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(u, 0, v, 0)
dot.Size = UDim2.new(0, 22, 0, 22)
dot.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
dot.Font = Enum.Font.Oswald
dot.Text = tostring(idx)
dot.TextColor3 = Color3.fromRGB(20, 12, 11)
dot.TextScaled = true
dot.ZIndex = 5
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
local btnAuto = Instance.new("TextButton")
btnAuto.Position = UDim2.new(0, 14, 1, -42)
btnAuto.Size = UDim2.new(0.48, -4, 0, 32)
btnAuto.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
btnAuto.Font = Enum.Font.Oswald
btnAuto.Text = "АВТО-ПУТЬ ПО КОВРУ (CARPET)"
btnAuto.TextColor3 = Color3.fromRGB(39, 20, 17)
btnAuto.TextScaled = true
btnAuto.Parent = frame
Instance.new("UICorner", btnAuto).CornerRadius = UDim.new(0, 6)
btnAuto.MouseButton1Click:Connect(function() PathfindLib.AutoGenerateFromCarpet(); redraw() end)
local btnClr = Instance.new("TextButton")
btnClr.AnchorPoint = Vector2.new(1, 0)
btnClr.Position = UDim2.new(1, -14, 1, -42)
btnClr.Size = UDim2.new(0.48, -4, 0, 32)
btnClr.BackgroundColor3 = Color3.fromRGB(204, 68, 26)
btnClr.Font = Enum.Font.Oswald
btnClr.Text = "ОЧИСТИТЬ ТОЧКИ"
btnClr.TextColor3 = Color3.fromRGB(255, 222, 189)
btnClr.TextScaled = true
btnClr.Parent = frame
Instance.new("UICorner", btnClr).CornerRadius = UDim.new(0, 6)
btnClr.MouseButton1Click:Connect(function() PathfindLib.ClearNodes(); redraw() end)
redraw()
end
return PathfindLib