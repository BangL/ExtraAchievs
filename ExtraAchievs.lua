-- Loot tracking for blammosweep. Hooked on several game classes (see main.xml), each one is patched as soon as it exists.
-- Greed items and intel documents only exist on the host, so the host checks blammosweep and tells the clients.
ExtraAchievs = ExtraAchievs or {}
ExtraAchievs.GOLD_RUSH_GOLD = 40
ExtraAchievs.BLAMMOSWEEP_MSG = "ExtraAchievs_blammosweep"
ExtraAchievs.PICKPOCKET_MSG = "ExtraAchievs_pickpocket"
ExtraAchievs.PICKPOCKET_FAIL_MSG = "ExtraAchievs_pickpocket_fail"
ExtraAchievs.UNLOCK_MSG = "ExtraAchievs_unlock" -- host decided an achievement for everyone, data = achievement id
ExtraAchievs.HELLO_MSG = "ExtraAchievs_hello" -- host: "I judge the Pickpocket achievements for everyone"
ExtraAchievs.PROGRESS_MSG = "ExtraAchievs_progress" -- host: one more counted kill for the receiver, data = KILL_COUNTERS key
ExtraAchievs.PROGRESS_FILE = "ExtraAchievs.json" -- in SavePath, counters of the kill achievements

-- achievements the host decides and tells the clients (they can't see the weapons of other peers' kills)
ExtraAchievs.HOST_ACHIEVEMENTS = { for_the_motherland = true, deutschland_den_deutschen = true, protect_lange = true,
    dont_be_so_whiney = true, sicher_ist_sicher = true, dont_you_dare_to_explode = true, this_is_seeadler = true,
    ouch_my_art = true, tiger_hunter = true, come_and_see = true, enemy_at_the_gates = true, shotgun_sniper = true,
    sniper_duel = true, not_from_here = true, flying_change = true, greed_killed_the_communist = true,
    the_game_was_rigged = true, nazi_scalps_for_aldo = true, a_nazi_walks_into_a_bar = true }

-- weapon ids (npc variants have a suffix, see WeaponId)
ExtraAchievs.RUSSIAN_WEAPONS = { tt33 = true, mosin = true, dp28 = true }
ExtraAchievs.GERMAN_WEAPONS = { c96 = true, mp38 = true, mp44 = true, kar_98k = true, mg42 = true, geco = true,
    georg = true, -- Luger P08
    m24 = true, concrete = true, d343 = true, gold_bar = true, betty = true, -- grenades, spring mine
    german_brass_knuckles = true }
ExtraAchievs.GENERALS = { soviet_nkvd_int_security_captain = true, soviet_nkvd_int_security_captain_b = true }
ExtraAchievs.GENERALS_COUNT = 2 -- STRONGPOINT
ExtraAchievs.OFFICERS = { fb_german_commander = true, fb_german_commander_boss = true } -- FULL STOP
ExtraAchievs.SNIPER = "german_sniper"
ExtraAchievs.DUEL_DISTANCE = 3000 -- cm, headshot with a pistol
ExtraAchievs.SWITCH_KILLS = 3 -- kills with this many different weapon classes ...
ExtraAchievs.SWITCH_TIME = 5 -- ... within this many seconds
ExtraAchievs.FLAMER = "german_flamer"
ExtraAchievs.SHOTGUNS = { m1912 = true, ithaca = true, browning = true, shotty = true, geco = true } -- player shotguns (WeaponId)
ExtraAchievs.GATES_DISTANCE = 5000 -- cm, headshot with the mosin
ExtraAchievs.PAINTINGS = { carry_id = "painting_sto", count = 6 } -- ROGUES GALLERY, count = target of the paintings counter

-- kills of the shooter that are counted over all raids (HARD and up): weapon id (WeaponId) -> counter and achievement
ExtraAchievs.KILL_COUNTERS = {
    m3_knife = { id = "nazi_scalps_for_aldo", target = 100 },
}
ExtraAchievs.KILL_COUNTERS.m1918 = { id = "a_nazi_walks_into_a_bar", target = 100 } -- BAR (browning is the Auto-5 shotgun)
ExtraAchievs.KILL_COUNTERS.gold_bar = ExtraAchievs.KILL_COUNTERS.m1918 -- the gold bar grenade counts too

-- mission elements that say "the goal is reached" (id -> job and goal), judged by the host when the mission is complete
ExtraAchievs.GOAL_ELEMENTS = {
    [101403] = { job = "forest_gumpy", goal = "gold_trucks" }, -- ex_lootcounter_eq0: all gold of the trucks secured
    [100763] = { job = "ger_bridge", goal = "train_gold" },    -- logic_link_all_gold_in: all gold of the train secured
    [102159] = { job = "fury_railway", goal = "train_loot" },  -- trains_emptied_of_gold: the gold of all trains taken
}
-- Tiger Trap: the game's own counter (100878) only counts the IED kill of the first tiger; the AA shell kills of the others
-- only fire "tank destroyed" (100419-100422). So count the distinct tigers over both outputs; 4 always spawn, the mission itself wants fewer.
ExtraAchievs.TANK_ELEMENTS = { [100419] = 1, [101019] = 1, [100420] = 2, [101015] = 2, [100421] = 3, [101017] = 3, [100422] = 4, [101018] = 4 }
ExtraAchievs.TANKS_NEEDED = 4
-- Firestarter: logic_link_barrel_destroyed (103365) runs once per destroyed wine barrel (by anyone or by the fire),
-- logic_random_015 always spawns 20 of them. The objective itself wants fewer on HARD, so we count on our own.
ExtraAchievs.WHINEY_ELEMENT = 103365
ExtraAchievs.WHINEY_BARRELS = 20
ExtraAchievs.FLAMER_FIRE = "flamer_incendiary" -- fire tweak id of the pool the incendiary grenade of the flamer leaves

-- brot: stand in front of the Brot store (operation mission id -> spot, cm) for BROT_TIME seconds
ExtraAchievs.BROT_TIME = 20
ExtraAchievs.BROT_RADIUS = 1000
ExtraAchievs.BROT_TOLERANCE = 60 -- degrees
-- the spot (nearly the same in both variants of RHINEGOLD day 2) and the compass heading to look at (the HUD compass shows -yaw)
ExtraAchievs.BROT_SPOT = { pos = Vector3(2585, 4800, -17), heading = 30 }
ExtraAchievs.BROT_MISSIONS = { oper_flamable_mini_raid_2_destroyed = true, oper_flamable_mini_raid_2_roundabout = true }

if not ExtraAchievs._hooked_brot then
    ExtraAchievs._hooked_brot = true

    Hooks:Add("GameSetupUpdate", "ExtraAchievs_GameSetupUpdate", function(t, dt)
        local job = managers.raid_job and managers.raid_job:current_job()
        -- free play runs the single event as a raid: no current_event_data, the event id is the job id
        local mission_id = job and (job.current_event_data and job.current_event_data.mission_id or job.job_id)
        local spot = mission_id and ExtraAchievs.BROT_MISSIONS[mission_id] and ExtraAchievs.BROT_SPOT
        local player = spot and managers.player and managers.player:local_player()
        local camera = spot and managers.viewport:get_current_camera()
        if not (alive(player) and camera and managers.player:current_state() ~= "bleed_out") then
            ExtraAchievs._brot_time = nil
            return
        end
        local pos = player:position()
        local heading = (-camera:rotation():yaw() - spot.heading + 180) % 360 - 180
        if mvector3.distance(pos, spot.pos) <= ExtraAchievs.BROT_RADIUS and math.abs(pos.z - spot.pos.z) < 300
            and math.abs(heading) <= ExtraAchievs.BROT_TOLERANCE then
            ExtraAchievs._brot_time = (ExtraAchievs._brot_time or 0) + dt
            if ExtraAchievs._brot_time >= ExtraAchievs.BROT_TIME then
                ExtraAchievs:Unlock("brot")
                ExtraAchievs._brot_time = nil
            end
        else
            ExtraAchievs._brot_time = nil
        end
    end)
end

if not ExtraAchievs._hooked_network then
    ExtraAchievs._hooked_network = true

    Hooks:Add("NetworkReceivedData", "ExtraAchievs_NetworkReceivedData", function(sender, id, data)
        if Network:is_server() or (id ~= ExtraAchievs.BLAMMOSWEEP_MSG and id ~= ExtraAchievs.HELLO_MSG and id ~= ExtraAchievs.UNLOCK_MSG
            and id ~= ExtraAchievs.PROGRESS_MSG) then
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
        elseif id == ExtraAchievs.PROGRESS_MSG then
            if ExtraAchievs.KILL_COUNTERS[data] and managers.raid_job:current_job() then
                ExtraAchievs:AddKill(data)
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
    if element._id == self.WHINEY_ELEMENT and Network:is_server() and element._values.enabled then
        local diff = tonumber(tostring(Global.game_settings.difficulty):match("%d+")) or 0
        local job = managers.raid_job and managers.raid_job:current_job()
        if diff >= 3 and job and (job.job_id == "oper_flamable_castle" or job.job_id == "oper_flamable") then -- HARD and up, element ids are not unique over the levels
            self._run.barrels = self._run.barrels + 1
            if self._run.barrels == self.WHINEY_BARRELS then
                self:UnlockForAll("dont_be_so_whiney")
            end
        end
    end
    local tank = self.TANK_ELEMENTS[element._id]
    if tank and Network:is_server() then
        local job = managers.raid_job and managers.raid_job:current_job()
        if job and job.job_id == "tnd" then
            self._run.tanks = self._run.tanks or {}
            self._run.tanks[tank] = true
            local n = 0
            for _ in pairs(self._run.tanks) do n = n + 1 end
            log("[ExtraAchievs] tiger " .. tank .. " destroyed via " .. tostring(element._id) .. ", " .. n .. " so far")
            if n >= self.TANKS_NEEDED then
                self._run.goals.tanks = true
            end
        end
    end
    local goal = self.GOAL_ELEMENTS[element._id]
    if goal then
        local job = managers.raid_job and managers.raid_job:current_job()
        log("[ExtraAchievs] goal element " .. tostring(element._id) .. " (" .. goal.goal .. ") executed, job=" .. tostring(job and job.job_id)
            .. " server=" .. tostring(Network:is_server()) .. " enabled=" .. tostring(element._values.enabled))
    end
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
    local names = {}
    for name in pairs(goals) do
        table.insert(names, name)
    end
    log("[ExtraAchievs] CheckGoals job=" .. tostring(job_id) .. " difficulty=" .. tostring(difficulty) .. " goals={" .. table.concat(names, ",")
        .. "} rockets=" .. tostring(self:AllRocketsDestroyed()))
    if job_id == "silo" and difficulty >= 3 and self:AllRocketsDestroyed() then
        self:UnlockForAll("sicher_ist_sicher")
    elseif job_id == "forest_gumpy" and difficulty >= 3 and goals.gold_trucks then
        self:UnlockForAll("dont_you_dare_to_explode")
    elseif job_id == "ger_bridge" and difficulty >= 4 and goals.train_gold then
        self:UnlockForAll("this_is_seeadler")
    elseif job_id == "tnd" and difficulty >= 4 and goals.tanks then
        self:UnlockForAll("tiger_hunter")
    elseif job_id == "fury_railway" and difficulty >= 4 and goals.train_loot then
        local killed = managers.statistics._global.session.killed[self.SNIPER]
        if not killed or killed.count == 0 then
            self:UnlockForAll("come_and_see")
        end
    elseif job_id == "sto" and difficulty >= 4 and self._run.loud_first_loot and (self._run.secured[self.PAINTINGS.carry_id] or 0) >= self.PAINTINGS.count then
        self:UnlockForAll("ouch_my_art")
    end
end

function ExtraAchievs:Difficulty()
    return tonumber(tostring(Global.game_settings.difficulty):match("%d+")) or 0
end

-- unlock for one peer: the local player directly, a client by message (only the host calls this)
function ExtraAchievs:UnlockForPeer(peer_id, id)
    if peer_id == managers.network:session():local_peer():id() then
        self:Unlock(id)
    else
        LuaNetworking:SendToPeer(peer_id, self.UNLOCK_MSG, id)
    end
end

-- counts a kill of the local player for KILL_COUNTERS[key], persisted over the raids
function ExtraAchievs:AddKill(key)
    local counter = self.KILL_COUNTERS[key]
    if not self._progress then
        local file = io.open(SavePath .. self.PROGRESS_FILE, "r")
        local ok, data = false, nil
        if file then
            ok, data = pcall(function() return json.decode(file:read("*all")) end)
            file:close()
        end
        self._progress = ok and type(data) == "table" and data or {}
    end
    key = counter.id
    local count = (tonumber(self._progress[key]) or 0) + 1
    if count > counter.target then
        return
    end
    self._progress[key] = count
    local file = io.open(SavePath .. self.PROGRESS_FILE, "w")
    if file then
        file:write(json.encode(self._progress))
        file:close()
    end
    if count >= counter.target then
        self:Unlock(counter.id)
    end
end

-- unlock for the local player and, as host, tell the clients
function ExtraAchievs:UnlockForAll(id)
    self:Unlock(id)
    if LuaNetworking:IsMultiplayer() then
        LuaNetworking:SendToPeers(self.UNLOCK_MSG, id)
    end
end

-- attacker and weapon id of a kill; grenades are the attacker themselves (thrower_unit), their weapon id is in the projectile tweak
function ExtraAchievs:Attacker(attack_data)
    local attacker = attack_data and attack_data.attacker_unit
    local base = alive(attacker) and attacker:base()
    if base and base.thrower_unit then
        local entry = base.projectile_entry and base:projectile_entry()
        local projectile = entry and tweak_data.projectiles[entry]
        return base:thrower_unit(), projectile and projectile.weapon_id
    end
    return attacker, nil
end

-- attack_data.headshot is only set after die() ran, so look at the body hit
function ExtraAchievs:IsHeadshot(unit, attack_data)
    if attack_data.headshot ~= nil then
        return attack_data.headshot and true or false
    end
    local damage = alive(unit) and unit:character_damage()
    local body = attack_data.col_ray and attack_data.col_ray.body
    return damage ~= nil and damage._ids_head_body_name ~= nil and body ~= nil and alive(body)
        and body:name() == damage._ids_head_body_name or false
end

function ExtraAchievs:WeaponId(attack_data)
    local weapon_unit = attack_data and attack_data.weapon_unit
    local base = alive(weapon_unit) and weapon_unit:base()
    if attack_data and attack_data.variant == "melee" and attack_data.name_id then
        return attack_data.name_id
    end
    local name = base and base.get_name_id and base:get_name_id()
    if not name then
        return nil
    end
    return (tostring(name):gsub("_npc$", ""):gsub("_crew$", ""))
end

-- host: an enemy died (called from CopDamage:die). Kills by anyone count, the weapon decides.
function ExtraAchievs:OnEnemyDeath(unit, attack_data)
    local job = managers.raid_job and managers.raid_job:current_job()
    if not job then
        return
    end

    local base = alive(unit) and unit:base()
    local tweak_name = base and base._tweak_table
    if not tweak_name then
        return
    end

    local attacker, grenade_weapon = self:Attacker(attack_data)
    local weapon = grenade_weapon or self:WeaponId(attack_data)
    local difficulty = self:Difficulty()
    local headshot = attack_data and self:IsHeadshot(unit, attack_data)

    -- shooter peer (nil for bots and other kills), the personal achievements go to them
    local peer = alive(attacker) and managers.network:session():peer_by_unit(attacker)

    -- enemy_at_the_gates: german sniper headshot with the mosin from a distance
    if peer and tweak_name == self.SNIPER and weapon == "mosin" and headshot
        and mvector3.distance(attacker:position(), unit:position()) >= self.GATES_DISTANCE then
        self:UnlockForPeer(peer:id(), "enemy_at_the_gates")
    end

    -- shotgun_sniper: german sniper headshot with any shotgun
    if peer and tweak_name == self.SNIPER and weapon and self.SHOTGUNS[weapon] and headshot then
        self:UnlockForPeer(peer:id(), "shotgun_sniper")
    end

    -- sniper_duel: german sniper headshot with a pistol from a distance
    local weapon_tweak = weapon and tweak_data.weapon[weapon]
    if peer and tweak_name == self.SNIPER and weapon_tweak and weapon_tweak.category == WeaponTweakData.WEAPON_CATEGORY_PISTOL
        and headshot and mvector3.distance(attacker:position(), unit:position()) >= self.DUEL_DISTANCE then
        self:UnlockForPeer(peer:id(), "sniper_duel")
    end

    -- not_from_here: flamethrower trooper killed with a melee weapon
    if peer and tweak_name == self.FLAMER and attack_data.variant == "melee" then
        self:UnlockForPeer(peer:id(), "not_from_here")
    end

    -- flying_change: kills with SWITCH_KILLS different weapon classes within SWITCH_TIME seconds (melee is a class of its own)
    local class = attack_data and attack_data.variant == "melee" and "melee" or weapon_tweak and weapon_tweak.category
    if peer and class then
        local now = TimerManager:game():time()
        local recent = self._run.recent_kills or {}
        self._run.recent_kills = recent
        local list = recent[peer:id()] or {}
        recent[peer:id()] = list
        table.insert(list, { time = now, class = class })
        local classes, count = {}, 0
        for i = #list, 1, -1 do
            if now - list[i].time > self.SWITCH_TIME then
                table.remove(list, i)
            elseif not classes[list[i].class] then
                classes[list[i].class] = true
                count = count + 1
            end
        end
        if count >= self.SWITCH_KILLS then
            self:UnlockForPeer(peer:id(), "flying_change")
        end
    end

    -- nazi_scalps_for_aldo / a_nazi_walks_into_a_bar: HARD and up
    local counter = weapon and self.KILL_COUNTERS[weapon]
    if peer and counter and difficulty >= 3 then
        if peer:id() == managers.network:session():local_peer():id() then
            self:AddKill(weapon)
        else
            LuaNetworking:SendToPeer(peer:id(), self.PROGRESS_MSG, weapon)
        end
    end

    -- greed_killed_the_communist: both generals in STRONGPOINT killed with the gold bar on HARD
    if job.job_id == "settlement" and difficulty >= 3 and self.GENERALS[tweak_name] and weapon == "gold_bar" then
        local run = self._run
        run.gold_general_kills = (run.gold_general_kills or 0) + 1
        if run.gold_general_kills >= self.GENERALS_COUNT then
            self:UnlockForAll("greed_killed_the_communist")
        end
    end

    -- the_game_was_rigged: the officer in FULL STOP killed with the luger on HARD
    if job.job_id == "forest_bunker" and difficulty >= 3 and self.OFFICERS[tweak_name] and weapon == "georg" then
        self:UnlockForAll("the_game_was_rigged")
    end

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
        secured = {},    -- carry_id -> secured bags
        loud_first_loot = false, -- the alarm was up when the first loot was secured
        loot_secured = 0,
        barrels = 0,     -- destroyed wine barrels of FIRESTARTER, see WHINEY_ELEMENT
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
            local run = ExtraAchievs._run
            if carry_id == "gold" then
                run.gold = run.gold + 1
            end
            run.secured[carry_id] = (run.secured[carry_id] or 0) + 1
            if run.loot_secured == 0 then
                local state = managers.groupai and managers.groupai:state()
                run.loud_first_loot = state ~= nil and not state:whisper_mode()
            end
            run.loot_secured = run.loot_secured + 1
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
