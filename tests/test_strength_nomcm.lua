-- Without the Mod Configuration Menu: the default keeps the Strength part, and nothing fails.
-- Both bootstrap files run in one Lua state, as on the host, where client and server share the spell stats.

Harness.Mods[ModuleUUID] = { Info = { ModVersion = { 1, 0, 0, 0 } } }

local syncs = 0
local function NewJump()
    return {
        TargetRadius = "9",
        AddRangeFromAbility = "Strength,1",
        UseCosts = "Movement:Distance",
        Sync = function() syncs = syncs + 1 end,
    }
end
Harness.Stats.Projectile_Jump = NewJump()

Ext.Require("BootstrapServer.lua")
Ext.Require("BootstrapClient.lua")

local function ServerLog()
    Harness.RunTimers()
    return Harness.Files["bg3_jumpunbound/server.log"] or ""
end

local function SentOfKind(kind)
    local found = {}
    for _, message in ipairs(Harness.Channels.Strength.Sent) do
        if message.Kind == kind then
            found[#found + 1] = message
        end
    end
    return found
end

Test("without MCM the default keeps the Strength part", function()
    AssertEq(MCM, nil, "no MCM table")
    Ext.Events.StatsLoaded:Fire()
    Ext.Events.SessionLoaded:Fire()
    AssertEq(Harness.Stats.Projectile_Jump.AddRangeFromAbility, "Strength,1", "Strength part")
    AssertEq(syncs, 0, "nothing to sync")
    AssertTrue(string.find(ServerLog(), "Session loaded: Strength part on (default). Projectile_Jump: TargetRadius 9, "
        .. 'AddRangeFromAbility "Strength,1", UseCosts "Movement:Distance"', 1, true), "server.log line")
    AssertEq(SentOfKind("Broadcast")[1].Data.AddStrength, true, "the server tells the clients")
    AssertEq(#SentOfKind("RequestToServer"), 1, "the client asks the server")
end)

Test("the server answers a request with its value", function()
    AssertEq(Harness.Channels.Strength.RequestHandler({}, 1).AddStrength, true, "reply")
end)

Test("the console command prints the jump stats", function()
    Harness.ConsoleCommands.jumpunbound("jumpunbound")
    AssertTrue(Harness.OutputContains('[JumpUnbound] Status: Projectile_Jump: TargetRadius 9, AddRangeFromAbility "Strength,1"'),
        "console line")
end)

Test("a missing jump spell is logged, not an error", function()
    Harness.Stats.Projectile_Jump = nil
    Ext.Events.SessionLoaded:Fire()
    AssertTrue(string.find(ServerLog(), "but Projectile_Jump was not found.", 1, true), "server.log line")
    Harness.Stats.Projectile_Jump = NewJump()
end)
