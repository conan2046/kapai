--76.lua--补偿奖励使者
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm --二层交互的确认框
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
SendSysInfo = j.SendSysInfo --Tips
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 76
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
jifenRoleId = 5001759
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local serverId = pUser:GetServerId()
	local canGet,value = GetRechargeVal(pUser)
	local opt = ""

	--print("canGet",canGet,"money",value)
	if canGet ~= nil and canGet == 0 and value ~= nil and value > 0 then
		opt = "1|内测充值返利领取|"
	end
	
	local state = j.HaveAward_TestAccount(pUser)
	--print("HaveAward_TestAccount",state)
	if state then    
	    opt = opt.."2|内测玩家称号领取|"
	end
--	if pUser:HaveBitSet(556) and not pUser:HaveBitSet(1513) then
--        opt = opt.."3|次充翅膀领取|"
--	end
--	if serverId <= 6 or serverId == 20 then
--		opt = opt.."4|开服活动称号补偿|"
--	end
--	if pUser:GetRoleId() == jifenRoleId and not pUser:HaveBitSet(1516) then
--       opt = opt.."5|转盘积分恢复|"
--    end
	if pUser:GetItemNum(2745) > 0 or pUser:GetItemNum(2574) > 0 then
	   	opt = opt.."6|羽翼碎片回收|"
	else
		for itemId = 4501, 4510 do
			local num = pUser:GetItemNum(itemId)
			if num > 0 then
		    	opt = opt.."6|羽翼碎片回收|"
				break
			end
		end
	end

	-- local hasOpt = false
	-- local mid = {6,7,8,9,10}
	-- local miid = {2562,2575,2762,2806,2823}
	-- for idx=1, #mid do
	-- 	local num = pUser:GetItemNum(miid[idx])
	-- 	if num > 0 then
	-- 	    opt = opt.."7|坐骑碎片回收|"
	-- 	    hasOpt = true
	-- 	    break
	-- 	end
	-- end
	-- if not hasOpt then
	-- 	for itemId = 4511, 4520 do
	-- 		local num = pUser:GetItemNum(itemId)
	-- 		if num > 0 then
	-- 		    opt = opt.."7|坐骑碎片回收|"
	-- 		    break
	-- 		end
	-- 	end
	-- end
	-- for itemId = 2725, 2730 do
	-- 	local num = pUser:GetItemNum(itemId)
	-- 	if num > 0 then
	--     	opt = opt.."8|阵法书回收|"
	-- 		break
	-- 	end
	-- end
	-- for itemId = 851, 851 do
	-- 	local num = pUser:GetItemNum(itemId)
	-- 	if num > 0 then
	--     	opt = opt.."9|强化石回收|"
	-- 		break
	-- 	end
	-- end
	if j.GetServerType() == "doushen" then
		opt = opt.."11|重新开始|12|数据转移|17|更换选择|"
	end
	local roleId = pUser:GetRoleId()
	if not pUser:HaveBitSet(1564) then
		if roleId == 8000027 then
			opt = opt.."21|礼包恢复|"
		end
	end
	opt = string.sub(opt,1,-2)
	if #opt > 0 then
	    -- Option(pUser,NPCName,"重新开始：剑阵诛仙开服后，可以重新体验，斗神充值将120%返还（100%元宝+20%绑元）。\r\n数据转移：剑阵诛仙开启2个王者归来新服，玩家在此创建角色后，练到开启福利功能，输入识别码后，重新上线即可把斗神角色数据转移到新服。",opt)
	    Option(pUser,NPCName,"大衍之数五十，其用四十有九，掌握住这遁去的一，才能补偿缺憾，超脱万物。关于这件事，但我可以帮你。", opt)
		pUser:SetCallFun("DoOption")
	else
	    Dialog(pUser,NPCName,"大衍之数五十，其用四十有九，掌握住这遁去的一，才能补偿缺憾，超脱万物。关于这件事，但我可以帮你。")
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

--获取领取状态，充值金额
function GetRechargeVal(pUser)
    local info = j.GetTestCZFanLiInfo(pUser)
	if info == nil then
		return nil
	end
	--print("GetTestCZFanLiInfo",info)
	local t = FormatMission(info)
	if #t < 2 then 
        return nil,nil
	end
	local canGet = tonumber(t[1]) --0未领取奖励  1已领取
	local value = tonumber(t[2])--充值金额
	return canGet,value
end

--获取返利元宝
function GetRebateCash(value)
	local cash = 0
	if value < 2000 then
		cash = value*20
	else
		cash = value*24
	end
	--print("GetRebateCash value:",value)
	if j.GetServerType() == "jianzhen" then
		if value <= 5000 then
			cash = value*20
		else
			cash = 5000*20 + (value - 5000)*15
		end
	end
	--print("GetRebateCash cash:",cash)
	return cash
end

function DoOption(pUser, sel)
	if sel == 1 then
	    local canGet,value = GetRechargeVal(pUser)
		if canGet == nil or canGet ~= 0 or value == nil or value < 1 then
		    SendSysInfo(pUser,"您不符合领取条件，或者已领取奖励！")
		    return
		end
		local vipExp = value*10
		local cash = GetRebateCash(value)
		
	    local str = string.format("您在之前的游戏内测中累计充值了%d元，可为你返还%d的元宝和%d贵族经验。在该服务器领取返利后将不能在其他服务器领取，是否确认领取？",value,cash,vipExp)
		-- 内测充值返利领取提示
		Option(pUser,NPCName,str,"10001|取消|1001|确认领取")
		pUser:SetCallFun("DoOption")
	elseif sel == 1001 then
	    local canGet,value = GetRechargeVal(pUser)
		if canGet == nil or canGet ~= 0 or value == nil or value < 1 then
		    SendSysInfo(pUser,"您不符合领取条件，或者已领取奖励")
		    return
		end
		local r = j.SetTestCZFanLiAward(pUser)
		if not r then 
		    SendSysInfo(pUser,"领取出错！")
		    return 
		end
		local vipExp = value*10
		local cash = GetRebateCash(value)
		-- 内测充值返利领取
		pUser:AddTongBao(cash)
		pUser:AddExVipExp(vipExp)
		pUser:UpdateVipInfoEx()
        SendSysInfo(pUser,string.format("成功领取%d元宝,%d贵族经验。",cash,vipExp))
		--print("DoOption",sel,cash,vipExp)
	elseif sel == 2 then
		local state = j.HaveAward_TestAccount(pUser)
		if not state then
		    SendSysInfo(pUser,"您不符合领取条件，或者已领取奖励")
		    return
		end
		local isChongZhi = j.IsTestCZAccount(pUser)
		local str = "您之前进行了内测游戏体验，特为您发放“斗神先行者“称号”，感谢您对游戏的支持。在该服务器领取返利后将不能在其他服务器领取，是否确认领取？"
		if isChongZhi then
		    str = "您之前进行了内测游戏体验并且有充值行为，特为您发放“斗神执道者“称号”，感谢您对游戏的支持。在该服务器领取返利后将不能在其他服务器领取，是否确认领取？"
		end
		-- 内测玩家称号领取提示
		Option(pUser,NPCName,str,"10002|取消|1002|确认领取")
		pUser:SetCallFun("DoOption")
	elseif sel == 4 then
		if pUser:HaveBitSet(1514) then
			SendSysInfo(pUser,"您已领过或没有称号需要补偿")
			return
		end
		pUser:SetBitSet(1514)
		
		local roleId = pUser:GetRoleId()
		local hasTitle = false
		if roleId == 1000193 or roleId == 2001050 or roleId == 3000276 or roleId == 4000078 or roleId == 20000402 then
			pUser:AddTitle(33)
			hasTitle = true
		end
		if roleId == 1000449 or roleId == 2000392 or roleId == 3000264 or roleId == 4000520 or roleId == 20000103 then
			pUser:AddTitle(34)
			hasTitle = true
		end
		if roleId == 1000024 or roleId == 2000021 or roleId == 3000099 or roleId == 4000057 or roleId == 20000011 then
			pUser:AddTitle(35)
			hasTitle = true
		end

		if roleId == 1000036 or roleId == 2000021 or roleId == 3002008 or roleId == 4000048 or roleId == 5000140 or roleId == 6000921 or roleId == 20000402 then
			pUser:AddTitle(36)
			hasTitle = true
		end
		if roleId == 1000004 or roleId == 2000016 or roleId == 3001256 or roleId == 4000135 or roleId == 5000652 or roleId == 6000023 or roleId == 20000325 then
			pUser:AddTitle(37)
			hasTitle = true
		end
		if roleId == 1000383 or roleId == 2000005 or roleId == 3000102 or roleId == 4000397 or roleId == 5000466 or roleId == 6000223 or roleId == 20000304 then
			pUser:AddTitle(38)
			hasTitle = true
		end

		if roleId == 20000073 then
			pUser:AddTitle(30)
			hasTitle = true
		end
		if roleId == 20000534 then
			pUser:AddTitle(31)
			hasTitle = true
		end
		if roleId == 20000103 then
			pUser:AddTitle(32)
			hasTitle = true
		end

		if not hasTitle then
		    SendSysInfo(pUser,"您没有称号需要补偿")
		end
	elseif sel == 5 then
		if pUser:GetRoleId() ~= jifenRoleId or pUser:HaveBitSet(1516) then
        	SendSysInfo(pUser,"您的积分不需要恢复")
        	return
        end
        pUser:SetExtData32(12, pUser:GetExtData32(12)+1500)
        SendSysInfo(pUser,"您的积分已经恢复")
        pUser:SetBitSet(1516)
        print("积分恢复已经操作", os.time(), pUser:GetRoleId())
	elseif sel == 1002 then
	    local state = j.HaveAward_TestAccount(pUser)
		if not state then
		    SendSysInfo(pUser,"您不符合领取条件，或者已领取奖励")
		    return
		end
		local r = j.SetAward_TestAccount(pUser)
		if not r then 
		    SendSysInfo(pUser,"领取出错！")
		    return 
		end
		local isChongZhi = j.IsTestCZAccount(pUser)
		titleId = 86
		if isChongZhi then
		    titleId = 87
		end
		-- 内测玩家称号领取
		pUser:AddTitle(titleId)
	elseif sel == 3 then
	    if pUser:HaveBitSet(556) and not pUser:HaveBitSet(1513) then
		    pUser:SetBitSet(1513)
			pUser:AddWing(8)
		end
	elseif sel == 6 then
		local opt = ""
	    local itemOpt = 
		{
			[2745] = "2745|火凤燎原碎片(%d)|",
			[2574] = "2574|通天灵翼碎片(%d)|",
			[4501] = "4501|冰蓝之翼碎片(%d)|",
			[4502] = "4502|紫色魅影碎片(%d)|",
			[4503] = "4503|红色回响碎片(%d)|",
			[4504] = "4504|叛逆之羽碎片(%d)|",
			[4505] = "4505|青色流年碎片(%d)|",
			[4506] = "4506|蝠影纷纷碎片(%d)|",
			[4507] = "4507|烈焰彩羽碎片(%d)|",
			[4508] = "4508|樱色轮回碎片(%d)|",
			[4509] = "4509|地狱之翼碎片(%d)|",
			[4510] = "4510|圣气化翼碎片(%d)|",
		}
		local itemId
		itemId = 2745
		if pUser:HaveWing(9) then
			local num = pUser:GetItemNum(itemId)
			if num > 0 then
				opt = opt..string.format(itemOpt[itemId], num)
			end
		end
		itemId = 2574
		if pUser:HaveWing(10) then
			local num = pUser:GetItemNum(itemId)
			if num > 0 then
				opt = opt..string.format(itemOpt[itemId], num)
			end
		end
		for itemId = 4501, 4510 do
			if pUser:HaveWing(itemId - 4490) then
				local num = pUser:GetItemNum(itemId)
				if num > 0 then
					opt = opt..string.format(itemOpt[itemId], num)
				end
			end
		end
		opt = string.sub(opt,1,-2)
		if #opt > 0 then
	    	Option(pUser,NPCName,"老夫这里急需多余的羽翼碎片，价格公道，[c3]50绑元/个[/c]碎片做个交易怎么样？",opt)
			pUser:SetCallFun("DoOption")
		else
		    Dialog(pUser,NPCName,"你没有碎片可以交易。")
		end
	elseif sel == 7 then
		local opt = ""
	    local itemOpt = 
		{
			[2562] = "2562|流光扇碎片(%d)|",
			[2575] = "2575|判官笔碎片(%d)|",
			[2762] = "2762|飞天剑碎片(%d)|",
			[2806] = "2806|太极盘碎片(%d)|",
			[2823] = "2823|五十弦碎片(%d)|",
			[4511] = "4511|擎天神剑碎片(%d)|",
			[4512] = "4512|筋斗云碎片(%d)|",
			[4513] = "4513|赤鱬碎片(%d)|",
			[4514] = "4514|万花异兽碎片(%d)|",
			[4515] = "4515|蝶舞灵座碎片(%d)|",
			[4516] = "4516|异世飞毯碎片(%d)|",
			[4517] = "4517|幽光宝莲碎片(%d)|",
			[4518] = "4518|地心青莲碎片(%d)|",
			[4519] = "4519|紫炎焚莲碎片(%d)|",
			[4520] = "4520|极寒冰台碎片(%d)|",
		}
		local mid = {6,7,8,9,10}
		local miid = {2562,2575,2762,2806,2823}
		for idx=1, #mid do
			if pUser:HaveMount(mid[idx]) then
				local num = pUser:GetItemNum(miid[idx])
				if num > 0 then
					opt = opt..string.format(itemOpt[miid[idx]], num)
				end
			end
		end
		for itemId = 4511, 4520 do
			if pUser:HaveMount(itemId - 4500) then
				local num = pUser:GetItemNum(itemId)
				if num > 0 then
					opt = opt..string.format(itemOpt[itemId], num)
				end
			end
		end
		opt = string.sub(opt,1,-2)
		if #opt > 0 then
	    	Option(pUser,NPCName,"老夫这里急需多余的坐骑碎片，价格公道，[c3]50绑元/个[/c]碎片做个交易怎么样？",opt)
			pUser:SetCallFun("DoOption")
		else
		    Dialog(pUser,NPCName,"你没有碎片可以交易。")
		end
	elseif (sel >= 4501 and sel <= 4510) or sel == 2745 or sel == 2574 then
		local num = pUser:GetItemNum(sel)
        pUser:DelPackageByIdLevel(sel, 0, -1)
        pUser:AddMaterial(60001, num * 50, false)
		Option(pUser,NPCName,"回收成功。","6|返回")
		pUser:SetCallFun("DoOption")
	elseif (sel >= 4511 and sel <= 4520)
		 or sel == 2562
		 or sel == 2575
		 or sel == 2762
		 or sel == 2823
		 or sel == 2806 then
		local num = pUser:GetItemNum(sel)
        pUser:DelPackageByIdLevel(sel, 0, -1)
        pUser:AddMaterial(60001, num * 50, false)
		Option(pUser,NPCName,"回收成功。","7|返回")
		pUser:SetCallFun("DoOption")
	elseif sel == 8 then
		local opt = ""
	    local itemOpt = 
		{
			[2725] = "2725|七星阵法书(%d)|",
			[2726] = "2726|玄火阵法书(%d)|",
			[2727] = "2727|急流阵法书(%d)|",
			[2728] = "2728|地绝阵法书(%d)|",
			[2729] = "2729|密林阵法书(%d)|",
			[2730] = "2730|山岳阵法书(%d)|",
		}
		for itemId = 2725, 2730 do
			local num = pUser:GetItemNum(itemId)
			if num > 0 then
				opt = opt..string.format(itemOpt[itemId], num)
			end
		end
		opt = string.sub(opt,1,-2)
		if #opt > 0 then
	    	Option(pUser,NPCName,"老夫这里急需多余的阵法书，价格公道，[c3]50绑元/本[/c]做个交易怎么样？",opt)
			pUser:SetCallFun("DoOption")
		else
		    Dialog(pUser,NPCName,"你没有阵法书可以交易。")
		end
	elseif sel >= 2725 and sel <= 2730 then
		local num = pUser:GetItemNum(sel)
	    local itemOpt = 
		{
			[2725] = "七星阵法书",
			[2726] = "玄火阵法书",
			[2727] = "急流阵法书",
			[2728] = "地绝阵法书",
			[2729] = "密林阵法书",
			[2730] = "山岳阵法书",
		}
		local opt = sel.."|确定|8|取消"
		local str = string.format("回收[c3]%s[/c]*[c1]%d[/c]本, 是否确定？", itemOpt[sel], num)
	    Option(pUser,NPCName, str, opt)
		pUser:SetCallFun("SellShu")
	elseif sel == 9 then
		local opt = ""
	    local itemOpt = 
		{
			[851] = "851|1级强化石(%d)|",
			[852] = "852|2级强化石(%d)|",
			[853] = "853|3级强化石(%d)|",
			[854] = "854|4级强化石(%d)|",
			[855] = "855|5级强化石(%d)|",
		}
		for itemId = 851, 851 do
			local num = pUser:GetItemNum(itemId)
			if num > 0 then
				opt = opt..string.format(itemOpt[itemId], num)
			end
		end
		opt = string.sub(opt,1,-2)
		if #opt > 0 then
	    	Option(pUser,NPCName,"老夫这里急需多余的强化石，价格公道，[c3]5绑元/个[/c]做个交易怎么样？",opt)
			pUser:SetCallFun("DoOption")
		else
		    Dialog(pUser,NPCName,"你没有强化石可以交易。")
		end
	elseif sel >= 851 and sel <= 855 then
		local num = pUser:GetItemNum(sel)
	    local itemOpt = 
		{
			[851] = "1级强化石",
			[852] = "2级强化石",
			[853] = "3级强化石",
			[854] = "4级强化石",
			[855] = "5级强化石",
		}
		local opt = sel.."|确定|9|取消"
		local str = string.format("回收[c3]%s[/c]*[c1]%d[/c]个, 是否确定？", itemOpt[sel], num)
	    Option(pUser,NPCName, str, opt)
		pUser:SetCallFun("SellQiangHuaShi")
	elseif sel == 11 then
		local mark = ""
		if pUser:HaveBitSet(1543) then
			Dialog(pUser,NPCName, "您已经选择了数据转移，请在数据转移中查看详情。")
	   		return
		end
		if pUser:HaveBitSet(1542) then
			mark = j.QueryJZZXJiHuoMa(pUser)
		else
			mark = j.CreateJZZXJiHuoMa(pUser, 1)
			pUser:SetBitSet(1542)
		end
		local chat = string.format("您的识别码：[c1]%s[/c]，请及时在各渠道下载《诛仙剑阵》游戏包。（选择“重新开始”的玩家请于10月16日17:00数据备份后，可选择除“王者归来一/二”任意服务器，游戏内点击福利-奖励兑换-填入兑换码即可领取到相应的等级和充值补偿）。[c1]请玩家截屏记录[/c]。\r\n注意进行过数据转移登记的的角色在数据备份后就不能再登录斗神无双了。", mark)
		Dialog(pUser,NPCName, chat)
	elseif sel == 12 then
		if pUser:HaveBitSet(1542) then
	   		Dialog(pUser,NPCName, "您已选择了重新开始，请在重新开始中查看详情。")
	   		return
	   	end
		local mark = ""
		if pUser:HaveBitSet(1543) then
			mark = j.QueryJZZXJiHuoMa(pUser)
		else
			mark = j.CreateJZZXJiHuoMa(pUser, 2)
			pUser:SetBitSet(1543)
		end
		local chat = string.format("您的识别码：[c1]%s[/c]，请及时在各渠道下载《诛仙剑阵》游戏包。（选择“数据转移”的玩家请于10月16日17:00数据备份后，只能选择“王者归来一/二”两个服务器，游戏内点击福利-奖励兑换-填入兑换码重新上线后即可实现个人数据的平移）。[c1]请玩家截屏记录[/c]。\r\n注意进行过数据转移登记的的角色在数据备份后就不能再登录斗神无双了。", mark)
		Dialog(pUser,NPCName, chat)
	elseif sel == 13 then
		local mark = ""
		if pUser:HaveBitSet(1542) then
			mark = j.QueryJZZXJiHuoMa(pUser)
		else
			mark = j.CreateJZZXJiHuoMa(pUser, 1)
			pUser:ClearBitSet(1543)
			pUser:SetBitSet(1542)
		end
		local chat = string.format("您的识别码：[c1]%s[/c]，请及时在各渠道下载《诛仙剑阵》游戏包。（选择“重新开始”的玩家请于10月16日17:00数据备份后，可选择除“王者归来一/二”任意服务器，游戏内点击福利-奖励兑换-填入兑换码即可领取到相应的等级和充值补偿）。[c1]请玩家截屏记录[/c]。\r\n注意进行过数据转移登记的的角色在数据备份后就不能再登录斗神无双了。", mark)
		Dialog(pUser,NPCName, chat)
	elseif sel == 14 then
		local mark = ""
		if pUser:HaveBitSet(1543) then
			mark = j.QueryJZZXJiHuoMa(pUser)
		else
			mark = j.CreateJZZXJiHuoMa(pUser, 2)
			pUser:ClearBitSet(1542)
			pUser:SetBitSet(1543)
		end
		local chat = string.format("您的识别码：[c1]%s[/c]，请及时在各渠道下载《诛仙剑阵》游戏包。（选择“数据转移”的玩家请于10月16日17:00数据备份后，只能选择“王者归来一/二”两个服务器，游戏内点击福利-奖励兑换-填入兑换码重新上线后即可实现个人数据的平移）。[c1]请玩家截屏记录[/c]。\r\n注意进行过数据转移登记的的角色在数据备份后就不能再登录斗神无双了。", mark)
		Dialog(pUser,NPCName, chat)
	elseif sel == 17 then
		local opt = "13|重新开始|14|数据转移"
	    Option(pUser,NPCName,"重新开始：剑阵诛仙开服后，可以重新体验，斗神充值将120%返还（100%元宝+20%绑元）。\r\n数据转移：剑阵诛仙开启2个王者归来新服，玩家在此创建角色后，练到开启福利功能，输入识别码后，重新上线即可把斗神角色数据转移到新服。", opt)
		pUser:SetCallFun("DoOption")
	elseif sel == 21 then
		local roleId = pUser:GetRoleId()
		local nowTime = os.time()
		if roleId == 8000027 then
			pUser:SetExtData32(470, nowTime)
			pUser:SetExtData32(471, 0)
			pUser:SetExtData8(645, 1)
		    SendSysInfo(pUser,"[c3]街边小巷活跃基金[/c]恢复成功！")
		end

		if roleId == 8000027 then
			pUser:SetExtData32(472, nowTime)
			pUser:SetExtData32(473, 0)
			pUser:SetExtData8(646, 1)
		    SendSysInfo(pUser,"[c3]朝歌酒楼活跃基金[/c]恢复成功！")
		end
		pUser:SetBitSet(1564)
    end
end

function SellShu(pUser, sel)
	if sel == 8 then
		DoOption(pUser, sel)
		return
	end
	local num = pUser:GetItemNum(sel)
	pUser:DelPackageByIdLevel(sel, 0, -1)
	pUser:AddMaterial(60001, num * 50, false)
	Option(pUser,NPCName,"回收成功。","8|返回")
	pUser:SetCallFun("DoOption")
end

function SellQiangHuaShi(pUser, sel)
	if sel ~= 851 then
		DoOption(pUser, sel)
		return
	end
	local num = pUser:GetItemNum(sel)
	pUser:DelPackageByIdLevel(sel, 0, -1)
	pUser:AddMaterial(60001, num * 5, false)
	Option(pUser,NPCName,"回收成功。","9|返回")
	pUser:SetCallFun("DoOption")
end