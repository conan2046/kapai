--22442.lua 高级藏宝图
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
	
	j.SendZhuanpanFromLevelAward(pUser, 62901, 15)
	pUser:DelPackage(pos)
	
	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_46)
end