--77.lua--玄武塔 id=77
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   
ShowGuidance = j.ShowGuidance --任务引导 

------------------------------------------
--以下为脚本部分：
------------------------------------------

thisId = 77
local NPCName = "玄武塔"

function NpcMain(pUser, missionId, index)
	j.Collect(pUser, thisId, 5,4,5,LANGUAGE_ZQX_0040)
	pUser:SetCallFun("CollectOver77")
end

function CollectOver77(pUser,npcIdx)
	if j.CollectTower(pUser, thisId) then
		j.Collect(pUser, thisId, 5,4,5,LANGUAGE_ZQX_0040)
		pUser:SetCallFun("CollectOver77")
	else
		j.ClearCollectState(pUser)
	end
end