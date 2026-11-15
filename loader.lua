-- loader.lua (Точка входа в репозиторий MemeActor)
local REPO_BASE = "https://githubusercontent.com"

local function Import(path)
    local url = REPO_BASE .. path .. "?t=" .. tostring(os.time())
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not source or source == "" then
        warn("[MemeActor Loader] Ошибка скачивания модуля: " .. path)
        return nil
    end
    local fn, err = loadstring(source)
    if not fn then
        warn("[MemeActor Loader] Синтаксическая ошибка в " .. path .. ": " .. tostring(err))
        return nil
    end
    return fn()
end

local ConfigManager = Import("core/ConfigManager.lua")
local MainEngine    = Import("core/MainEngine.lua")

if ConfigManager and MainEngine then
    local cfg = ConfigManager.Load()
    MainEngine(Import, cfg)
end