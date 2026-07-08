local WelfareConfig = {}

WelfareConfig.WelfareTypeInfos = {}
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 1, type_name = "登录礼包" , uiscript = "View.Welfare.LoginGiftUIPage"})
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 2, type_name = "等级礼包" , uiscript = "View.Welfare.LevelGiftUI"})
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 3, type_name = "每日签到" , uiscript = "View.DailySign.DailySignUI"})

--[[
    PlatinumLayer
    OfflineLayer
    OnlineGiftLayer
]]

table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 7, type_name = "在线奖励" , uiscript = "View.Welfare.OnlineAwardUI"})
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 4, type_name = "仙尊月卡" , uiscript = "View.Welfare.PlatinumUI"})
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 6, type_name = "资源找回" , uiscript = "View.Welfare.FindOfflineExp"})
--table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 5, type_name = "离线经验" , uiscript = "View.Welfare.OfflineAwardUI"})
table.insert(WelfareConfig.WelfareTypeInfos,{ type_id = 8, type_name = "奖励兑换" , uiscript = "View.Welfare.NewActiveCodeUI"})
function WelfareConfig:GetConfByTypeId(type_id)
    local n = #self.WelfareTypeInfos
    for i = 1, n do
        if type_id == self.WelfareTypeInfos[i].type_id then
            return self.WelfareTypeInfos[i]
        end
    end
end

function WelfareConfig:GetIndexByTypeId(type_id)
	-- body
	local n = #self.WelfareTypeInfos
	for i=1, n do
		if type_id == self.WelfareTypeInfos[i].type_id then
            return i
        end
	end
	return 0
end

function WelfareConfig:Init()
    if true then
        return
    end
    --登录礼包
    local loginGift = LRoleDataMgr.MyHeroInfo.m_pLoginGift
    if loginGift and loginGift.getNum and loginGift.getNum == loginGift.dayNum then
        local num = 0
        for k,v in pairs(loginGift.dayInfo) do
            if v and v.haveGet then
                num = num + 1
            end
        end
        if num == loginGift.dayNum then
            local index = self:GetIndexByTypeId(1)
            table.remove(self.WelfareTypeInfos, index)
        end
    end

    --等级礼包
    if LRoleDataMgr.MyHeroInfo.m_pLevelWard then
        local level = LRoleDataMgr.MyHeroInfo.level
        local isHave = false
        for k,v in pairs(LRoleDataMgr.MyHeroInfo.m_pLevelWard) do
            if level < v.level or (level >= v.level and v.canBuy) then
                isHave = true
                break
            end
        end
        if not isHave then
            local index = self:GetIndexByTypeId(2)
            table.remove(self.WelfareTypeInfos, index)
        end
    end
end

return WelfareConfig