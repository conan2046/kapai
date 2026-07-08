--22386.lua--金币礼包
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
function Main(pUser, pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil or num == 0 then
		return
	end
	if pItem.num < num then
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0148)
		return
	end

	pUser:DelPackage(pos,num)

	local totalMoney = 0
	local totalBangYB = 0
	local rnd
	for i=1,num do
		rnd = math.random(1,100)
		if rnd > 90 then
			totalBangYB = totalBangYB + 300
		end
		totalMoney = totalMoney + 25000
	end

	pUser:AddMoney(totalMoney)
	pUser:AddTongBao(totalBangYB,1)
	j.SaveDate(pUser,22,totalMoney,LANGUAGE_SSJ_0149..num..LANGUAGE_SSJ_0150..totalMoney)
	j.SaveDate(pUser,22,totalBangYB,LANGUAGE_SSJ_0149..num..LANGUAGE_SSJ_0150..totalBangYB)
	
--	j.SaveUseItem(pUser:GetRoleId(),2386,"使用金币礼包",1,"","")
	if totalBangYB == 0 then
		j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0151..totalMoney)
	else
		j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0151..totalMoney..LANGUAGE_SSJ_0152..totalBangYB)
	end
end


