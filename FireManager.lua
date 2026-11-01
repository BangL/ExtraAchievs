-- remembers which fire is dealing damage right now, for the player damage of hans_forget_the_flammenwerfer
local do_damage_tick_original = FireManager._do_damage_tick

function FireManager:_do_damage_tick(fire_data, ...)
    if ExtraAchievs then
        ExtraAchievs._fire_tweak_id = fire_data and fire_data.tweak_id
    end
    local result = do_damage_tick_original(self, fire_data, ...)
    if ExtraAchievs then
        ExtraAchievs._fire_tweak_id = nil
    end
    return result
end
