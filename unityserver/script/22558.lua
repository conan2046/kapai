--22558.lua--帮战强者礼包
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
	
	local award = {{awardType = 853, num = 2}, {awardType = 614, num = 10}, {awardType = 2539, num = 3},{awardType = 60000, num = 30000},}
	local info = ""
		
	pUser:DelPackage(pos)
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			info = info .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_525
			isGet = true
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			info = info .. LANGUAGE_TRANSFORM_526 .. v.num .. LANGUAGE_TRANSFORM_527
			isGet = true
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			info = info .. LANGUAGE_TRANSFORM_528 .. v.num .. LANGUAGE_TRANSFORM_529
			isGet = true
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			info = info .. LANGUAGE_TRANSFORM_530 .. v.num .. LANGUAGE_TRANSFORM_531
			isGet = true
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			info = info .. LANGUAGE_TRANSFORM_532 .. v.num .. LANGUAGE_TRANSFORM_533
			isGet = true
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			info = info .. LANGUAGE_TRANSFORM_534 .. v.num .. LANGUAGE_TRANSFORM_535
			isGet = true
		end
	end
	
	info = string.sub(info,1,-3)
	info = LANGUAGE_TRANSFORM_536..info.."[/c]"
	j.SendSysInfo(pUser,info)
	j.SaveUseItemStr(pUser:GetRoleId(), pItem.tmplId,LANGUAGE_TRANSFORM_537, 1,"", "")
end
