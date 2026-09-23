--22557.lua--帮战霸主礼包
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
	
	local award = {{awardType = 853, num = 4}, {awardType = 614, num = 15}, {awardType = 2539, num = 6},{awardType = 60000, num = 40000},}
	local info = ""
		
	pUser:DelPackage(pos)
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			info = info .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_226
			isGet = true
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			info = info .. LANGUAGE_TRANSFORM_227 .. v.num .. LANGUAGE_TRANSFORM_228
			isGet = true
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			info = info .. LANGUAGE_TRANSFORM_229 .. v.num .. LANGUAGE_TRANSFORM_230
			isGet = true
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			info = info .. LANGUAGE_TRANSFORM_231 .. v.num .. LANGUAGE_TRANSFORM_232
			isGet = true
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			info = info .. LANGUAGE_TRANSFORM_233 .. v.num .. LANGUAGE_TRANSFORM_234
			isGet = true
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			info = info .. LANGUAGE_TRANSFORM_235 .. v.num .. LANGUAGE_TRANSFORM_236
			isGet = true
		end
	end
	
	info = string.sub(info,1,-3)
	info = LANGUAGE_TRANSFORM_237..info.."[/c]"
	j.SendSysInfo(pUser,info)
	j.SaveUseItemStr(pUser:GetRoleId(), pItem.tmplId,LANGUAGE_TRANSFORM_238,1, "", "")
end
