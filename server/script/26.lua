--26.lua--战神蚩尤(离开) id=26
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式

thisId = 26
NPCName = nil

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,NPCName,LANGUAGE_SSJ_0004,LANGUAGE_SSJ_0015)
	pUser:SetCallFun("KuaFuOption")
end

function KuaFuOption(pUser,sel)
	if sel==1 then
		if pUser:HaveTeam() then
			Option(pUser,NPCName,LANGUAGE_SSJ_0172,LANGUAGE_SSJ_0171)
			pUser:SetCallFun("LeaveTeamOption")
		else
			pUser:NoticeClientToGameServer()
		end
	elseif sel == 2 then	-- 清除捉妖任务
		Option(pUser,NPCName,LANGUAGE_SSJ_0108,LANGUAGE_SSJ_0109)
		pUser:SetCallFun("SelectOption")
	end
end

function LeaveTeamOption(pUser,sel)
	if sel == 1 then	-- 退队并进入
		pUser:NoticeClientToGameServer()
	elseif sel == 2 then	-- 取消
		CloseInteract(pUser)
	end
end

function SelectOption(pUser,sel)
	if sel == 1 then	-- 返回
		NpcMain(pUser,0)
	elseif sel == 2 then
		if pUser:GetMission(806) ~= nil then
			pUser:DelMission(806)
			j.DelNpc(pUser,231)
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0110)
		else
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0111)
		end
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end


