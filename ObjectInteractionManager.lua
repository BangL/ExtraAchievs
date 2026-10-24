local init_original = ObjectInteractionManager.init
local update_original = ObjectInteractionManager.update
local add_unit_original = ObjectInteractionManager.add_unit
local remove_unit_original = ObjectInteractionManager.remove_unit
local end_action_interact_original = ObjectInteractionManager.end_action_interact

function ObjectInteractionManager:init(...)
    init_original(self, ...)
    self._queued_units = {}
end

function ObjectInteractionManager:update(t, ...)
    update_original(self, t, ...)
    self:_process_queued_units(t)
end

function ObjectInteractionManager:add_unit(unit, ...)
    self:add_unit_clbk(unit)
    return add_unit_original(self, unit, ...)
end

function ObjectInteractionManager:remove_unit(unit, ...)
    self:remove_unit_clbk(unit)
    return remove_unit_original(self, unit, ...)
end

function ObjectInteractionManager:end_action_interact(...)
    local value = end_action_interact_original(self, ...)

    if alive(self._active_unit) and self._active_unit:interaction() then
        local id = self._active_unit:interaction().tweak_data
        local editor_id = self._active_unit:editor_id()
        ExtraAchievs:InteractiveUnitEvent(ExtraAchievs.UNIT_EVENT_INTERACT,
            tostring(self._active_unit:key()), { unit = self._active_unit, editor_id = editor_id, interact_id = id })
    end

    return value
end
