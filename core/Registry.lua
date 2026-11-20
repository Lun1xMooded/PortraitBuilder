-- core/Registry.lua
local Registry = {}

Registry.Plugins = {
    "plugins/CombatPlugin.lua",
    "plugins/FreecamPlugin.lua",
    "plugins/PathfindPlugin.lua",
    "plugins/CutsceneControlPlugin.lua",
    "plugins/ActorModsPlugin.lua",
}

Registry.MenuToggleKeys = {
    Enum.KeyCode.LeftBracket,
    Enum.KeyCode.RightBracket,
    Enum.KeyCode.RightShift,
}

Registry.ActorList = {
    { Id = "PortraitLight", Label = "Portrait Белый (Сток)", Type = "Portrait",      Path = "builders/PortraitBuilder.lua",    Variant = "PortraitLight", IsPortrait = true, RootOffset = 3.65 },
    { Id = "PortraitDark",  Label = "Portrait Чёрный",       Type = "Portrait",      Path = "builders/PortraitBuilder.lua",    Variant = "PortraitDark",  IsPortrait = true, RootOffset = 3.65 },
    { Id = "LocalAvatar",   Label = "Мой аватар (Билдер)",   Type = "CustomBuilder", Path = "builders/LocalAvatarBuilder.lua", Variant = nil,             RootOffset = 3.55 },
}

Registry.ModeModules = {
    { Id = "Locomotion",    Path = "modes/LocomotionMode.lua" },
    { Id = "Statue",        Path = "modes/StatueMode.lua" },
    { Id = "Mirror",        Path = "modes/MirrorMode.lua" },
    { Id = "HardcoreChase", Path = "modes/HardcoreChaseMode.lua" },
    { Id = "Pathfind",      Path = "modes/PathfindMode.lua" },
}

Registry.ModeBindings = {
    { ConfigKey = "StraightMove",  Fallback = Enum.KeyCode.F, ModuleId = "Locomotion",    SubMode = "Straight", AutoSpawn = "Close" },
    { ConfigKey = "Chase",         Fallback = Enum.KeyCode.N, ModuleId = "Locomotion",    SubMode = "Chase",    AutoSpawn = "Far" },
    { ConfigKey = "HardcoreChase", Fallback = Enum.KeyCode.Q, ModuleId = "HardcoreChase", SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Statue",        Fallback = Enum.KeyCode.H, ModuleId = "Statue",        SubMode = nil,        AutoSpawn = "Far" },
    { ConfigKey = "Mirror",        Fallback = Enum.KeyCode.R, ModuleId = "Mirror",        SubMode = nil,        AutoSpawn = "Close" },
}

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

Registry.MenuCategories = {
    {
        Id = "Actor",
        Title = "Актёр",
        Icon = "rbxassetid://113778120734375",
        Items = {
            { Type = "Section", Text = "Спавн и облик (СКМ по кнопке = бинд)" },
            { Type = "Button",  Text = "Заспавнить перед камерой", ButtonText = "SPAWN",      Action = "SpawnFar",    DefaultBind = Enum.KeyCode.Z },
            { Type = "Button",  Text = "Заспавнить в себе",        ButtonText = "SPAWN HERE", Action = "SpawnHere",   DefaultBind = Enum.KeyCode.P },
            { Type = "Button",  Text = "Сменить облик",            ButtonText = "NEXT ACTOR", Action = "SwitchActor", DefaultBind = Enum.KeyCode.G },
            { Type = "Button",  Text = "Развернуть на 180°",       ButtonText = "ROTATE",     Action = "Rotate",      DefaultBind = Enum.KeyCode.B },
            { Type = "Section", Text = "Состояния и эффекты" },
            { Type = "Toggle",  Text = "Режим толпы клонов",       StateKey = "MultiClone", DefaultBind = Enum.KeyCode.U },
            { Type = "Toggle",  Text = "Приседание",               StateKey = "Crouch",     DefaultBind = Enum.KeyCode.T },
            { Type = "Toggle",  Text = "Следить головой 360°",     StateKey = "HeadLook",   DefaultBind = Enum.KeyCode.K },
            { Type = "Toggle",  Text = "Дрожь статуи",             StateKey = "Jitter",     DefaultBind = Enum.KeyCode.Y },
            { Type = "Button",  Text = "Удалить всех клонов",      ButtonText = "CLEAR ALL",  Action = "RemoveAll", DefaultBind = Enum.KeyCode.V, Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "Modes",
        Title = "Режимы",
        Icon = "rbxassetid://91079368272694",
        Items = {
            { Type = "Section", Text = "Поведение и погони (СКМ = бинд)" },
            { Type = "Button",  Text = "Режим Зеркала",         ButtonText = "MIRROR",   ModeId = "Mirror",        AutoSpawn = "Close", DefaultBind = Enum.KeyCode.R },
            { Type = "Button",  Text = "Хардкорная погоня",     ButtonText = "HARDCORE", ModeId = "HardcoreChase", AutoSpawn = "Far",   DefaultBind = Enum.KeyCode.Q, Color = Color3.fromRGB(204, 68, 26) },
            { Type = "Button",  Text = "Обычные догонялки",     ButtonText = "CHASE",    ModeId = "Locomotion",    SubMode = "Chase",    AutoSpawn = "Far",   DefaultBind = Enum.KeyCode.N },
            { Type = "Button",  Text = "Прямой бег / ходьба",   ButtonText = "STRAIGHT", ModeId = "Locomotion",    SubMode = "Straight", AutoSpawn = "Close", DefaultBind = Enum.KeyCode.F },
            { Type = "Button",  Text = "Режим Статуи",          ButtonText = "STATUE",   ModeId = "Statue",        AutoSpawn = "Far",   DefaultBind = Enum.KeyCode.H },
            { Type = "Section", Text = "Бой и взаимодействие" },
            { Type = "Button",  Text = "Удар BoxingGloves",     ButtonText = "PUNCH",    Action = "Punch",         DefaultBind = Enum.KeyCode.O },
        }
    },
    {
        Id = "CameraAndPath",
        Title = "Путь / Камера",
        Icon = "rbxassetid://10099841910",
        Items = {
            { Type = "Section", Text = "Свободная камера и Катсцены" },
            { Type = "Toggle",  Text = "Свободная камера (WASD + QE)",                StateKey = "Freecam" },
            { Type = "Toggle",  Text = "Свобода в катсценах (Камера + Ходьба)",       StateKey = "CutsceneFreedom" },
            { Type = "Section", Text = "PathfindNodes (Планировка и точки)" },
            { Type = "Button",  Text = "Открыть схему комнаты (Carpet / Мебель)",     ButtonText = "ROOM MAP",    Action = "OpenRoomMap" },
            { Type = "Button",  Text = "Поставить точку в моей позиции",              ButtonText = "ADD NODE",    Action = "AddNodeHere" },
            { Type = "Button",  Text = "Авто-маршрут по коврам (Carpet)",             ButtonText = "AUTO CARPET", Action = "AutoCarpet" },
            { Type = "Button",  Text = "Запустить бег клона по точкам",              ButtonText = "START PATH",  ModeId = "Pathfind", AutoSpawn = "Close", DefaultBind = Enum.KeyCode.F1, Color = Color3.fromRGB(76, 154, 204) },
            { Type = "Toggle",  Text = "Показывать 3D-шары точек в комнате",          StateKey = "PathMarkers" },
            { Type = "Toggle",  Text = "Зациклить маршрут (Loop)",                    StateKey = "PathLoop" },
            { Type = "Toggle",  Text = "Бежать по точкам (Sprint)",                   StateKey = "PathSprint" },
            { Type = "Button",  Text = "Очистить все точки маршрута",                 ButtonText = "CLEAR NODES", Action = "ClearNodes", Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "BindsTab",
        Title = "Бинды",
        Icon = "rbxassetid://7059346373",
        Items = {
            { Type = "Section", Text = "Горячие клавиши сцен (ЛКМ или СКМ по любой кнопке)" },
            { Type = "Keybind", Text = "Бег по точкам маршрута",                    BindKey = "KeyPathRun" },
            { Type = "Keybind", Text = "Прямой бег + удар и убийство",              BindKey = "KeyStraightRush" },
            { Type = "Section", Text = "Быстрые действия (СКМ по кнопке = сменить клавишу)" },
            { Type = "Button",  Text = "Заспавнить перед камерой",                  ButtonText = "SPAWN",      Action = "SpawnFar",    DefaultBind = Enum.KeyCode.Z },
            { Type = "Button",  Text = "Заспавнить в себе",                         ButtonText = "SPAWN HERE", Action = "SpawnHere",   DefaultBind = Enum.KeyCode.P },
            { Type = "Button",  Text = "Удар BoxingGloves",                         ButtonText = "PUNCH",      Action = "Punch",       DefaultBind = Enum.KeyCode.O },
            { Type = "Button",  Text = "Удалить всех клонов",                       ButtonText = "CLEAR ALL",  Action = "RemoveAll",   DefaultBind = Enum.KeyCode.V, Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "CustomMods",
        Title = "Кастом",
        Icon = "rbxassetid://113778120734375",
        Items = {
            { Type = "Section", Text = "Глобальные настройки режимов Portrait" },
            { Type = "Toggle",  Text = "Своя скорость во всех режимах",         StateKey = "UseCustomSpeed" },
            { Type = "Slider",  Text = "Значение скорости (studs/s)",           SettingKey = "CustomSpeed",   Min = 5,  Max = 150 },
            { Type = "Toggle",  Text = "Удар и нокаут возле игрока",            StateKey = "AutoKnockout" },
            { Type = "Toggle",  Text = "Убивать при ударе (Kill on Hit)",       StateKey = "KillOnHit" },
            { Type = "Slider",  Text = "Сила удара / нокаута",                  SettingKey = "KnockoutPower", Min = 20, Max = 180 },
            { Type = "Toggle",  Text = "Всегда держать BoxingGloves в руках",   StateKey = "AlwaysGloves" },
            { Type = "Toggle",  Text = "Исчезать после удара (Скример)",        StateKey = "VanishAfterHit" },
        }
    },
}

function Registry.PrintStartupBanner(Config)
print(string.format("[MemeActor v%s] Загружено! [ [ / ] / RShift ] Menu | СКМ по любой кнопке = Бинд", tostring(Config.Version)))
end
return Registry