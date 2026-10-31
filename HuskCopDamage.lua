-- on clients all enemies are husks, whose die() overrides (doesn't call) CopDamage:die
local die_original = HuskCopDamage.die

function HuskCopDamage:die(...)
    if not self._dead then
        ExtraAchievs._run.kills = ExtraAchievs._run.kills + 1
        ExtraAchievs:FailPickpocket("kill")
    end
    return die_original(self, ...)
end
