-- Loader.lua (с принудительным сбросом кэша GitHub и выводом точных ошибок)
local BASE_URL = "https://raw.githubusercontent.com/Lun1xMooded/PortraitBuilder/refs/heads/main/" -- Вставь свою ссылку из старого Loader!

local Cache = {}
local CacheBust = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))

local function Import(path)
    if Cache[path] ~= nil then
        return Cache[path]
    end

    local url = BASE_URL .. path .. "?cb=" .. CacheBust
    local okHttp, body = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not okHttp or not body or body:find("404: Not Found") then
        warn("[MemeActor Loader] Не удалось скачать:", path, url)
        return nil
    end

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

local Config = Import("core/Config.lua") or {
    Version = "2.3",
    WalkSpeed = 14,
    SprintSpeed = 24,
    CrouchSpeed = 8,
    SpawnDistanceFar = 14,
    SpawnDistanceClose = 5,
    JitterIntensity = 4.0,
    Keys = {}
}

local MainEngine = Import("core/MainEngine.lua")
if type(MainEngine) == "function" then
    local okEngine, errEngine = xpcall(function()
        MainEngine(Import, Config)
    end, debug.traceback)
    if not okEngine then
        warn("[MemeActor Loader] Сбой при запуске MainEngine:\n" .. tostring(errEngine))
    end
else
    warn("[MemeActor Loader] core/MainEngine.lua не вернул функцию!")
end
