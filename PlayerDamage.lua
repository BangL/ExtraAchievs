local damage_fall_original = PlayerDamage.damage_fall

function PlayerDamage:damage_fall(data, ...)
    local was_alive = self:get_real_health() > 0 and not self._bleed_out
    local in_freefall = self._unit:movement():current_state_name() == "freefall"
    local result = damage_fall_original(self, data, ...)

    if was_alive and self:get_real_health() <= 0 then
        ExtraAchievs:OnFallDeath(data, in_freefall)
    end

    return result
end
