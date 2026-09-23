--22817.lua--功勋宝箱
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

local AWARD = {}
AWARD[1] = {ratio = 4470, award = {{awardType = 2798, num = 2},}}
AWARD[2] = {ratio = 6470, award = {{awardType = 2798, num = 3},}}
AWARD[3] = {ratio = 8000, award = {{awardType = 2798, num = 4},}}
AWARD[4] = {ratio = 10000, award = {{awardType = 2799, num = 1},}}


function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then 
		return
	end
	
	local maxNum = #AWARD
	pUser:DelPackageById(2817, num)
	for i=1,num do
		local r=math.random(AWARD[maxNum].ratio)
		for k, v in ipairs(AWARD) do
			if r <= v.ratio then
				GetAward(pUser,v.award)
				break
			end 
		end
	end

end

function GetAward(pUser, award)
	local str = ""
	
	for k, v in pairs(award) do
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			str = str .. j.GetItemName(v.awardType) .. "*" .. v.num .. LANGUAGE_TRANSFORM_889
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			str = str .. LANGUAGE_TRANSFORM_890 .. v.num .. LANGUAGE_TRANSFORM_891
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			str = str .. LANGUAGE_TRANSFORM_892 .. v.num .. LANGUAGE_TRANSFORM_893
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			str = str .. LANGUAGE_TRANSFORM_894 .. v.num .. LANGUAGE_TRANSFORM_895
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			str = str .. LANGUAGE_TRANSFORM_896 .. v.num .. LANGUAGE_TRANSFORM_897
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			str = str .. LANGUAGE_TRANSFORM_898 .. v.num .. LANGUAGE_TRANSFORM_899
		end
	end
	
	if serverType == "taiwan" then
		str = string.sub(str,1,-4)
	else
		str = string.sub(str,1,-3)
	end
	
	str = "[c4]"..LANGUAGE_LLD_0015..":".. str.."[c/]"
	j.SendSysInfo(pUser,str)
end
