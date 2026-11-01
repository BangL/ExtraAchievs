-- tells ExtraAchievs about the mission elements it waits for (GOAL_ELEMENTS). ExtraAchievs is a plain global,
-- and the core module is not our environment: the class is reached via the CoreMissionScriptElement namespace.
local core_module = rawget(_G, "CoreMissionScriptElement")
Hooks:PreHook(core_module and core_module.MissionScriptElement, "on_executed", "ExtraAchievs_MissionScriptElement_pre_on_executed", function(self)
    local extra_achievs = _G.ExtraAchievs
    if extra_achievs then
        extra_achievs:OnElementExecuted(self)
    end
end)
