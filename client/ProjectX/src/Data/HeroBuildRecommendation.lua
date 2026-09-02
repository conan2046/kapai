-- Read-only equipment guidance. Never changes skill branches, equipment or saves.
local M = {}
M.profiles = require("ConfigData.hero_build_profile_dat")

local function contains(values, value)
    for _, candidate in ipairs(values or {}) do
        if candidate == value then return true end
    end
    return false
end

function M.Score(profile, key)
    if not profile or not key or key == "" then return 0 end
    if contains(profile.core_affixes, key) then return 100 end
    local tag = string.match(key, "^([A-Z]+)%-")
    return tag and contains(profile.support_tags, tag) and 60 or 0
end

function M.Rank(key)
    local result = {}
    for _, profile in ipairs(M.profiles) do
        if M.Score(profile, key) > 0 then table.insert(result, profile) end
    end
    table.sort(result, function(a, b)
        local sa, sb = M.Score(a, key), M.Score(b, key)
        return sa > sb or (sa == sb and a.id < b.id)
    end)
    return result
end

local function matchText(profile, key)
    local score = M.Score(profile, key)
    local label = score == 100 and "核心" or (score == 60 and "兼容" or "不匹配")
    return string.format("%d/100（%s）", score, label)
end

function M.Describe(heroId, key)
    if not key or key == "" then return "尚无特殊词条，无法计算匹配度。" end
    local lines = {}
    if (heroId or 0) > 0 then
        local profiles = {}
        for _, profile in ipairs(M.profiles) do
            if profile.hero_id == heroId then table.insert(profiles, profile) end
        end
        table.sort(profiles, function(a, b) return a.id < b.id end)
        if #profiles == 0 then return "该神将尚未配置首批 A/B 配装参考。" end
        table.insert(lines, "配装参考：" .. profiles[1].hero_name .. "（不切换技能）")
        for _, profile in ipairs(profiles) do
            table.insert(lines, profile.branch .. "·" .. profile.name .. "：" .. matchText(profile, key))
            table.insert(lines, "建议：" .. profile.strategy_hint)
        end
    else
        local profiles = M.Rank(key)
        if #profiles == 0 then return "暂无首批构筑匹配，可参考通用流派说明。" end
        table.insert(lines, "适配推荐（配装参考，不切换技能）")
        for i = 1, math.min(3, #profiles) do
            local profile = profiles[i]
            table.insert(lines, profile.hero_name .. "·" .. profile.name .. "：" .. matchText(profile, key))
        end
    end
    table.insert(lines, "仅评单件词条；不计战力、Tier与套装。")
    return table.concat(lines, "\n")
end

return M
