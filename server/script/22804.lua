--22804.lua--优秀功勋礼包
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
	
	local award = {{awardType = 2798, num = 5}}
	local info = ""
		
	pUser:DelPackage(pos)
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			info = info .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_920
			isGet = true
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			info = info .. LANGUAGE_TRANSFORM_921 .. v.num .. LANGUAGE_TRANSFORM_922
			isGet = true
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			info = info .. LANGUAGE_TRANSFORM_923 .. v.num .. LANGUAGE_TRANSFORM_924
			isGet = true
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			info = info .. LANGUAGE_TRANSFORM_925 .. v.num .. LANGUAGE_TRANSFORM_926
			isGet = true
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			info = info .. LANGUAGE_TRANSFORM_927 .. v.num .. LANGUAGE_TRANSFORM_928
			isGet = true
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			info = info .. LANGUAGE_TRANSFORM_929 .. v.num .. LANGUAGE_TRANSFORM_930
			isGet = true
		end
	end
	
	info = string.sub(info,1,-3)
	info = LANGUAGE_TRANSFORM_931..info.."[/c]"
	j.SendSysInfo(pUser,info)
	j.SaveUseItemStr(pUser:GetRoleId(), pItem.tmplId, j.GetItemName(pItem.tmplId), 1,"", "")
end
