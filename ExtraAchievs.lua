-- Loot tracking for blammosweep. Hooked on several game classes (see main.xml), each one is patched as soon as it exists.
-- Greed items and intel documents only exist on the host, so blammosweep can only be earned as host.
ExtraAchievs = ExtraAchievs or {}
ExtraAchievs.GOLD_RUSH_GOLD = 40

function ExtraAchievs:ResetRun()
    self._run = {
        gold = 0,        -- secured gold bars
        kills = 0,       -- enemy deaths by anyone
        cache_units = {}, -- world_id -> greed cache units that were spawned
        intel_units = {}, -- world_id -> chosen intel document unit
    }
end

if not ExtraAchievs._run then
    ExtraAchievs:ResetRun()
end

function ExtraAchievs:Unlock(id, package_id)
    if not CustomAchievementPackage then
        log("[Extra Achievements] [ERROR] CustomAchievementPackage was nil")
        return
    end

    local package = CustomAchievementPackage:new(package_id or "extra_achievements")
    local achievement = package and package:Achievement(id)
    if achievement and not achievement:IsUnlocked() then
        achievement:Unlock()
    end
end

-- local player died from a fall (called from PlayerDamage:damage_fall)
-- in_freefall: the player was in the freefall state (mechanic when jumping from very high up), which sends them
-- straight to custody instead of bleeding out
function ExtraAchievs:OnFallDeath(data, in_freefall)
    local job = managers.raid_job:current_job()

    -- cant_take_it_anymore: jump from the very top of the bridge in TRAIN WRECK
    if in_freefall and job and job.job_id == "ger_bridge" and job.job_type ~= OperationsTweakData.JOB_TYPE_OPERATION then
        self:Unlock("cant_take_it_anymore")
    end
end

local function interactable_left(unit)
    return alive(unit) and unit:interaction() and unit:interaction():active()
end

-- true if gold, dogtags, greed items, greed cache and intel of the finished mission were all collected
function ExtraAchievs:IsAllLootSecured(event_complete_state)
    if not Network:is_server() then
        return false
    end

    local run = self._run

    if run.gold < self.GOLD_RUSH_GOLD then
        return false
    end

    if event_complete_state.loot_spawned ~= event_complete_state.loot_acquired then -- dogtags
        return false
    end

    for _, unit in ipairs(managers.greed._active_greed_items or {}) do -- picked up items get removed from this list
        if alive(unit) then
            return false
        end
    end

    for _, units in pairs(run.cache_units) do
        for _, unit in ipairs(units) do
            if alive(unit) and unit:greed() and unit:greed():reserve_left() > 0 then
                return false
            end
        end
    end

    if not managers.consumable_missions:is_all_missions_unlocked() then -- otherwise the document can't be picked up anyway
        for _, unit in pairs(run.intel_units) do
            if interactable_left(unit) then
                return false
            end
        end
    end

    return true
end

if GreedManager and not ExtraAchievs._hooked_greed then
    ExtraAchievs._hooked_greed = true

    Hooks:PostHook(GreedManager, "plant_greed_items_on_level", "ExtraAchievs_GreedManager_post_plant_greed_items_on_level",
        function(self, world_id)
            local units = {}
            for _, cache in pairs(self._registered_greed_cache_items[world_id] or {}) do
                if not cache.deleted and alive(cache.unit) then
                    table.insert(units, cache.unit)
                end
            end
            ExtraAchievs._run.cache_units[world_id] = units
        end
    )
end

if ConsumableMissionManager and not ExtraAchievs._hooked_intel then
    ExtraAchievs._hooked_intel = true

    Hooks:PreHook(ConsumableMissionManager, "_destroy_unused_documents", "ExtraAchievs_ConsumableMissionManager_pre__destroy_unused_documents",
        function(self, world_id, chosen_document_unit)
            ExtraAchievs._run.intel_units[world_id] = chosen_document_unit
        end
    )
end

if LootManager and not ExtraAchievs._hooked_loot then
    ExtraAchievs._hooked_loot = true

    Hooks:PostHook(LootManager, "sync_secure_loot", "ExtraAchievs_LootManager_post_sync_secure_loot",
        function(self, carry_id)
            if carry_id == "gold" then
                ExtraAchievs._run.gold = ExtraAchievs._run.gold + 1
            end
        end
    )
end

if RaidJobManager and not ExtraAchievs._hooked_job then
    ExtraAchievs._hooked_job = true

    Hooks:PostHook(RaidJobManager, "external_start_mission_clbk", "ExtraAchievs_RaidJobManager_post_external_start_mission_clbk",
        function()
            ExtraAchievs:ResetRun()
        end
    )
end
