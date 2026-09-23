--230.lua--擎天战神 id=230
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 230
NPCName = nil

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
--[[
	local serverType = j.GetServerType()
	if serverType == "yuenan" then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0035)
		return
--	elseif serverType == "qq_qudao_kf" then
--		Dialog(pUser,NPCName,LANGUAGE_SSJ_0035)
--		return
	end
--]]
	local lvLimit = j.GetFuncOpenLevel(39)
	if pUser:GetLevel() < lvLimit then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0168..lvLimit..LANGUAGE_SSJ_0169)
		return
	end
	if j.InKuaFu() then
		Option(pUser,NPCName,LANGUAGE_SSJ_0035,"1|"..LANGUAGE_SSJ_0036)
		pUser:SetCallFun("NpcMainSel")
	else
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0035)
	end
end

function NpcMainSel(pUser,sel)
	if sel == 1 then
		if pUser:GetTeam() == pUser:GetRoleId() then
			if j.InFuncionLevelReadyTime(39) then
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0037)
			else
				j.EnterTeamKunLunShan(pUser)
			end
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0038)
		end
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

