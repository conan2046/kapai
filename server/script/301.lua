-- 护宝小妖  301 藏宝图使用
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示

thisId = 301

function NpcMain(pUser,missionId)
	local itemid = pUser:GetExtData16(62)
	if itemid == 0 then
		j.DelNpc(pUser, thisId)
		return
	end
	if pUser:GetItemNum(itemid) == 0 then
		j.DelNpc(pUser, thisId)
		return
	end
	
	j.WabaoFight(pUser)
	pUser:SetCallFun("BattleOver")
end

function BattleOver(pUser,state)
	if state==0 then
		WbUseCangBaotuFightCallBack(pUser,thisId)
	elseif state==1 then
		j.CloseInteract(pUser)
	else
		j.CloseInteract(pUser)
	end
end

function GetState(pUser)
	local s 
	local id
	local t
	local lv=pUser:GetLevel()
	
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
