-- Checks at the end of a successful mission. Vanilla awards (_achievements_awarded) only after stats AND loot data are ready, and
-- the loot data never comes in missions without dog tags (loot_spawned == 0, e.g. BURNING MAN). So every check says what it needs:
--   needs_loot = false: runs once as soon as the stats are ready (and the mission is a success)
--   needs_loot = true:  runs once after vanilla awarded (loot data and dog tags known, see IsAllLootSecured)
-- A new achievement registers itself with ExtraAchievs:AddEndCheck(id, needs_loot, function(state, ctx) ... end), ctx = { difficulty,
-- is_operation, is_very_hard, job_id, unlock = ExtraAchievs.Unlock }.
ExtraAchievs._end_checks = ExtraAchievs._end_checks or {}

function ExtraAchievs:AddEndCheck(id, needs_loot, fn)
    self._end_checks[id] = { needs_loot = needs_loot, fn = fn }
end

function ExtraAchievs:RunEndChecks(state, with_loot)
    local job_id = state._current_job_data.job_id
    local difficulty = tonumber(tostring(state._difficulty):match("%d+")) or 0
    local ctx = {
        job_id = job_id,
        difficulty = difficulty,
        is_operation = state._current_job_data.job_type == OperationsTweakData.JOB_TYPE_OPERATION,
        is_very_hard = difficulty >= 4,
        unlock = function(id)
            ExtraAchievs:Unlock(id)
        end,
    }
    for id, check in pairs(self._end_checks) do
        if check.needs_loot == with_loot then
            local ok, err = blt.pcall(check.fn, state, ctx)
            if not ok then
                log("[ExtraAchievs] end check '" .. tostring(id) .. "' failed: " .. tostring(err))
            end
        end
    end
end

ExtraAchievs:AddEndCheck("pickpocket", false, function(state)
    ExtraAchievs:CheckPickpocket(state)
end)

ExtraAchievs:AddEndCheck("goals", false, function(state, ctx)
    if not ctx.is_operation and Network:is_server() then
        ExtraAchievs:CheckGoals(ctx.job_id, ctx.difficulty)
    end
end)

ExtraAchievs:AddEndCheck("very_hard_raids", false, function(state, ctx)
    if ctx.is_operation or not ctx.is_very_hard then
        return
    end
    local job_id, unlock = ctx.job_id, ctx.unlock

    local killed = managers.statistics._global.session.killed
    local function kills(enemy)
        return killed[enemy] and killed[enemy].count or 0
    end

    -- no_blood_on_the_risers: COUNTDOWN without anyone going to bleed out
    if job_id == "silo" and state.downed_stats and (state.downed_stats.total_downs or 0) == 0 then
        unlock("no_blood_on_the_risers")
    end

    -- let_them_watch: TRAIN WRECK without killing snipers or spotters
    if job_id == "ger_bridge" and kills("german_sniper") == 0 and kills("german_spotter") == 0 then
        unlock("let_them_watch")
    end

    -- protect_lange: WIRETAP with Lange alive (the host judges: his death only switches off this operator, see
    -- global_state_operator_franz_alive; it's the same one that makes the escort bonus go away)
    if job_id == "radio_defense" and Network:is_server() then
        local franz_alive = managers.mission:get_element_by_name("global_state_operator_franz_alive")
        if franz_alive and franz_alive:enabled() then
            ExtraAchievs:UnlockForAll("protect_lange")
        end
    end
end)

-- blammosweep: GOLD RUSH with all gold, dogtags, greed items, greed cache and intel secured
ExtraAchievs:AddEndCheck("blammosweep", true, function(state, ctx)
    if ctx.is_operation or not ctx.is_very_hard then
        return
    end
    if ctx.job_id == "gold_rush" and ExtraAchievs:IsAllLootSecured(state) then
        ctx.unlock("blammosweep")
        if LuaNetworking:IsMultiplayer() then
            LuaNetworking:SendToPeers(ExtraAchievs.BLAMMOSWEEP_MSG, "1") -- the clients can't see this themselves
        end
    end
end)

Hooks:PostHook(EventCompleteState, "_check_complete_achievements",
    "ExtraAchievements_EventCompleteState_post__check_complete_achievements",
    function(self)
        if not self.stats_ready then
            return
        end
        if not self:is_success() then
            return
        end

        if not self._extra_stats_checked then
            self._extra_stats_checked = true
            ExtraAchievs:RunEndChecks(self, false)
        end

        if self._achievements_awarded and not self._extra_loot_checked then
            self._extra_loot_checked = true
            ExtraAchievs:RunEndChecks(self, true)
        end
    end
)

-- the state is a singleton: the once-per-mission flags must not survive into the next mission
Hooks:PostHook(EventCompleteState, "at_exit", "ExtraAchievements_EventCompleteState_post_at_exit", function(self)
    self._extra_stats_checked = nil
    self._extra_loot_checked = nil
end)
