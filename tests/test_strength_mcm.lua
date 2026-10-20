-- With the Mod Configuration Menu: the checkbox removes or restores the Strength part, at once and after a profile
-- switch; clients take the host's value. Both bootstrap files run in one Lua state, as on the host.

Harness.Mods[ModuleUUID] = { Info = { ModVersion = { 1, 0, 0, 0 } } }
-- MCM loads first, so this mod gets the MCM table (playbook knowledge\mcm.md).
Harness.InstallMCM({ add_strength_to_jump = false })

local syncs = 0
local jump = {
    TargetRadius = "9",
    AddRangeFromAbility = "Strength,1",
    UseCosts = "Movement:Distance",
    Sync = function() syncs = syncs + 1 end,
}
Harness.Stats.Projectile_Jump = jump

Ext.Require("BootstrapServer.lua")
Ext.Require("BootstrapClient.lua")

local function LogFile(name)
    Harness.RunTimers()
    return Harness.Files["bg3_jumpunbound/" .. name] or ""
end

local function LastSent(kind)
    local sent = Harness.Channels.Strength.Sent
    for i = #sent, 1, -1 do
        if sent[i].Kind == kind then
            return sent[i]
        end
    end
end

Test("the checkbox off removes the Strength part when the stats load", function()
    Ext.Events.StatsLoaded:Fire()
    AssertEq(jump.AddRangeFromAbility, "", "no Strength part")
    AssertEq(syncs, 1, "synced once")
    AssertTrue(string.find(LogFile("client.log"), "Strength part off (local setting).", 1, true), "client.log line")
end)

Test("the session load keeps it and tells the clients", function()
    Ext.Events.SessionLoaded:Fire()
    AssertEq(jump.AddRangeFromAbility, "", "still no Strength part")
    AssertEq(syncs, 1, "no second sync for the same value")
    AssertTrue(string.find(LogFile("server.log"), "Session loaded: Strength part off (MCM).", 1, true), "server.log line")
    AssertEq(LastSent("Broadcast").Data.AddStrength, false, "broadcast")
end)

Test("a change in MCM applies at once", function()
    Harness.FireMCMSettingSaved("add_strength_to_jump", true)
    AssertEq(jump.AddRangeFromAbility, "Strength,1", "Strength part back")
    AssertEq(syncs, 2, "synced")
    AssertTrue(string.find(LogFile("server.log"), "Setting changed: Strength part on (MCM).", 1, true), "server.log line")
    AssertEq(LastSent("Broadcast").Data.AddStrength, true, "broadcast")
end)

Test("other mods and other settings are ignored", function()
    Harness.FireMCMSettingSaved("add_strength_to_jump", false, "00000000-0000-0000-0000-000000000000")
    Harness.FireMCMSettingSaved("some_other_setting", false)
    AssertEq(jump.AddRangeFromAbility, "Strength,1", "unchanged")
    AssertEq(syncs, 2, "no sync")
end)

Test("a profile switch reads the value again", function()
    Harness.MCMValues.add_strength_to_jump = false
    Ext.ModEvents.BG3MCM["MCM_Profile_Activated"]:Fire({ profileName = "Other" })
    AssertEq(jump.AddRangeFromAbility, "", "value of the new profile")
    AssertTrue(string.find(LogFile("server.log"), "MCM profile changed: Strength part off (MCM).", 1, true), "server.log line")
end)

Test("the server answers a request with the value it applied", function()
    AssertEq(Harness.Channels.Strength.RequestHandler({}, 1).AddStrength, false, "reply")
end)

Test("a client applies the host's value from the reply and from broadcasts", function()
    LastSent("RequestToServer").Callback({ AddStrength = true })
    AssertEq(jump.AddRangeFromAbility, "Strength,1", "reply applied")
    Harness.Channels.Strength.MessageHandler({ AddStrength = false })
    AssertEq(jump.AddRangeFromAbility, "", "broadcast applied")
    Harness.Channels.Strength.MessageHandler({ Something = 1 })
    AssertEq(jump.AddRangeFromAbility, "", "a message without a value changes nothing")
    AssertTrue(string.find(LogFile("client.log"), "Strength part off (host).", 1, true), "client.log line")
end)

Test("an MCM error falls back to the default", function()
    local Settings = Ext.Require("Shared/Settings.lua")
    local original = MCM.Get
    MCM.Get = function() error("broken") end
    local value, source = Settings.Get("add_strength_to_jump", true)
    MCM.Get = original
    AssertEq(value, true, "default value")
    AssertEq(source, "default", "source")
end)
