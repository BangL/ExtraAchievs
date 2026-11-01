-- tells ExtraAchievs about the mission elements it waits for (GOAL_ELEMENTS). ExtraAchievs is a plain global,
-- but this file runs inside the core module.
Hooks:PreHook(MissionScriptElement, "on_executed", "ExtraAchievs_MissionScriptElement_pre_on_executed", function(self)
    local extra_achievs = _G.ExtraAchievs
    if extra_achievs then
        extra_achievs:OnElementExecuted(self)
    end
end)
