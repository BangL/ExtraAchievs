-- <class>_mastery: every warcry, boost and talent of a class on its highest tier (on any character of that class).
-- Checked when a savegame slot gets loaded (all character slots, so finished characters unlock without playing them)
-- and whenever skill points are given.
ExtraAchievs = ExtraAchievs or {}

local CLASSES = { assault = true, recon = true, infiltrator = true, demolitions = true }

-- tree: SkillTreeManager's base_class_skill_tree of a character (type -> skill id -> save data)
function ExtraAchievs:IsClassMastered(tree, class)
    local organised = tree and tweak_data.skilltree:get_skills_organised(class)
    if not organised then
        return false
    end

    for _, skill_type in ipairs({ SkillTreeTweakData.TYPE_WARCRY, SkillTreeTweakData.TYPE_BOOSTS, SkillTreeTweakData.TYPE_TALENT }) do
        for skill_id in pairs(organised[skill_type]) do
            local requirements = tweak_data.skilltree.skills[skill_id].exp_requirements
            local save_skill = tree[skill_type] and tree[skill_type][skill_id]
            if not requirements or not save_skill or (save_skill.exp_tier or 0) < #requirements then
                return false
            end
        end
    end

    return true
end

function ExtraAchievs:CheckClassMastery(skilltree_data)
    local class = skilltree_data and skilltree_data.character_profile_base_class
    if CLASSES[class] and self:IsClassMastered(skilltree_data.base_class_skill_tree, class) then
        self:Unlock(class .. "_mastery")
    end
end

if SavefileManager and not ExtraAchievs._hooked_skills_save then
    ExtraAchievs._hooked_skills_save = true

    Hooks:PostHook(SavefileManager, "_load_cache", "ExtraAchievs_SavefileManager_post__load_cache", function(self)
        for slot = SavefileManager.CHARACTER_PROFILE_STARTING_SLOT, SavefileManager.CHARACTER_PROFILE_STARTING_SLOT + SavefileManager.CHARACTER_PROFILE_SLOTS_COUNT - 1 do
            local meta_data = self:_meta_data(slot)
            local cache = meta_data and meta_data.cache
            if cache and cache.SkillTreeManager then
                blt.pcall(ExtraAchievs.CheckClassMastery, ExtraAchievs, cache.SkillTreeManager)
            end
        end
    end)
end

if SkillTreeManager and not ExtraAchievs._hooked_skills_points then
    ExtraAchievs._hooked_skills_points = true

    Hooks:PostHook(SkillTreeManager, "add_skill_points", "ExtraAchievs_SkillTreeManager_post_add_skill_points", function(self)
        blt.pcall(ExtraAchievs.CheckClassMastery, ExtraAchievs, self._global)
    end)
end
