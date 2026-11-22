-- core/KeybindStorage.lua
local HttpService = game:GetService("HttpService")
local FOLDER = "PortraitBuilder"
local FILE = FOLDER .. "/keybinds.json"

local KeybindStorage = {}

function KeybindStorage.Save(keyMap)
    if type(writefile) ~= "function" then return false end
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(FOLDER) then
            makefolder(FOLDER)
        end
        local serialized = {}
        for action, keyCode in pairs(keyMap) do
            if typeof(keyCode) == "EnumItem" then
                serialized[action] = keyCode.Name
            elseif type(keyCode) == "string" then
                serialized[action] = keyCode
            end
        end
        writefile(FILE, HttpService:JSONEncode(serialized))
    end)
    return true
end

function KeybindStorage.Load(defaultKeyMap)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return defaultKeyMap end
    if not isfile(FILE) then return defaultKeyMap end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(FILE))
    end)
    if ok and type(data) == "table" then
        for action, keyName in pairs(data) do
            if keyName == "NONE" then
                defaultKeyMap[action] = "NONE"
            elseif Enum.KeyCode[keyName] then
                defaultKeyMap[action] = Enum.KeyCode[keyName]
            elseif Enum.UserInputType[keyName] then
                defaultKeyMap[action] = Enum.UserInputType[keyName]
            end
        end
    end
    return defaultKeyMap
end

return KeybindStorage
