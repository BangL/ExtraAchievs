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
