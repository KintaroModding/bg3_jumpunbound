local Common = Ext.Require("Shared/Common.lua")
local ClientLog = Ext.Require("Client/ClientLog.lua")

Ext.Events.SessionLoaded:Subscribe(function()
    ClientLog.Add("Jump Unbound " .. Common.ModVersion() .. " loaded.")
end)

local StrengthClient = Ext.Require("Client/StrengthClient.lua")
StrengthClient.Init()
