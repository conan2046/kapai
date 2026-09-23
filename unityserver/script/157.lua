--157.lua--恐怖的灵魔 id=157
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

MonsterName = LANGUAGE_TRANSFORM_2150
LEVEL_LIMIT = 30

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId,index)
	pUser:SetVal(1,index)
	Option(pUser,MonsterName,LANGUAGE_TRANSFORM_2151,LANGUAGE_TRANSFORM_2152)
	pUser:SetCallFun("MonsterCallBack")
end

function MonsterCallBack(pUser,sel)
	if sel == 1 then
		if pUser:GetLevel() < LEVEL_LIMIT then
			Dialog(pUser,MonsterName,LANGUAGE_TRANSFORM_2153..LEVEL_LIMIT..LANGUAGE_TRANSFORM_2154)
			return
		end
		if not j.CanJoinActivity(pUser) then
			return
		end
		
--		if pUser:GetTeam() ~= pUser:GetRoleId() then
--			Dialog(pUser,MonsterName,"只有队长才可以操作")
--			return
--		end
--		local num = pUser:GetTeamMemberNum()
--		if num >= 3 then
--			for i=2,num,1 do
--				local member = j.GetTeamMember(pUser,i)
--				if member:GetLevel() < 70 then
--					Dialog(pUser,MonsterName,"需达到70级并且3人或以上的队伍才能挑战")
--					return
--				end
--			end
--		else
--			Dialog(pUser,MonsterName,"需达到70级并且3人或以上的队伍才能挑战")
--			return
--		end
		res = j.LingQiJuanXianFight(pUser)
		if res == -1 then
			Dialog(pUser,MonsterName,LANGUAGE_TRANSFORM_1883)
		elseif res == 1 then
			Dialog(pUser,MonsterName,LANGUAGE_TRANSFORM_1884)
		elseif res == 2 then
			Dialog(pUser,MonsterName,LANGUAGE_TRANSFORM_1885)
		else	-- 成功
		
		end
		pUser:SetCall(0,"")
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

