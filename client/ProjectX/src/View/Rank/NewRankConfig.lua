local NewRankConfig = {}
NewRankConfig.Types = {
    ["DengJi"] = 1,
    ["ZhanLi"] = 2,
    ["MeiLi"] = 3,
    ["CaiFu"] = 4,
    ["ShenJiang"] = 5,
    ["BangHui"] = 6,
    ["HuoDong"] = 7,
    ["LiLianTa"] = 8,
    ["XiuXianLiLian"] = 9,
}


NewRankConfig.RankTypeInfos = {}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.DengJi] = {name="等级排行", titles = {"排行","名称","职业","等级"}, opid = 1}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.ZhanLi] = {name="战力排行", titles = {"排行","名称","职业","战斗力"}, opid = 2}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.MeiLi] = {name="魅力排行", titles = {"排行","名称","魅力值","称号"}, opid = 6}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.CaiFu] = {name="财富排行", titles = {"排行","名称","职业","金币"}, opid = 3}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.ShenJiang] = {name="神将排行", titles = {"排行","玩家名称","神将名称","战斗力"}, opid = 4}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.BangHui] = {name="帮会排行", titles = {"排行","帮会名称","帮主","帮会等级"}, opid = 5}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.HuoDong] = {name="活动排行", titles = {"排行","名称","职业","活动内容"}, opid = 6}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.LiLianTa] = {name="历练塔", titles = {"排行","名称","职业","最高通关层数"},   opid = 21}
NewRankConfig.RankTypeInfos[NewRankConfig.Types.XiuXianLiLian] = {name="修仙历练", titles = {"排行","名称","职业","每日通关章节"}, opid = 22}

function NewRankConfig:GetRankConfigByTypeId(id)
    if id == nil then
        return nil
    end
    local ret = NewRankConfig.RankTypeInfos[id]
    if ret ~= nil then
        return ret
    end
    for k,v in pairs(NewRankConfig.RankTypeInfos) do
        return v
    end
    return nil
end

return NewRankConfig










