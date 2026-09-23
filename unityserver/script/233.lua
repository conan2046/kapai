--233.lua--夺宝大使 id=233
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 233
NPCName = nil
huodongType = 64 --夺宝抽抽抽
limitCount = 5

------------------------------------------
--以下为脚本部分：
------------------------------------------

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

	j.HDChouCall(pUser,NPCName,"NpcMainSel")
end


function NpcMainSel(pUser,sel)
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local lv = pUser:GetLevel()
		
	if sel == 1 then
		j.HDChouBet(pUser,NPCName,limitCount,"NpcMainSel")
		return
	elseif sel == 2 then
		j.HDChouIntro(pUser,NPCName,limitCount)
		return
	elseif sel == 3 then
		NpcMain(pUser)
	end
end


function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end