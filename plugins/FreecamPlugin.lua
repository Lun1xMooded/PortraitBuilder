-- plugins/FreecamPlugin.lua
return function(API)
    local FreecamLib = API.Import("libs/FreecamLib.lua")
    if not FreecamLib then return end

    API.RegisterState("Freecam",
        function() return FreecamLib.Enabled end,
        function(v) FreecamLib.SetEnabled(v) end
    )

    API.OnCleanup(function()
        FreecamLib.SetEnabled(false)
    end)
end
