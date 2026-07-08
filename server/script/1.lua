--1.lua--领奖天官 id=1
---------------------------------------
require "global"

Dialog = j.Dialog	   --对话
Option =j.Option		--对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End	   
SMessage_End = j.SMessage_End   

thisId = 1
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
local dataAnd = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608}
local bit=require "bit"

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local opt = ""
	local lv = pUser:GetLevel()
	local ad = pUser:GetAd()
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()

	local LiBao4Opt = {
		"131|首日伴守礼|",
		"132|次日伴守礼|",
		"133|三日伴守礼|",
		"134|四日伴守礼|",
		"135|五日伴守礼|",
		"136|六日伴守礼|",
		"137|七日伴守礼|",
		"138|八日伴守礼|",
		"139|九日相伴礼|",
		"140|十日相伴礼|",
	}

	for i=1,#LiBao4Opt do
		if CheckLiBao4Time(i, 1) then
			opt = opt..LiBao4Opt[i]
		end
	end

	local signDay = pUser:GetExtData8(643)
	if signDay < 90 then
		opt = opt.."802|签到领SSS红将|"
	end
	if signDay >= 30 and not pUser:HaveBitSet(617) then
		opt = opt.."803|领取SSS红将孔宣|804|领取SSS红将准提|805|领取SSS红将接引|"
	end
	if signDay >= 60 and not pUser:HaveBitSet(623) then
		opt = opt.."|807|领取SSS红将金灵|"
	elseif signDay >= 90 and (not pUser:HaveBitSet(623) or not pUser:HaveBitSet(624)) then
		opt = opt.."|807|领取SSS红将金灵|"
	end
	--opt = "901|等级升10级|902|vip提升至15|903|加金币、元宝、神魂|904|加所有宠物|905|等级升1级|1000|下一页|"--906|添加所有神将装备|907|添加白金特权|908|添加永久月卡|909|加帮派资金|
--[[
	local binding = pUser:GetAccountBinding()
	if binding == 1 then
		 opt = opt .. "1001|账号绑定|" 
	end
--]]

	opt = string.sub(opt,1,-2)
	if #opt ~= 0 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_725,opt)
		pUser:SetCallFun("NpcMainSel")
	else
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_726)
	end
end

-- 检查时间
--付费测试日常想办理
function CheckLiBao4Time(idx, type) -- 1 展示 2 领取

	local function makeTime(day, time)
		local lday = day:split("-")
		local ltime = time:split(":")
		return os.time{year=lday[1],month=lday[2],day=lday[3],hour=ltime[1],min=ltime[2],sec=ltime[3]}
	end

	local LiBao4Time = {} -- 1 展示时间 2 开始时间 3 结束时间
	table.insert(LiBao4Time, {makeTime("2019-5-28", "10:0:0"), makeTime("2019-5-28", "10:0:0"), makeTime("2019-5-28", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-5-28", "20:0:0"), makeTime("2019-5-29", "0:0:0"), makeTime("2019-5-29", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-5-29", "20:0:0"), makeTime("2019-5-30", "0:0:0"), makeTime("2019-5-30", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-5-30", "20:0:0"), makeTime("2019-5-31", "0:0:0"), makeTime("2019-5-31", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-5-31", "20:0:0"), makeTime("2019-6-1", "0:0:0"), makeTime("2019-6-1", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-6-1", "20:0:0"), makeTime("2019-6-2", "0:0:0"), makeTime("2019-6-2", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-6-2", "20:0:0"), makeTime("2019-6-3", "0:0:0"), makeTime("2019-6-3", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-6-3", "20:0:0"), makeTime("2019-6-4", "0:0:0"), makeTime("2019-6-4", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-6-4", "20:0:0"), makeTime("2019-6-5", "0:0:0"), makeTime("2019-6-5", "23:59:59")})
	table.insert(LiBao4Time, {makeTime("2019-6-5", "20:0:0"), makeTime("2019-6-6", "0:0:0"), makeTime("2019-6-6", "23:59:59")})

	if idx > #LiBao4Time then
		return false
	end
	local startTime
	if type == 1 then
		startTime = LiBao4Time[idx][1]
	else
		startTime = LiBao4Time[idx][2]
	end
	return Timing(startTime, LiBao4Time[idx][3])
end

-- 发放奖励
function SendLiBao4Award(pUser, day)
	local LiBao4Award = {} -- 1 展示时间 2 开始时间 3 结束时间
	LiBao4Award[1] = {name = "首日相伴礼", bitset = 1261, award = {{awardType = 836, num = 5},{awardType = 60000, num = 10000},},}
	LiBao4Award[2] = {name = "次日相伴礼", bitset = 1262, award = {{awardType = 2356, num = 5},{awardType = 60000, num = 15000},},}
	LiBao4Award[3] = {name = "三日相伴礼", bitset = 1263, award = {{awardType = 2377, num = 1},{awardType = 60000, num = 20000},},}
	LiBao4Award[4] = {name = "四日相伴礼", bitset = 1264, award = {{awardType = 501, num = 5},{awardType = 60000, num = 25000},},}
	LiBao4Award[5] = {name = "五日相伴礼", bitset = 1265, award = {{awardType = 2539, num = 10},{awardType = 60000, num = 30000},},}
	LiBao4Award[6] = {name = "六日相伴礼", bitset = 1266, award = {{awardType = 801, num = 5},{awardType = 610, num = 10},{awardType = 60000, num = 35000},},}
	LiBao4Award[7] = {name = "七日相伴礼", bitset = 1267, award = {{awardType = 2821, num = 2},{awardType = 60000, num = 40000},},}
	LiBao4Award[8] = {name = "八日相伴礼", bitset = 1268, award = {{awardType = 2377, num = 5},{awardType = 60000, num = 50000},},}	
	LiBao4Award[9] = {name = "九日相伴礼", bitset = 1269, award = {{awardType = 60001, num = 288},{awardType = 60000, num = 50000},},}
	LiBao4Award[10] = {name = "十日相伴礼", bitset = 1270, award = {{awardType = 1818, num = 5},{awardType = 60000, num = 60000},},}
	if day > #LiBao4Award then 
		return
	end

	if not CheckLiBao4Time(day, 2) then		
			Dialog(pUser,NPCName,"明日登录即可领取日常相伴礼包！")
		return
	end
	
	if not pUser:HaveBitSet(LiBao4Award[day].bitset) then
		local dlgStr = "成功领取"..LiBao4Award[day].name..": "
		for i=1,#LiBao4Award[day].award do
			if i ~= 1 then
				dlgStr = dlgStr.."， "
			end
			local awd = LiBao4Award[day].award[i]
			
			pUser:AddMaterial(awd.awardType, awd.num, false)
			dlgStr = dlgStr..j.GetItemName(awd.awardType).."*"..awd.num
		end
		dlgStr = dlgStr.."。"
		Dialog(pUser,NPCName, dlgStr)
		pUser:SetBitSet(LiBao4Award[day].bitset)
	else
		Dialog(pUser,NPCName,"你已经领过该礼包了！")
	end
end

function NpcMainSel(pUser,sel)
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local lv = pUser:GetLevel()
	
	if sel == 131 or
		sel == 132 or
		sel == 133 or
		sel == 134 or
		sel == 135 or
		sel == 136 or
		sel == 137 or
		sel == 138 or
		sel == 139 or
		sel == 140 then
		SendLiBao4Award(pUser, sel - 130)
		return	
	elseif sel == 802 then
		local signDay = pUser:GetExtData8(643)
		if not pUser:HaveBitSet(616) then
			if signDay < 30 then
				Option(pUser,NPCName, string.format("您已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]中选取领取一个红将", signDay, 30 - signDay), "806|签到")
			elseif signDay < 60 then
				Option(pUser,NPCName, string.format("您已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 60 - signDay), "806|签到")
			elseif signDay < 90 then
				Option(pUser,NPCName, string.format("您已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 90 - signDay), "806|签到")
			end
			pUser:SetCallFun("NpcMainSel")
		else
			if signDay < 30 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]中选取领取一个红将", signDay, 30 - signDay), "2|离开")
			elseif signDay < 60 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 60 - signDay), "2|离开")
			elseif signDay < 90 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 90 - signDay), "2|离开")
			end
		end
	elseif sel == 803 then
		local signDay = pUser:GetExtData8(643)
		if (signDay >= 30 and not pUser:HaveBitSet(617))
			or (signDay >= 60 and not pUser:HaveBitSet(623))
			or (signDay >= 90 and not pUser:HaveBitSet(624)) then
			Option(pUser,NPCName, "成功领取[c1]SSS级红将孔宣[/c]", "2|离开")
			if not pUser:HaveBitSet(617) then
				pUser:SetBitSet(617)
			elseif not pUser:HaveBitSet(623) then
				pUser:SetBitSet(623)
			elseif not pUser:HaveBitSet(624) then
				pUser:SetBitSet(624)
			end
			j.AddPet(pUser,13,1)
		end
	elseif sel == 804 then
		local signDay = pUser:GetExtData8(643)
		if (signDay >= 30 and not pUser:HaveBitSet(617))
			or (signDay >= 60 and not pUser:HaveBitSet(623))
			or (signDay >= 90 and not pUser:HaveBitSet(624)) then
			Option(pUser,NPCName, "成功领取[c1]SSS红将准提[/c]", "2|离开")
			if not pUser:HaveBitSet(617) then
				pUser:SetBitSet(617)
			elseif not pUser:HaveBitSet(623) then
				pUser:SetBitSet(623)
			elseif not pUser:HaveBitSet(624) then
				pUser:SetBitSet(624)
			end
			j.AddPet(pUser,12,1)
		end
	elseif sel == 805 then
		local signDay = pUser:GetExtData8(643)
		if (signDay >= 30 and not pUser:HaveBitSet(617))
			or (signDay >= 60 and not pUser:HaveBitSet(623))
			or (signDay >= 90 and not pUser:HaveBitSet(624)) then
			Option(pUser,NPCName, "成功领取[c1]SSS红将接引[/c]", "2|离开")
			
			if not pUser:HaveBitSet(617) then
				pUser:SetBitSet(617)
			elseif not pUser:HaveBitSet(623) then
				pUser:SetBitSet(623)
			elseif not pUser:HaveBitSet(624) then
				pUser:SetBitSet(624)
			end
			j.AddPet(pUser,11,1)
		end
	elseif sel == 806 then
		local signDay = pUser:GetExtData8(643)
		if not pUser:HaveBitSet(616) then
			signDay = signDay + 1
			pUser:AddMaterial(502, 1, false)
			pUser:AddMaterial(2442, 2, false)
			pUser:AddMaterial(1101, 5, false)

			if signDay == 30 then
				Option(pUser,NPCName, "您经累计签到30天，可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]中选取一个自由领取 ", "803|领取SSS红将孔宣|804|领取SSS红将准提|805|领取SSS红将接引")
				pUser:SetCallFun("NpcMainSel")
			elseif signDay == 60 then
				Option(pUser,NPCName, "您经累计签到60天，可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取一个自由领取 ", "803|领取SSS红将孔宣|804|领取SSS红将准提|805|领取SSS红将接引|807|领取SSS红将金灵")
				pUser:SetCallFun("NpcMainSel")
			elseif signDay == 90 then
				Option(pUser,NPCName, "您经累计签到90天，可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取一个自由领取 ", "803|领取SSS红将孔宣|804|领取SSS红将准提|805|领取SSS红将接引|807|领取SSS红将金灵")
				pUser:SetCallFun("NpcMainSel")
			else
				if signDay < 30 then
					Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]中选取领取一个红将", signDay, 30 - signDay), "2|离开")
				elseif signDay < 60 then
					Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 60 - signDay), "2|离开")
				elseif signDay < 90 then
					Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 90 - signDay), "2|离开")
				end
			end
			pUser:SetBitSet(616)
			pUser:SetExtData8(643, signDay)
		else
			if signDay < 30 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]中选取领取一个红将", signDay, 30 - signDay), "2|离开")
			elseif signDay < 60 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 60 - signDay), "2|离开")
			elseif signDay < 90 then
				Option(pUser,NPCName, string.format("您今日已签到，已经累计签到[c3]%d[/c]天，继续签到[c3]%d[/c]天即可从[c1]SSS级红将孔宣[/c]、[c1]SSS红将准提[/c]、[c1]SSS红将接引[/c]、[c1]SSS红将金灵[/c]中选取领取一个红将", signDay, 90 - signDay), "2|离开")
			end
		end
	elseif sel == 807 then
		local signDay = pUser:GetExtData8(643)
		if (signDay >= 60 and not pUser:HaveBitSet(623))
			or (signDay >= 90 and not pUser:HaveBitSet(624)) then
			Option(pUser,NPCName, "成功领取[c1]SSS红将金灵[/c]", "2|离开")
			if not pUser:HaveBitSet(623) then
				pUser:SetBitSet(623)
			elseif not pUser:HaveBitSet(624) then
				pUser:SetBitSet(624)
			end
			j.AddPet(pUser,15,1)
		end
	elseif sel == 901 then
		for i=1,10 do
			local lv = pUser:GetLevel()
			local e = j.GetRoleLevelUpExp(lv)
			pUser:AddExp(e)
		end
		Option(pUser,NPCName,"成功升级","1|返回")
		pUser:SetCallFun("LevelUpSel")
	elseif sel == 902 then
		pUser:SetExtData32(13,999999)
		pUser:Init()
		pUser:UpdateInfo()
		Option(pUser,NPCName,"vip15提升成功","1|返回")
		pUser:SetCallFun("LevelUpSel")
	elseif sel == 903 then
		local m = pUser:GetMoney()
		if m < 999999999 then
			pUser:AddMoney(999999999-m)
		end
		local yb = pUser:GetTongBao()
		if yb < 99999999 then
			pUser:AddTongBao(99999999-yb)
		end
		pUser:SetExtData32(93,10000000)
		Option(pUser,NPCName,"金币、元宝、神魂添加成功","1|返回")
		pUser:SetCallFun("LevelUpSel")
	elseif sel == 904 then
		for petId=10,68 do
			j.AddPet(pUser,petId,pUser:GetLevel())
		end
	elseif sel == 905 then
		local lv = pUser:GetLevel()
		local e = j.GetRoleLevelUpExp(lv)
		pUser:AddExp(e)
		Option(pUser,NPCName,"成功升级","1|返回")
		pUser:SetCallFun("LevelUpSel")
	elseif sel == 906 then
		for et = 0, 9 do
			local baseId = 1000+et*100
			for i=1, 6 do
				local star = math.random(1,6)
				pUser:AddPetEquip(baseId + i, star)
			end
		end
	elseif sel == 907 then
		pUser:BuyMonthCard(0)
	elseif sel == 908 then
		pUser:BuyMonthCard(1)
	elseif sel == 909 then
		if pUser:GetBangPai() > 0 then
			j.AddBangMoney(pUser,300000)
			Option(pUser,NPCName,"帮派资金添加成功","1|返回")
		else
			Option(pUser,NPCName,"失败：请先加入帮派","1|返回")
		end
		pUser:SetCallFun("LevelUpSel")
	elseif sel == 1000 then
	    local opt = "906|添加所有神将装备|907|添加白金特权|908|添加永久月卡|909|加帮派资金|"
		opt = string.sub(opt,1,-2)
		if #opt ~= 0 then
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_725,opt)
			pUser:SetCallFun("NpcMainSel")
		end
	elseif sel == 1001 then --游客绑定入口
		j.Input2Str(pUser,LANGUAGE_LLD_0044)
		pUser:SetCallFun("Binding")
	elseif sel == 701 then --集字活动错误掉落兑换（临时）
	    local sign = true
		for i=0,4 do
			local oldId = 2992+i
			local newId = 3300+i
			local num = pUser:GetItemNum(oldId)
			if num > 0 then
				pUser:DelPackageById(oldId,num)
				pUser:AddPackage(newId,num)
				sign = false
			end
		end
		if sign then --提示没有兑换物品
			j.SendSysInfo(pUser,"您的背包没有可兑换字样")
		end
	end
end

function LevelUpSel(pUser,sel)
	if sel == 1 then
		NpcMain(pUser)
	end
end

function Binding(pUser, name, passwd)
	if(name == nil) or (passwd == nil)then
		Dialog(pUser,NPCName,LANGUAGE_LLD_0045)
		return
	end
	j.Binding(pUser, NPCName, name, passwd)
end

function CheckNewUser_JHM_all(pUser, input)
	input = j.SQLFilterForLua(input)
	if j.GetServerType() == "jianzhen" and string.len(input) == 12 then
		local str = string.sub(input, 1, 2)
		if str == "JZ" or str == "WZ" then
			j.UseJZZXJiHuoMa(pUser, input)
			return
		end
	end
	local JHM_info = j.GetJiHuoMaInfo(input)
	if JHM_info == nil then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_779)
		return
	end
	local t = FormatMission(JHM_info)
	local type = tonumber(t[1])
	local ad = tonumber(t[2])
	if ad ~= 0 and ad ~= pUser:GetAd() then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_780)
		return
	end
	
	local check = (type == 1 or type == 2 or type == 3 or type == 4)
	HD_JiHuoMa(pUser,input,type, not check)
end

function HD_JiHuoMa(pUser,code,type,notCheck)
	if code=='' then
--		j.SendSysInfo(pUser,"[c1]您输入的激活码无效！[/c]")
		return
	end
--	code = string.gsub(code," ", "")
--	if #code == 0 then
--		j.SendSysInfo(pUser,"[c1]您输入的激活码无效！[/c]")
--		return
--	end
	local LiBao = {}
--普通渠道激活码
	if j.GetServerType() == "doushen" then
		LiBao[1] = {ad = 0, bitset = 1501, name = "新手礼包", award = {{awardType = 2377, num = 1}, {awardType = 836, num = 5}, {awardType = 60000, num = 50000},},useMul = false,}
		LiBao[2] = {ad = 0, bitset = 1502, name = "进阶礼包", award = {{awardType = 2377, num = 2}, {awardType = 852, num = 5}, {awardType = 60000, num = 75000},},useMul = false,}
		LiBao[3] = {ad = 0, bitset = 1503, name = "豪华礼包", award = {{awardType = 2377, num = 3}, {awardType = 502, num = 5},{awardType = 60000, num = 100000},},useMul = false,}
		LiBao[4] = {ad = 0, bitset = 1504, name = "特权礼包", award = {{awardType = 1817, num = 5}, {awardType = 613, num = 10}, {awardType = 614, num = 10},{awardType = 60001, num = 300},},useMul = false,}
		LiBao[5] = {ad = 0, bitset = 1505, name = "大神礼包", award = {{awardType = 4404, num = 5}, {awardType = 2251, num = 10}, {awardType = 2538, num = 10},{awardType = 2818, num = 10}, {awardType = 60001, num = 500},},useMul = false,}
	--公户渠道激活码
		LiBao[6] = {ad = 0, bitset = 1506, name = "新手礼包", award = {{awardType = 2377, num = 2}, {awardType = 836, num = 10}, {awardType = 60000, num = 50000},},useMul = false,}
		LiBao[7] = {ad = 0, bitset = 1507, name = "公会礼包", award = {{awardType = 2377, num = 2}, {awardType = 852, num = 5}, {awardType = 60000, num = 75000},},useMul = false,}
		LiBao[8] = {ad = 0, bitset = 1508, name = "独家礼包", award = {{awardType = 1817, num = 3}, {awardType = 613, num = 10}, {awardType = 614, num = 10},{awardType = 60001, num = 300},},useMul = false,}
		LiBao[9] = {ad = 0, bitset = 1509, name = "特权礼包", award = {{awardType = 4404, num = 5}, {awardType = 2251, num = 10}, {awardType = 2538, num = 10},{awardType = 2818, num = 10}, {awardType = 60001, num = 500},},useMul = false,}
	--oppo预约激活码		
		LiBao[10] = {ad = 0, bitset = 1510, name = "预约礼包", award = {{awardType = 2377, num = 2}, {awardType = 836, num = 10}, {awardType = 60000, num = 50000},},useMul = false,}
	--qq群激活码
		LiBao[11] = {ad = 0, bitset = 1511, name = "入群礼包", award = {{awardType = 2377, num = 2}, {awardType =852, num = 5}, {awardType =836, num = 10},{awardType = 60000, num = 100000},},useMul = false,}
		LiBao[12] = {ad = 0, bitset = 1512, name = "特殊礼包", award = {{awardType = 4405, num = 2}, {awardType = 2377, num = 5}, {awardType = 502, num = 10},{awardType = 836, num = 30}, {awardType = 60000, num = 150000},},useMul = false,}
		LiBao[31] = {ad = 0, bitset = 1501, name = "反馈礼包", award = {{awardType = 2377, num = 2}, {awardType = 502, num = 2}, {awardType = 1101, num = 10},{awardType = 2442, num = 5},{awardType = 60000, num = 100000},},useMul = false,}
	end

	LiBao[13] = {ad = 0, bitset = 1517, name = "累充500元礼包", award = {{awardType = 2378, num = 1}, {awardType = 60000, num = 10000},},useMul = false,}
	LiBao[14] = {ad = 0, bitset = 1518, name = "累充500元礼包", award = {{awardType = 2378, num = 1}, {awardType = 60000, num = 10000},},useMul = false,}
	LiBao[15] = {ad = 0, bitset = 1519, name = "累充500元礼包", award = {{awardType = 2378, num = 1}, {awardType = 60000, num = 10000},},useMul = false,}
	
	LiBao[16] = {ad = 0, bitset = 1520, name = "累充1000元礼包", award = {{awardType = 1112, num = 2}, {awardType = 60000, num = 20000},},useMul = false,}
	LiBao[17] = {ad = 0, bitset = 1521, name = "累充1000元礼包", award = {{awardType = 1112, num = 2}, {awardType = 60000, num = 20000},},useMul = false,}
	LiBao[18] = {ad = 0, bitset = 1522, name = "累充1000元礼包", award = {{awardType = 1112, num = 2}, {awardType = 60000, num = 20000},},useMul = false,}
	
	LiBao[19] = {ad = 0, bitset = 1523, name = "累充3000元礼包", award = {{awardType = 2516, num = 20}, {awardType = 502, num = 20},},useMul = false,}
	LiBao[20] = {ad = 0, bitset = 1524, name = "累充3000元礼包", award = {{awardType = 2516, num = 20}, {awardType = 502, num = 20},},useMul = false,}
	LiBao[21] = {ad = 0, bitset = 1525, name = "累充3000元礼包", award = {{awardType = 2516, num = 20}, {awardType = 502, num = 20},},useMul = false,}
	
	LiBao[22] = {ad = 0, bitset = 1526, name = "累充6000元礼包", award = {{awardType = 1113, num = 4}, {awardType = 4406, num = 20},},useMul = false,}
	LiBao[23] = {ad = 0, bitset = 1527, name = "累充6000元礼包", award = {{awardType = 1113, num = 4}, {awardType = 4406, num = 20},},useMul = false,}
	LiBao[24] = {ad = 0, bitset = 1528, name = "累充6000元礼包", award = {{awardType = 1113, num = 4}, {awardType = 4406, num = 20},},useMul = false,}
	
	LiBao[25] = {ad = 0, bitset = 1529, name = "累充10000元礼包", award = {{awardType = 1818, num = 10}, {awardType = 1112, num = 5},},useMul = false,}
	LiBao[26] = {ad = 0, bitset = 1530, name = "累充10000元礼包", award = {{awardType = 1818, num = 10}, {awardType = 1112, num = 5},},useMul = false,}
	LiBao[27] = {ad = 0, bitset = 1531, name = "累充10000元礼包", award = {{awardType = 1818, num = 10}, {awardType = 1112, num = 5},},useMul = false,}
	
	LiBao[28] = {ad = 0, bitset = 1532, name = "累充20000元礼包", award = {{awardType = 541, num = 5}, {awardType = 549, num = 5}, {awardType = 555, num = 5},{awardType = 559, num = 5},},useMul = false,}
	LiBao[29] = {ad = 0, bitset = 1533, name = "累充20000元礼包", award = {{awardType = 541, num = 5}, {awardType = 549, num = 5}, {awardType = 555, num = 5},{awardType = 559, num = 5},},useMul = false,}
	LiBao[30] = {ad = 0, bitset = 1534, name = "累充20000元礼包", award = {{awardType = 541, num = 5}, {awardType = 549, num = 5}, {awardType = 555, num = 5},{awardType = 559, num = 5},},useMul = false,}
	

	if j.GetServerType() == "jianzhen" then
		LiBao[32] = {ad = 0, bitset = 1536, name = "预约礼包", award = {{awardType = 2377, num = 2}, {awardType = 60000, num = 50000}, {awardType = 2251, num = 10}, {awardType = 2538, num = 10}, {awardType = 2818, num = 10},},useMul = false,}
		LiBao[33] = {ad = 0, bitset = 1537, name = "进阶礼包", award = {{awardType = 2377, num = 3}, {awardType = 60000, num = 100000}, {awardType = 502, num = 5},},useMul = false,}
		LiBao[34] = {ad = 0, bitset = 1538, name = "豪华礼包", award = {{awardType = 60001, num = 500}, {awardType = 4405, num = 5},{awardType = 1817, num = 5},},useMul = false,}	
		LiBao[35] = {ad = 0, bitset = 1539, name = "入群礼包", award = {{awardType = 2377, num = 2}, {awardType = 852, num = 5},{awardType = 836, num = 10},{awardType = 60000, num = 100000},},useMul = false,}	
		LiBao[36] = {ad = 0, bitset = 1540, name = "问题反馈礼包", award = {{awardType = 2377, num = 2}, {awardType = 502, num = 2},{awardType = 1101, num = 10},{awardType = 2442, num = 5},{awardType = 60000, num = 100000},},useMul = false,}	
		LiBao[37] = {ad = 0, bitset = 1544, name = "新手礼包", award = {{awardType = 2377, num = 2}, {awardType = 60000, num = 50000},{awardType = 2251, num = 10},{awardType = 2538, num = 10},{awardType = 2818, num = 10},},useMul = false,}	
		LiBao[38] = {ad = 0, bitset = 1545, name = "进阶礼包", award = {{awardType = 2377, num = 3}, {awardType = 60000, num = 100000},{awardType = 502, num = 3},},useMul = false,}	
		LiBao[39] = {ad = 0, bitset = 1546, name = "豪华礼包", award = {{awardType = 1817, num = 5}, {awardType = 2516, num = 2},{awardType = 60001, num = 150},},useMul = false,}	
		LiBao[40] = {ad = 0, bitset = 1547, name = "特权礼包", award = {{awardType = 4405, num = 4}, {awardType = 802, num = 5},{awardType = 60000, num = 150000},},useMul = false,}	
		LiBao[41] = {ad = 0, bitset = 1548, name = "大神礼包", award = {{awardType = 2378, num = 1}, {awardType = 613, num = 30},{awardType = 613, num = 30},},useMul = false,}	
		LiBao[42] = {ad = 0, bitset = 1549, name = "豪华礼包", award = {{awardType = 1817, num = 5}, {awardType = 2516, num = 2},{awardType = 60001, num = 150},},useMul = false,}	
		LiBao[43] = {ad = 0, bitset = 0, name = "单日累冲10000元礼包", award = {{awardType = 2461, num = 8}, {awardType = 1112, num = 10},{awardType = 804, num = 8},},useMul = false,}	
		LiBao[44] = {ad = 0, bitset = 0, name = "单日累冲5000元礼包", award = {{awardType = 2461, num = 6}, {awardType = 1818, num = 10},},useMul = false,}	
		LiBao[47] = {ad = 0, bitset = 0, name = "单日累冲3000元礼包", award = {{awardType = 2461, num = 4}, {awardType = 503, num = 10},},useMul = false,}	
		LiBao[45] = {ad = 0, bitset = 0, name = "单日累冲2000元礼包", award = {{awardType = 2461, num = 3}, {awardType = 2517, num = 8},},useMul = false,}	
		LiBao[46] = {ad = 0, bitset = 0, name = "单日累冲1000元礼包", award = {{awardType = 2461, num = 2}, {awardType = 4406, num = 5},},useMul = false,}	
		LiBao[48] = {ad = 0, bitset = 0, name = "单日累冲648元礼包", award = {{awardType = 2461, num = 1}, {awardType = 1112, num = 1},},useMul = false,}	
		LiBao[49] = {ad = 0, bitset = 1551, name = "累冲20000元礼包", award = {{awardType = 541, num = 5}, {awardType = 549, num = 5},{awardType = 555, num = 5},{awardType = 559, num = 5},},useMul = false,}	
		LiBao[50] = {ad = 0, bitset = 1552, name = "累冲10000元礼包", award = {{awardType = 1818, num = 10}, {awardType = 1112, num = 5},},useMul = false,}	
		LiBao[51] = {ad = 0, bitset = 1553, name = "累冲6000元礼包", award = {{awardType = 1113, num = 4}, {awardType = 4406, num = 20},},useMul = false,}	
		LiBao[52] = {ad = 0, bitset = 1554, name = "累冲3000元礼包", award = {{awardType = 2516, num = 20}, {awardType = 502, num = 20},},useMul = false,}	
		LiBao[53] = {ad = 0, bitset = 1555, name = "累冲1000元礼包", award = {{awardType = 1112, num = 2}, {awardType = 60000, num = 20000},},useMul = false,}	
		LiBao[54] = {ad = 0, bitset = 1556, name = "累冲500元礼包", award = {{awardType = 2378, num = 1}, {awardType = 60000, num = 10000},},useMul = false,}	
		LiBao[55] = {ad = 0, bitset = 1557, name = "100元充值礼包", award = {{awardType = 2516, num = 3}, {awardType = 60000, num = 50000},},useMul = false,}	
		LiBao[56] = {ad = 0, bitset = 1558, name = "60元充值礼包", award = {{awardType = 2516, num = 2}, {awardType = 60000, num = 50000},},useMul = false,}	
		LiBao[57] = {ad = 0, bitset = 0, name = "每日30元充值礼包", award = {{awardType = 2516, num = 1}, {awardType = 60000, num = 50000},},useMul = false,}	
		LiBao[58] = {ad = 0, bitset = 1559, name = "客服礼包", award = {{awardType = 852, num = 5}, {awardType = 60000, num = 100000},},useMul = false,}	
		LiBao[59] = {ad = 0, bitset = 1560, name = "福利礼包", award = {{awardType = 502, num = 2}, {awardType = 2516, num = 2},},useMul = false,}	
		LiBao[60] = {ad = 0, bitset = 1561, name = "特权礼包", award = {{awardType = 4405, num = 4}, {awardType = 802, num = 5},},useMul = false,}	
		LiBao[61] = {ad = 0, bitset = 1562, name = "新手礼包", award = {{awardType = 2377, num = 1}, {awardType = 60000, num = 50000},},useMul = false,}	
		LiBao[62] = {ad = 0, bitset = 1563, name = "豪华礼包", award = {{awardType = 1817, num = 5}, {awardType = 2516, num = 2}, {awardType = 60001, num = 150},},useMul = true,}	
	end

	if j.GetServerType() == "bt" then
		LiBao[63] = {ad = 0, bitset = 2001, name = "媒体礼包", award = {{awardType = 2356, num = 1}, {awardType = 506, num = 100}, {awardType = 851, num = 100},},useMul = true,}	
		LiBao[64] = {ad = 0, bitset = 2002, name = "独家礼包", award = {{awardType = 4404, num = 1}, {awardType = 2357, num = 1}, },useMul = true,}	
		LiBao[65] = {ad = 0, bitset = 2003, name = "新手礼包", award = {{awardType = 2251, num = 2}, {awardType = 2538, num = 2}, {awardType = 836, num = 5}, },useMul = true,}	
		LiBao[66] = {ad = 0, bitset = 2004, name = "免费礼包", award = {{awardType = 60014, num = 500}, {awardType = 851, num = 100}, {awardType = 836, num = 5}, },useMul = true,}	
		LiBao[67] = {ad = 0, bitset = 2005, name = "累计充值300元", award = {{awardType = 2378, num = 1}, {awardType = 1817, num = 5}, {awardType = 60014, num = 10000}, {awardType = 4406, num = 1},},useMul = false,}	
		LiBao[68] = {ad = 0, bitset = 2006, name = "累计充值500元", award = {{awardType = 2460, num = 10}, {awardType = 1818, num = 1}, {awardType = 60014, num = 15000}, {awardType = 4406, num = 2},},useMul = false,}	
		LiBao[69] = {ad = 0, bitset = 2007, name = "累计充值1000元", award = {{awardType = 2409, num = 10}, {awardType = 1818, num = 2}, {awardType = 60014, num = 30000}, {awardType = 4406, num = 3},},useMul = false,}	
		LiBao[70] = {ad = 0, bitset = 2008, name = "累计充值3000元", award = {{awardType = 4503, num = 50}, {awardType = 1818, num = 3}, {awardType = 60014, num = 50000}, {awardType = 4406, num = 5},},useMul = false,}	
		LiBao[71] = {ad = 0, bitset = 2009, name = "累计充值5000元", award = {{awardType = 2806, num = 50}, {awardType = 1818, num = 5}, {awardType = 60014, num = 70000}, {awardType = 4406, num = 7},},useMul = false,}	
		LiBao[72] = {ad = 0, bitset = 2010, name = "累计充值10000元", award = {{awardType = 2463, num = 60}, {awardType = 1818, num = 8}, {awardType = 60014, num = 10000}, {awardType = 4406, num = 10},},useMul = false,}	
		LiBao[73] = {ad = 0, bitset = 2011, name = "新游礼包", award = {{awardType = 506, num = 50}, {awardType = 801, num = 50}, },useMul = false,}	
		LiBao[74] = {ad = 0, bitset = 2012, name = "进阶礼包", award = {{awardType = 2377, num = 2}, {awardType = 60001, num = 10000}, },useMul = false,}	
		LiBao[75] = {ad = 0, bitset = 2013, name = "累充166", award = {{awardType = 2251, num = 50}, {awardType = 851, num = 500}, {awardType = 2538, num = 50}, {awardType = 1112, num = 1}, },useMul = false,}	
		LiBao[76] = {ad = 0, bitset = 2014, name = "累充666", award = {{awardType = 2251, num = 150}, {awardType = 851, num = 1000}, {awardType = 2538, num = 150}, {awardType = 1112, num = 2}, },useMul = false,}	
		LiBao[77] = {ad = 0, bitset = 2015, name = "累充1666", award = {{awardType = 2251, num = 300}, {awardType = 851, num = 1500}, {awardType = 2538, num = 300}, {awardType = 1112, num = 3}, },useMul = false,}	
		LiBao[78] = {ad = 0, bitset = 2016, name = "新人狂欢礼", award = {{awardType = 2357, num = 1}, {awardType = 60014, num = 3000}, {awardType = 851, num = 30}, {awardType = 506, num = 30}, },useMul = false,}	
	end
	if j.GetServerType() == "kapai" then
		LiBao[101] = {ad = 0, bitset = 2016, name = "新手礼包", award = {{awardType = 1001, num = 10}, {awardType = 60000, num = 50000}, {awardType = 500, num = 4},},useMul = false,}
		LiBao[102] = {ad = 0, bitset = 2017, name = "豪华礼包", award = {{awardType = 1001, num = 20}, {awardType = 60000, num = 1000000}, {awardType = 1221, num = 1},},useMul = false,}
		LiBao[103] = {ad = 0, bitset = 2018, name = "福利礼包", award = {{awardType = 1001, num = 10}, {awardType = 60000, num = 50000}, {awardType = 500, num = 4},},useMul = false,}
		LiBao[104] = {ad = 0, bitset = 0, name = "bug奖励礼包", award = {{awardType = 60001, num = 1000}, {awardType = 1002, num = 50}, {awardType = 60000, num = 250000},},useMul = false,}
		LiBao[105] = {ad = 0, bitset = 0, name = "游戏意见奖励礼包", award = {{awardType = 60001, num = 1000}, {awardType = 1002, num = 50}, {awardType = 60000, num = 250000},},useMul = false,}
		LiBao[106] = {ad = 0, bitset = 0, name = "客服礼包", award = {{awardType = 60001, num = 1000}, {awardType = 1002, num = 50}, {awardType = 60000, num = 250000},},useMul = false,}
		LiBao[107] = {ad = 0, bitset = 2022, name = "入群礼包", award = {{awardType = 60001, num = 1000}, {awardType = 1001, num = 5}, {awardType = 500, num = 2},{awardType = 851, num = 500},},useMul = true,}
	end

	local myVipLevel = pUser:GetVipLevel()
	local myRoleLevel = pUser:GetLevel()
	local ad = LiBao[type].ad
	local bitset = LiBao[type].bitset
	local name = LiBao[type].name
	local award = LiBao[type].award
	local useMul = false
	local vipLevel = LiBao[type].vipLevel == nil and 0 or LiBao[type].vipLevel
	local roleLevel = LiBao[type].roleLevel == nil and 10 or LiBao[type].roleLevel
	local startTime =  LiBao[type].startTime
	local endTime =  LiBao[type].endTime
	local nowTime = os.time()
	
	if LiBao[type].useMul ~= nil then
		useMul = LiBao[type].useMul
	end

	if startTime and
		os.time{year=startTime.year,month=startTime.month,day=startTime.day,hour=startTime.hour,min=startTime.min,sec=startTime.sec} > nowTime then
		j.SendSysInfo(pUser,LANGUAGE_LLD_0148)
		return
	end
	
	if endTime and
		os.time{year=endTime.year,month=endTime.month,day=endTime.day,hour=endTime.hour,min=endTime.min,sec=endTime.sec} < nowTime then
		j.SendSysInfo(pUser,LANGUAGE_LLD_0148)
		return
	end
	
	if myRoleLevel < roleLevel then
		j.SendSysInfo(pUser,string.format(LANGUAGE_LLD_0146,roleLevel))
		return
	end
	
	if myVipLevel < vipLevel then
		j.SendSysInfo(pUser,string.format(LANGUAGE_LLD_0147,vipLevel))
		return
	end
	
	if bitset ~= 0 and pUser:HaveBitSet(bitset) and isSetLiBaoType(type) then 
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_885..name..LANGUAGE_TRANSFORM_886)
		return
	end
	
	local res = j.FindUniqueJiHuoMa(pUser,code,ad,type,useMul)
	if res == 1 then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_887)
		return
	elseif res ~= 0 then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_888)
		return
	end
	
	j.SaveDate(pUser, 51, 1,tostring(code))

	-- 领取奖励
	if award ~= nil and next(award) ~= nil then
		HD_GetAward(pUser,bitset,name, award,type, true)
	end
end

function isSetLiBaoType(libaoType)
	-- 不设置bitset的libaoType列表
	local notSettypeList = {31,36,43,44,45,46,47,48,57}
	
	for k, v in pairs(notSettypeList) do
		if v == libaoType then
			return false
		end
	end
	
	return true
end

function HD_GetAward(pUser, bitset, name, award, libaoType, showTips)
	local str = ""
	local isGet = false

	if libaoType == nil or isSetLiBaoType(libaoType) or bitset == 0 then
		pUser:SetBitSet(bitset)
	end

	if showTips then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_900..name)
	end

	for k, v in pairs(award) do
		if showTips then
			pUser:AddMaterial(v.awardType, v.num, false)
		else
			if v.awardType < 60000 then
				pUser:AddBangDingPackage(v.awardType, v.num)
				str = str .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_889
				isGet = true
			elseif v.awardType == 60000 then
				pUser:AddMoney(v.num)
				str = str .. LANGUAGE_TRANSFORM_890 .. v.num .. LANGUAGE_TRANSFORM_891
				isGet = true
			elseif v.awardType == 60001 then
				pUser:AddTongBao(v.num, 1)
				str = str .. LANGUAGE_TRANSFORM_892 .. v.num .. LANGUAGE_TRANSFORM_893
				isGet = true
			elseif v.awardType == 60003 then
				pUser:AddTongBao(v.num, 0)
				str = str .. LANGUAGE_TRANSFORM_894 .. v.num .. LANGUAGE_TRANSFORM_895
				isGet = true
			elseif v.wardType == 60006 then
				pUser:AddExp(v.num)
				str = str .. LANGUAGE_TRANSFORM_896 .. v.num .. LANGUAGE_TRANSFORM_897
				isGet = true
			elseif v.awardType == 60007 then
				pUser:AddQianNeng(v.num)
				str = str .. LANGUAGE_TRANSFORM_898 .. v.num .. LANGUAGE_TRANSFORM_899
				isGet = true
			elseif v.awardType == 70000 then
				pUser:ChongZhiJiJinFanli(v.num)
				str = str .. "可以在【活动】中领取对应的七天基金返利，本期活动已无法激活其他两种基金，请不要重复购买。"
				isGet = true
			end
		end
	end
	
	str = string.sub(str,1,-2)
	if not showTips then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_900..name..LANGUAGE_TRANSFORM_901 .. str)
	end
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

function GetState(pUser)
	return 0
end
