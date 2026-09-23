--232.lua 喜糖
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
DialogS_Start = j.DialogS_Start --剧情对话开始
DialogS_Doing = j.DialogS_Doing --剧情对话过程
DialogS_End = j.DialogS_End --剧情对话结束
ShowGuidance = j.ShowGuidance --任务引导
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

G_DAY = 0

Award_Item_List = 
{
-- 		ratio,itemId,num,gonggao(1show),save
	[1] = {1674,60000,15000,0,999999,0},
	[2] = {1004,2370,5,0,999999,0},
	[3] = {836,2310,1,0,999999,0},
	[4] = {372,2377,1,0,999999,0},
	[5] = {50,2378,1,0,999999,0},
	[6] = {50,2379,1,1,999999,0},
	[7] = {1004,851,1,0,999999,0},
	[8] = {836,507,2,0,999999,0},
	[9] = {1004,614,5,0,999999,0},
	[10] = {1004,613,5,0,999999,0},
	[11] = {1004,801,1,0,999999,0},
	[12] = {335,802,1,0,999999,0},
	[13] = {112,803,1,1,999999,0},
	[14] = {143,2519,1,1,999999,0},
	[15] = {143,2544,1,1,999999,0},
	[16] = {143,2422,1,1,999999,0},
	[17] = {143,2423,1,1,999999,0},
	[18] = {143,2424,1,1,999999,0},
}

NPCID = 232
------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId,index)
--	j.Collect(pUser,NPCID,index,1,2,LANGUAGE_SSJ_0116)
--	pUser:SetCallFun("CollectCall")
end

function CollectCall(pUser,index)
	if not j.FindDynamicNpcWithIndex(pUser,NPCID,index) then
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0048)
		return
	end
	j.DelDynamicNpcWithIndex(pUser,NPCID,index)
	
	if G_DAY ~= j.GetDay() then
		G_DAY = j.GetDay()
		for i=1,#Award_Item_List,1 do
			Award_Item_List[i][6] = 0
		end
	end
	
	local total = 0
	for i=1,#Award_Item_List,1 do
		total = total+Award_Item_List[i][1]
	end
	local r = j.Random(1,total)
	local ratio = 0
	local index = 0
	for i=1,#Award_Item_List,1 do
		ratio = ratio + Award_Item_List[i][1]
		if r <= ratio then
			if Award_Item_List[i][6] >= Award_Item_List[i][5] then	-- 数量不足
				index = 1
			else
				index = i
			end
			break
		end
	end
	
	if index == 0 then
		return
	end
	if Award_Item_List[index][2] == 60000 then	-- 金币
		pUser:AddMoney(Award_Item_List[index][3])
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4823..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0049..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4825)
		end
	elseif Award_Item_List[index][2] == 60001 then	-- 绑元
		pUser:AddTongBao(Award_Item_List[index][3],1)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4826..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0050..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4828)
		end
	elseif Award_Item_List[index][2] == 60003 then	-- 元宝
		pUser:AddTongBao(Award_Item_List[index][3],0)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4829..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0051..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4831)
		end
	elseif Award_Item_List[index][2] == 60006 then	-- 经验
		pUser:AddExp(Award_Item_List[index][3])
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4832..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0052..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4834)
		end
	elseif Award_Item_List[index][2] == 60007 then	-- 潜能
		pUser:AddQianNeng(Award_Item_List[index][3])
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4835..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0053..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4837)
		end
	else
		pUser:AddBangDingPackage(Award_Item_List[index][2],Award_Item_List[index][3])
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4838..j.GetItemName(Award_Item_List[index][2]).."*"..Award_Item_List[index][3].."[c/]")
		if Award_Item_List[index][4] == 1 then	-- 公告
			j.SysInfoToAllUser("[c13]"..pUser:GetName()..LANGUAGE_SSJ_0054..j.GetItemName(Award_Item_List[index][2]).."*"..Award_Item_List[index][3]..LANGUAGE_TRANSFORM_4840)
		end
	end
	Award_Item_List[index][6] = Award_Item_List[index][6]+1
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

