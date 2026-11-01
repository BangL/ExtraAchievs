local damage_fall_original = PlayerDamage.damage_fall

function PlayerDamage:damage_fall(data, ...)
    local was_alive = self:get_real_health() > 0 and not self._bleed_out
    local deadly_fall = data.height > self._class_tweak_data.damage.FALL_DAMAGE_DEATH_HEIGHT
    local result = damage_fall_original(self, data, ...)

    if was_alive and self:get_real_health() <= 0 then
        ExtraAchievs:OnFallDeath(data, deadly_fall)
    end

    return result
end

local damage_fire_original = PlayerDamage.damage_fire

-- hans_forget_the_flammenwerfer: the fire pool of the flamer's incendiary grenade (set in FireManager.lua) puts the player down
function PlayerDamage:damage_fire(attack_data, ...)
    local flamer_fire = ExtraAchievs._fire_tweak_id == ExtraAchievs.FLAMER_FIRE
    local was_alive = flamer_fire and not self._bleed_out and self:get_real_health() > 0
    local result = damage_fire_original(self, attack_data, ...)

    if was_alive and (self._bleed_out or self:get_real_health() <= 0) then
        ExtraAchievs:Unlock("hans_forget_the_flammenwerfer")
    end

    return result
end
