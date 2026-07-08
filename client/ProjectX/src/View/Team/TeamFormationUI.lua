--[[
组队阵容界面
]]



local TeamFormationUI = LUIBase:New()
TeamFormationUI.__index = TeamFormationUI

function TeamFormationUI:New()
	local o = LUIBase:New()
	setmetatable(o,TeamFormationUI)	
    o:Init()
	return o
end


function TeamFormationUI:Init()
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitPetListTableView()
    self:InitEvt()
    self:ShowFightModel()
    self:ShowFormation()
end

function TeamFormationUI:ShowFormation()
    self:ShowCurFormation()
    self:ShowFormationAttr()
    self:ShowMatItem()
    self:ShowBtnTitle()
    self:CheckUseBtnVisible()
end

function TeamFormationUI:ShowBtnTitle()

    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local fdata = LDataConstMgr:GetFormationLvUpData(data.id,1)

    local myFData = LRoleDataMgr.myFormation

    local lv = myFData:GetMyZhenfaLvById(fdata.id)
    local textLabel = self.m_pStudyBtn:getChildByName("Text")
    if lv > 0 then
        textLabel:setString(GUITips.UI_Shengjiang_Btn_LvUp)
    else
        textLabel:setString(GUITips.UI_Shengjiang_Btn_Learn)
    end

    local ret = LRoleDataMgr:FormationCheckUp(self.m_curInd + 1)
    local redImg = self.m_pStudyBtn:getChildByName("Prompt")
    redImg:setVisible(ret)
end

--[[
显示升级需要的材料
]]
function TeamFormationUI:ShowMatItem()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]

    local myFData = LRoleDataMgr.myFormation
    local lv = myFData:GetMyZhenfaLvById(data.id)

    local fdata
    local isMax = false
    if lv == 10 then
        --没有找到默认到了最大级
        isMax = true
        fdata = LDataConstMgr:GetFormationLvUpData(data.id,10)
    else
        fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)
    end

    local itemId = fdata.costItemId
    local itemNum = fdata.costItemNum



    local citem = LDataConstMgr:getCItemByID(itemId)
    local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    local itemIconImg = self.m_pIconBtn:getChildByName("Icon")
    itemIconImg:loadTexture(string.format("item/equip%d.png", citem.m_pic), ccui.TextureResType.localType)
    local itemNumLabel = self.m_pIconBtn:getChildByName("Value")
    itemNumLabel:setString( "" .. myItemNum .. "/" .. itemNum)
    if isMax or myItemNum >= itemNum then
        itemNumLabel:setTextColor(UICOLOR_GREEN)
    else
        itemNumLabel:setTextColor(UICOLOR_RED)
    end

    self.m_pMatNameLabel:setString(citem.m_name)
end

function TeamFormationUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFormationEvent.PetFight,
        LUIFormationEvent.ChangePos,
        LUIFormationEvent.UseTeamZhenfaChanged,
        LUIFormationEvent.UseZhenfaChanged,
        LUIFormationEvent.ZhenfaChanged,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function TeamFormationUI:ProcessEvent(msg)
    if msg.msgId == LUIFormationEvent.PetFight then
        self:PetFightStateChanged(msg.value)
        self:CheckPetFightStateChanged(msg.value)
    elseif msg.msgId == LUIFormationEvent.ChangePos then
        self:ChangeFightPos(msg.value[1],msg.value[2])
    elseif msg.msgId == LUIFormationEvent.UseTeamZhenfaChanged
    or msg.msgId == LUIFormationEvent.UseZhenfaChanged then
        self:UseZhenfa()
        self:ShowCurFormation()
    elseif msg.msgId ==  LUIFormationEvent.ZhenfaChanged then
        self:FormationUpdate(msg.value)
        self:ShowFormationAttr()
        self:ShowMatItem()
        self:ShowBtnTitle()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:ShowTeamInfo()
    end
end

function TeamFormationUI:ShowTeamInfo()

    if self.m_pHeroData:IsTeam() == true then
        self.m_capFormationCtr:CheckPetFight()
    end
    
    self:ShowFightModel()
    -- if self.m_pHeroData:IsTeam() == true then

    --     self:ShowMyTeamMember()
    -- else
    --     self:ShowNoTeamInfo()
    -- end
end

--[[
检查宠物出站状态变更
@param1:pid:宠物id
]]
function TeamFormationUI:CheckPetFightStateChanged(pid)
    if self.m_pHeroData:IsTeam() == true then
        self.m_capFormationCtr:CheckPetFightStateChanged(pid)
    else
        self.m_memberFormationCtr:CheckPetFightStateChanged(pid)
    end
end

--[[
新学习了阵法或者阵法升级
@param1:fid需要更新的阵法id
]]
function TeamFormationUI:FormationUpdate(fid)
    local list = LDataConstMgr:GetFormationDataList()
    local myFData = LRoleDataMgr.myFormation
    for i = 1, #list do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            cell = cell:getChildByTag(123)
            local tmpPanel = cell:getChildByName("bg_Formation")
            local lvLabel = tmpPanel:getChildByName("Level")
            local useFlagImg = cell:getChildByName("Tag")
            if myFData.useId == list[i].id then
                useFlagImg:setVisible(true)
            else
                useFlagImg:setVisible(false)
            end

            -- local ret = LRoleDataMgr:FormationCheckUp(i)
            -- local redImg = cell:getChildByName("Prompt")
            -- redImg:setVisible(ret)
            
            local lv = myFData:GetMyZhenfaLvById(list[i].id)
            if lv > 0 then
                lvLabel:setString("Lv." .. lv)
            else
                lvLabel:setString(GUITips.RSI_PAGE_MSG1)
            end
        end
    end
    self:CheckUseBtnVisible()
end

function TeamFormationUI:ChangeFightPos(oldPos, newPos)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ChangeFightPos(oldPos, newPos)
    else
        self.m_memberFormationCtr:ChangeFightPos(oldPos, newPos)
    end
end

function TeamFormationUI:ShowHeroFightUnit(fightPos)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ShowHeroFightUnit(fightPos)
    else
        self.m_memberFormationCtr:ShowHeroFightUnit(fightPos)
    end
end

function TeamFormationUI:PetFightStateChanged(pid)

    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:PetFightStateChanged(pid)
    else
        self.m_memberFormationCtr:PetFightStateChanged(pid)
    end
end

--[[
显示宠物出站位模型
]]
function TeamFormationUI:ShowPetFightUnit(fightPos, petData)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ShowPetFightUnit(fightPos)
    else
        self.m_memberFormationCtr:ShowPetFightUnit(fightPos, petData)
    end
end

function TeamFormationUI:ShowFightModel()
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ShowFightModel()
    else
        self.m_memberFormationCtr:ShowFightModel()
    end
end

function TeamFormationUI:UseZhenfa()
    local list = LDataConstMgr:GetFormationDataList()
    local cnt = #list
    local useInd = 0
    for i = 1, cnt do
         local cell = self.m_pTableView:cellAtIndex(i - 1)
         if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            local isUse = false
            if self.m_pHeroData:IsLeader() == true then
                isUse = self.m_capFormationCtr:UseZhenfa(cellChild, i - 1)
            else
                isUse = self.m_memberFormationCtr:UseZhenfa(cellChild,i - 1)
            end
            if isUse then
                useInd = i
            end
         end
    end
    self:CheckUseBtnVisible()
end
--[[
使用阵容
]]
function TeamFormationUI:ShowCurFormation()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    if finfo == nil then
        return
    end

    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local ind = self:GetCurFormationPos(i)
        if ind > 0 then
            self.m_pPosNumList[i]:setVisible(true)
            local numLabel = self.m_pPosNumList[i]:getChildByName("Value")
            numLabel:setString(ind)
            self.m_pPosBtnList[i]:setOpacity(255)--40%透明度
            if finfo.posOpenLvList[ind] > LRoleDataMgr.MyHeroInfo.level then
                self.m_pPosLockList[i]:setVisible(true)
--                print("the string is ", self.m_pPosLockList[i]:getString())
            else
                self.m_pPosLockList[i]:setVisible(false)
            end
        else
            self.m_pPosBtnList[i]:setOpacity(102)--40%透明度
            self.m_pPosLockList[i]:setVisible(false)
            self.m_pPosNumList[i]:setVisible(false)
        end
    end

    for i = 1, AppDef.Formation.MaxFightNum do
        local pos = finfo.posList[i]
        self.m_pModelNodeList[i]:retain()
        self.m_pModelNodeList[i]:removeFromParent()
        self.m_pNodeList[pos]:addChild(self.m_pModelNodeList[i])
        self.m_pModelNodeList[i]:release()
    end

    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ShowCurFormation()
    else
        self.m_memberFormationCtr:ShowCurFormation()
    end
end

function TeamFormationUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/FormationLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function TeamFormationUI:onExit()
    self.m_pUILayer = nil
    self.m_pLayout = nil--阵型列表
    self.m_pCell = nil--阵型子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_pTableView = nil--阵型tableView
    self.m_pUseBtn = nil--使用按钮

    self.m_pPosBtnList = nil
    self.m_pModelNodeWorldPosList = nil
    self.m_pPosLockList = nil
    self.m_pPosNumList = nil
    self.m_pPosPanelList = nil
    --出站模型父节点列表，9个
    self.m_pNodeList = nil
    --出站模型列表，5个
    self.m_pModelNodeList = nil


    self.m_pIconBtn = nil--阵型icon
    self.m_pMatNameLabel = nil--升级材料的名字
    self.m_pAddAttrLabels = nil--属性加成Label
    self.m_pKezhiLabel = nil--克制Label
    self.m_pStudyBtn = nil--学习按钮
    self.m_curInd = nil--当前选中的阵型

    self.m_curMoveInd = nil--当前选中需要切换位置的模型下表
    self.m_pTouchBeganPos = nil

    self.m_capFormationCtr:onExit()
    self.m_memberFormationCtr:onExit()

    self.m_capFormationCtr = nil
    self.m_memberFormationCtr = nil
    self:Destory()
end

--[[
初始化成员变量
]]
function TeamFormationUI:InitMemberVariable()

    LRoleDataMgr.Pet:SortPetList()
    self.m_pPetList = LRoleDataMgr.Pet.petlist
    self.m_pHeroData = LRoleDataMgr.MyHeroInfo
    self.m_pUILayer = nil
     
    self.m_pPetListTableView = nil

    self.m_pSubLayer = {}
    self.m_curUIInd = 0--当前子页签下表
    self.m_curPetInd = 0--当前选中宠物下标


    self.m_pLayout = nil--阵型列表
    self.m_pCell = nil--阵型子元素
    self.m_cellSize = nil--子元素尺寸
    self.m_pTableView = nil--阵型tableView

    self.m_pPosBtnList = {}
    self.m_pPosPanelList = {}
    self.m_pModelNodeWorldPosList = {}
    self.m_pPosLockList = {}
    self.m_pPosNumList = {}
    --出站模型父节点列表，9个
    self.m_pNodeList = {}
    --出站模型列表，5个
    self.m_pModelNodeList = {}


    self.m_pIconBtn = nil--阵型icon
    self.m_pMatNameLabel = nil--升级材料的名字
    self.m_pAddAttrLabels = {}--属性加成Label
    self.m_pKezhiLabel = nil--克制Label
    self.m_pStudyBtn = nil--学习按钮
    self.m_curInd = 0--当前选中的阵型
    
    if self.m_pHeroData:IsTeam() == true then
        local myFData = LRoleDataMgr.myFormation
        local flist = LDataConstMgr:GetFormationDataList()
        for i = 1, #flist do
            if flist[i].id == self.m_pHeroData.m_pTeam.m_zhenfaId then
                self.m_curInd = i - 1
                break
            end
        end
    else
        local myFData = LRoleDataMgr.myFormation
        local flist = LDataConstMgr:GetFormationDataList()
        for i = 1, #flist do
            if flist[i].id == myFData.useId then
                self.m_curInd = i - 1
                break
            end
        end
        
    end
    


    self.m_curMoveInd = 0--当前选中需要切换位置的模型下表
    self.m_pTouchBeganPos = cc.p(0,0)

    self.m_capFormationCtr = require("View.Team.Formation.TeamCapFormationCtr"):New(self)
    self.m_memberFormationCtr = require("View.Team.Formation.TeamMemberFormationCtr"):New(self)

    self:InitFightUnitData()
end

--[[
初始化出站单位数据
]]
function TeamFormationUI:InitFightUnitData()
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:InitFightUnitData()
    else
        self.m_memberFormationCtr:InitFightUnitData()
    end
end

function TeamFormationUI:CheckUseBtnVisible()
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:CheckUseBtnVisible()
    else
        self.m_memberFormationCtr:CheckUseBtnVisible()
    end
end


function TeamFormationUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("FormationUI")
    local petPanel = panel:getChildByName("List")
    self.m_pPetListPanel = petPanel:getChildByName("ListView")
    self.m_pPetCell = petPanel:getChildByName("Item")
    self.m_pStarImg = petPanel:getChildByName("Star")

    self.m_pCellSize = self.m_pPetCell:getContentSize()

    local listPanel = panel:getChildByName("List_Formation")
    self.m_pLayout = listPanel:getChildByName("ListView")--阵型列表
    self.m_pUseBtn = listPanel:getChildByName("btn_Use")
    self.m_pCell = listPanel:getChildByName("Item")--阵型子元素
    self.m_cellSize = self.m_pCell:getContentSize()--子元素尺寸

    local formationPanel = panel:getChildByName("Show")
    local posPanel = formationPanel:getChildByName("Formation")
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosBtnList[i] = posPanel:getChildByName("Position" .. i)
        self.m_pPosPanelList[i] = self.m_pPosBtnList[i]:getChildByName("Panel")
        self.m_pPosLockList[i] = self.m_pPosBtnList[i]:getChildByName("Lock")
        self.m_pPosNumList[i] = self.m_pPosBtnList[i]:getChildByName("bg_Num")
        self.m_pNodeList[i] = posPanel:getChildByName("Node_" .. i)
        self.m_pModelNodeWorldPosList[i] = self.m_pNodeList[i]:convertToWorldSpace(cc.p(0,0))
    end

    
    --出站模型列表，5个
    self.m_pModelNodeList = {}
    local infoPanel = formationPanel:getChildByName("Info")
    for i = 1, AppDef.Formation.MaxFightNum do
        self.m_pModelNodeList[i] = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
        self.m_pNodeList[i]:addChild(self.m_pModelNodeList[i])
        local tmp = infoPanel:getChildByName("Attribute" .. i)
        self.m_pAddAttrLabels[i] = tmp:getChildByName("Content")
    end
    
    self.m_pIconBtn = infoPanel:getChildByName("btn_Material")
    self.m_pKezhiLabel = infoPanel:getChildByName("Restriction"):getChildByName("Content")
    self.m_pStudyBtn = infoPanel:getChildByName("btn_Upgrade")

    self.m_pMatNameLabel = infoPanel:getChildByName("bg_Name"):getChildByName("Name")

    self:InitFormationTableView()
end

function TeamFormationUI:InitPetListTableView()
    local tableView = cc.TableView:create(self.m_pPetListPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pPetListPanel:getAnchorPoint())
    tableView:setPosition(self.m_pPetListPanel:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pPetListPanel:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:PetCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pCellSize.width
        local height = self.m_pCellSize.height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:PetCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local cnt = #self.m_pPetList
        return cnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pPetListTableView = tableView

    self.m_pPetListPanel:removeFromParent()
    self.m_pPetListPanel = nil
end

function TeamFormationUI:PetCellSelected(cellChild, ind)
    -- if self.m_curPetInd == ind then
    --     return
    -- end

    self.m_curPetInd = ind
    --cellChild:setSelected(true)
    
   self:HandlePetFight(ind + 1)
end

function TeamFormationUI:HandlePetFight(petInd)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:HandlePetFight(petInd)
    else
        self.m_memberFormationCtr:HandlePetFight(petInd)
    end
end

function TeamFormationUI:PetCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    self:PetCellSelected(cellChild, ind)
end

function TeamFormationUI:PetCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pPetCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowPetCellInfo(cellChild,idx)
    return cell
end

function TeamFormationUI:SetPetFightFlag(curPet, cellChild)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:SetPetFightFlag(curPet, cellChild)
    else
        self.m_memberFormationCtr:SetPetFightFlag(curPet, cellChild)
    end
end

function TeamFormationUI:ShowPetCellInfo(cell, ind)

    local curPet = self.m_pPetList[ind+1]
    local headPanel = cell:getChildByName("bg_Head")
    local headImg = headPanel:getChildByName("Icon")
    local colorImg = headPanel:getChildByName("Color")
    colorImg:setVisible(false)
    local attrImg = headPanel:getChildByName("Attribute")--属性
    local lvLabel = headPanel:getChildByName("Value")
    local nameLabel = headPanel:getChildByName("Name")
    local starListView = headPanel:getChildByName("Stars")
    --starListView:removeAllItems()
    AppDef:ShowProAttrImg(attrImg, curPet.baseData.petType)
    
    lvLabel:setString(curPet.level)
    nameLabel:setString(curPet.name)
    local color = AppDef:GetPetQualityColor(curPet.baseData.quality)
    nameLabel:setTextColor(color)

    Utils:ShowPetHeadImg(headImg, curPet.baseData.pic, headPanel, curPet.baseData.quality, curPet:IsShiny())
    self:SetPetFightFlag(curPet, cell)
    self:ShowPetStars(starListView, curPet.star)
end

function TeamFormationUI:ShowPetStars(starLayout, star)
    starLayout:removeAllChildren()
    local panelSize = starLayout:getContentSize()
    local size = self.m_pStarImg:getContentSize()
    local sizeWith =size.width
    if star>6 then
     sizeWith =size.width-5
    end
    local width = sizeWith*star
    local sx = (panelSize.width - width)/2 + sizeWith/2
    local sy = size.height/2
    for i = 1, star do

        local starImg = self.m_pStarImg:clone()
        starLayout:addChild(starImg)
        starImg:setPosition(cc.p(sx, sy))
        sx = sx + sizeWith
    end
end

function TeamFormationUI:InitFormationTableView()
    local tableView = cc.TableView:create(self.m_pLayout:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(self.m_pLayout:getAnchorPoint())
    tableView:setPosition(self.m_pLayout:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_pLayout:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:FormationCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_cellSize.width
        local height = self.m_cellSize.height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:FormationCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local list = LDataConstMgr:GetFormationDataList()
        local cnt = #list
        return cnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pTableView = tableView

    self.m_pLayout:removeFromParent()
    self.m_pLayout = nil
end

function TeamFormationUI:FormationCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    if self.m_curInd == ind then
        return
    end

    local oldCell = self.m_pTableView:cellAtIndex(self.m_curInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
            --oldCellChild:setSelected(false)
        end
    end
    self.m_curInd = ind
    --cellChild:setSelected(true)
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)
    
    self:ShowFormation()
end

function TeamFormationUI:ShowFormationAttr()
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local myFData = LRoleDataMgr.myFormation
    if myFData == nil then
        return
    end
    local lv = myFData:GetMyZhenfaLvById(data.id)
    
    local fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)

    --每个站位对应两个附加属性值
    local attrType
    local attrValue
    local arrName
    local strAttr = ""
    for i = 1, AppDef.Formation.MaxFightNum do
        strAttr = ""
        for j = 1,#fdata.addAttrType[i] do
            attrType = fdata.addAttrType[i][j]
            if attrType == AppDef.EAttrType.EAT_ATTACK then
                arrName = GUITips.Item_Info_Attr145
            else
                arrName = LDataConstMgr:GetItemAttrName(attrType)
            end
            attrValue = fdata.addAttrValue[i][j]
            if AppDef:IsRatioAttr(attrType) then
                attrValue = attrValue / 100.0
                tmp = "%"
            else
                tmp = ""
            end

            if attrValue > 0 then
                strAttr = strAttr .. arrName .. "+" .. attrValue .. tmp .. "  "
            else
                strAttr = strAttr .. arrName .. attrValue .. tmp .. "  "
            end
        end
        

        self.m_pAddAttrLabels[i]:setString(strAttr)
    end

    strAttr = ""
    for i = 1, #data.restraintList do
        local kezhiData = LDataConstMgr:GetFormationDataById(data.restraintList[i])
        strAttr = strAttr .. kezhiData.name .. "  "
    end
    self.m_pKezhiLabel:setString(strAttr)
end

function TeamFormationUI:FormationCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pCell:clone()
        
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)


    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowFormationCellInfo(cellChild,idx)

    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curInd then 
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
    return cell
end

function TeamFormationUI:ShowFormationCellInfo(cell, ind)
    if self.m_pHeroData:IsLeader() == true then
        self.m_capFormationCtr:ShowFormationCellInfo(cell, ind)
    else
        self.m_memberFormationCtr:ShowFormationCellInfo(cell, ind)
    end
end

function TeamFormationUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    local function MatItemClicked(sender)
        local flist = LDataConstMgr:GetFormationDataList()
        local data = flist[self.m_curInd + 1]

        local fdata = LDataConstMgr:GetFormationLvUpData(data.id,1)
        local itemId = fdata.costItemId

        local citem = LDataConstMgr:getCItemByID(itemId)

        local item = 
        {
            itemType = "CItem",
            itemData = citem,
        }
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self.m_pIconBtn:addClickEventListener(MatItemClicked)
	self:MarkIntaractCObj(self.m_pIconBtn)
    local function StudyBtnClicked(sender)
        self:HandleStudy()
    end
    self.m_pStudyBtn:addClickEventListener(StudyBtnClicked)
	self:MarkIntaractCObj(self.m_pStudyBtn)

    local function ChangePosBtnTouched(pTouch, pEvent)
        if pEvent == ccui.TouchEventType.began then
            self.m_pTouchBeganPos = pTouch:getTouchBeganPosition()
            local ind = pTouch:getTag()
            self:PosBtnTouchBegan(ind)
        elseif pEvent == ccui.TouchEventType.moved then
            local movePos = pTouch:getTouchMovePosition()
            self:PosBtnTouchMoved(movePos)
        elseif pEvent == ccui.TouchEventType.ended
                or pEvent == ccui.TouchEventType.canceled then
            self:PosBtnTouchEnd()
        end
    end

    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        self.m_pPosPanelList[i]:addTouchEventListener(ChangePosBtnTouched)
		self:MarkIntaractCObj(self.m_pPosPanelList[i])
        self.m_pPosPanelList[i]:setTag(i)
        self.m_pPosPanelList[i]:setTouchEnabled(true)
    end

    local function UseZhenfaClicked( sender )
        -- body
        local flist = LDataConstMgr:GetFormationDataList()
        local data = flist[self.m_curInd + 1]
        local myFData = LRoleDataMgr.myFormation

        local lv = myFData:GetMyZhenfaLvById(data.id)
        if lv > 0 then
            if self.m_pHeroData:IsLeader() == true then
                LuaNetSendMsg:QueryTeamFormationUse(data.id)
            else
                LuaNetSendMsg:QueryFormationUse(data.id)
            end
            
        end
    end
    self.m_pUseBtn:addClickEventListener(UseZhenfaClicked)
	self:MarkIntaractCObj(self.m_pUseBtn)
end


function TeamFormationUI:PosBtnTouchMoved(movePos)
    if self.m_curMoveInd <= 0 then
        return
    end
    local offx = movePos.x - self.m_pTouchBeganPos.x
    local offy = movePos.y - self.m_pTouchBeganPos.y
    self.m_pTouchBeganPos = movePos
    local modelPos = cc.p(self.m_pModelNodeList[self.m_curMoveInd]:getPosition())
    self.m_pModelNodeList[self.m_curMoveInd]:setPosition(cc.p(modelPos.x + offx, modelPos.y + offy))
end

--[[
根据9宫格下标获取出站位置
]]
function TeamFormationUI:GetCurFormationPos(ind)
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    for i = 1, AppDef.Formation.MaxFightNum do
        if finfo.posList[i] == ind then
            return i
        end
    end
    return 0
end

function TeamFormationUI:PosBtnTouchBegan(posInd)
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]
    local finfo = LDataConstMgr:GetFormationDataById(data.id)
    
    local ind = self:GetCurFormationPos(posInd)
    if ind == 0 then
        return
    end

    if finfo.posOpenLvList[ind] > LRoleDataMgr.MyHeroInfo.level then
        return
    end
    self.m_curMoveInd = ind
end

function TeamFormationUI:PosBtnTouchEnd()
    if self.m_curMoveInd <= 0 then
        return
    end
    local modeNode = self.m_pModelNodeList[self.m_curMoveInd]
    local endPos = cc.p(self.m_pModelNodeList[self.m_curMoveInd]:getPosition())
    local endWorldPos = modeNode:convertToWorldSpace(cc.p(0,0))
    self.m_pModelNodeList[self.m_curMoveInd]:setPosition(cc.p(0,0))
    local minDis = 1000000
    local minInd = 0
    for i = 1, AppDef.BTConst.MaxHalfUnitNum do
        local dis = cc.pDistanceSQ(endWorldPos, self.m_pModelNodeWorldPosList[i])
        if minDis > dis then
            minDis = dis
            minInd = i
        end
        
    end

    local oldPos = self.m_curMoveInd
    local newPos = self:GetCurFormationPos(minInd)
    self.m_curMoveInd = 0
    if oldPos ~= newPos
        and minDis <= 1000 then
        if self.m_pHeroData:IsLeader() == true then
            LuaNetSendMsg:QueryTeamFormationChangePos(oldPos, newPos)
        else
            LuaNetSendMsg:QueryFormationChangePos(oldPos, newPos)
        end
    end
end

function TeamFormationUI:HandleStudy()

    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[self.m_curInd + 1]

    LuaNetSendMsg:QueryFormationLvUp(data.id)
end

return TeamFormationUI