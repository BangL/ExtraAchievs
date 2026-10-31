-- Optional support for "Pickpocket mission equipment": its pacifist achievements live in their own package, which only
-- exists (and can only be earned) while that mod is installed and loaded.
ExtraAchievs = ExtraAchievs or {}

local PICKPOCKET_MOD = "Pickpocket mission equipment"
local PACKAGE_ID = "extra_achievements_pickpocket"

-- rank (1 bronze - 4 platinum) and gold reward per game difficulty; ENIGMATIC is an operation day, so a step harder
local ROGUES_GALLERY = { { 1, 10 }, { 1, 25 }, { 2, 50 }, { 3, 75 } }
local ENIGMATIC = { { 1, 25 }, { 2, 50 }, { 3, 75 }, { 4, 100 } }

local ACHIEVEMENTS = {}
for i, v in ipairs(ROGUES_GALLERY) do
    table.insert(ACHIEVEMENTS, { id = "pacifist_rogues_gallery_difficulty_" .. i, rank = v[1], reward_type = "gold", reward_amount = v[2] })
end
for i, v in ipairs(ENIGMATIC) do
    table.insert(ACHIEVEMENTS, { id = "pacifist_enigmatic_difficulty_" .. i, rank = v[1], reward_type = "gold", reward_amount = v[2] })
end
table.insert(ACHIEVEMENTS, { id = "pacifist_burning_man", rank = 4, reward_type = "gold", reward_amount = 150 })

local PREFIXES = { pacifist_rogues_gallery = true, pacifist_enigmatic = true, pacifist_burning_man = true }

local FREE_PLAY_DAYS = {
    clear_skies_gold_rush = 2,
    clear_skies_mini_raid_2_park = 3,
    clear_skies_mini_raid_2_destroyed = 3,
}

-- the original mod only ships a legacy mod.xml, which BeardLib loads in compat mode (SuperBLT doesn't know it)
function ExtraAchievs:HasPickpocket()
    return BeardLib.Frameworks.Base._loaded_mods[PICKPOCKET_MOD] ~= nil
end

-- registered once tweak_data exists, as package of its own (not in main.xml, so it's absent without the mod)
if not ExtraAchievs._hooked_pickpocket_tweak then
    ExtraAchievs._hooked_pickpocket_tweak = true

    Hooks:Add("SetupInitManagers", "ExtraAchievs_pickpocket_achievements", function()
        local achievement_data = tweak_data.achievement
        if not achievement_data.custom_achievements or not ExtraAchievs:HasPickpocket() then
            return
        end

        local package = {}
        achievement_data.custom_achievements[PACKAGE_ID] = package
        achievement_data.custom_achievements_packages[PACKAGE_ID] = {
            id = PACKAGE_ID,
            icon = "guis/textures/achievement_package_default",
            name = PACKAGE_ID .. "_name",
        }

        for _, config in ipairs(ACHIEVEMENTS) do
            local id = config.id
            package[id] = {
                id = id,
                name_id = id .. "_name",
                desc_id = id .. "_desc",
                obj_id = id .. "_objective",
                icon = "guis/textures/achievement_trophy_white",
                rank = config.rank,
                amount = 0,
                reward_type = config.reward_type,
                reward_amount = config.reward_amount,
                hidden_achievement = false,
            }
        end
        BeardLib.Managers.Achievement:SetupAchievements() -- create progress files
    end)
end

-- a higher difficulty also unlocks all lower ones ("difficulty_3" -> difficulty_1..3)
function ExtraAchievs:UnlockUpTo(prefix, difficulty)
    for i = 1, tonumber(tostring(difficulty):match("%d+")) or 0 do
        self:Unlock(prefix .. "_difficulty_" .. i, PACKAGE_ID)
    end
end

local RAID_NAMES = { rogues_gallery = "ROGUES GALLERY", enigmatic = "ENIGMATIC", burning_man = "BURNING MAN" }

-- which pacifist achievement set the current mission belongs to (same rules as CheckPickpocket)
function ExtraAchievs:PickpocketTarget()
    local job = managers.raid_job:current_job()
    if not job then
        return nil
    end
    local is_operation = job.job_type == OperationsTweakData.JOB_TYPE_OPERATION
    if not is_operation and job.job_id == "sto" then
        return "rogues_gallery"
    end
    local day = is_operation and job.job_id == "clear_skies" and job.current_event or FREE_PLAY_DAYS[job.job_id]
    return day == 2 and "enigmatic" or day == 3 and "burning_man" or nil
end

function ExtraAchievs:ShowPickpocketFail(target, reason)
    if not RAID_NAMES[target] or (reason ~= "kill" and reason ~= "alarm") then
        return
    end
    local loc = managers.localization
    managers.notification:add_notification({
        id = "extra_achievs_pacifist_failed",
        duration = 6,
        shelf_life = 8,
        text = loc:text("extra_achievs_pacifist_failed"):format(RAID_NAMES[target], loc:text("extra_achievs_pacifist_failed_" .. reason)),
    })
end

-- the host judges the Pickpocket achievements. A client only does so itself if the host doesn't (no hello received),
-- and only if it saw the mission start, otherwise it missed gold and kills.
function ExtraAchievs:JudgesPickpocket()
    if Network:is_server() then
        return true
    end
    local session = managers.network:session()
    return self._run.started == session and self._hello_session ~= session
end

-- the first enemy death or the alarm ends the pacifist run, everyone gets a toast (once per mission)
function ExtraAchievs:FailPickpocket(reason)
    if not self:JudgesPickpocket() or self._run.pacifist_failed or not self:HasPickpocket() then
        return
    end
    local target = self:PickpocketTarget()
    if not target or self._run.ended then -- end scripts may still flip the whisper state
        return
    end
    self._run.pacifist_failed = true
    self:ShowPickpocketFail(target, reason)
    if Network:is_server() and LuaNetworking:IsMultiplayer() then
        LuaNetworking:SendToPeers(self.PICKPOCKET_FAIL_MSG, target .. ":" .. reason)
    end
end

function ExtraAchievs:ApplyPickpocket(prefix, difficulty)
    if difficulty then
        self:UnlockUpTo(prefix, difficulty)
    else
        self:Unlock(prefix, PACKAGE_ID)
    end
end

-- the host decides (it sees every kill and the secured loot, a client that joined late doesn't) and tells the clients
if not ExtraAchievs._hooked_pickpocket_network then
    ExtraAchievs._hooked_pickpocket_network = true

    Hooks:Add("NetworkReceivedData", "ExtraAchievs_pickpocket_fail_NetworkReceivedData", function(sender, id, data)
        if id ~= ExtraAchievs.PICKPOCKET_FAIL_MSG or Network:is_server() or not ExtraAchievs:HasPickpocket() then
            return
        end
        local target, reason = tostring(data):match("^([%w_]+):(%a+)$")
        if target and ExtraAchievs:IsHost(sender) then
            ExtraAchievs:ShowPickpocketFail(target, reason)
        end
    end)

    Hooks:Add("NetworkReceivedData", "ExtraAchievs_pickpocket_NetworkReceivedData", function(sender, id, data)
        if id ~= ExtraAchievs.PICKPOCKET_MSG or Network:is_server() or not ExtraAchievs:HasPickpocket() then
            return
        end
        local prefix, difficulty = tostring(data):match("^([%w_]+):(%d*)$")
        if prefix and PREFIXES[prefix] and ExtraAchievs:IsHost(sender) then
            ExtraAchievs:ApplyPickpocket(prefix, tonumber(difficulty))
        end
    end)
end

-- called once per finished mission (see EventCompleteState.lua)
function ExtraAchievs:CheckPickpocket(state)
    if not self:JudgesPickpocket() or not self:HasPickpocket() or not state._success then
        return
    end

    local job_id = state._current_job_data.job_id
    local event_index = state._current_job_data.current_event
    local is_operation = state._current_job_data.job_type == OperationsTweakData.JOB_TYPE_OPERATION

    if not state._job_memory.stealth or managers.statistics._global.session.killed.total.count ~= 0
        or self._run.kills ~= 0 then
        return
    end

    local prefix, difficulty
    if not is_operation and job_id == "sto" then -- ROGUES GALLERY, with 2 gold secured
        if self._run.gold >= 2 then
            prefix, difficulty = "pacifist_rogues_gallery", tonumber(tostring(state._difficulty):match("%d+")) or 0
        end
    else
        -- free play runs a single operation event as a plain raid, with the event's mission_id as job_id
        local day = is_operation and job_id == "clear_skies" and event_index or FREE_PLAY_DAYS[job_id]
        if day == 2 then -- ENIGMATIC
            prefix, difficulty = "pacifist_enigmatic", tonumber(tostring(state._difficulty):match("%d+")) or 0
        elseif day == 3 then -- BURNING MAN
            prefix = "pacifist_burning_man"
        end
    end

    if prefix then
        self:ApplyPickpocket(prefix, difficulty)
        if Network:is_server() and LuaNetworking:IsMultiplayer() then
            LuaNetworking:SendToPeers(self.PICKPOCKET_MSG, prefix .. ":" .. (difficulty or ""))
        end
    end
end
