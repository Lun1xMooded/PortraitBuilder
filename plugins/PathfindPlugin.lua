-- plugins/PathfindPlugin.lua
return function(API)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local PathfindLib = API.Import("libs/PathfindLib.lua")
    if not PathfindLib then
        warn("[PathfindPlugin] Ошибка загрузки libs/PathfindLib.lua!")
        return
    end

    API.RegisterService("Pathfind", PathfindLib)

    API.RegisterAction("OpenRoomMap", function()
        getgenv().MemeAllClones = API.GetAllClones()
        local ok, err = pcall(PathfindLib.OpenLayoutMap)
        if not ok then warn("[RoomMap Error]:", err) end
    end)

    API.RegisterAction("AddNodeHere", function()
        local myR = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
        if myR then
            PathfindLib.AddNode(myR.Position - Vector3.new(0, 2.5, 0), PathfindLib.SelectedClone)
        end
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

    API.RegisterSpawnOverride("Pathfind", function()
        local route = PathfindLib.GetRoute(1)
        if #route.Nodes > 0 then
            local sIdx = math.clamp(route.StartNodeIndex or 1, 1, #route.Nodes)
            return CFrame.new(route.Nodes[sIdx] + Vector3.new(0, 3.6, 0))
        end
        return nil
    end)
end
