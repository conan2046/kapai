--23.lua--宠物仙子 id=23
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner
ShowGuidance = j.ShowGuidance
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End 	--剧情对话结束 

thisId = 23
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser, missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s = ""
	local lv = pUser:GetLevel()
	local op = ""
	local openlv = j.GetFuncOpenLevel(16)
	if lv >= openlv then
		if j.GetHour() == 12 and j.GetMinute() < 20 then
			op = op..LANGUAGE_TRANSFORM_1692 -- 双倍
		else
			op = op..LANGUAGE_TRANSFORM_1693 -- 
		end
	end
	if op == "" then
		op = op..LANGUAGE_TRANSFORM_1694  -- 离开
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_1695,op)
	pUser:SetCallFun("DoSelect")
end

function DoSelect(pUser,input)
	if input == 7 then	-- 选择护送神将
		if pUser:HaveTeam() then
			Option(pUser,NPCName,LANGUAGE_ZQX_0039,LANGUAGE_ZQX_0038)
			pUser:SetCallFun("LeaveTeamOption")
			return
		end
		if not DodayCanHuSongShenJiangMission(pUser) then
			Dialog(pUser,NPCName, LANGUAGE_TRANSFORM_1713)
			j.UpdateNpcState(pUser, thisId, 0)
		else
			if pUser:HaveCMission(MISSION_ID_HUSONG) then
				Dialog(pUser,NPCName, LANGUAGE_SSJ_0146)
				return
			end

			HuSongFunc(pUser)
		end
	end
end

function LeaveTeamOption(pUser,sel)
	if sel == 1 then	-- 退队并进入
		j.UserLeaveTeam(pUser)
		DoSelect(pUser, 7)
	elseif sel == 2 then	-- 取消
		CloseInteract(pUser)
	end
end

function HuSongSelect(pUser,sel)
	if sel == 1 then
		HuSongFunc(pUser)
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end

function HuSongFunc(pUser)
	if pUser:InTreasure() then	-- 正在寻宝不能护送
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1710)
		return
	end

	if pUser:HaveTeam() then	-- 组队状态不能护送
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1711)
		return
	end

	if pUser:GetLevel() < 30 then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0147)
		return
	end

	-- GetExtData8(81) 护送神将任务 获取今日护送任务的次数
	if pUser:GetExtData8(81) < 5 then
		j.ShowHuSongShenShowTaskPanel(pUser)
	end
end

function GetState(pUser)
	local openlv = j.GetFuncOpenLevel(16)
	local userlv = pUser:GetLevel()
	if userlv < openlv then
		return 0
	end
	if not pUser:HaveCMission(MISSION_ID_HUSONG) then
		if DodayCanDoShaDiDuoBaoMission(pUser) then
			return 1  -- 可接
		end
	end
	return 0 
end

function GetChatMsg(pUser)
	return NPC_HEAD_HUSONG
end


