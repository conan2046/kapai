--11.lua--帮战传送员 id=11
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

thisId = 11
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_4633,LANGUAGE_TRANSFORM_4634)
	pUser:SetCallFun("SelectOption")
end

function SelectOption(pUser,sel)
	if sel == 1 then
		if pUser:GetTeam() ~= 0 and pUser:GetTeam() ~= pUser:GetRoleId() then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4635)
			return
		end
		if pUser:GetBangPai() == 0 then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4636)
			return
		end
		
		local wday = j.GetWeekDay()
		local hour = j.GetHour()
		local minute = j.GetMinute()
		-- 每周三、周六 20:00-20:25可进
		if wday == 3 or wday == 6 then
			if hour == 20 and minute < 20 then
				-- if pUser:GetExtData16(7) < 300 or pUser:GetExtData16(7) > 60000 then
				-- 	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4637)
				-- 	return
				-- end
				
				-- if pUser:GetTeam() > 0 then
				-- 	for i=1,5 do
				-- 		local member = j.GetTeamMember(pUser, i)
				-- 		if member ~= nil then
				-- 			if member:GetExtData16(7) < 300 or member:GetExtData16(7) > 60000 then
				-- 				j.SendSysInfo(pUser,"[c1]"..member:GetName()..LANGUAGE_TRANSFORM_4638)
				-- 				return
				-- 			end
				-- 		end	
				-- 	end
				-- end
				
				j.EnterBPFightScene(pUser)
				return
			elseif hour == 20 and minute >= 20 and minute < 25 then
				if j.GetBZ_WIN_BANG_ID() == pUser:GetBangPai() then
					j.EnterBPFightScene(pUser)
					return
				end
			end
		end
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4640)
	elseif sel == 2 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_4641,LANGUAGE_TRANSFORM_4642)
		pUser:SetCallFun("SelectOption_1")
	elseif sel == 3 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4641)
	elseif sel == 4 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4643)
	end
end

function SelectOption_1(pUser,sel)
	if sel == 1 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4645)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

