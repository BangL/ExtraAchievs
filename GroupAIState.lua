Hooks:PostHook(GroupAIStateBase, "set_whisper_mode", "ExtraAchievs_GroupAIStateBase_post_set_whisper_mode",
    function(self, enabled)
        if not enabled then
            ExtraAchievs:FailPickpocket("alarm")
        end
    end
)
