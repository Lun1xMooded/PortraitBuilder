-- core/Registry.lua
local Registry = {}

Registry.ModeModules = {
    { Id = "Locomotion", Path = "modes/LocomotionMode.lua" },
    { Id = "Statue",     Path = "modes/StatueMode.lua" },
    { Id = "Mirror",     Path = "modes/MirrorMode.lua" },
}

Registry.ModeBindings = {
    { ConfigKey = "StraightMove", Fallback = Enum.KeyCode.F, ModuleId = "Locomotion", SubMode = "Straight", AutoSpawn = "Close" },
    { ConfigKey = "Chase",        Fallback = Enum.KeyCode.N, ModuleId = "Locomotion", SubMode = "Chase",    AutoSpawn = "Far" },
    { ConfigKey = "Statue",       Fallback = Enum.KeyCode.H, ModuleId = "Statue",     SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Mirror",       Fallback = Enum.KeyCode.R, ModuleId = "Mirror",     SubMode = nil,        AutoSpawn = "Close" },
}

Registry.SystemKeys = {
    Spawn        = { ConfigKey = "Spawn",        Fallback = Enum.KeyCode.Z },
    SpawnHere    = { ConfigKey = "SpawnHere",    Fallback = Enum.KeyCode.P },
    SwitchActor  = { ConfigKey = "SwitchActor",  Fallback = Enum.KeyCode.G },
    PaceToggle   = { ConfigKey = "PaceToggle",   Fallback = Enum.KeyCode.L },
    Crouch       = { ConfigKey = "CrouchToggle", Fallback = Enum.KeyCode.T },
    JitterToggle = { ConfigKey = "JitterToggle", Fallback = Enum.KeyCode.Y },
    HeadLook     = { ConfigKey = "HeadLook",     Fallback = Enum.KeyCode.K },
    Rotate       = { ConfigKey = "Rotate",       Fallback = Enum.KeyCode.B },
    Remove       = { ConfigKey = "Remove",       Fallback = Enum.KeyCode.V },
}

function Registry.PrintStartupBanner(Config)
    local keys = Config.Keys or {}
    print(string.format(
        "[MemeActor v%s] Загружено! [%s] Спавн | [%s] Спавн в себе | [%s] Облик | [%s] Присед | [%s] Бег | [%s] Темп | [%s] Догонялки | [%s] Статуя | [%s] Зеркало | [%s] Дрожь | [%s] HeadLook | [%s] Удалить",
        tostring(Config.Version),
        keys.Spawn or "Z",
        keys.SpawnHere or "P",
        keys.SwitchActor or "G",
        keys.CrouchToggle or "T",
        keys.StraightMove or "F",
        keys.PaceToggle or "L",
        keys.Chase or "N",
        keys.Statue or "H",
        keys.Mirror or "R",
        keys.JitterToggle or "Y",
        keys.HeadLook or "K",
        keys.Remove or "V"
    ))
end

return Registry
