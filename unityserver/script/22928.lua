--22928.lua 背包扩容券
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil or num > 200 then
		return
	end
	
	local unOpenNum = j.GetUnOpenPackageNum(pUser)
	if unOpenNum == 0 then
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0046)
		return
	else
		if num > unOpenNum then
			num = unOpenNum
		end
		if pUser:AddMaxPackageNum(num) then
			pUser:DelPackage(pos,num)
			j.SaveDate(pUser,47,2928,""..num)
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0047..num..LANGUAGE_SSJ_0058)
		else
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0046)
			return
		end
	end
end

