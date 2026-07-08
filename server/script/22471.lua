--22471.lua 金宠巨猿皇
-------------------------
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract			
require "global"

-----------------------------

PET_ID = 108

-----------------------------
function Main(pUser, pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	if pUser:GetPetNum() >= pUser:GetCurMaxCarryPetNum() then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4765)
		return
	end

	pUser:DelPackage(pos)

	j.AddPet(pUser,PET_ID,1,-1,true)
end


