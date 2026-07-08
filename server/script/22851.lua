--22851.lua--11K充值卡,300元宝
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

ADD_YB = 300

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	pUser:DelPackage(pos)

	pUser:AddTongBao(ADD_YB)
	pUser:CheckChongZhiHuoDong(true,math.floor(ADD_YB/150*5500),ADD_YB)
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1995..ADD_YB..LANGUAGE_TRANSFORM_1996..ADD_YB..LANGUAGE_TRANSFORM_1997)
	j.SaveDate(pUser,21,ADD_YB,"")
	j.setMarriageRmbTimeByRoleID(pUser:GetRoleId())
end

