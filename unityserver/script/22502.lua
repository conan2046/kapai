--22502.lua--648元充值卡
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

ADD_YB = 648 * YUANBAO_LILV

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
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1992..yb..LANGUAGE_TRANSFORM_1993..yb..LANGUAGE_TRANSFORM_1994)
	j.SaveDate(pUser,21,yb,pItem.tmplId.."*"..num)
	j.setMarriageRmbTimeByRoleID(pUser:GetRoleId())
end

