-- The host decides whether Strength adds to the jump distance. The server applies the setting and tells the
-- clients: when a session loads, when a client asks, and when the player changes the setting in MCM.

local Common = Ext.Require("Shared/Common.lua")
local JumpStats = Ext.Require("Shared/JumpStats.lua")
local Settings = Ext.Require("Shared/Settings.lua")
local events = Ext.Require("Server/ServerLog.lua")

local StrengthServer = {}

-- The value the server applied last; nil before the first session.
local current = nil

--- Prints a message to the Script Extender console and adds it to server.log.
local function Log(message)
    _P("[JumpUnbound] " .. message)
    events.Add(message)
end

local function ReadSetting()
    local value, source = Settings.Get(Common.SettingId, Common.DefaultAddStrength)
    return value and true or false, source
end

local function Update(reason)
    local value, source = ReadSetting()
    local changed = JumpStats.Apply(value)
    current = value
    Common.Channels.Strength:Broadcast({ AddStrength = value })
    if changed == nil then
        Log(string.format("%s: Strength part %s (%s), but %s was not found.", reason, value and "on" or "off", source,
            Common.JumpSpell))
    else
        Log(string.format("%s: Strength part %s (%s). %s", reason, value and "on" or "off", source, JumpStats.Describe()))
    end
end

function StrengthServer.Init()
    Ext.Events.SessionLoaded:Subscribe(function()
        Update("Session loaded")
    end)

    Settings.OnChange(function(settingId)
        if settingId == nil then
            Update("MCM profile changed")
        elseif settingId == Common.SettingId then
            Update("Setting changed")
        end
    end)

    Common.Channels.Strength:SetRequestHandler(function()
        if current == nil then
            current = ReadSetting()
        end
        return { AddStrength = current }
    end)

    Ext.RegisterConsoleCommand("jumpunbound", function()
        Log("Status: " .. JumpStats.Describe())
    end)
end

return StrengthServer
