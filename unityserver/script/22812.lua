--22812.lua--跨服优秀礼包
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
	local ZhanWeiItemNum = 5
	local money = 2500
	local item1 = 2799
	local num1 = 1
	local item2 = 2798
	local num2 = 7
	pUser:AddBangDingPackage(itemId,ZhanWeiItemNum)
	pUser:AddMoney(money)
	pUser:AddBangDingPackage(item1,num1)
	pUser:AddBangDingPackage(item2,num2)
	
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1995..j.GetItemName(itemId).."*"..ZhanWeiItemNum..","..j.GetItemName(item1).."*"..num1..","..j.GetItemName(item2).."*"..num2..","..LANGUAGE_SSJ_0033.."*"..money.."[/c]")
	j.SaveDate(pUser,710,2812,"")
end

