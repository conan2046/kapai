--22534.lua 金色东华
-------------------------
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract			
require "global"

-----------------------------

PET_ID = 121

-----------------------------
function Main(pUser, pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	if pUser:GetPetNum() >= pUser:GetCurMaxCarryPetNum() then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1446)
		return
	end

	pUser:DelPackage(pos)

	j.AddPet(pUser,PET_ID,1,-1,true)
end


