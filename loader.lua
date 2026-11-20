-- Loader.lua для Lun1xMooded/PortraitBuilder
local BASE_URL = "https://raw.githubusercontent.com/Lun1xMooded/PortraitBuilder/refs/heads/main/"

local Cache = {}
local cb = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))

local function Import(path)
    if Cache[path] ~= nil then return Cache[path] end
    local okHttp, body = pcall(function() return game:HttpGet(BASE_URL .. path .. "?cb=" .. cb, true) end)
    if not okHttp or not body or body:find("404: Not Found") then return nil end

    local fn, synErr = loadstring(body, "@" .. path)
    if not fn then
        warn("[MemeActor Loader] Синтаксическая ошибка в", path, "->", synErr)
        return nil
    end

    local okRun, res = xpcall(fn, debug.traceback)
    if not okRun then
        warn("[MemeActor Loader] Ошибка выполнения", path, "->\n" .. tostring(res))
        return nil
    end

    Cache[path] = res
    return res
end

local Config = Import("Config.lua") or {
    Version = "3.1", WalkSpeed = 14, SprintSpeed = 24, CrouchSpeed = 8,
    SpawnDistanceFar = 14, SpawnDistanceClose = 5, JitterIntensity = 4.0, Keys = {}
}

local MainEngine = Import("core/MainEngine.lua")
if type(MainEngine) == "function" then
    MainEngine(Import, Config)
end