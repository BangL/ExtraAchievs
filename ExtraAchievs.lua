-- Loot tracking for blammosweep. Hooked on several game classes (see main.xml), each one is patched as soon as it exists.
-- Greed items and intel documents only exist on the host, so the host checks blammosweep and tells the clients.
ExtraAchievs = ExtraAchievs or {}
ExtraAchievs.GOLD_RUSH_GOLD = 40
ExtraAchievs.BLAMMOSWEEP_MSG = "ExtraAchievs_blammosweep"
ExtraAchievs.PICKPOCKET_MSG = "ExtraAchievs_pickpocket"
ExtraAchievs.PICKPOCKET_FAIL_MSG = "ExtraAchievs_pickpocket_fail"
ExtraAchievs.UNLOCK_MSG = "ExtraAchievs_unlock" -- host decided an achievement for everyone, data = achievement id
ExtraAchievs.HELLO_MSG = "ExtraAchievs_hello" -- host: "I judge the Pickpocket achievements for everyone"

-- achievements the host decides and tells the clients (they can't see the weapons of other peers' kills)
ExtraAchievs.HOST_ACHIEVEMENTS = { for_the_motherland = true, deutschland_den_deutschen = true, protect_lange = true,
    dont_be_so_whiney = true, sicher_ist_sicher = true, dont_you_dare_to_explode = true, this_is_seeadler = true }

-- weapon ids (npc variants have a suffix, see WeaponId)
ExtraAchievs.RUSSIAN_WEAPONS = { tt33 = true, mosin = true, dp28 = true }
ExtraAchievs.GERMAN_WEAPONS = { c96 = true, mp38 = true, mp44 = true, kar_98k = true, mg42 = true, geco = true,
    georg = true, -- Luger P08
    m24 = true, concrete = true, d343 = true, gold_bar = true, betty = true, -- grenades, spring mine
    german_brass_knuckles = true }
ExtraAchievs.GENERALS = { soviet_nkvd_int_security_captain = true, soviet_nkvd_int_security_captain_b = true }
ExtraAchievs.GENERALS_COUNT = 2 -- STRONGPOINT
ExtraAchievs.OFFICERS = { fb_german_commander = true, fb_german_commander_boss = true } -- FULL STOP

-- mission elements that say "the goal is reached" (id -> job and goal), judged by the host when the mission is complete
ExtraAchievs.GOAL_ELEMENTS = {
    [101403] = { job = "forest_gumpy", goal = "gold_trucks" }, -- ex_lootcounter_eq0: all gold of the trucks secured
    [100763] = { job = "ger_bridge", goal = "train_gold" },    -- logic_link_all_gold_in: all gold of the train secured
}
ExtraAchievs.WHINEY_OBJECTIVE = "obj_ger_castle_op_02" -- Firestarter: shoot the wine barrels (sub objective counts them)
ExtraAchievs.FLAMER_FIRE = "flamer_incendiary" -- fire tweak id of the pool the incendiary grenade of the flamer leaves

if not ExtraAchievs._hooked_network then
    ExtraAchievs._hooked_network = true

    Hooks:Add("NetworkReceivedData", "ExtraAchievs_NetworkReceivedData", function(sender, id, data)
        if Network:is_server() or (id ~= ExtraAchievs.BLAMMOSWEEP_MSG and id ~= ExtraAchievs.HELLO_MSG and id ~= ExtraAchievs.UNLOCK_MSG) then
            return
        end
        if not ExtraAchievs:IsHost(sender) then
            return
        end
        if id == ExtraAchievs.HELLO_MSG then
            ExtraAchievs._hello_session = managers.network:session() -- valid for this lobby only
        elseif id == ExtraAchievs.UNLOCK_MSG then
            if ExtraAchievs.HOST_ACHIEVEMENTS[data] and managers.raid_job:current_job() then
                ExtraAchievs:Unlock(data)
            end
        else
            ExtraAchievs:Unlock("blammosweep")
        end
    end)
end

-- sender of a LuaNetworking message is the host
function ExtraAchievs:IsHost(sender)
    local session = managers.network:session()
    local host = session and session:server_peer()
    return host ~= nil and sender == host:id()
end

-- host: a goal element of the mission script was executed (called from MissionScriptElement:on_executed)
function ExtraAchievs:OnElementExecuted(element)
    local goal = self.GOAL_ELEMENTS[element._id]
    if goal and Network:is_server() and element._values.enabled then
        local job = managers.raid_job and managers.raid_job:current_job()
        if job and job.job_id == goal.job then
            self._run.goals[goal.goal] = true
        end
    end
end

function ExtraAchievs:IsRocket(unit)
    local name = alive(unit) and unit:name():t()
    return name and name:find("rocket_v2", 1, true) and name:find("redtip", 1, true) and true or false
end

-- true if every red-tipped rocket that was placed (and not taken away by the mission script) went off
function ExtraAchievs:AllRocketsDestroyed()
    local exploded = 0
    for _, rocket in pairs(self._rockets) do
        if rocket.exploded then
            exploded = exploded + 1
        elseif not rocket.disabled then
            return false
        end
    end
    return exploded > 0
end

-- host: checks of the raid goals, called once the mission is complete (difficulty is the number of difficulty_N)
function ExtraAchievs:CheckGoals(job_id, difficulty)
    local goals = self._run.goals
    if job_id == "silo" and difficulty >= 3 and self:AllRocketsDestroyed() then
        self:UnlockForAll("sicher_ist_sicher")
    elseif job_id == "forest_gumpy" and difficulty >= 3 and goals.gold_trucks then
        self:UnlockForAll("dont_you_dare_to_explode")
    elseif job_id == "ger_bridge" and difficulty >= 4 and goals.train_gold then
        self:UnlockForAll("this_is_seeadler")
    end
end

-- unlock for the local player and, as host, tell the clients
function ExtraAchievs:UnlockForAll(id)
    self:Unlock(id)
    if LuaNetworking:IsMultiplayer() then
        LuaNetworking:SendToPeers(self.UNLOCK_MSG, id)
    end
end

function ExtraAchievs:WeaponId(attack_data)
    local weapon_unit = attack_data and attack_data.weapon_unit
    local base = alive(weapon_unit) and weapon_unit:base()
    local name = base and base.get_name_id and base:get_name_id()
    if not name then
        return nil
    end
    return (tostring(name):gsub("_npc$", ""):gsub("_crew$", ""))
end

-- host: an enemy died (called from CopDamage:die). Kills by anyone count, the weapon decides.
function ExtraAchievs:OnEnemyDeath(unit, attack_data)
    local job = managers.raid_job and managers.raid_job:current_job()
    if not job or job.job_type == OperationsTweakData.JOB_TYPE_OPERATION then
        return
    end

    local base = alive(unit) and unit:base()
    local tweak_name = base and base._tweak_table
    if not tweak_name then
        return
    end

    local weapon = self:WeaponId(attack_data)

    -- for_the_motherland: both generals in STRONGPOINT killed with russian weapons
    if job.job_id == "settlement" and self.GENERALS[tweak_name] and weapon and self.RUSSIAN_WEAPONS[weapon] then
        local run = self._run
        run.russian_general_kills = (run.russian_general_kills or 0) + 1
        if run.russian_general_kills >= self.GENERALS_COUNT then
            self:UnlockForAll("for_the_motherland")
        end
    end

    -- deutschland_den_deutschen: the officer in FULL STOP killed with a german weapon
    if job.job_id == "forest_bunker" and self.OFFICERS[tweak_name] and weapon and self.GERMAN_WEAPONS[weapon] then
        self:UnlockForAll("deutschland_den_deutschen")
    end
end

function ExtraAchievs:ResetRun()
    self._run = {
        gold = 0,        -- secured gold bars
        started = false, -- session we saw the mission start in (not a drop-in), so gold and kills are complete
        ended = false,   -- the mission is over (stage_success is no use: it stays set from the camp)
        kills = 0,       -- enemy deaths by anyone
        pacifist_failed = false, -- the "run failed" toast was already shown
        cache_units = {}, -- world_id -> greed cache units that were spawned
        intel_units = {}, -- world_id -> chosen intel document unit
        goals = {},      -- goal -> true, see GOAL_ELEMENTS
    }
    -- rockets are placed with the world, which may be before the mission start: keep the ones that still exist
    for key, rocket in pairs(self._rockets or {}) do
        if not alive(rocket.unit) then
            self._rockets[key] = nil
        end
    end
end

ExtraAchievs._rockets = ExtraAchievs._rockets or {} -- unit key -> { unit, exploded, disabled } of the red-tipped V2 rockets

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
-- deadly_fall: fell from above FALL_DAMAGE_DEATH_HEIGHT (jumping from very high up), which sends them
-- straight to custody instead of bleeding out
function ExtraAchievs:OnFallDeath(data, deadly_fall)
    local job = managers.raid_job:current_job()

    -- cant_take_it_anymore: jump from the very top of the bridge in TRAIN WRECK
    if deadly_fall and job and job.job_id == "ger_bridge" and job.job_type ~= OperationsTweakData.JOB_TYPE_OPERATION then
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

    Hooks:PreHook(RaidJobManager, "do_external_end_mission", "ExtraAchievs_RaidJobManager_pre_do_external_end_mission",
        function()
            ExtraAchievs._run.ended = true
        end
    )

    Hooks:PostHook(RaidJobManager, "external_start_mission_clbk", "ExtraAchievs_RaidJobManager_post_external_start_mission_clbk",
        function()
            ExtraAchievs:ResetRun()
            ExtraAchievs._run.started = managers.network:session() -- the lobby it was seen in
            if Network:is_server() and LuaNetworking:IsMultiplayer() and ExtraAchievs:HasPickpocket() then
                LuaNetworking:SendToPeers(ExtraAchievs.HELLO_MSG, "1")
            end
        end
    )
end

if ExplodingProp and not ExtraAchievs._hooked_rockets then
    ExtraAchievs._hooked_rockets = true

    Hooks:PostHook(ExplodingProp, "init", "ExtraAchievs_ExplodingProp_post_init", function(self, unit)
        if ExtraAchievs:IsRocket(unit) then
            ExtraAchievs._rockets[unit:key()] = { unit = unit }
        end
    end)

    Hooks:PostHook(ExplodingProp, "detonate", "ExtraAchievs_ExplodingProp_post_detonate", function(self)
        local rocket = alive(self._unit) and ExtraAchievs._rockets[self._unit:key()]
        if rocket then
            rocket.exploded = true
        end
    end)
end

if GamePlayCentralManager and not ExtraAchievs._hooked_gameplaycentral then
    ExtraAchievs._hooked_gameplaycentral = true

    -- the mission script takes the black-tipped or the red-tipped rockets away, those are not spawned
    Hooks:PostHook(GamePlayCentralManager, "mission_disable_unit", "ExtraAchievs_GamePlayCentralManager_post_mission_disable_unit", function(self, unit)
        local rocket = alive(unit) and ExtraAchievs._rockets[unit:key()]
        if rocket then
            rocket.disabled = true
        end
    end)

    Hooks:PostHook(GamePlayCentralManager, "mission_enable_unit", "ExtraAchievs_GamePlayCentralManager_post_mission_enable_unit", function(self, unit)
        local rocket = alive(unit) and ExtraAchievs._rockets[unit:key()]
        if rocket then
            rocket.disabled = nil
        end
    end)
end

if ObjectivesManager and not ExtraAchievs._hooked_objectives then
    ExtraAchievs._hooked_objectives = true

    -- dont_be_so_whiney: Firestarter counts the destroyed wine barrels as sub objective, which is finished with the last one
    Hooks:PostHook(ObjectivesManager, "complete_sub_objective", "ExtraAchievs_ObjectivesManager_post_complete_sub_objective",
        function(self, id, sub_id, load_data)
            if id ~= ExtraAchievs.WHINEY_OBJECTIVE or load_data or not Network:is_server() then
                return
            end
            if (tonumber(tostring(Global.game_settings.difficulty):match("%d+")) or 0) < 3 then -- HARD and up
                return
            end
            local objective = self._objectives[id]
            local sub_objective = objective and objective.sub_objectives[sub_id]
            if sub_objective and sub_objective.completed then
                ExtraAchievs:UnlockForAll("dont_be_so_whiney")
            end
        end
    )
end
