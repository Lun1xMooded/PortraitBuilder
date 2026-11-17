-- core/Registry.lua
local Registry = {}

-- 1. Список обликов, переключаемых клавишей [G]
Registry.ActorList = {
    { Id = "PortraitLight", Label = "Portrait Белый (Сток)", Type = "Portrait",      Variant = "PortraitLight" },
    { Id = "PortraitDark",  Label = "Portrait Чёрный",       Type = "Portrait",      Variant = "PortraitDark" },
    { Id = "LocalAvatar",   Label = "Мой аватар (Билдер)",   Type = "CustomBuilder", Path = "builders/LocalAvatarBuilder.lua" },
}

-- 2. Внешние модули режимов из папки modes/
Registry.ModeModules = {
    { Id = "Locomotion",    Path = "modes/LocomotionMode.lua" },
    { Id = "Statue",        Path = "modes/StatueMode.lua" },
    { Id = "Mirror",        Path = "modes/MirrorMode.lua" },
    { Id = "HardcoreChase", Path = "modes/HardcoreChaseMode.lua" },
}

-- 3. Привязка клавиш к режимам
Registry.ModeBindings = {
    { ConfigKey = "StraightMove",  Fallback = Enum.KeyCode.F, ModuleId = "Locomotion",    SubMode = "Straight", AutoSpawn = "Close" },
    { ConfigKey = "Chase",         Fallback = Enum.KeyCode.N, ModuleId = "Locomotion",    SubMode = "Chase",    AutoSpawn = "Far" },
    { ConfigKey = "HardcoreChase", Fallback = Enum.KeyCode.Q, ModuleId = "HardcoreChase", SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Statue",        Fallback = Enum.KeyCode.H, ModuleId = "Statue",        SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Mirror",        Fallback = Enum.KeyCode.R, ModuleId = "Mirror",        SubMode = nil,        AutoSpawn = "Close" },
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
    PunchAction  = { ConfigKey = "PunchAction",  Fallback = Enum.KeyCode.O },
    Remove       = { ConfigKey = "Remove",       Fallback = Enum.KeyCode.V },
}

-- 5. Декларативная структура меню DOORS (открывается на [ или ])
-- Чтобы добавить новую вкладку или кнопку (например, Freecam), просто добавь её сюда!
Registry.MenuCategories = {
    {
        Id = "Actor",
        Title = "Актёр",
        Icon = "rbxassetid://113778120734375",
        Items = {
            { Type = "Section", Text = "Спавн и облик" },
            { Type = "Button",  Text = "Заспавнить перед камерой [Z]", ButtonText = "SPAWN",      Action = "SpawnFar" },
            { Type = "Button",  Text = "Заспавнить в себе [P]",        ButtonText = "SPAWN HERE", Action = "SpawnHere" },
            { Type = "Button",  Text = "Сменить облик [G]",            ButtonText = "NEXT ACTOR", Action = "SwitchActor" },
            { Type = "Button",  Text = "Развернуть на 180° [B]",       ButtonText = "ROTATE",     Action = "Rotate" },
            { Type = "Section", Text = "Состояния и эффекты" },
            { Type = "Toggle",  Text = "Режим толпы клонов [U]",       StateKey = "MultiClone" },
            { Type = "Toggle",  Text = "Приседание [T]",               StateKey = "Crouch" },
            { Type = "Toggle",  Text = "Следить головой 360° [K]",     StateKey = "HeadLook" },
            { Type = "Toggle",  Text = "Дрожь статуи [Y]",             StateKey = "Jitter" },
            { Type = "Button",  Text = "Удалить всех клонов [V]",      ButtonText = "CLEAR ALL",  Action = "RemoveAll", Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "Modes",
        Title = "Режимы",
        Icon = "rbxassetid://91079368272694",
        Items = {
            { Type = "Section", Text = "Поведение и погони" },
            { Type = "Button",  Text = "Режим Зеркала [R]",         ButtonText = "MIRROR",   ModeId = "Mirror",        AutoSpawn = "Close" },
            { Type = "Button",  Text = "Хардкорная погоня [Q]",     ButtonText = "HARDCORE", ModeId = "HardcoreChase", AutoSpawn = "Far", Color = Color3.fromRGB(204, 68, 26) },
            { Type = "Button",  Text = "Обычные догонялки [N]",     ButtonText = "CHASE",    ModeId = "Locomotion",    SubMode = "Chase",    AutoSpawn = "Far" },
            { Type = "Button",  Text = "Прямой бег / ходьба [F]",   ButtonText = "STRAIGHT", ModeId = "Locomotion",    SubMode = "Straight", AutoSpawn = "Close" },
            { Type = "Button",  Text = "Режим Статуи [H]",          ButtonText = "STATUE",   ModeId = "Statue",        AutoSpawn = "Far" },
            { Type = "Section", Text = "Бой и взаимодействие" },
            { Type = "Button",  Text = "Удар BoxingGloves [O]",     ButtonText = "PUNCH",    Action = "Punch" },
        }
    },
}

function Registry.PrintStartupBanner(Config)
    local keys = Config.Keys or {}
    print(string.format(
        "[MemeActor v%s] Загружено! [ [ / ] ] Меню | [%s] Спавн | [%s] В себе | [%s] Толпа | [%s] Облик | [%s] Хардкор-погоня | [%s] Зеркало | [%s] Удар | [%s] Удалить",
        tostring(Config.Version),
        keys.Spawn or "Z",
        keys.SpawnHere or "P",
        keys.MultiToggle or "U",
        keys.SwitchActor or "G",
        keys.HardcoreChase or "Q",
        keys.Mirror or "R",
        keys.PunchAction or "O",
        keys.Remove or "V"
    ))
end

return Registry
