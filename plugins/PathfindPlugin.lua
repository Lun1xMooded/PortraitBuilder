-- plugins/PathfindPlugin.lua
return function(API)
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local PathfindLib = API.Import("libs/PathfindLib.lua")
    if not PathfindLib then return end

    API.RegisterService("Pathfind", PathfindLib)

    API.RegisterAction("OpenRoomMap", function() PathfindLib.OpenLayoutMap() end)
    API.RegisterAction("AddNodeHere", function()
        local myR = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("CollisionPart") or LocalPlayer.Character.PrimaryPart)
        if myR then PathfindLib.AddNode(myR.Position - Vector3.new(0, 2.5, 0)) end
    end)
    API.RegisterAction("AutoCarpet", function() PathfindLib.AutoGenerateFromCarpet() end)
    API.RegisterAction("ClearNodes", function() PathfindLib.ClearNodes() end)

    API.RegisterState("PathMarkers", function() return PathfindLib.ShowMarkers end, function(v) PathfindLib.SetMarkersVisible(v) end)
    API.RegisterState("PathLoop",    function() return PathfindLib.LoopPath end,    function(v) PathfindLib.LoopPath = v end)
    API.RegisterState("PathSprint",  function() return PathfindLib.SprintPath end,  function(v) PathfindLib.SprintPath = v end)

    API.RegisterSpawnOverride("Pathfind", function()
        if #PathfindLib.Nodes > 0 then
            local sIdx = math.clamp(PathfindLib.StartNodeIndex or 1, 1, #PathfindLib.Nodes)
            return CFrame.new(PathfindLib.Nodes[sIdx] + Vector3.new(0, 3.6, 0))
        end
        return nil
    end)
end