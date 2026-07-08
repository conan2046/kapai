--离线奖励找回
LOfflineRewardData = {}
LOfflineRewardData.__index = LOfflineRewardData
function LOfflineRewardData:New()
	local o = {}
	setmetatable(o,LOfflineRewardData)	
	o:ctor()
	return o
end

function LOfflineRewardData:ctor()
	self.findId = 0    --找回资源的ID
	self.activityName = ""   --找回资源的名字
	self.findTimes = 0		 --找回次数

	self.normalFindType = 0  --普通找回类型
	self.normalFindPay = 0	 --普通找回

	self.perfectFindType = 0 --完美找回类型
	self.perfectFindPay = 0  --完美找回

	self.awardNum = 0 --奖励数量
	self.awardInfo = {}  --奖励内容
	self.normalListInfo = {} --正常奖励内容
	self.perfectListInfo = {} --完美奖励内容
end

function LOfflineRewardData:Delete()

	self.findId = nil    --找回资源的ID
	self.activityName = nil   --找回资源的名字
	self.findTimes = nil		 --找回次数

	self.normalFindType = nil  --普通找回类型
	self.normalFindPay = nil	 --普通找回

	self.perfectFindType = nil --完美找回类型
	self.perfectFindPay = nil  --完美找回

	self.awardNum = nil --奖励数量
	self.awardInfo = nil  --奖励内容

	self.normalListInfo = nil --正常奖励内容
	self.perfectListInfo = nil --完美奖励内容
end



LOfflineResInfo = {}
LOfflineResInfo.__index = LOfflineResInfo
function LOfflineResInfo:New()
	local o = {}
	setmetatable(o, LOfflineResInfo)	
	o:ctor()
	return o
end

function LOfflineResInfo:ctor()
	self.coinFindPay = 0   --一键金币找回
	self.goldFindPay = 0   --一键完美找回

	self.offlineListInfo = {}

end

function LOfflineResInfo:Delete()
	self.coinFindPay = nil
	self.goldFindPay = nil
	self.offlineListInfo = nil

end

function LOfflineResInfo:Reset()
	self.coinFindPay = 0
	self.goldFindPay = 0
	self.offlineListInfo = {}

end

function LOfflineResInfo:updateFindAllData()
	-- body
	for i = 1, #self.offlineListInfo do
		local normalFindPay = self.offlineListInfo[i].normalFindPay * self.offlineListInfo[i].findTimes
		if normalFindPay then
			self.coinFindPay = self.coinFindPay + normalFindPay
		end

		local perfectFindPay = self.offlineListInfo[i].perfectFindPay * self.offlineListInfo[i].findTimes
		if perfectFindPay then
			self.goldFindPay = self.goldFindPay + perfectFindPay
		end

	end
end