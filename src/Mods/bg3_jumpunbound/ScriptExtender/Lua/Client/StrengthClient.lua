-- Applies the host's choice in this game process. In multiplayer every player's game has its own copy of the spell
-- stats, so each client sets the Strength part itself, with the value that the server sends.

local Common = Ext.Require("Shared/Common.lua")
local JumpStats = Ext.Require("Shared/JumpStats.lua")
local Settings = Ext.Require("Shared/Settings.lua")
local events = Ext.Require("Client/ClientLog.lua")

local StrengthClient = {}

local function Apply(value, source)
    value = value and true or false
    local changed = JumpStats.Apply(value)
    if changed == nil then
        events.Add(string.format("Strength part %s (%s), but %s was not found.", value and "on" or "off", source,
            Common.JumpSpell))
    elseif changed then
        events.Add(string.format("Strength part %s (%s).", value and "on" or "off", source))
    end
end

local function FromServer(data)
    if type(data) == "table" and data.AddStrength ~= nil then
        Apply(data.AddStrength, "host")
    end
end

function StrengthClient.Init()
    -- A first value from the local MCM settings; the host's value follows when the session is loaded.
    Ext.Events.StatsLoaded:Subscribe(function()
        Apply((Settings.Get(Common.SettingId, Common.DefaultAddStrength)), "local setting")
    end)

    Ext.Events.SessionLoaded:Subscribe(function()
        Common.Channels.Strength:RequestToServer({}, FromServer)
    end)

    Common.Channels.Strength:SetHandler(FromServer)
end

return StrengthClient
