local Common = Ext.Require("Shared/Common.lua")
local ServerLog = Ext.Require("Server/ServerLog.lua")

Ext.Events.SessionLoaded:Subscribe(function()
    ServerLog.Add("Jump Unbound " .. Common.ModVersion() .. " loaded.")
end)

local StrengthServer = Ext.Require("Server/StrengthServer.lua")
StrengthServer.Init()
