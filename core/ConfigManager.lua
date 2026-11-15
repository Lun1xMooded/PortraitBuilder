-- core/ConfigManager.lua
local HttpService = game:GetService("HttpService")

local ConfigManager = {}
local VERSION = "0.7"
local FOLDER_NAME = "MemeActor"
local FILE_PATH = FOLDER_NAME .. "/config_v" .. VERSION .. ".json"

local DEFAULT_CONFIG = {
    Version = VERSION,
    TargetPlayerName = "",
    SpawnDistanceFar = 15,
    SpawnDistanceClose = 10,
    CrouchSpeed = 10,
    WalkSpeed = 14,
    SprintSpeed = 21,
    ChaseStopDistance = 10,
    ChaseAcceleration = 34,
    ChaseFriction = 7.5,
    MaxStepHeight = 2.5,
    JitterIntensity = 4.0,
    Keys = {
        Spawn = "Z",
        SpawnHere = "P",
        MultiToggle = "U",
        SwitchActor = "G",
        StraightMove = "F",
        PaceToggle = "L",
        CrouchToggle = "T",
        Chase = "N",
        HardcoreChase = "Q",
        Statue = "H",
        Mirror = "R",
        JitterToggle = "Y",
        HeadLook = "K",
        Rotate = "B",
        PunchAction = "O", -- Ручной удар BoxingGloves у клона
        Remove = "V",
    }
}

function ConfigManager.Load()
    if not isfolder or not makefolder or not writefile or not readfile or not isfile then
        return DEFAULT_CONFIG
    end

    if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end

    if not isfile(FILE_PATH) then
        writefile(FILE_PATH, HttpService:JSONEncode(DEFAULT_CONFIG))
        print("[MemeActor] Создан новый конфиг версии v" .. VERSION .. " -> " .. FILE_PATH)
        return DEFAULT_CONFIG
    end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(FILE_PATH)) end)
    if ok and type(decoded) == "table" and decoded.Version == VERSION then
        for k, v in pairs(DEFAULT_CONFIG) do if decoded[k] == nil then decoded[k] = v end end
        for k, v in pairs(DEFAULT_CONFIG.Keys) do if decoded.Keys[k] == nil then decoded.Keys[k] = v end end
        return decoded
    else
        writefile(FILE_PATH, HttpService:JSONEncode(DEFAULT_CONFIG))
        return DEFAULT_CONFIG
    end
end

return ConfigManager
