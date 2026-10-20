-- Values and helpers shared by the server and client contexts.

local Common = {}

--- Returns the version of this mod from its meta.lsx, for example "1.0.0.0".
function Common.ModVersion()
    local ok, version = pcall(function() return Ext.Mod.GetMod(ModuleUUID).Info.ModVersion end)
    if not ok or version == nil then
        return "?"
    end
    return table.concat({ tostring(version[1]), tostring(version[2]), tostring(version[3]), tostring(version[4]) }, ".")
end

-- The jump of the player characters. The stats file of this mod (Public/bg3_jumpunbound/Stats) sets its base range
-- to 9 m and its cost to the movement used; this script sets only the Strength part.
Common.JumpSpell = "Projectile_Jump"
-- AddRangeFromAbility of the base game: 1 m per point of Strength modifier on top of TargetRadius.
Common.StrengthPart = "Strength,1"

-- The checkbox in MCM_blueprint.json. Do not rename it: MCM stores the player's value under this id.
Common.SettingId = "add_strength_to_jump"
Common.DefaultAddStrength = true

Common.MCMModuleUUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"

Common.Channels = {
    -- Server -> client: { AddStrength = bool } after a change. Client -> server request: the current value.
    Strength = Ext.Net.CreateChannel(ModuleUUID, "Strength"),
}

return Common
