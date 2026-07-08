--22493.lua--98元充值卡
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

ADD_YB = 98*YUANBAO_LILV

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil or num == 0 then
		return
	end
	if pItem.num < num then
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0148)
		return
	end

	pUser:DelPackage(pos,num)

	local yb = ADD_YB*num
	pUser:AddTongBao(yb)
	pUser:CheckChongZhiHuoDong(true,math.floor(yb/YUANBAO_LILV),yb)
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4625..yb..LANGUAGE_TRANSFORM_4626..yb..LANGUAGE_TRANSFORM_4627)
	j.SaveDate(pUser,21,yb,pItem.tmplId.."*"..num)
	j.setMarriageRmbTimeByRoleID(pUser:GetRoleId())
end

