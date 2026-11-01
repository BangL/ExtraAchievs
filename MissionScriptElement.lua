-- tells ExtraAchievs about the mission elements it waits for (GOAL_ELEMENTS). ExtraAchievs is a plain global.
-- Hooked after the game script merged into the core class (override_class), so the core class is hooked.
core:import("CoreMissionScriptElement")

Hooks:PreHook(CoreMissionScriptElement.MissionScriptElement, "on_executed", "ExtraAchievs_MissionScriptElement_pre_on_executed", function(self)
    local extra_achievs = _G.ExtraAchievs
    if extra_achievs then
        extra_achievs:OnElementExecuted(self)
    end
end)
