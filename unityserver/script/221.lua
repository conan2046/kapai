--221-- 221.lua --圣诞树
require "global"
-------------------------
Dialog = j.Dialog       --对话
DialogS_Start = j.DialogS_Start --剧情对话开始
DialogS_Doing = j.DialogS_Doing --剧情对话过程
DialogS_End = j.DialogS_End --剧情对话结束
ShowGuidance = j.ShowGuidance --任务引导
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
SMessage_End = j.SMessage_End
Dialog_End = j.Dialog_End
CloseInteract=j.CloseInteract
TransportUser=j.TransportUser
MissionBanner = j.MissionBanner --新版任务面板接取模式

thisId = 70
NPCName = nil
NPCID = 221
-----------------------
local costYB = 10

local AWARD_OTHER = {}

AWARD_OTHER[1] = {ratio = 1491, award = {{awardType = 2548, num = 1},}}
AWARD_OTHER[2] = {ratio = 2733, award = {{awardType = 2549, num = 1},}}
AWARD_OTHER[3] = {ratio = 3106, award = {{awardType = 2550, num = 1},}}
AWARD_OTHER[4] = {ratio = 3292, award = {{awardType = 2551, num = 1},}}
AWARD_OTHER[5] = {ratio = 7019, award = {{awardType = 2552, num = 1},}}
AWARD_OTHER[6] = {ratio = 8882, award = {{awardType = 2553, num = 1},}}
AWARD_OTHER[7] = {ratio = 9627, award = {{awardType = 2554, num = 1},}}
AWARD_OTHER[8] = {ratio = 10000, award = {{awardType = 2555, num = 1},}}

local AWARD_IOS = {}
AWARD_IOS[1] = {ratio = 1491, award = {{awardType = 851, num = 1},}}
AWARD_IOS[2] = {ratio = 2733, award = {{awardType = 506, num = 1},}}
AWARD_IOS[3] = {ratio = 3106, award = {{awardType = 2310, num = 1},}}
AWARD_IOS[4] = {ratio = 3292, award = {{awardType = 611, num = 1},}}
AWARD_IOS[5] = {ratio = 7019, award = {{awardType = 801, num = 1},}}
AWARD_IOS[6] = {ratio = 8882, award = {{awardType = 614, num = 1},}}
AWARD_IOS[7] = {ratio = 9627, award = {{awardType = 501, num = 1},}}
AWARD_IOS[8] = {ratio = 10000, award = {{awardType = 2370, num = 1},}}

local bless = {LANGUAGE_LLD_0005,LANGUAGE_LLD_0006,LANGUAGE_LLD_0007,LANGUAGE_LLD_0008,LANGUAGE_LLD_0009,LANGUAGE_LLD_0010,LANGUAGE_LLD_0011,LANGUAGE_LLD_0012,
				LANGUAGE_LLD_0013,LANGUAGE_LLD_0014}

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

	j.ChristmasTreeShow(pUser,NPCName,"NpcMainSel",costYB)
end

function NpcMainSel(pUser,sel)
	if sel==1 then
		if pUser:GetLevel() < 30 then
			Dialog(pUser,NPCName,LANGUAGE_CHY_293)
			return
		end
		if pUser:GetExtData8(387) >= 5  then
			Dialog(pUser,NPCName,LANGUAGE_CHY_290)
			return
		end
		if pUser:GetExtData32(291) +5*60 > j.GetSystemTime() then
			Dialog(pUser,NPCName,LANGUAGE_CHY_291)
			return
		end
		if pUser:HaveTeam() then
			Dialog(pUser,NPCName,LANGUAGE_CHY_292)
			return
		end
		j.EnterWaitingList(pUser:GetRoleId(),NPCID,0)
		j.Collect(pUser,NPCID,0,1,3,LANGUAGE_SSJ_0117)
		pUser:SetCallFun("CollectCall")	
	elseif sel == 2 then
		GiveBless(pUser)
	elseif sel == 3 then
		j.ChristmasTreeBangShow(pUser,NPCName,"NpcMainSel")
	elseif sel == 4 then
		local opt = ""
		opt = opt .. LANGUAGE_LLD_0076
		opt = opt .. LANGUAGE_LLD_0077
		opt = opt .. LANGUAGE_LLD_0075
		opt = string.sub(opt,1,-2)

		Option(pUser,NPCName,LANGUAGE_LLD_0078,opt)
		pUser:SetCallFun("NpcMainSel")
	elseif sel == 5 then
		j.GetChristmasTreeGrowAward(pUser,NPCName)
	elseif sel == 6 then
		j.ChristmasTreeZhuangBan(pUser,NPCName,1)
	elseif sel == 7 then
		j.ChristmasTreeZhuangBan(pUser,NPCName,2)
	end
end


function GiveBless(pUser)
	local serverType = j.GetServerType()
	if pUser:GetTongBao() < costYB then
		j.ShowJumpNotice(pUser, 1)  -- 1 元宝跳转
	else
		pUser:AddTongBao(-costYB)
		local AWARD = {}
		if serverType == "qq_ios" or serverType == "ali_ios" then
			AWARD = AWARD_IOS
		else
			AWARD = AWARD_OTHER
		end
		
		local maxNum = #AWARD
		local r=math.random(AWARD[maxNum].ratio)
		for k, v in ipairs(AWARD) do
			if r <= v.ratio then
				GetAward(pUser,v.award)
				break
			end 
		end
		--GetBless(pUser)
	end
end

function GetBless(pUser)
	local r = math.random(1, #bless)
	local str = string.format(bless[r], pUser:GetName())
	j.SysInfoToAllUser(str)
end

function GetAward(pUser, award)
	local str = ""
	local serverType = j.GetServerType()
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			str = str .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_889
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			str = str .. LANGUAGE_TRANSFORM_890 .. v.num .. LANGUAGE_TRANSFORM_891
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			str = str .. LANGUAGE_TRANSFORM_892 .. v.num .. LANGUAGE_TRANSFORM_893
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			str = str .. LANGUAGE_TRANSFORM_894 .. v.num .. LANGUAGE_TRANSFORM_895
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			str = str .. LANGUAGE_TRANSFORM_896 .. v.num .. LANGUAGE_TRANSFORM_897
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			str = str .. LANGUAGE_TRANSFORM_898 .. v.num .. LANGUAGE_TRANSFORM_899
		end
	end
	
	if serverType == "taiwan" then
		str = string.sub(str,1,-4)
	else
		str = string.sub(str,1,-3)
	end
	
	str = "[c4]"..LANGUAGE_LLD_0015..":".. str.."[c/]"
	j.SendSysInfo(pUser,str)
end

function GetState(pUser)
	return 0
end

function GetNpcPos(state)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE	
end

function CollectCall(pUser,index)
	j.StartToFight(pUser,NPCID,0);	
end
