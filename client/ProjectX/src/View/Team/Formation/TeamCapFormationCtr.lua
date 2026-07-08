--[[
队长阵容界面
]]
--[[
组队阵容界面
]]


local function Debug(log)
    --
end
local TeamCapFormationCtr = {}
TeamCapFormationCtr.__index = TeamCapFormationCtr

function TeamCapFormationCtr:New(formationUI)
	local o = LUIBase:New()
	setmetatable(o,TeamCapFormationCtr)	
    o:Init(formationUI)
	return o
end


function TeamCapFormationCtr:Init(formationUI)
	self.m_parent = formationUI
    self:InitMemberVariable()
end

function TeamCapFormationCtr:ChangeFightPos(oldPos, newPos)
    local oldInd
    local newInd
    --print("ChangeFightPos:oldPos=",oldPos, "newPos = ", newPos)
    for i = 1, #self.m_fightArr do
        --print("I=",i,"Pos=",self.m_fightArr[i][2])
        if self.m_fightArr[i][2] == oldPos then
            oldInd = i
        elseif self.m_fightArr[i][2] == newPos then
            newInd = i
        end
    end
    -- print("22ChangeFightPos",oldPos, newPos)
    --print("oldInd=",oldInd,"newInd=",newInd)
    local oldArr
    if oldInd ~= nil then
        oldArr = self.m_fightArr[oldInd]
    end
    local newArr
    if newInd ~= nil then
        newArr = self.m_fightArr[newInd]
    end
    
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    if oldArr ~= nil then
        oldArr[2] = oldPos
        --
        
        local curMember = self:GetMemberInfoByFightPos(oldArr[2])
        --print("oldArrPos=",oldArr[2],"curMember",curMember)
        if curMember ~= nil then
            if curMember.m_type == 1 then
                self:ShowHeroFightUnit(oldArr[2])
            else
                self:ShowPetFightUnit(oldArr[2])
            end
        end
        
    end

    if newArr ~= nil then
        newArr[2] = newPos
        
        local curMember = self:GetMemberInfoByFightPos(newArr[2])
        --print("newArrPos=",newArr[2],"curMember",curMember)
        if curMember ~= nil then
            if curMember.m_type == 1 then
                self:ShowHeroFightUnit(newArr[2])
            else
                self:ShowPetFightUnit(newArr[2])
            end
        end
        
    end
end

function TeamCapFormationCtr:GetMemberInfoByFightPos(fightPos)
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    for i = 1, #members do
        if members[i].m_type > 0 and members[i].m_srcPos == fightPos then
            return members[i]
        end
    end
    return nil
end

function TeamCapFormationCtr:ShowHeroFightUnit(fightPos)
    local member = self:GetMemberInfoByFightPos(fightPos)
    if member == nil then
        return
    end

    if member.m_shap <= 0 then
        self.m_parent.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Hero, 
                                    member.m_professnal, 
                                    member.m_weapon, 
                                    member.m_wLight,
                                    0,
                                    0,
                                    0)
    else
        self.m_parent.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Monster, 
                                    member.m_shap)
    end
    self.m_parent.m_pModelNodeList[fightPos]:PlayStand(4)
end

function TeamCapFormationCtr:PetFightStateChanged(pid)
    -- local petData = LRoleDataMgr.Pet:GetPetById(pid)
    -- if petData == nil then
    --     return
    -- end
    -- if petData.fightPos > 0 then
    --     --[[
    --     ]]
    --     for i = 1, #self.m_fightArr do
    --         if self.m_fightArr[i][1] == pid then
    --             return
    --         end
    --     end
    --     table.insert(self.m_fightArr, {pid,petData.fightPos})
    --     self:ShowPetFightUnit(petData.fightPos, petData)
    -- else
    --     for i = 1, #self.m_fightArr do
    --         if self.m_fightArr[i][1] == pid then
    --             self:ShowPetFightUnit(self.m_fightArr[i][2])
    --             table.remove(self.m_fightArr, i)
    --             return
    --         end
    --     end
    -- end
end

function TeamCapFormationCtr:ShowCurFormation()
    for i = 1, #self.m_fightArr do
        self.m_parent.m_pModelNodeList[self.m_fightArr[i][2]]:setVisible(true)
        self.m_parent.m_pModelNodeList[self.m_fightArr[i][2]]:PlayStand(4)
    end
end

--[[
显示宠物出站位模型
]]
function TeamCapFormationCtr:ShowPetFightUnit(fightPos)
    local member = self:GetMemberInfoByFightPos(fightPos)
    if member == nil then
        self.m_parent.m_pModelNodeList[fightPos]:setVisible(false)
        return
    end
    --print("ShowPetFightUnit",fightPos,member.m_name)
    self.m_parent.m_pModelNodeList[fightPos]:setVisible(true)
    local basePet = LDataConstMgr:GetPetData(member.m_id)
    self.m_parent.m_pModelNodeList[fightPos]:InitAni(AppDef.CEnum.ModelAniType.Monster, basePet.pic)
    self.m_parent.m_pModelNodeList[fightPos]:PlayStand(4)
end

function TeamCapFormationCtr:CheckPetFight()
    for i = 1, #self.m_parent.m_pPetList do
        local cell = self.m_parent.m_pPetListTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            local ck = cellChild:getChildByName("CheckBox")
            if self:IsPetInTeamMember(self.m_parent.m_pPetList[i].id) ~= nil then
                ck:setSelected(true)
            else
                ck:setSelected(false)
            end
        end
    end
    self:InitFightUnitData()
end

function TeamCapFormationCtr:ShowFightModel()
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    local cnt = #self.m_fightArr
    local inds = {1,1,1,1,1}
    for i = 1, cnt do
        local curMember = members[self.m_fightArr[i][1]]
        inds[self.m_fightArr[i][2]] = 0
        if curMember.m_type == 1 then
            self:ShowHeroFightUnit(self.m_fightArr[i][2])
        else
            self:ShowPetFightUnit(self.m_fightArr[i][2])
        end
    end

    for i = 1, #inds do
        if inds[i] == 1 then
            self.m_parent.m_pModelNodeList[i]:ClearAni()
        end
    end

end

function TeamCapFormationCtr:onExit()
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
function TeamCapFormationCtr:InitMemberVariable()

    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    --[[
    出站宠物id列表
    {
        {队伍下表, fightpos},
        {队伍下表, fightpos},
        ...
        如果pid==0就是英雄
    }
    ]]
    self.m_fightArr = {}
    
end

--[[
初始化出站单位数据
]]
function TeamCapFormationCtr:InitFightUnitData()
    self.m_fightArr = {}
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    for i = 1, #members do
        if members[i].m_type == 2 or(members[i].m_type == 1 and members[i].m_state > 0) then
            table.insert(self.m_fightArr, {i,members[i].m_srcPos})
        end
    end
end

--[[
检查宠物是否在队伍成员里面
]]
function TeamCapFormationCtr:IsPetInTeamMember(pid)
    local members = self.m_pHeroData.m_pTeam.m_pMembers
    for i = 1, #members do
        if members[i].m_type == 2 and members[i].m_id == pid then
            return members[i]
        end
    end
    return nil
end

function TeamCapFormationCtr:HandlePetFight(petInd)

    local pet = self.m_parent.m_pPetList[petInd]
    local petMember = self:IsPetInTeamMember(pet.id)

    --请求出战
    if petMember ~= nil then
        LuaNetSendMsg:QueryTeamFormationPetPos(pet.id, 2)
    else
        LuaNetSendMsg:QueryTeamFormationPetPos(pet.id, 1)
    end
end

function TeamCapFormationCtr:SetPetFightFlag(curPet, cellChild)
    local ck = cellChild:getChildByName("CheckBox")
    if self:IsPetInTeamMember(curPet.id) ~= nil then
        ck:setSelected(true)
    else
        ck:setSelected(false)
    end
end

--[[
检查宠物出站状态变更
@param1:pid:宠物id
]]
function TeamCapFormationCtr:CheckPetFightStateChanged(pid)
    
    -- for i = 1, #self.m_parent.m_pPetList do
    --     if self.m_parent.m_pPetList[i].id == pid then
    --         local cell = self.m_parent.m_pPetListTableView:cellAtIndex(i - 1)
    --         if cell ~= nil then
    --             local cellChild = cell:getChildByTag(123)
    --             local ck = cellChild:getChildByName("CheckBox")
    --             if self.m_parent.m_pPetList[i].fightPos > 0 then
    --                 ck:setSelected(true)
    --             else
    --                 ck:setSelected(false)
    --             end
    --         end
    --         return
    --     end
    -- end
end

function TeamCapFormationCtr:UseZhenfa(cell, ind)
    local myFData = LRoleDataMgr.myFormation

    local flist = LDataConstMgr:GetFormationDataList()
    local fdata = flist[ind + 1]
    local useFlagImg = cell:getChildByName("Tag")
    if self.m_pHeroData.m_pTeam.m_zhenfaId == fdata.id then
        useFlagImg:setVisible(true)
        return true
    else
        useFlagImg:setVisible(false)
        return false
    end
end

function TeamCapFormationCtr:CheckUseBtnVisible()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_parent.m_curInd + 1]

    local myFData = LRoleDataMgr.myFormation

    local lv = myFData:GetMyZhenfaLvById(data.id)

    if self.m_pHeroData.m_pTeam.m_zhenfaId == data.id or lv == 0 then
        self.m_parent.m_pUseBtn:setVisible(false)
    else

        self.m_parent.m_pUseBtn:setVisible(true)
    end
end

function TeamCapFormationCtr:ShowFormationCellInfo(cell, ind)

    local myFData = LRoleDataMgr.myFormation


    local flist = LDataConstMgr:GetFormationDataList()
    local fdata = flist[ind + 1]
    
    local tmpPanel = cell:getChildByName("bg_Formation")
    local lvLabel = tmpPanel:getChildByName("Level")

    local nameLabel = tmpPanel:getChildByName("Name")
    nameLabel:setString(fdata.name)

    local useFlagImg = cell:getChildByName("Tag")

    if self.m_pHeroData.m_pTeam.m_zhenfaId == fdata.id then
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

    -- local ret = LRoleDataMgr:FormationCheckUp(ind + 1)
    -- local redImg = cell:getChildByName("Prompt")
    -- redImg:setVisible(ret)

    
    local iconImg = tmpPanel:getChildByName("Icon")
    local iconRes = AppDef.Formation.IconRes .. fdata.id .. ".png"
    iconImg:loadTexture(iconRes,ccui.TextureResType.localType)
end


return TeamCapFormationCtr