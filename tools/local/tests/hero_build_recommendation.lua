-- Run from the repository root. Output is retained in .local by the PS runner.
package.path = "client/ProjectX/src/?.lua;" .. package.path
local recommendation = require("Data.HeroBuildRecommendation")
local tags = {"SHIELD", "HEAL", "GUARD", "COUNTER", "CRIT", "COMBO", "BREAK", "CONTROL", "DOT", "DEBUFF", "DEATH", "TACTIC"}
local keys = {}
for _, tag in ipairs(tags) do
    for index = 1, 4 do table.insert(keys, string.format("%s-%02d", tag, index)) end
end
for _, key in ipairs({"", "NOPE-01", "heal-01", "HEAL"}) do table.insert(keys, key) end
local heroIds = {0, 10, 11, 12, 13, 14, 15, 16, 17, 23, 31, 34, 60, 999}
assert(recommendation.Score(nil, "HEAL-01") == 0)
assert(recommendation.Score(recommendation.profiles[1], nil) == 0)
assert(loadfile("client/ProjectX/src/View/PetEquip/EquipInfoUI.lua"))

-- Exercise the real UI context method with lightweight widgets, not a game window.
LUIBase = { New = function() return {} end }
cc = { size = function(w, h) return {width = w, height = h} end,
    p = function(x, y) return {x = x, y = y} end }
LRoleDataMgr = { Pet = { ShowPosList = {[1] = 10},
    GetPetByFightPos = function() error("First-hero fallback must not be used") end } }
local EquipInfoUI = dofile("client/ProjectX/src/View/PetEquip/EquipInfoUI.lua")
local node = { setVisible = function(self, value) self.visible = value end,
    setContentSize = function(self, value) self.size = value end }
local label = { setString = function(self, value) self.text = value end,
    getVirtualRendererSize = function() return {height = 120} end,
    setPosition = function() end }
local ui = setmetatable({m_heroPos = 0, m_fpos = 1,
    m_info = {specialAffixId = 5, specialAffixKey = "HEAL-01"},
    m_buildRecommendationNode = node, m_buildRecommendationLabel = label,
    m_listView = {forceDoLayout = function() end}}, EquipInfoUI)
ui:RefreshBuildRecommendation()
assert(label.text:find("配装参考：女娲娘娘", 1, true) == 1 and node.visible)
ui.m_fpos = 2
ui:RefreshBuildRecommendation()
assert(label.text:find("适配推荐", 1, true) == 1)
ui.m_fpos, ui.m_heroPos = 1, 2
ui:RefreshBuildRecommendation()
assert(label.text:find("适配推荐", 1, true) == 1)
ui.m_info = nil
ui:RefreshBuildRecommendation()
assert(not node.visible and node.size.height == 0)
ui.m_cfgData, ui.m_descLabel = {des = "模板预览"}, label
ui:RefreshAffixDescription()
assert(label.text == "模板预览")

for _, profile in ipairs(recommendation.profiles) do
    print(table.concat({"P", profile.id, profile.hero_id, profile.hero_name, profile.branch,
        profile.name, table.concat(profile.core_affixes, ","), table.concat(profile.support_tags, ","), profile.strategy_hint}, "\t"))
    for _, key in ipairs(keys) do
        print(table.concat({"S", profile.id, key, recommendation.Score(profile, key)}, "\t"))
    end
end
for _, key in ipairs(keys) do
    local ids = {}
    for _, profile in ipairs(recommendation.Rank(key)) do table.insert(ids, profile.id) end
    print("R\t" .. key .. "\t" .. table.concat(ids, ","))
    for _, heroId in ipairs(heroIds) do
        local text = recommendation.Describe(heroId, key):gsub("\n", "\\n")
        print("D\t" .. heroId .. "\t" .. key .. "\t" .. text)
    end
end
