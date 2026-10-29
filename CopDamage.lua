-- counts every enemy death (any killer, incl. other peers and bots) for the pacifist achievements
local die_original = CopDamage.die

function CopDamage:die(...)
    if not self._dead then
        ExtraAchievs._run.kills = ExtraAchievs._run.kills + 1
    end
    return die_original(self, ...)
end
