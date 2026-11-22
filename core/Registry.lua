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
    { Id = "Honcho",        Label = "Honcho (Процедурный)",  Type = "CustomBuilder", Path = "builders/HonchoBuilder.lua",      Variant = nil,             RootOffset = 6.35 },
	{ Id = "Figus",         Label = "Figus (Figure)",        Type = "CustomBuilder", Path = "builders/FigusBuilder.lua",       Variant = nil,             RootOffset = 6.45 },
}

Registry.ModeModules = {
    { Id = "Locomotion",    Path = "modes/LocomotionMode.lua" },
    { Id = "Statue",        Path = "modes/StatueMode.lua" },
    { Id = "Mirror",        Path = "modes/MirrorMode.lua" },
    { Id = "HardcoreChase", Path = "modes/HardcoreChaseMode.lua" },
    { Id = "Pathfind",      Path = "modes/PathfindMode.lua" },
}

Registry.ModeBindings = {}
Registry.SystemKeys = {}

Registry.MenuCategories = {
    {
        Id = "Actor",
        Title = "Актёр",
        Icon = "rbxassetid://113778120734375",
        Items = {
            { Type = "Section", Text = "Спавн и облик (СКМ по кнопке = быстрый бинд)" },
            { Type = "Button",  Text = "Заспавнить перед камерой", ButtonText = "SPAWN",      Action = "SpawnFar",    SyncId = "SpawnFar",    DefaultBind = Enum.KeyCode.Z },
            { Type = "Button",  Text = "Заспавнить в себе",        ButtonText = "SPAWN HERE", Action = "SpawnHere",   SyncId = "SpawnHere",   DefaultBind = Enum.KeyCode.P },
            { Type = "Button",  Text = "Сменить облик",            ButtonText = "NEXT ACTOR", Action = "SwitchActor", SyncId = "SwitchActor", DefaultBind = Enum.KeyCode.G },
            { Type = "Button",  Text = "Развернуть на 180°",       ButtonText = "ROTATE",     Action = "Rotate",      SyncId = "Rotate",      DefaultBind = Enum.KeyCode.B },
            { Type = "Section", Text = "Состояния и эффекты" },
            { Type = "Toggle",  Text = "Режим толпы клонов",       StateKey = "MultiClone", SyncId = "MultiClone", DefaultBind = Enum.KeyCode.U },
            { Type = "Toggle",  Text = "Приседание",               StateKey = "Crouch",     SyncId = "Crouch",     DefaultBind = Enum.KeyCode.T },
            { Type = "Toggle",  Text = "Следить головой 360°",     StateKey = "HeadLook",   SyncId = "HeadLook",   DefaultBind = Enum.KeyCode.K },
            { Type = "Toggle",  Text = "Дрожь статуи",             StateKey = "Jitter",     SyncId = "Jitter",     DefaultBind = Enum.KeyCode.Y },
            { Type = "Button",  Text = "Удалить всех клонов",      ButtonText = "CLEAR ALL",  Action = "RemoveAll",   SyncId = "RemoveAll",   DefaultBind = Enum.KeyCode.V, Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "Modes",
        Title = "Режимы",
        Icon = "rbxassetid://91079368272694",
        Items = {
            { Type = "Section", Text = "Поведение и погони (СКМ = быстрый бинд)" },
            { Type = "Button",  Text = "Режим Зеркала",         ButtonText = "MIRROR",   ModeId = "Mirror",        AutoSpawn = "Close", SyncId = "Mirror_nil",           DefaultBind = Enum.KeyCode.R },
            { Type = "Button",  Text = "Хардкорная погоня",     ButtonText = "HARDCORE", ModeId = "HardcoreChase", AutoSpawn = "Far",   SyncId = "HardcoreChase_nil",    DefaultBind = Enum.KeyCode.Q, Color = Color3.fromRGB(204, 68, 26) },
            { Type = "Button",  Text = "Обычные догонялки",     ButtonText = "CHASE",    ModeId = "Locomotion",    SubMode = "Chase",    AutoSpawn = "Far",   SyncId = "Locomotion_Chase",    DefaultBind = Enum.KeyCode.N },
            { Type = "Button",  Text = "Прямой бег / ходьба",   ButtonText = "STRAIGHT", ModeId = "Locomotion",    SubMode = "Straight", AutoSpawn = "Close", SyncId = "Locomotion_Straight", DefaultBind = Enum.KeyCode.F },
            { Type = "Button",  Text = "Режим Статуи",          ButtonText = "STATUE",   ModeId = "Statue",        AutoSpawn = "Far",   SyncId = "Statue_nil",           DefaultBind = Enum.KeyCode.H },
            { Type = "Section", Text = "Бой и взаимодействие" },
            { Type = "Button",  Text = "Удар BoxingGloves",     ButtonText = "PUNCH",    Action = "Punch",         SyncId = "Punch", DefaultBind = Enum.KeyCode.O },
        }
    },
    {
        Id = "CameraAndPath",
        Title = "Путь / Камера",
        Icon = "rbxassetid://10099841910",
        Items = {
            { Type = "Section", Text = "Свободная камера и Катсцены" },
            { Type = "Toggle",  Text = "Свободная камера (WASD + QE)",                StateKey = "Freecam",         SyncId = "Freecam" },
            { Type = "Toggle",  Text = "Свобода в катсценах (Камера + Ходьба)",       StateKey = "CutsceneFreedom", SyncId = "CutsceneFreedom" },
            { Type = "Section", Text = "PathfindNodes (Планировка и точки)" },
            { Type = "Button",  Text = "Открыть схему комнаты (Carpet / Мебель)",     ButtonText = "ROOM MAP",    Action = "OpenRoomMap", SyncId = "OpenRoomMap" },
            { Type = "Button",  Text = "Поставить точку: КУРСОР (+) [ПКМ]",           ButtonText = "ADD NODE",    Action = "AddNodeHere", RightClickAction = "ToggleNodePlaceMode", SyncId = "AddNodeHere", DefaultBind = nil },
            { Type = "Toggle",  Text = "Прицел-плюсик (+) для точек",                 StateKey = "CursorCrosshair", SyncId = "CursorCrosshair" },
            { Type = "Button",  Text = "Авто-маршрут по коврам (Carpet)",             ButtonText = "AUTO CARPET", Action = "AutoCarpet",  SyncId = "AutoCarpet" },
            { Type = "Button",  Text = "Запустить бег клона по точкам",              ButtonText = "START PATH",  ModeId = "Pathfind", AutoSpawn = "Close", SyncId = "Pathfind_nil", DefaultBind = Enum.KeyCode.F1, Color = Color3.fromRGB(76, 154, 204) },
            { Type = "Toggle",  Text = "Показывать 3D-шары точек в комнате",          StateKey = "PathMarkers" },
            { Type = "Toggle",  Text = "Зациклить маршрут (Loop)",                    StateKey = "PathLoop" },
            { Type = "Toggle",  Text = "Бежать по точкам (Sprint)",                   StateKey = "PathSprint" },
            { Type = "Button",  Text = "Очистить все точки маршрута",                 ButtonText = "CLEAR NODES", Action = "ClearNodes", Color = Color3.fromRGB(204, 68, 26) },
        }
    },
    {
        Id = "CustomMods",
        Title = "Кастом",
        Icon = "rbxassetid://113778120734375",
        Items = {
            { Type = "Section", Text = "Готовые сценарии Portrait" },
            { Type = "Button",  Text = "Запустить бег по точкам маршрута",          ButtonText = "RUN PATH",      ModeId = "Pathfind",    AutoSpawn = "Close", SyncId = "Pathfind_nil", DefaultBind = Enum.KeyCode.F1, Color = Color3.fromRGB(76, 154, 204) },
            { Type = "Button",  Text = "Прямой бег + удар и убийство",              ButtonText = "STRAIGHT RUSH", Action = "StraightRush",                     SyncId = "StraightRush", DefaultBind = Enum.KeyCode.F2, Color = Color3.fromRGB(204, 68, 26) },
            { Type = "Section", Text = "Глобальные настройки режимов Portrait" },
            { Type = "Toggle",  Text = "Своя скорость во всех режимах",             StateKey = "UseCustomSpeed", SyncId = "UseCustomSpeed" },
            { Type = "Slider",  Text = "Значение скорости (studs/s)",               SettingKey = "CustomSpeed",   Min = 5,  Max = 150 },
            { Type = "Toggle",  Text = "Удар и нокаут возле игрока",                StateKey = "AutoKnockout",   SyncId = "AutoKnockout" },
            { Type = "Toggle",  Text = "Убивать при ударе (Kill on Hit)",           StateKey = "KillOnHit",      SyncId = "KillOnHit" },
            { Type = "Slider",  Text = "Сила удара / нокаута",                      SettingKey = "KnockoutPower", Min = 20, Max = 180 },
            { Type = "Toggle",  Text = "Всегда держать BoxingGloves в руках",       StateKey = "AlwaysGloves",   SyncId = "AlwaysGloves" },
            { Type = "Toggle",  Text = "Опустить предметы (без анимации)",          StateKey = "LowerTools",     SyncId = "LowerTools" },
            { Type = "Toggle",  Text = "Исчезать после удара (Скример)",            StateKey = "VanishAfterHit", SyncId = "VanishAfterHit" },
        }
    },
    {
        Id = "BindsTab",
        Title = "Бинды",
        Icon = "rbxassetid://7059346373",
        Items = {
            { Type = "Section", Text = "Управление актёром (Нажми ЛКМ или СКМ для смены)" },
            { Type = "Keybind", Text = "Заспавнить перед камерой",      SyncId = "SpawnFar",    DefaultBind = Enum.KeyCode.Z },
            { Type = "Keybind", Text = "Заспавнить в себе",             SyncId = "SpawnHere",   DefaultBind = Enum.KeyCode.P },
            { Type = "Keybind", Text = "Сменить облик",                 SyncId = "SwitchActor", DefaultBind = Enum.KeyCode.G },
            { Type = "Keybind", Text = "Развернуть на 180°",            SyncId = "Rotate",      DefaultBind = Enum.KeyCode.B },
            { Type = "Keybind", Text = "Режим толпы клонов",            SyncId = "MultiClone",  DefaultBind = Enum.KeyCode.U },
            { Type = "Keybind", Text = "Приседание",                    SyncId = "Crouch",      DefaultBind = Enum.KeyCode.T },
            { Type = "Keybind", Text = "Следить головой 360°",          SyncId = "HeadLook",    DefaultBind = Enum.KeyCode.K },
{ Type = "Keybind", Text = "Дрожь статуи",                  SyncId = "Jitter",      DefaultBind = Enum.KeyCode.Y },
{ Type = "Keybind", Text = "Удалить всех клонов",           SyncId = "RemoveAll",   DefaultBind = Enum.KeyCode.V },
{ Type = "Section", Text = "Режимы и бой" },
{ Type = "Keybind", Text = "Режим Зеркала",                 SyncId = "Mirror_nil",           DefaultBind = Enum.KeyCode.R },
{ Type = "Keybind", Text = "Хардкорная погоня",             SyncId = "HardcoreChase_nil",    DefaultBind = Enum.KeyCode.Q },
{ Type = "Keybind", Text = "Обычные догонялки",             SyncId = "Locomotion_Chase",    DefaultBind = Enum.KeyCode.N },
{ Type = "Keybind", Text = "Прямой бег / ходьба",           SyncId = "Locomotion_Straight", DefaultBind = Enum.KeyCode.F },
{ Type = "Keybind", Text = "Режим Статуи",                  SyncId = "Statue_nil",           DefaultBind = Enum.KeyCode.H },
{ Type = "Keybind", Text = "Удар BoxingGloves",             SyncId = "Punch",                DefaultBind = Enum.KeyCode.O },
{ Type = "Section", Text = "Кастомные сценарии и камера" },
{ Type = "Keybind", Text = "Поставить точку маршрута",      SyncId = "AddNodeHere",     DefaultBind = nil },
{ Type = "Keybind", Text = "Бег по точкам маршрута",        SyncId = "Pathfind_nil",    DefaultBind = Enum.KeyCode.F1 },
{ Type = "Keybind", Text = "Прямой бег + удар и убийство",  SyncId = "StraightRush",    DefaultBind = Enum.KeyCode.F2 },
{ Type = "Keybind", Text = "Опустить / Поднять предмет",    SyncId = "LowerTools",      DefaultBind = nil },
{ Type = "Keybind", Text = "Свободная камера (Freecam)",    SyncId = "Freecam",         DefaultBind = nil },
{ Type = "Keybind", Text = "Свобода в катсценах",           SyncId = "CutsceneFreedom", DefaultBind = nil },
}
},
}
function Registry.PrintStartupBanner(Config)
print(string.format("[MemeActor v%s] Загружено! [ [ / ] / RShift ] Menu | СКМ по кнопке = Бинд", tostring(Config.Version)))
end
return Registry