--22340.lua--竞技场礼包

-- TODO：等级超过115级，经验值超过上限的话，数值会有问题。c++lua传值数字长度问题引起的。

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
	local serverType = j.GetServerType()
	pItem = pUser:GetItem(pos)
	if pItem == nil then 
		return
	end
	
	local rank = GetItemRank(pItem)	

	-- 不正常的道具排名直接领取最后的奖励
	if rank <= 0 then 
		rank = 5001
	end
	
	-- 扣道具
	pUser:DelPackage(pos)

    -- 前10名奖励
	local ARY10 = {250,200,175,150,125,120,115,110,105,100}

	local yb = 13
	if rank >= 1 and rank <= 10 then
		yb = ARY10[rank]
	elseif rank <= 20 then
		yb = 80
	elseif rank <= 30 then
		yb = 60
	elseif rank <= 50 then
		yb = 40
	elseif rank <= 100 then
		yb = 35
	elseif rank <= 200 then
		yb = 30
	elseif rank <= 300 then
		yb = 25
	elseif rank <= 400 then
		yb = 22
	elseif rank <= 500 then
		yb = 20
	elseif rank <= 700 then
		yb = 18
	elseif rank <= 1000 then
		yb = 16
	elseif rank <= 2000 then
		yb = 14
	elseif rank <= 3000 then
		yb = 13
	elseif rank <= 4000 then
		yb = 12
	elseif rank <= 5000 then
		yb = 11
	else
		yb = 10
	end
	
	if serverType == "BT" then
		yb = yb * 8
	end
	
	pUser:AddTongBao(yb, 1)
	j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1420..yb.."[/c]")	
end

function GetItemRank(pItem)
	if not pItem then 
		return 0
	end
	return pItem.extData
end


