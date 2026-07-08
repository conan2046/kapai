--21003.lua--钓竿
-------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End --剧情对话结束 
CloseInteract=j.CloseInteract

-----------------------------
function Main(pUser)
	local s
	local m

	m=pUser:GetScene()
	if m:GetId()~=6 then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_147..j.GetSceneName(6)..LANGUAGE_TRANSFORM_148)
		return
	end

	s=pUser:GetMission(618)
	if s~=nil then
		t=FormatMission(s)
		if tonumber(t[1])==0 then
			t[2] = tonumber(t[2]) + 5
			if t[2] >= 20 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_149)
				j.UpdateNpcState(pUser,75,3)
				pUser:UpdateMission(618,"1|"..t[2])
			else
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_150)
				pUser:UpdateMission(618,"0|"..t[2])
			end

--			j.MissionFight618(pUser)
--			pUser:SetCallFun("BattleOver")
		end
	end

end

function BattleOver(pUser,state)
	if state==0 then
		pUser:UpdateMission(618,"1|1")
--		DialogS_End(pUser,-1,pUser:GetName(),"啊……好像有个[c3]鼎[/c]在一片光芒之中隐现……")
--		DialogS_Start(pUser,66,"糖宝","哇！你真厉害，居然打得它们落花流水！")
--		pUser:SetCallFun("MissionDialog618_1")
	else
		
	end

end

function MissionDialog618_1(pUser)
	DialogS_End(pUser,-1,pUser:GetName(),LANGUAGE_CHY_17)
end


