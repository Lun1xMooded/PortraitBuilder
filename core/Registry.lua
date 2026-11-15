-- core/Registry.lua
local Registry = {}

-- 1. Список обликов, переключаемых клавишей [G] (все собираются через чистые билдеры с GitHub!)
Registry.ActorList = {
    { Id = "PortraitLight", Label = "Portrait Белый (Сток)", Type = "Portrait",      Variant = "PortraitLight" },
    { Id = "PortraitDark",  Label = "Portrait Чёрный",       Type = "Portrait",      Variant = "PortraitDark" },
    { Id = "LocalAvatar",   Label = "Мой аватар (Билдер)",   Type = "CustomBuilder", Path = "builders/LocalAvatarBuilder.lua" },
}

-- 2. Внешние модули режимов из папки modes/
Registry.ModeModules = {
    { Id = "Locomotion", Path = "modes/LocomotionMode.lua" },
    { Id = "Statue",     Path = "modes/StatueMode.lua" },
    { Id = "Mirror",     Path = "modes/MirrorMode.lua" },
}

-- 3. Привязка клавиш к режимам
Registry.ModeBindings = {
    { ConfigKey = "StraightMove", Fallback = Enum.KeyCode.F, ModuleId = "Locomotion", SubMode = "Straight", AutoSpawn = "Close" },
    { ConfigKey = "Chase",        Fallback = Enum.KeyCode.N, ModuleId = "Locomotion", SubMode = "Chase",    AutoSpawn = "Far" },
    { ConfigKey = "Statue",       Fallback = Enum.KeyCode.H, ModuleId = "Statue",     SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Mirror",       Fallback = Enum.KeyCode.R, ModuleId = "Mirror",     SubMode = nil,        AutoSpawn = "Close" },
}

-- 4. Системные клавиши ядра
Registry.SystemKeys = {
    Spawn        = { ConfigKey = "Spawn",        Fallback = Enum.KeyCode.Z },
    SpawnHere    = { ConfigKey = "SpawnHere",    Fallback = Enum.KeyCode.P },
    MultiToggle  = { ConfigKey = "MultiToggle",  Fallback = Enum.KeyCode.U },
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
        "[MemeActor v%s] Загружено! [%s] Спавн | [%s] Спавн в себе | [%s] Толпа клонов | [%s] Облик | [%s] Присед | [%s] Зеркало | [%s] Дрожь | [%s] HeadLook | [%s] Удалить всех",
        tostring(Config.Version),
        keys.Spawn or "Z",
        keys.SpawnHere or "P",
        keys.MultiToggle or "U",
        keys.SwitchActor or "G",
        keys.CrouchToggle or "T",
        keys.Mirror or "R",
        keys.JitterToggle or "Y",
        keys.HeadLook or "K",
        keys.Remove or "V"
    ))
end

return Registry
