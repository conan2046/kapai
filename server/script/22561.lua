--22561.lua--帮战参与礼包
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
	
	local award = {{awardType = 852, num = 1}, {awardType = 614, num = 5}, {awardType = 2538, num = 2},{awardType = 60000, num = 5000},}
	local info = ""
		
	pUser:DelPackage(pos)
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			info = info .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_4542
			isGet = true
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			info = info .. LANGUAGE_TRANSFORM_4543 .. v.num .. LANGUAGE_TRANSFORM_4544
			isGet = true
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			info = info .. LANGUAGE_TRANSFORM_4545 .. v.num .. LANGUAGE_TRANSFORM_4546
			isGet = true
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			info = info .. LANGUAGE_TRANSFORM_4547 .. v.num .. LANGUAGE_TRANSFORM_4548
			isGet = true
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			info = info .. LANGUAGE_TRANSFORM_4549 .. v.num .. LANGUAGE_TRANSFORM_4550
			isGet = true
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			info = info .. LANGUAGE_TRANSFORM_4551 .. v.num .. LANGUAGE_TRANSFORM_4552
			isGet = true
		end
	end
	
	info = string.sub(info,1,-3)
	info = LANGUAGE_TRANSFORM_4553..info.."[/c]"
	j.SendSysInfo(pUser,info)
	j.SaveUseItemStr(pUser:GetRoleId(), pItem.tmplId,LANGUAGE_TRANSFORM_4554, 1,"", "")
end
