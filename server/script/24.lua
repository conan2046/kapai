--24.lua--擂台大使 id=24
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 24
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------

-- 40~59级的玩家参与周二擂台赛
-- 60~79级的玩家参与周四擂台赛
-- 80级及以上的玩家参与周日擂台赛
local LeiTaiTimeTab = { -- lua时间从周日开始 周六结束 1-7
	[80] = 1, -- 周日
	[40] = 3, -- 周二
	[50] = 3, -- 周二
	[60] = 5, -- 周四
	[70] = 5, -- 周四

	["startTime"] = 2000, -- 开始时间
	["endTime"] = 2030, -- 结束时间

	["hanzi"] = {
		[1] = LANGUAGE_TRANSFORM_1496,
		[2] = LANGUAGE_TRANSFORM_1497,
		[3] = LANGUAGE_TRANSFORM_1498,
		[4] = LANGUAGE_TRANSFORM_1499,
		[5] = LANGUAGE_TRANSFORM_1500,
		[6] = LANGUAGE_TRANSFORM_1501,
		[7] = LANGUAGE_TRANSFORM_1502,
	},
}

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local lv
	local ns

	ns=pUser:GetSaveVal(5)
	lv=pUser:GetLevel()

	if lv < 40 then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1033)
		return
	end
	local leiTaiLv = math.floor(lv/10)*10
	if leiTaiLv >80 then 
		leiTaiLv = 80
	elseif leiTaiLv >= 70 and leiTaiLv < 80 then
		leiTaiLv = 60
	elseif leiTaiLv >= 50 and leiTaiLv < 60 then
		leiTaiLv = 40
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_1034,LANGUAGE_TRANSFORM_1035..leiTaiLv..LANGUAGE_TRANSFORM_1036);
	pUser:SetCallFun("NpcMainSel")
end

function NpcMainSel(pUser,sel)
	if sel == 1 then -- 参加擂台赛
		LeiTaiJoin(pUser)
	elseif sel == 2 then -- 查看排名
		LeiTaiCheckRank(pUser)
	elseif sel == 3 then 
		LeiTaiReward(pUser)
	elseif sel == 4 then -- 规则说明
		local leiTaiLv = math.floor(pUser:GetLevel()/10)*10
		if leiTaiLv >80 then 
			leiTaiLv = 80
		elseif leiTaiLv >= 70 and leiTaiLv < 80 then
			leiTaiLv = 60
		elseif leiTaiLv >= 50 and leiTaiLv < 60 then
			leiTaiLv = 40
		end
		if leiTaiLv == 80 then
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_1037..leiTaiLv..LANGUAGE_TRANSFORM_1038..leiTaiLv..LANGUAGE_TRANSFORM_1039,LANGUAGE_TRANSFORM_1040)
		else
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_1041..leiTaiLv..LANGUAGE_TRANSFORM_1042..leiTaiLv.."~"..(leiTaiLv+9)..LANGUAGE_TRANSFORM_1043,LANGUAGE_TRANSFORM_1044)
		end
		pUser:SetCallFun("LeiTaiInstruct")
	end
end

function LeiTaiJoin(pUser)
	if pUser:HaveCMission(105) then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1045)
		return
	end
	if pUser:InTreasure() then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1047)
		return
	end
	if pUser:GetData8(1) >= 5 then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1048)
		return
	end
	local leiTaiLv = math.floor(pUser:GetLevel()/10)*10
	if leiTaiLv >80 then 
		leiTaiLv = 80
	elseif leiTaiLv >= 70 and leiTaiLv < 80 then
		leiTaiLv = 60
	elseif leiTaiLv >= 50 and leiTaiLv < 60 then
		leiTaiLv = 40
	end
	local addWeek = LeiTaiTimeTab[leiTaiLv]
	if not addWeek then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1049)
		return
	end
	if pUser:HaveTeam() then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1050)
		return
	end

	local timeTab = os.date("*t",os.time())
	local time = string.format("%02d:%02d-%02d:%02d",LeiTaiTimeTab.startTime/100, LeiTaiTimeTab.startTime % 100, LeiTaiTimeTab.endTime/100, LeiTaiTimeTab.endTime % 100)
	if timeTab.wday ~= addWeek then
		Dialog(pUser,NPCName,leiTaiLv..LANGUAGE_TRANSFORM_1051..LeiTaiTimeTab.hanzi[addWeek]..", "..time)
		return
	end
	local curTime = timeTab.hour * 100 + timeTab.min
	if LeiTaiTimeTab.startTime > curTime or LeiTaiTimeTab.endTime < curTime then
		Dialog(pUser,NPCName,leiTaiLv..LANGUAGE_TRANSFORM_1052..LeiTaiTimeTab.hanzi[addWeek]..", "..time)
		return
	end
	pUser:SaveEnterPos(pUser:GetSceneId(),pUser:GetX(),pUser:GetY()) -- 记录传送前的位置
	local tPos = j.GetCanWalkPos(51)
	j.TransportUser(pUser,51,tPos.x,tPos.y,6)
end

function LeiTaiCheckRank(pUser)
	if j.GetHour() == LeiTaiTimeTab.startTime then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1053)
		return
	end
	local s = j.GetPaiMing()
	if not s then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1054)
		return
	end
	local t = FormatMission(s)	
	local msg = ""
	if t[1] then 
		msg = msg..LANGUAGE_TRANSFORM_1055..t[1]
	end
	if t[2] then 
		msg = msg..LANGUAGE_TRANSFORM_1056..t[2]
	end
	if t[3] then 
		msg = msg..LANGUAGE_TRANSFORM_1057..t[3]
	end	
	Dialog(pUser,NPCName,msg)
end

function LeiTaiReward(pUser)
	if j.GetHour() == LeiTaiTimeTab.startTime then 
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1058)
		return
	end
	local jifen = j.GetLeiTaiJiFen(pUser)
	if(jifen == 0)then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1059)
		return
	end
	local s = j.GetPaiMing()
	if not s then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1060)
		return
	end
	j.ClearLeiTaiJiFen(pUser)
	local addBangDingYuanBao = 3*jifen/10
	local info = LANGUAGE_TRANSFORM_1061..jifen..LANGUAGE_TRANSFORM_1062..addBangDingYuanBao..LANGUAGE_TRANSFORM_1063
	local t = FormatMission(s)	
	local userName = pUser:GetName()
	if addBangDingYuanBao == 0 then
		addBangDingYuanBao = 1
	end

	--功勋牌 奖励
	local leiTaiLv = math.floor(pUser:GetLevel()/10)*10
	if leiTaiLv >80 then 
		leiTaiLv = 80
	end
	local gongxun_item_id = 0
	local gongxun_item_num = 0
	local serverType = j.GetServerType()
	if serverType ~= "qq_qudao" then
		if t[1] == userName then -- 第一名
			if leiTaiLv == 50 then
				gongxun_item_id = 2798
				gongxun_item_num = 10
			elseif leiTaiLv == 60 then
				gongxun_item_id = 2799
				gongxun_item_num = 4
			elseif leiTaiLv == 70 then
				gongxun_item_id = 2799
				gongxun_item_num = 6
			elseif leiTaiLv == 80 then
				gongxun_item_id = 2799
				gongxun_item_num = 8
			end
		else
			if leiTaiLv == 50 then
				gongxun_item_id = 2798
				gongxun_item_num = 5
			elseif leiTaiLv == 60 then
				gongxun_item_id = 2799
				gongxun_item_num = 2
			elseif leiTaiLv == 70 then
				gongxun_item_id = 2799
				gongxun_item_num = 3
			elseif leiTaiLv == 80 then
				gongxun_item_id = 2799
				gongxun_item_num = 4
			end
		end
	end
	if gongxun_item_id ~= 0 and gongxun_item_num ~=0 then
		pUser:AddPackage( gongxun_item_id,gongxun_item_num)
		info = info..LANGUAGE_CHY_300..j.GetItemName(gongxun_item_id).."*"..gongxun_item_num
	end

	if t[1] == userName then -- 第一名
		addBangDingYuanBao = addBangDingYuanBao + 70
		pUser:AddTongBao(addBangDingYuanBao,1)
		pUser:AddTitle(27)
		info = info..LANGUAGE_TRANSFORM_1064
		Dialog(pUser,NPCName,info)
	elseif t[2] == userName then -- 第二名
		addBangDingYuanBao = addBangDingYuanBao + 50
		pUser:AddTongBao(addBangDingYuanBao,1)
		pUser:AddTitle(28)
		info = info..LANGUAGE_TRANSFORM_1065
		Dialog(pUser,NPCName,info)
	elseif t[3] == userName then -- 第三名
		addBangDingYuanBao = addBangDingYuanBao + 30
		pUser:AddTongBao(addBangDingYuanBao,1)
		pUser:AddTitle(29)
		info = info..LANGUAGE_TRANSFORM_1066
		Dialog(pUser,NPCName,info)
	else
		pUser:AddTongBao(addBangDingYuanBao,1)
		Dialog(pUser,NPCName,info)
	end

	j.SaveDate(pUser, 40, addBangDingYuanBao,"")
end

function LeiTaiInstruct(pUser,sel)
	if sel == 2 or sel < 0 then 
		j.CloseInteract(pUser)
		return
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_1067,LANGUAGE_TRANSFORM_1068)
	pUser:SetCallFun("LeiTaiInstruct1")	
	--3：进入场地后，系统根据玩家的装备强度，随机分配比赛对手。进入战斗以后，不可逃跑。\n4：战斗中掉线的成员，按战斗失败处理。每获得5个败场，将会被传送出比赛场地，当日则不可再次进入。\n5：单局战斗最多10分钟，超过10分钟则强制结束战斗，双方均不算积分。\n6：个人擂台赛时间结束后，则根据积分判定前三，拥有持续一周的专属勋章以及额外的元宝奖励，额外的元宝奖励可以在比赛结束后通过积分兑换奖励时领取，逾期则视为放弃。	
end

function LeiTaiInstruct1(pUser,sel)
	if sel == 2 or sel < 0 then 
		j.CloseInteract(pUser)
		return
	end
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1069)
	pUser:SetCallFun("")
end

function MissionBannerCallBack0(pUser,missionId)
	--AddMison
	--Call剧情Dialog
	if missionId==1 then

	end
end

function MissionBannerCallBack1(pUser,missionId)
	--DelMison
	--AddAward
	if missionId==1 then


	end
end

function GetState(pUser)
	local s 


	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

