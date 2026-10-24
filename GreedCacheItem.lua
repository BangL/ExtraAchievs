local on_interacted_original = GreedCacheItem.on_interacted

function GreedCacheItem:on_interacted(amount, ...)
    local pickup_amount = on_interacted_original(self, amount, ...)

    if self:reserve_left() == 0 then
        local unit = self._unit
        local key = tostring(unit:key())
        local editor_id = unit:editor_id()
        local interact_id = unit:interaction().tweak_data
        ExtraAchievs:InteractiveUnitEvent(ExtraAchievs.UNIT_EVENT_REMOVE,
            key, { unit = unit, editor_id = editor_id, interact_id = interact_id })
    end

    return pickup_amount
end
