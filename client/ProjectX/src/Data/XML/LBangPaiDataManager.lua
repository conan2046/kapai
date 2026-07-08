--[[
lua里面的游戏逻辑控制
]]

LBangPaiDataManager = LDataBase:New()
LBangPaiDataManager.__index = LBangPaiDataManager
function LBangPaiDataManager:New()
	local o = LUIBase:New()
	setmetatable(o,LBangPaiDataManager)	
	o:Awake()
	return o
end

function LBangPaiDataManager:Awake()
	self.m_bIsLoaded = false
	self.m_pBangPaiBuff = {}--帮派数据
	self.m_pBangPaiCostBuff = {}--帮派修炼升级消耗数据
	self.m_pBangPaiDonateBuff = {}--帮派捐献数据
	self.m_pBangPaiWarBuff = {}--帮派战斗数据
end


function LBangPaiDataManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LBangPaiDataManager:Instance()
	if self.m_bIsLoaded == false then
		self.m_bIsLoaded = true
		self:ReadBangPaiData()
		self:ReadBangPaiCostData()
		self:ReadBangPaiDonateData()
		self:ReadBangPaiWarData()
	end
	return self
end

--[[
获取帮派不同等级对应相关数据
]]
function LBangPaiDataManager:GetBangPaiLevelByLevel(Level)
	return self.m_pBangPaiBuff[Level]
end

function LBangPaiDataManager:GetActionIsVisible(level,action,office)
	local bangpaiLevel = self.m_pBangPaiBuff[level]
	if bangpaiLevel.m_rigrt[office] == nil then
		return false
	end
	for i=1,bangpaiLevel.m_rigrt[office].m_rigrtNum do
		if bangpaiLevel.m_rigrt[office].m_rigrt[i] == action then
			return true
		end
	end
	return false
end

--[[
读取帮派数据
]]
function LBangPaiDataManager:ReadBangPaiData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/ganglevel.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for m = 1, #rec do
		local v = rec[m]
		local BangPaiLevel = {}
		BangPaiLevel.m_level = tonumber(v["@Level"])
		BangPaiLevel.m_num = tonumber(v["@MemberMax"])
		local officeList = string.split(v["@OfficeNumber"], "|")
		BangPaiLevel.m_officeNumber = {}
		for i=1, #officeList do
			BangPaiLevel.m_officeNumber[i] = tonumber(officeList[i])
		end
		BangPaiLevel.m_rigrt = {}
		local RigrtList = string.split(v["@Rigrt"], "|")
		for i=1, #RigrtList do
			local bangPaiOfficeRigrt = {}
			local tempList = string.split(RigrtList[i], "-")
			bangPaiOfficeRigrt.m_rigrtNum = #tempList
			bangPaiOfficeRigrt.m_rigrt = {}
			for j=1,#tempList do
				bangPaiOfficeRigrt.m_rigrt[j] = tonumber(tempList[j])
			end
			table.insert(BangPaiLevel.m_rigrt,bangPaiOfficeRigrt)
		end
		BangPaiLevel.m_dayCost = tonumber(v["@DayconCost"])
		BangPaiLevel.m_levelUpMoney = tonumber(v["@LevelupCost"])
		BangPaiLevel.m_constructMin = tonumber(v["@ConstructMin"])
		BangPaiLevel.m_constructMax = tonumber(v["@ConstructMax"])

		local arraySalary = string.split(v["@DailyWages"], "|")
		BangPaiLevel.m_salary = {}
		BangPaiLevel.m_salaryType = {}
		for i=1,#arraySalary do
			local tempList = string.split(arraySalary[i], "-")
			BangPaiLevel.m_salary[i] = tonumber(tempList[1])
			BangPaiLevel.m_salaryType[i] = tonumber(tempList[2])
		end
		self.m_pBangPaiBuff[BangPaiLevel.m_level] = BangPaiLevel
	end
end

--[[
读取帮派升级消耗数据
]]
function LBangPaiDataManager:ReadBangPaiCostData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/drillCost.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	local index = 0
	for m = 1, #rec do
		local v = rec[m]
		local BangPaiXiuLianCost = {}
		BangPaiXiuLianCost.m_level = tonumber(v["@Level"])
		BangPaiXiuLianCost.m_costTongQian = tonumber(v["@MoneyCost"])
		BangPaiXiuLianCost.m_costBangGong = tonumber(v["@ContributionCost"])
		self.m_pBangPaiCostBuff[index] = BangPaiXiuLianCost
		index = index + 1
	end
end

--[[
获取升级消耗金钱
]]
function LBangPaiDataManager:GetBangPaiXiuLianMoney(level)
	if level == 0 then
		return 0
	end
	local Currentlevel = LRoleData:Instance().m_iBangPaiXiuLianLv
	local ret = 0
	for i=Currentlevel,Currentlevel + level do
		ret = ret + self.m_pBangPaiCostBuff[i].m_costTongQian
	end
	return ret
end

--[[
获取升级消耗帮贡
]]
function LBangPaiDataManager:GetBangPaiXiuLianBangGong(level)
	if level == 0 then
		return 0
	end
	local Currentlevel = LRoleData:Instance().m_iBangPaiXiuLianLv
	local ret = 0
	for i=Currentlevel,Currentlevel + level do
		ret = ret + self.m_pBangPaiCostBuff[i].m_costBangGong
	end
	return ret
end

--[[
读取帮派捐献数据
]]
function LBangPaiDataManager:ReadBangPaiDonateData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/gangDonate.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for m = 1, #rec do
		local v = rec[m]
		local BangPaiDonate = {}
		BangPaiDonate.m_level = tonumber(v["@ID"])
		BangPaiDonate.m_costMoneyType = tonumber(v["@MoneyType"])
		BangPaiDonate.m_costMoneyNum = tonumber(v["@MoneyCost"])
		BangPaiDonate.m_rewardBangGong = tonumber(v["@ContributionAdd"])
		BangPaiDonate.m_rewardBangPaiZiJin = tonumber(v["@MoneyAdd"])
		self.m_pBangPaiDonateBuff[BangPaiDonate.m_level] = BangPaiDonate
	end
end

--[[
获取帮派捐献数据
]]
function LBangPaiDataManager:GetBangPaiDonateData(level)
	return self.m_pBangPaiDonateBuff[level]
end

--[[
加载帮战数据
]]
function LBangPaiDataManager:ReadBangPaiWarData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/bangzhan.xml")
	-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for m = 1, #rec do
		local v = rec[m]
		local BangPaiWarData = {}
		BangPaiWarData.m_id = tonumber(v["@id"])
		BangPaiWarData.m_value = tonumber(v["@detail"])

		self.m_pBangPaiWarBuff[BangPaiWarData.m_id] = BangPaiWarData
	end
end

function LBangPaiDataManager:GetBangPaiWarData(id)
	return self.m_pBangPaiWarBuff[id]
end

return LBangPaiDataManager:Awake()