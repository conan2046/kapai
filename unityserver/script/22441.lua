--22441.lua 低级藏宝图
-------------------------
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract			
require "global"

-----------------------------
function Main(pUser, pos, num)
	local pItem = pUser:GetItem(pos)
	local npcId=301
	if pItem == nil then
		j.SendSysInfo(pUser, LANGUAGE_SSJ_0133)
		return
	end
	local map, mPos = GetXunbaoMap(pItem.extData)
	if map ~= pUser:GetSceneId() or math.abs(mPos.x - pUser:GetX()) > 100 or math.abs(mPos.y - pUser:GetY()) > 100 then
		j.SendSysInfo(pUser, LANGUAGE_SSJ_0153)
		return
	end
	pUser:DelPackage(pos)
	local rand = math.random(1,100)
	if rand > 20 then
		j.GetAwardFromLevelAward(pUser, 62900, false)
	else
		j.WabaoFight(pUser)		
		pUser:SetCallFun("BattleOver")
	end
	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_45)
end

function BattleOver(pUser,state)
	if state==0 then
		-- 发送奖励
		j.GetAwardFromLevelAward(pUser, 62900, true)
		-- WbUseCangBaotuFightCallBack(pUser,thisId)
	elseif state==1 then
		j.CloseInteract(pUser)
	else
		j.CloseInteract(pUser)
	end
end


