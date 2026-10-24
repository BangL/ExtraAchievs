-- Vanilla only awards (and sets _achievements_awarded) once stats and loot are ready and the mission was a success,
-- so we piggyback on that: run exactly once after it flipped to true.
Hooks:PostHook(EventCompleteState, "_check_complete_achievements",
    "ExtraAchievements_EventCompleteState_post__check_complete_achievements",
    function(self)
        if not self._achievements_awarded then
            self._extra_achievs_checked = nil
            return
        end
        if self._extra_achievs_checked then
            return
        end
        self._extra_achievs_checked = true

        local function unlock(id)
            ExtraAchievs:Unlock(id)
        end

        local job_id = self._current_job_data.job_id
        local is_operation = self._current_job_data.job_type == OperationsTweakData.JOB_TYPE_OPERATION
        local is_very_hard = self._difficulty == "difficulty_4"

        if is_operation or not is_very_hard then
            return
        end

        local killed = managers.statistics._global.session.killed
        local function kills(enemy)
            return killed[enemy] and killed[enemy].count or 0
        end

        -- no_blood_on_the_risers: COUNTDOWN without anyone going to bleed out
        -- (downed_stats is only set once stats are ready, which vanilla guarantees at this point)
        if job_id == "silo" and self.downed_stats and (self.downed_stats.total_downs or 0) == 0 then
            unlock("no_blood_on_the_risers")
        end

        -- let_them_watch: TRAIN WRECK without killing snipers or spotters
        if job_id == "ger_bridge" and kills("german_sniper") == 0 and kills("german_spotter") == 0 then
            unlock("let_them_watch")
        end

        -- blammosweep: GOLD RUSH with all gold, dogtags, greed items, greed cache and intel secured
        if job_id == "gold_rush" and ExtraAchievs:IsAllLootSecured(self) then
            unlock("blammosweep")
        end

        ExtraAchievs:ResetRun()
    end
)
