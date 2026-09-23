--22930.lua 免战牌
-------------------------
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract			
require "global"


DURING_TIME = 5
SHENJIEMIJING_SCENE_ID = 74
-----------------------------
function Main(pUser, pos,num)
	if not j.InKuaFu() or pUser:GetSrcSceneId() ~= SHENJIEMIJING_SCENE_ID then
		return j.SendSysInfo(pUser,LANGUAGE_LLD_0072)
	end
	
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end

	pUser:DelPackage(pos)
	
	local lastUsedTime = pUser:GetExtData32(365)
	local nowTime = os.time()
	
	if nowTime > lastUsedTime then
		pUser:SetExtData32(365,nowTime + DURING_TIME * 60)
	else
		pUser:SetExtData32(365,lastUsedTime + DURING_TIME * 60)
	end
	j.SendMianZhanPaiCD(pUser)
	return j.SendSysInfo(pUser,string.format(LANGUAGE_LLD_0073,DURING_TIME))
end


