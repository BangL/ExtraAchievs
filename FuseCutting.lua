-- perfect_cut: a bomb fuse cut completely (the minigame ends on the first miss, so all cuts done = no miss)
Hooks:PostHook(HUDSpecialInteractionFuseCutting, "check_interact_success", "ExtraAchievs_HUDSpecialInteractionFuseCutting_post_check_interact_success",
    function(self)
        if self:_is_all_cut() then
            ExtraAchievs:Unlock("perfect_cut")
        end
    end
)
