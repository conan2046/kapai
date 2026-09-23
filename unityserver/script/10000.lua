--10000.lua--特殊功能脚本
-------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SendSysInfo = j.SendSysInfo --Tips


-- 0 -默认色,1-红色,2-蓝色,3-绿色,4-金色,5-粉色,6-灰黑色
function Logon(pUser)
	if not pUser:HaveBitSet(1) then
		pUser:SetExtData8(59,25)
		pUser:SetBitSet(1)
		pUser:SendMailByLevel()
		j.PlayFightCG(pUser, 1)
	end
end

-- --------------------------------------------------------
-- 多人闯关配置api
_CGConfig = {}
function InitChuangGuanConfig()
	-- _CGConfig.NormalRollTimesMax = 20 -- 非VIP筛子上限
	-- _CGConfig.VipRollTimesMax = 25 -- 非VIP筛子上限
	-- _CGConfig.DailyBuyTimesMax = 5 -- 每日购买筛子次数上限
	-- _CGConfig.BuyRollTimesMoneyType = 60001 -- 60000 金币 60001 绑元 60003元宝
	-- _CGConfig.BuyRollTimesMoneyC = 5 -- 扣除钱数
	table.insert(_CGConfig, 25)    -- 非VIP筛子上限
	table.insert(_CGConfig, 25)    -- 非VIP筛子上限
	table.insert(_CGConfig, 10)     -- 每日购买筛子次数上限
	table.insert(_CGConfig, 60001) -- 60000 金币 60001 绑元 60003元宝
	table.insert(_CGConfig, 5)     -- 扣除钱数
end 

function QueryChuangGuanConfig(pUser)
	if #_CGConfig<=0 then
		InitChuangGuanConfig()
	end 
	print(table.concat(_CGConfig,"-"))
	return table.concat(_CGConfig,"-")
end 

