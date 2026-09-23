--22816.lua--跨服参与礼包
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	pUser:DelPackage(pos)
	
	local itemId = 801
	local ZhanWeiItemNum = 2
	local money = 1000
	pUser:AddBangDingPackage(itemId,ZhanWeiItemNum)
	pUser:AddMoney(money)
	
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1995..j.GetItemName(itemId).."*"..ZhanWeiItemNum..","..LANGUAGE_SSJ_0033.."*"..money.."[/c]")
	j.SaveDate(pUser,710,2816,"")
end

