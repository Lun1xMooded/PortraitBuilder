-- plugins/PathfindPlugin.lua
return function(API)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local PathfindLib = API.Import("libs/PathfindLib.lua")
    if not PathfindLib then
        warn("[PathfindPlugin] Ошибка загрузки libs/PathfindLib.lua!")
        return
    end

    local cursorMode = true         -- true = ставить точку по курсору, false = под игроком
    local crosshairEnabled = false  -- по умолчанию прицел (+) ВЫКЛЮЧЕН!
    local crosshairGui = nil
    local crosshairConn = nil

    local function setCrosshairActive(state)
        crosshairEnabled = state == true
        if crosshairEnabled then
            if not crosshairGui then
                local pgui = LocalPlayer:WaitForChild("PlayerGui")
                local old = pgui:FindFirstChild("MemeActorCrosshair")
                if old then old:Destroy() end

                crosshairGui = Instance.new("ScreenGui")
                crosshairGui.Name = "MemeActorCrosshair"
                crosshairGui.DisplayOrder = 100
                crosshairGui.IgnoreGuiInset = true
                crosshairGui.ResetOnSpawn = false
                crosshairGui.Parent = pgui

                local holder = Instance.new("Frame")
                holder.Name = "PlusHolder"
                holder.AnchorPoint = Vector2.new(0.5, 0.5)
                holder.Size = UDim2.new(0, 22, 0, 22)
                holder.BackgroundTransparency = 1
                holder.Parent = crosshairGui

                local hLine = Instance.new("Frame")
                hLine.AnchorPoint = Vector2.new(0.5, 0.5)
                hLine.Position = UDim2.new(0.5, 0, 0.5, 0)
                hLine.Size = UDim2.new(0, 16, 0, 2)
                hLine.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
                hLine.BorderSizePixel = 0
                hLine.Parent = holder
                local hStroke = Instance.new("UIStroke", hLine)
                hStroke.Color = Color3.new(0, 0, 0)
                hStroke.Thickness = 1

                local vLine = Instance.new("Frame")
                vLine.AnchorPoint = Vector2.new(0.5, 0.5)
                vLine.Position = UDim2.new(0.5, 0, 0.5, 0)
                vLine.Size = UDim2.new(0, 2, 0, 16)
                vLine.BackgroundColor3 = Color3.fromRGB(95, 255, 130)
                vLine.BorderSizePixel = 0
                vLine.Parent = holder
                local vStroke = Instance.new("UIStroke", vLine)
                vStroke.Color = Color3.new(0, 0, 0)
                vStroke.Thickness = 1

                crosshairConn = RunService.RenderStepped:Connect(function()
                    if not crosshairGui or not crosshairGui.Parent then return end
                    local pguiNow = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    local mainMenu = pguiNow and pguiNow:FindFirstChild("MemeActorDoorsAdmin")
                    local menuOpen = mainMenu and mainMenu:FindFirstChild("Container") and mainMenu.Container.Visible

                    -- Если открыто главное меню — временно показываем обычный курсор для удобства
                    if menuOpen then
                        holder.Visible = false
                        UserInputService.MouseIconEnabled = true
                    else
                        holder.Visible = true
                        local mPos = UserInputService:GetMouseLocation()
                        holder.Position = UDim2.new(0, mPos.X, 0, mPos.Y)
                        UserInputService.MouseIconEnabled = false
                    end
                end)
            end
        else
            if crosshairConn then crosshairConn:Disconnect(); crosshairConn = nil end
            if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
            UserInputService.MouseIconEnabled = true
        end
    end

    local function addNodeAtCursor()
        local cam = workspace.CurrentCamera
        if not cam then return false end

        local mPos = UserInputService:GetMouseLocation()
        local ray = cam:ScreenPointToRay(mPos.X, mPos.Y - 36)

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.RespectCanCollide = true
        local ignore = {}
        if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
        for _, entry in ipairs(API.GetAllClones()) do
            if entry.model then table.insert(ignore, entry.model) end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "MemeActorPathMarkers" then table.insert(ignore, obj) end
        end
        rp.FilterDescendantsInstances = ignore

        local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, rp)
        if hit then
            PathfindLib.AddNode(hit.Position, PathfindLib.SelectedClone)
            return true
        end
        return false
    end

    API.RegisterService("Pathfind", PathfindLib)

    API.RegisterAction("OpenRoomMap", function()
        getgenv().MemeAllClones = API.GetAllClones()
        local ok, err = pcall(PathfindLib.OpenLayoutMap)
        if not ok then warn("[RoomMap Error]:", err) end
    end)

    API.RegisterAction("AddNodeHere", function()
        if cursorMode then
            addNodeAtCursor()
        else
            PathfindLib.AddNodeAtPlayer(PathfindLib.SelectedClone)
        end
    end)

    API.RegisterAction("ToggleNodePlaceMode", function()
        cursorMode = not cursorMode
        if getgenv().MemeUpdateAddNodeLabel then
            getgenv().MemeUpdateAddNodeLabel(cursorMode)
        end
        print("[Pathfind] Режим точек:", cursorMode and "ПО КУРСОРУ" or "В ПОЗИЦИИ ИГРОКА")
    end)

    API.RegisterAction("AutoCarpet", function()
        PathfindLib.AutoGenerateFromCarpet(PathfindLib.SelectedClone)
    end)

    API.RegisterAction("ClearNodes", function()
        PathfindLib.ClearNodes(PathfindLib.SelectedClone)
    end)

    API.RegisterState("PathMarkers", function() return PathfindLib.ShowMarkers end, function(v) PathfindLib.SetMarkersVisible(v) end)
    API.RegisterState("PathLoop",    function() return PathfindLib.LoopPath end,    function(v) PathfindLib.LoopPath = v end)
    API.RegisterState("PathSprint",  function() return PathfindLib.SprintPath end,  function(v) PathfindLib.SprintPath = v end)
    API.RegisterState("CursorCrosshair", function() return crosshairEnabled end, function(v)
        setCrosshairActive(v)
    end)

    API.RegisterSpawnOverride("Pathfind", function()
        local route = PathfindLib.GetRoute(1)
        if #route.Nodes > 0 then
            local sIdx = math.clamp(route.StartNodeIndex or 1, 1, #route.Nodes)
            return CFrame.new(route.Nodes[sIdx] + Vector3.new(0, 3.6, 0))
        end
        return nil
    end)

    API.OnCleanup(function()
        setCrosshairActive(false)
    end)
end
