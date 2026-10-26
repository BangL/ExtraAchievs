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

-- called once per finished mission (see EventCompleteState.lua)
function ExtraAchievs:CheckPickpocket(state)
    if not self:HasPickpocket() or not state._success then
        return
    end

    local job_id = state._current_job_data.job_id
    local event_index = state._current_job_data.current_event
    local is_operation = state._current_job_data.job_type == OperationsTweakData.JOB_TYPE_OPERATION

    if not state._job_memory.stealth or managers.statistics._global.session.killed.total.count ~= 0 then
        return
    end

    if not is_operation and job_id == "sto" then -- ROGUES GALLERY, with 2 gold secured
        if self._run.gold >= 2 then
            self:Unlock("pacifist_rogues_gallery_" .. state._difficulty, PACKAGE_ID)
        end
    elseif is_operation and job_id == "clear_skies" then
        if event_index == 2 then -- ENIGMATIC
            self:Unlock("pacifist_enigmatic_" .. state._difficulty, PACKAGE_ID)
        elseif event_index == 3 then -- BURNING MAN
            self:Unlock("pacifist_burning_man", PACKAGE_ID)
        end
    end
end
