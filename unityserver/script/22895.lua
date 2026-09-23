--22895.lua--5990元积分卡 11980积分
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

ADD_JF = 11980

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	if j.AddHongLiJiFen(pUser,ADD_JF) then
		pUser:DelPackage(pos)
		j.SaveDate(pUser,45,ADD_JF,"")
		j.SendSysInfo(pUser,string.format(LANGUAGE_LLD_0069,ADD_JF))
	else
	j.SendSysInfo(pUser,LANGUAGE_LLD_0070)
	end
end

