--236.lua--微微小仙 id=236
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 236
NPCName = nil

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

	opt = opt..LANGUAGE_LLD_0155
	opt = opt..LANGUAGE_LLD_0156

	opt = string.sub(opt,1,-2)
	if #opt ~= 0 then
		Option(pUser,NPCName,LANGUAGE_LLD_0153,opt)
		pUser:SetCallFun("NpcMainSel")
	else
		Dialog(pUser,NPCName,LANGUAGE_LLD_0153)
	end
end

function NpcMainSel(pUser,sel)
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local lv = pUser:GetLevel()
	local opt = ""
		
	if sel == 1 then
		opt = opt..LANGUAGE_LLD_0159
		opt = opt..LANGUAGE_LLD_0158
		Option(pUser,NPCName,LANGUAGE_LLD_0157,opt)
		pUser:SetCallFun("NpcMainSel")
		return
	elseif sel == 2 then
		j.ShowShopYaoShiPanel(pUser)
		return
	elseif sel == 3 then
		NpcMain(pUser)
		return
	elseif sel == 4 then
		opt = opt..LANGUAGE_LLD_0160
		opt = opt..LANGUAGE_LLD_0158
		Option(pUser,NPCName,LANGUAGE_LLD_0161,opt)
		pUser:SetCallFun("NpcMainSel")
		return
	end
end


function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end