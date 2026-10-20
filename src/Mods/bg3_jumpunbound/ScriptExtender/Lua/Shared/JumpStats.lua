-- The Strength part of the jump range: AddRangeFromAbility of Projectile_Jump is "Strength,1" (the game's value) or
-- "" (no Strength part).
--
-- A change at run time reaches only this game process: Sync() refreshes the spell here, sends nothing to other
-- players and saves nothing. So the server and every client apply it themselves, again in every session.

local Common = Ext.Require("Shared/Common.lua")

local JumpStats = {}

local function Text(value)
    if type(value) == "string" or type(value) == "number" then
        return tostring(value)
    end
    return type(value)
end

--- Sets the Strength part. Returns true when the value changed, false when it was already set, nil when the
--- jump spell does not exist.
function JumpStats.Apply(addStrength)
    local spell = Ext.Stats.Get(Common.JumpSpell)
    if spell == nil then
        return nil
    end
    local wanted = addStrength and Common.StrengthPart or ""
    if spell.AddRangeFromAbility == wanted then
        return false
    end
    spell.AddRangeFromAbility = wanted
    spell:Sync()
    return true
end

--- Describes the jump stats for the logs, for example 'TargetRadius 9, AddRangeFromAbility "Strength,1", ...'.
function JumpStats.Describe()
    local spell = Ext.Stats.Get(Common.JumpSpell)
    if spell == nil then
        return Common.JumpSpell .. " not found"
    end
    return string.format('%s: TargetRadius %s, AddRangeFromAbility "%s", UseCosts "%s"', Common.JumpSpell,
        Text(spell.TargetRadius), Text(spell.AddRangeFromAbility), Text(spell.UseCosts))
end

return JumpStats
