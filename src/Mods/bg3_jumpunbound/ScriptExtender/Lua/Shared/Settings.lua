-- Player settings from the Mod Configuration Menu (MCM). Every access is guarded: without MCM, or when MCM loaded
-- after this mod, the defaults apply. MCM puts the global MCM table into this mod only when it loads first.

local Common = Ext.Require("Shared/Common.lua")

local Settings = {}

--- Returns the value of a setting and where it came from: "MCM", or "default" when MCM has no value.
function Settings.Get(id, default)
    local value = nil
    if MCM ~= nil then
        local ok, result = pcall(MCM.Get, id)
        if ok then
            value = result
        end
    end
    if value == nil then
        return default, "default"
    end
    return value, "MCM"
end

--- Calls fn(settingId) when the player changes a setting of this mod, and fn(nil) after a switch of the MCM profile
--- (that switch changes all values at once). Returns false when MCM is not loaded.
function Settings.OnChange(fn)
    if not (Ext.Mod.IsModLoaded(Common.MCMModuleUUID) and Ext.ModEvents and Ext.ModEvents.BG3MCM) then
        return false
    end
    local events = Ext.ModEvents.BG3MCM
    events["MCM_Setting_Saved"]:Subscribe(function(payload)
        if type(payload) == "table" and payload.modUUID == ModuleUUID then
            fn(payload.settingId)
        end
    end)
    events["MCM_Profile_Activated"]:Subscribe(function()
        fn(nil)
    end)
    return true
end

return Settings
