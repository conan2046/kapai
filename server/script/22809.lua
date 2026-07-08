--22809.lua--跨服战霸主礼包
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

ZhanWeiItem = {2596,2606,2616,2626,2636,2646,2656,2666,2676,2686,2696,2706,2716}
ZhanWeiItemNum = 1

function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	pUser:DelPackage(pos)
	
	local itemId = ZhanWeiItem[j.Random(1,#ZhanWeiItem)]
	local money = 8000
	local item1 = 2799
	local num1 = 3
	local item2 = 2798	
	local num2 = 16
	pUser:AddBangDingPackage(itemId,ZhanWeiItemNum)
	pUser:AddMoney(money)
	pUser:AddBangDingPackage(item1,num1)
	pUser:AddBangDingPackage(item2,num2)
	
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1995..j.GetItemName(itemId).."*"..ZhanWeiItemNum..","..j.GetItemName(item1).."*"..num1..","..j.GetItemName(item2).."*"..num2..","..LANGUAGE_SSJ_0033.."*"..money.."[/c]")
	j.SaveDate(pUser,710,2809,"")
end

