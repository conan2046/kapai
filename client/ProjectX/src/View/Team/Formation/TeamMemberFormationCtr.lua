--[[
队员阵容界面
]]



local TeamMemberFormationCtr = {}
TeamMemberFormationCtr.__index = TeamMemberFormationCtr

function TeamMemberFormationCtr:New(formationUI)
	local o = LUIBase:New()
	setmetatable(o,TeamMemberFormationCtr)	
    o:Init(formationUI)
	return o
end


function TeamMemberFormationCtr:Init(formationUI)
	self.m_parent = formationUI
    self:InitMemberVariable()
end

function TeamMemberFormationCtr:ChangeFightPos(oldPos, newPos)
    local oldInd
    local newInd
    for i = 1, #self.m_fightArr do
        if self.m_fightArr[i][2] == oldPos then
            oldInd = i
        elseif self.m_fightArr[i][2] == newPos then
            newInd = i
        end
    end
    local oldArr = self.m_fightArr[oldInd]
    local newArr = self.m_fightArr[newInd]

    if newArr == nil then
        self.m_parent.m_pModelNodeList[oldArr[2]]:setVisible(false)
        oldArr[2] = newPos
        if oldArr[1] == 0 then
            self:ShowHeroFightUnit(oldArr[2])
        else
            local petData = LRoleDataMgr.Pet:GetPetById(oldArr[1])
            self:ShowPetFightUnit(oldArr[2],petData)
        end
        return
    end

    oldArr[2] = newPos
    newArr[2] = oldPos
    if oldArr[1] == 0 then
        self:ShowHeroFightUnit(oldArr[2])
    else
        local petData = LRoleDataMgr.Pet:GetPetById(oldArr[1])
        self:ShowPetFightUnit(oldArr[2],petData)
    end

    if newArr[1] == 0 then
        self:ShowHeroFightUnit(newArr[2])
    else
        local petData = LRoleDataMgr.Pet:GetPetById(newArr[1])
        self:ShowPetFightUnit(newArr[2],petData)
    end
end

function TeamMemberFormationCtr:ShowHeroFightUnit(fightPos)
    local data = LRoleDataMgr.MyHeroInfo
    self.m_parent.m_pModelNodeList[fightPos]:setVisible(true)
    self.m_parent.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                            data.professional, 
                                            data:GetWeaponId(), 
                                            data.LightEffect,
                                            0,
                                            0,
                                            0)
    self.m_parent.m_pModelNodeList[fightPos]:PlayStand(4)
end

function TeamMemberFormationCtr:PetFightStateChanged(pid)
    local petData = LRoleDataMgr.Pet:GetPetById(pid)
    if petData == nil then
        return
    end
    if petData.fightPos > 0 then
        --[[
        ]]
        for i = 1, #self.m_fightArr do
            if self.m_fightArr[i][1] == pid then
                return
            end
        end
        table.insert(self.m_fightArr, {pid,petData.fightPos})
        self:ShowPetFightUnit(petData.fightPos, petData)
    else
        for i = 1, #self.m_fightArr do
            if self.m_fightArr[i][1] == pid then
                self:ShowPetFightUnit(self.m_fightArr[i][2])
                table.remove(self.m_fightArr, i)
                return
            end
        end
    end
end

function TeamMemberFormationCtr:ShowCurFormation()
    for i = 1, #self.m_fightArr do
        self.m_parent.m_pModelNodeList[self.m_fightArr[i][2]]:setVisible(true)
        self.m_parent.m_pModelNodeList[self.m_fightArr[i][2]]:PlayStand(4)
    end
end

--[[
显示宠物出站位模型
]]
function TeamMemberFormationCtr:ShowPetFightUnit(fightPos, petData)
    if petData == nil then
        self.m_parent.m_pModelNodeList[fightPos]:setVisible(false)
        return
    end
    self.m_parent.m_pModelNodeList[fightPos]:setVisible(true)
    self.m_parent.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Monster, petData.baseData.pic)
    self.m_parent.m_pModelNodeList[fightPos]:PlayStand(4)
end

function TeamMemberFormationCtr:ShowFightModel()
    for i = 1, #self.m_fightArr do
        if self.m_fightArr[i][1] == 0 then
            self:ShowHeroFightUnit(self.m_fightArr[i][2])
        else
            local petData = LRoleDataMgr.Pet:GetPetById(self.m_fightArr[i][1])
            self:ShowPetFightUnit(self.m_fightArr[i][2],petData)
        end
    end
end

function TeamMemberFormationCtr:onExit()
    self.m_parent = nil

    --[[
    出站宠物id列表
    {
        {pid, fightpos},
        {pid, fightpos},
        ...
        如果pid==0就是英雄
    }
    ]]
    self.m_fightArr = nil
end

--[[
初始化成员变量
]]
function TeamMemberFormationCtr:InitMemberVariable()

    
    --[[
    出站宠物id列表
    {
        {pid, fightpos},
        {pid, fightpos},
        ...
        如果pid==0就是英雄
    }
    ]]
    self.m_fightArr = {}
    
end

--[[
初始化出站单位数据
]]
function TeamMemberFormationCtr:InitFightUnitData()

    for i = 1, #LRoleDataMgr.Pet.petlist do
        if LRoleDataMgr.Pet.petlist[i].fightPos > 0 then
            table.insert(self.m_fightArr, {LRoleDataMgr.Pet.petlist[i].id,LRoleDataMgr.Pet.petlist[i].fightPos})
        end
    end
end

function TeamMemberFormationCtr:HandlePetFight(petInd)
    local pet = self.m_parent.m_pPetList[petInd]
    --请求出战
    if pet.fightPos > 0 then
        LuaNetSendMsg:QueryFormationPetPos(pet.id, 2)
    else
        LuaNetSendMsg:QueryFormationPetPos(pet.id, 1)
    end
end

function TeamMemberFormationCtr:SetPetFightFlag(curPet, cellChild)
    local ck = cellChild:getChildByName("CheckBox")
    if curPet.fightPos > 0 then
        ck:setSelected(true)
    else
        ck:setSelected(false)
    end
end

function TeamMemberFormationCtr:CheckUseBtnVisible()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_parent.m_curInd + 1]

    local myFData = LRoleDataMgr.myFormation

    local lv = myFData:GetMyZhenfaLvById(data.id)

    if myFData.useId == data.id or lv == 0 then
        self.m_parent.m_pUseBtn:setVisible(false)
    else

        self.m_parent.m_pUseBtn:setVisible(true)
    end
end

--[[
检查宠物出站状态变更
@param1:pid:宠物id
]]
function TeamMemberFormationCtr:CheckPetFightStateChanged(pid)
    
    for i = 1, #self.m_parent.m_pPetList do
        if self.m_parent.m_pPetList[i].id == pid then
            local cell = self.m_parent.m_pPetListTableView:cellAtIndex(i - 1)
            if cell ~= nil then
                local cellChild = cell:getChildByTag(123)
                local ck = cellChild:getChildByName("CheckBox")
                if self.m_parent.m_pPetList[i].fightPos > 0 then
                    ck:setSelected(true)
                else
                    ck:setSelected(false)
                end
            end
            return
        end
    end
end

function TeamMemberFormationCtr:UseZhenfa(cell, ind)
    local myFData = LRoleDataMgr.myFormation

    local flist = LDataConstMgr:GetFormationDataList()
    local fdata = flist[ind + 1]
    local useFlagImg = cell:getChildByName("Tag")

    if myFData.useId == fdata.id then
        useFlagImg:setVisible(true)
        return true
    else
        useFlagImg:setVisible(false)
        return false
    end
end

function TeamMemberFormationCtr:ShowFormationCellInfo(cell, ind)

    local myFData = LRoleDataMgr.myFormation


    local flist = LDataConstMgr:GetFormationDataList()
    local fdata = flist[ind + 1]
    
    local tmpPanel = cell:getChildByName("bg_Formation")
    local lvLabel = tmpPanel:getChildByName("Level")

    local nameLabel = tmpPanel:getChildByName("Name")
    nameLabel:setString(fdata.name)

    local useFlagImg = cell:getChildByName("Tag")

    if myFData.useId == fdata.id then
        useFlagImg:setVisible(true)
    else
        useFlagImg:setVisible(false)
    end

    local lv = myFData:GetMyZhenfaLvById(fdata.id)
    if lv > 0 then
        lvLabel:setString("Lv." .. lv)
    else
        lvLabel:setString(GUITips.RSI_PAGE_MSG1)
    end

    -- local redImg = cell:getChildByName("Prompt")
    -- redImg:setVisible(false)

    local iconImg = tmpPanel:getChildByName("Icon")
    local iconRes = AppDef.Formation.IconRes .. fdata.id .. ".png"
    iconImg:loadTexture(iconRes,ccui.TextureResType.localType)
end

return TeamMemberFormationCtr