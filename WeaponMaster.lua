-- One achievement per weapon: all of its weapon challenges completed. The package is checked on the main menu (covers challenges finished before the mod was
-- installed) and whenever a weapon challenge is completed.
ExtraAchievs = ExtraAchievs or {}

local PACKAGE_ID = "extra_achievements_weapons"
local ID_PREFIX = "weapon_master_"

local function achievement_id(weapon_id)
    return ID_PREFIX .. weapon_id
end

-- fixed list of vanilla weapons (skin mods may add weapons or rename existing ones); the names are always the vanilla
-- "bm_w_<id>" strings. garand_golden is left out: it shares the M1 Garand.
local WEAPONS = {
    "bren", "browning", "c96", "carbine", "dp28", "garand", "geco", "georg", "ithaca", "kar_98k", "lee_enfield", "m1903",
    "m1911", "m1912", "m1918", "mg42", "mosin", "mp38", "mp44", "shotty", "sten", "sterling", "thompson", "tt33", "webley",
    "welrod",
}
local WEAPON_SET = {}
for _, weapon_id in ipairs(WEAPONS) do
    WEAPON_SET[weapon_id] = true
end

-- rank (1 bronze - 3 gold) and gold reward by the number of upgrade tiers of the weapon (2 to 4)
local TIER_REWARDS = { [2] = { 1, 50 }, [3] = { 2, 75 }, [4] = { 3, 100 } }

local function weapon_ids()
    local ids = {}
    for _, weapon_id in ipairs(WEAPONS) do
        if tweak_data.weapon_skills.skill_trees[weapon_id] then
            table.insert(ids, weapon_id)
        end
    end
    return ids
end

if not ExtraAchievs._hooked_weapon_tweak then
    ExtraAchievs._hooked_weapon_tweak = true

    Hooks:Add("SetupInitManagers", "ExtraAchievs_weapon_achievements", function()
        local achievement_data = tweak_data.achievement
        if not achievement_data.custom_achievements then
            return
        end

        local package = {}
        achievement_data.custom_achievements[PACKAGE_ID] = package
        achievement_data.custom_achievements_packages[PACKAGE_ID] = {
            id = PACKAGE_ID,
            icon = "guis/textures/achievement_package_default",
            name = PACKAGE_ID .. "_name",
        }

        for _, weapon_id in ipairs(weapon_ids()) do
            local id = achievement_id(weapon_id)
            local reward = TIER_REWARDS[#tweak_data.weapon_skills.skill_trees[weapon_id]] or TIER_REWARDS[2]
            package[id] = {
                id = id,
                name_id = id .. "_name",
                desc_id = id .. "_desc",
                obj_id = id .. "_objective",
                icon = "guis/textures/achievement_trophy_white",
                rank = reward[1],
                amount = 0,
                reward_type = "gold",
                reward_amount = reward[2],
                hidden_achievement = false,
            }
        end
        BeardLib.Managers.Achievement:SetupAchievements() -- create progress files
    end)
end

-- names come from the game (weapon names), templates from the loc file
if LocalizationManager and not ExtraAchievs._hooked_weapon_loc then
    ExtraAchievs._hooked_weapon_loc = true

    local text_original = LocalizationManager.text

    function LocalizationManager:text(string_id, macros)
        local weapon_id, kind = tostring(string_id):match("^" .. ID_PREFIX .. "(.+)_(%a+)$")
        if weapon_id and WEAPON_SET[weapon_id] and (kind == "name" or kind == "desc" or kind == "objective") then
            local weapon_name = text_original(self, "bm_w_" .. weapon_id)
            return text_original(self, "extra_achievs_weapon_master_" .. (kind == "name" and "name" or "desc")):format(weapon_name)
        end
        return text_original(self, string_id, macros)
    end
end

function ExtraAchievs:IsWeaponMastered(weapon_id)
    local tree = Global.weapon_skills_manager and Global.weapon_skills_manager.weapon_skills_skill_tree[weapon_id]
    if not tree then
        return false
    end
    local count = 0
    for _, tier in ipairs(tree) do
        for _, skill in pairs(tier) do
            local challenge_id = skill[1] and skill[1].challenge_id
            local challenge = challenge_id and managers.challenge:get_challenge(ChallengeManager.CATEGORY_WEAPON_UPGRADE, challenge_id)
            if challenge then
                if not challenge:completed() then
                    return false
                end
                count = count + 1
            end
        end
    end
    return count > 0
end

-- weapon_id: only this weapon, otherwise all
function ExtraAchievs:CheckWeaponMaster(weapon_id)
    if not managers.challenge or not tweak_data.achievement.custom_achievements[PACKAGE_ID] then
        return
    end
    for _, id in ipairs(weapon_id and { weapon_id } or weapon_ids()) do
        if self:IsWeaponMastered(id) then
            self:Unlock(achievement_id(id), PACKAGE_ID)
        end
    end
end

if WeaponSkillsManager and not ExtraAchievs._hooked_weapon_skills then
    ExtraAchievs._hooked_weapon_skills = true

    Hooks:PostHook(WeaponSkillsManager, "on_weapon_challenge_completed", "ExtraAchievs_WeaponSkillsManager_post_on_weapon_challenge_completed",
        function(self, weapon_id)
            if WEAPON_SET[weapon_id] then
                ExtraAchievs:CheckWeaponMaster(weapon_id)
            end
        end
    )
end

if not ExtraAchievs._hooked_weapon_menu then
    ExtraAchievs._hooked_weapon_menu = true

    Hooks:Add("MenuManagerOnOpenMenu", "ExtraAchievs_weapon_MenuManagerOnOpenMenu", function(_, menu_name)
        if menu_name == "menu_main" then
            ExtraAchievs:CheckWeaponMaster()
        end
    end)
end
