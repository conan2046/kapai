--170.lua--帮派任务使
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
SeedList={1201,1202,1203,1204,1205,1206}

thisId = 170
NPCName = nil

------------------------------------------
function FormatMission(s)
	local t = {}
	local i = 1

	for w in string.gmatch(s, "%|+") do
		t[i] = w
		i = i + 1
	end
	return t
end
------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end



end


function GetState(pUser)
	local s 
	
	return 0
end


