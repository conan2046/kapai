--22560.lua--帮战优秀礼包
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
	
	local award = {{awardType = 852, num = 3}, {awardType = 614, num = 8}, {awardType = 2539, num = 1},{awardType = 60000, num = 10000},}
	local info = ""
		
	pUser:DelPackage(pos)
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			info = info .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_133
			isGet = true
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			info = info .. LANGUAGE_TRANSFORM_134 .. v.num .. LANGUAGE_TRANSFORM_135
			isGet = true
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			info = info .. LANGUAGE_TRANSFORM_136 .. v.num .. LANGUAGE_TRANSFORM_137
			isGet = true
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			info = info .. LANGUAGE_TRANSFORM_138 .. v.num .. LANGUAGE_TRANSFORM_139
			isGet = true
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			info = info .. LANGUAGE_TRANSFORM_140 .. v.num .. LANGUAGE_TRANSFORM_141
			isGet = true
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			info = info .. LANGUAGE_TRANSFORM_142 .. v.num .. LANGUAGE_TRANSFORM_143
			isGet = true
		end
	end
	
	info = string.sub(info,1,-3)
	info = LANGUAGE_TRANSFORM_144..info.."[/c]"
	j.SendSysInfo(pUser,info)
	j.SaveUseItemStr(pUser:GetRoleId(), pItem.tmplId,LANGUAGE_TRANSFORM_145, 1,"", "")
end
