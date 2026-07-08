--22368.lua--霸主礼包
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract			
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End --剧情对话结束 
ShowGuidance = j.ShowGuidance --任务引导 
-----------------------------
function FormatMission(s)					
	local t = {}
	local i = 1

	for w in string.gmatch(s, "%|+") do
		t[i] = w
		i = i + 1
	end
	return t
end

-----------------------------
function Main(pUser, pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then 
		return
	end
	local type = pItem.extData
	local exp = 0
	local itemId = 0
	local itemNum = 0
	local info = ""
		
	pUser:DelPackage(pos)
	if type == 1 then		--20
		itemId = 60014
		itemNum = 1000
	elseif type == 2 then	--60
		itemId = 60014
		itemNum = 1500
	elseif type == 3 then	--100
		itemId = 60014
		itemNum = 2000
	elseif type == 4 then	--150
		itemId = 60014
		itemNum = 2500
	elseif type == 5 then	--200
		itemId = 60014
		itemNum = 3000
	else
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_2013)
		return
	end

	--local name = j.GetItemName(itemId)
	--info = LANGUAGE_TRANSFORM_2014..name.."*"..itemNum.."[/c]"
	pUser:AddMaterial(itemId,itemNum, false)
	--j.SendSysInfo(pUser,info)
end


