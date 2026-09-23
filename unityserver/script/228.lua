--228.lua--战神蚩尤(跨服) id=228
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 228
NPCName = nil

ZHANDOULI_LIMIT = 200000

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end

--	local serverType = j.GetServerType()
--	if serverType == "qq_qudao" then
--	Dialog(pUser,NPCName,LANGUAGE_SSJ_0004)
--		return
--	end
	Option(pUser,NPCName,LANGUAGE_SSJ_0004,LANGUAGE_SSJ_0005)
	pUser:SetCallFun("NpcMainSel")
end

function NpcMainSel(pUser,sel)
	if sel == 1 then
--		if not pUser:HaveBitSet(594) then
--			Option(pUser,NPCName,LANGUAGE_SSJ_0069,LANGUAGE_SSJ_0070)
--			pUser:SetCallFun("EnterKuaFuSelect")
--		else
			EnterKuaFu(pUser)
--		end
	elseif sel == 2 then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0032)
	end
end

function EnterKuaFuSelect(pUser,sel)
	if sel == 1 then
		EnterKuaFu(pUser)
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end

function EnterKuaFu(pUser)
	if not j.IsOpenKuaFu() then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0031)
		return
	end

	local lv=pUser:GetLevel()
	local LEVEL_LIMIT = j.GetFuncOpenLevel(390)
	if lv < LEVEL_LIMIT then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0006..LEVEL_LIMIT..LANGUAGE_SSJ_0007)
		return
	end
	
--		if pUser:GetTotalZhanDouLi() < ZHANDOULI_LIMIT then
--			Dialog(pUser,NPCName,LANGUAGE_SSJ_0008..math.floor(ZHANDOULI_LIMIT/10000)..LANGUAGE_SSJ_0009)
--			return
--		end

	-- 未开启		LANGUAGE_SSJ_0010
	
	if pUser:GetFightId() > 0 then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0012)
		return
	end
--[[
	if pUser:GetMission(213) ~= nil then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0013)
		return
	end
--]]
	if pUser:HaveCMission(105) then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0014)
		return
	end
	if pUser:HaveTeam() then
		Option(pUser,NPCName,LANGUAGE_SSJ_0011,LANGUAGE_SSJ_0170)
		pUser:SetCallFun("LeaveTeamOption")
		return
	end
	
	pUser:NoticeClientToKuaFuServer()
end

function LeaveTeamOption(pUser,sel)
	if sel == 1 then	-- 退队并进入
		pUser:NoticeClientToKuaFuServer()
	elseif sel == 2 then	-- 取消
		CloseInteract(pUser)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

