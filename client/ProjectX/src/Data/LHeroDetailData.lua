LLianTiInfo = {}
LLianTiInfo.__index = LLianTiInfo
function LLianTiInfo:New()
	local o = {}
	setmetatable(o,LLianTiInfo)	
	o:ctor()
	return o
end

function LLianTiInfo:ctor()
	self.level = 0
	self.expVal = 0
end

function LLianTiInfo:Reset()
	self.level = 0
	self.expVal = 0
end

function LLianTiInfo:Delete()
	self.level = nil
	self.expVal = nil
end

LPetKaiJiaInfo = {}
LPetKaiJiaInfo.__index = LPetKaiJiaInfo
function LPetKaiJiaInfo:New()
	local o = {}
	setmetatable(o,LPetKaiJiaInfo)	
	o:ctor()
	return o
end

function LPetKaiJiaInfo:ctor()
	self.jie = 0
	self.xing = 0
	self.useMoney = 0
    self.type = 0
    self.zhandouli = 0
    self.val = 0
	self.diaadd = 0 --宝石加成
end

function LPetKaiJiaInfo:Reset()
	self.jie = 0
	self.xing = 0
	self.useMoney = 0
    self.type = 0
    self.zhandouli = 0
    self.val = 0
	self.diaadd = 0 --宝石加成
end

function LPetKaiJiaInfo:Delete()
	self.jie = nil
	self.xing = nil
	self.useMoney = nil
    self.type = nil
    self.zhandouli = nil
    self.val = nil
	self.diaadd = nil --宝石加成
end

--[[
玩家详细属性
]]
LHeroDetailData = {}
LHeroDetailData.__index = LHeroDetailData
function LHeroDetailData:New()
	local o = {}
	setmetatable(o,LHeroDetailData)	
	o:ctor()
	return o
end

function LHeroDetailData:ctor()
	self.exp = 0--经验
	self.attrs = {}
	--练体
	self.lianti = {
		LLianTiInfo:New(),
		LLianTiInfo:New(),
		LLianTiInfo:New(),
		LLianTiInfo:New(),
		LLianTiInfo:New(),
		LLianTiInfo:New()
	}
	self.hp = 0                             --气血
	self.potential = 0                      --潜能
	self.shenHun = 0                      --神魂
	self.gongName = ""                    --帮派名字
    self.BindMoney = 0                      --绑定金币
    self.Money = 0                          --金币
    self.BindTongBao = 0                   --绑定元宝
    self.TongBao = 0                        --元宝
	self.CompeteScore = 0                   --竞技积分
	self.xinXiuJingHua = 0				    --新宿精华（血战货币）
	self.ZaDanScore = 0				        --砸蛋积分
	self.tili = 0                       --体力
	self.arenaSorce = 0					--竞技场积分
	self.kunlunMoney = 0				--昆仑币
	self.huoYue = 0						--活跃
	self.ShengLing = 0                 --圣灵凭证
	self.TurntableScore = 0            --转盘积分
	-- self.m_PetKaiJia = {
	-- 	{LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New()},
	-- 	{LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New()},
	-- 	{LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New()},
	-- 	{LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New(),LPetKaiJiaInfo:New()}
	-- }
end

function LHeroDetailData:Reset()
	self.exp = 0--经验
	self.attrs = {}
	--练体
	for i = 1, #self.lianti do
		self.lianti[i]:Reset()
	end
	
	self.hp = 0                             --气血
	self.potential = 0                      --潜能
	self.gongName = ""                    --帮派名字
    self.BindMoney = 0                      --绑定金币
    self.Money = 0                          --金币
    self.tili = 0                         --体力
    self.BindTongBao = 0                   --绑定元宝
    self.TongBao = 0                        --元宝
	self.CompeteScore = 0                   --竞技积分
	self.ZaDanScore = 0				        --砸蛋积分
	-- for i = 1, #self.m_PetKaiJia do
	-- 	self.m_PetKaiJia[i]:Reset()
	-- end
end

function LHeroDetailData:Delete()
	self.exp = nil--经验
	self.attrs = nil
	self.strength = nil--体质
	self.power = nil                         --力量
	self.agile = nil                          --敏捷
	self.psychic = nil                        --灵力
	self.endurance = nil                      --耐力

	--练体
	for i = 1, 6 do
		self.lianti[i]:Delete()
		self.lianti[i] = nil
	end
	self.lianti = nil
	
	self.hp = nil                             --气血
    self.hpMax = nil                          --气血最大值
	self.tili = nil                           --体力
	self.ad = nil                             --物理攻击
	self.ap = nil                             --法术攻击
	self.speed = nil                          --攻击速度
	self.def = nil                            --防御

	self.hit = nil                            --命中
	self.avoid = nil                         --闪避
	self.crit = nil                           --暴击
	self.beatBack = nil                       --反击
	self.combo = nil                          --连击
	self.hurtBack = nil                       --反伤
	self.cutHurt = nil                        --减伤
	self.parry = nil                          --招架
	self.block = nil                          --格挡
	self.tenacity = nil                       --韧性
	self.adCrit = nil                         --物理暴击	
	self.adBeatBack = nil                     --物理反伤
	self.apBeatBack = nil                     --法术反伤
	self.apCrit = nil                         --法暴击
	
	self.potential = nil                      --潜能
	--self.daohang = nil                        --道行
	--self.gong = nil                           --门派
	self.gongName = nil                    --帮派名字
	--self.pkVal = nil                          --PK值
	--self.prestige = nil                       --声望

	--self.chat_Time = nil
	--self.admin = nil
	--self.openPackage = nil
	--self.clothesState = nil                   --服装状态(暂未用)

    self.BindMoney = nil                      --绑定金币
    self.Money = nil                          --金币
    self.BindTongBao = nil                   --绑定元宝
    self.TongBao = nil                        --元宝
	self.CompeteScore = nil                   --竞技积分
	self.ZaDanScore = nil				        --砸蛋积分

	-- for i = 1, 5 do
	-- 	for j = 1, 4 do
	-- 		self.m_PetKaiJia[i][j]:Delete()
	-- 		self.m_PetKaiJia[i][j] = nil
	-- 	end
	-- 	self.m_PetKaiJia[i] = nil
	-- end
	-- self.m_PetKaiJia = nil
end

function LHeroDetailData:setBindMoney(val)
	if val == nil then
		return
	end
	if self.BindMoney ~= val then
		self.BindMoney = val
		Utils:SendMsg(LUIRoleDataChangeEvent.BindMoneyChanged)
	end
end

function LHeroDetailData:setMoney(val)
	if val == nil then
		return
	end
	if self.Money ~= val then
		self.Money = val
		Utils:SendMsg(LUIRoleDataChangeEvent.MoneyChanged)
	end
end

function LHeroDetailData:setTili(val)
	if val == nil then
		return
	end
	if self.tili ~= val then
		self.tili = val
		Utils:SendMsg(LUIRoleDataChangeEvent.TiliChanged)
	end
end

function LHeroDetailData:setBindTongBao(val)
	if val == nil then
		return
	end
	if self.BindTongBao ~= val then
		self.BindTongBao = val
		Utils:SendMsg(LUIRoleDataChangeEvent.BindTongBaoChanged)
	end
end

function LHeroDetailData:setTongBao(val)
	if val == nil then
		return
	end
	if self.TongBao ~= val then
		self.TongBao = val
        Utils:SendMsg(LUIRoleDataChangeEvent.TongBaoChanged)
	end
end

function LHeroDetailData:setCompeteScore(val)
	if val == nil then
		return
	end
	if self.CompeteScore ~= val then
		self.CompeteScore = val
		Utils:SendMsg(LUIRoleDataChangeEvent.CompeteScoreChanged)
	end
end

function LHeroDetailData:setPotential(val)
	if val == nil then
		return
	end
	if self.potential ~= val then
		self.potential = val
        Utils:SendMsg(LUIRoleDataChangeEvent.PotentialChanged)
	end
end

function LHeroDetailData:setShenHun(val)
	--print("LHeroDetailData:setShenHun ===>", val)
	if val == nil then
		return
	end
	if self.shenHun ~= val then
		self.shenHun = val
        Utils:SendMsg(LUIRoleDataChangeEvent.ShenHunChanged)
	end
end

function LHeroDetailData:setXinXiuJingHua(val)
	-- body
	if val == nil then
		return
	end

	if self.xinXiuJingHua ~= val then
		self.xinXiuJingHua = val
		Utils:SendMsg(LUIRoleDataChangeEvent.XinXiuJingHuaChanged)
	end
end

function LHeroDetailData:setArenaSorce(val)
	-- body
	if val == nil then
		return
	end
	--print("LHeroDetailData:setArenaSorce ===>", val)
	if self.arenaSorce ~= val then
		self.arenaSorce = val
		Utils:SendMsg(LUIRoleDataChangeEvent.ArenaSorceChanged)
	end
end

function LHeroDetailData:setKunlunMoney(val)
	-- body
	if val == nil then
		return
	end
	if self.kunlunMoney ~= val then
		self.kunlunMoney = val
		Utils:SendMsg(LUIRoleDataChangeEvent.KunlunMoneyChanged)
	end
end

function LHeroDetailData:setShengLing(val)
	-- body
	if val == nil then
		return
	end
	if self.ShengLing ~= val then
		self.ShengLing = val
		Utils:SendMsg(LUIRoleDataChangeEvent.ShengLingChanged)
	end
end

function LHeroDetailData:setTurntableScore(val)
	-- body
	if val == nil then
		return
	end
	if self.TurntableScore ~= val then
		self.TurntableScore = val
		Utils:SendMsg(LUIRoleDataChangeEvent.TurntableScoreChanged)
	end
end


function LHeroDetailData:setZaDanScore(val)
	-- body
	if val == nil then
		return
	end

	if self.ZaDanScore ~= val then
		self.ZaDanScore = val
		Utils:SendMsg(LUIRoleDataChangeEvent.ZaDanJiFenChanged)
	end
end

function LHeroDetailData:setHuoYue(val)
	-- body
	if val == nil then
		return
	end
	if self.huoYue ~= val then
		self.huoYue = val
		Utils:SendMsg(LUIRoleDataChangeEvent.HuoYueChanged)
	end
end

--绑定非绑定统一处理
function LHeroDetailData:getMoney()
	return self.Money
end

function LHeroDetailData:getTili()
	-- body
	return self.tili
end

function LHeroDetailData:GetTongBao()
	return self.TongBao
end

function LHeroDetailData:GetBindTongBao()
	return self.BindTongBao
end

function LHeroDetailData:GetXinXiuJingHua()
	return self.xinXiuJingHua
end

function LHeroDetailData:GetArenaSorce()
	return self.arenaSorce
end

function LHeroDetailData:GetKunLunMoney()
	return self.kunlunMoney
end

function LHeroDetailData:GetHuoYue()
	return self.huoYue
end

function LHeroDetailData:GetShengLing()
	return self.ShengLing
end

function LHeroDetailData:GetTurntableScore() 
	return self.TurntableScore
end

function LHeroDetailData:SkillCheckCost(type, value, noTips)
	if type == AppDef.AwrdItem.AWRD_ITEM_COIN then -- 金币
		if self:getMoney() < value then
        	if noTips then return false end
			---Utils:ShowScrollTips(GUITips.RSI_Skill_Level_Err_Money)
				Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return false
		end
	elseif type == AppDef.AwrdItem.AWRD_ITEM_POTEN then -- 潜能
		if self.potential < value then
        	if noTips then return false end
			Utils:ShowScrollTips(GUITips.RSI_Skill_Level_Err_Potential)
			return false
		end
	elseif type == AppDef.AwrdItem.AWRD_ITEM_BDYB then -- 绑定元宝
	end
	return true
end