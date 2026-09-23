--22478.lua 紫宠蛮牛卫
-------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract

PET_ID = 19

-----------------------------
function Main(pUser, pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	
	if pUser:GetPetNum() >= pUser:GetCurMaxCarryPetNum() then
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_2029)
		return
	end

	pUser:DelPackage(pos)

	j.AddPet(pUser,PET_ID,1,-1,true)
end


