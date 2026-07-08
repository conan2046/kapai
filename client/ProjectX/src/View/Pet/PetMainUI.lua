--[[
lua里面的游戏逻辑控制
]]
local ScriptPath = "Pet.PetMainUI"
local PetUIDef = require "View.Pet.PetUIDef"
local PetMainUI = LUIBase:New()
PetMainUI.__index = PetMainUI
--local this = LTcpSocket
function PetMainUI:New(openTab)
    openTab = openTab or PetUIDef.Tab.Info
	local o = LUIBase:New()
	setmetatable(o,PetMainUI)	
    o:Init(openTab)
	return o
end

function PetMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.ChangePetName,
        LUIPetEvent.ChangePetLv,
        LUIFormationEvent.PetFight,
        LUIPetEvent.ComposionPet,
        LUIPetEvent.ChangePetSkill,
        LUIBagEvent.BagDataChanged,
        LUIPetEvent.ChangePetStar,
        LUIPetEvent.ChangePetXiulian,
        LUIPetEvent.PetStarAdd,
        LUIPetEvent.ResolveSucess,
        LUIFormationEvent.ZhenfaChanged,
	    LUIPetEvent.PetEquipAdd,
    }
    self:RegistSelf(self, self.msgIds)
end

function PetMainUI:Init(openTab)
    self.Script = ScriptPath
    self:RegistMsgs()
    self:InitData()
    self:InitViewSize()
    self:InitUICtr()
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:InitFCClass(openTab)
    self:InitTableView()
    --self.m_pSubLayer = {}
    self.m_curUIInd = 0

    if openTab == 6 then
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, 1)
    else
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, openTab)
    end
    
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self:TabClicked(openTab)
    --self:RegisterGuide()

    local function PlayDefault()
        self:ShowPetSoundEffect()
        if self.m_curUIInd == 6 then
            self:FormationClicked()
        end
    end
    Utils:DelayToCallFunc(self.m_pUILayer,0.1,PlayDefault)
end

--function PetMainUI:CheckTujianRedPoint()
--    local ret =  Utils:TujianRedDotCheck()
--    --local redImg = self.m_pTujianBtn:getChildByName("Prompt")
--    --redImg:setVisible(ret)
--end

function PetMainUI:RegisterGuide()
    -------------------------------------------------------
    -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_SHENJ_1)
    -- Utils:RegisterGuide(GuideDef.StepId.Guide_SHENJ_1, nil, function()
    --     self:HandlePetFight(3)
    -- end, data.maskOffset, true)
    -- -------------------------------------------------------
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RegisterCloseGuide, GuideDef.StepId.Guide_SHENJ_2)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetMainUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.ChangePetName then
        self:CheckPetNameChanged(msg.value)
    elseif msg.msgId == LUIPetEvent.ChangePetLv then
        self:CheckPetLvChanged(msg.value.pid)
    elseif msg.msgId == LUIFormationEvent.PetFight then
        self:CheckPetFightStateChanged(msg.value)
    elseif msg.msgId == LUIPetEvent.ComposionPet then
        self:updateGetPetUI()
    elseif msg.msgId == LUIPetEvent.ChangePetSkill then
        self:PetSkillChanged()
    elseif msg.msgId == LUIPetEvent.ChangePetStar then
        self:PetStarChanged()
    elseif msg.msgId == LUIPetEvent.ChangePetXiulian then
        self:PetXiulianChanged()
    elseif msg.msgId == LUIBagEvent.BagDataChanged then
        LRoleDataMgr:UpdatePetUpItems()
    elseif msg.msgId == LUIPetEvent.PetStarAdd then
        self:UpdateLeftViewPetStar()    
    elseif msg.msgId == LUIPetEvent.ResolveSucess then
        self:RefreshLeftView()
    elseif msg.msgId == LUIFormationEvent.ZhenfaChanged then
        self:CheckFormationRedPoint()
    elseif msg.msgId == LUIPetEvent.PetEquipAdd then
        self:PetXiulianChanged()
    end
end

function PetMainUI:OnEnter()
    self:CheckRedPointInTab()
end

--[[
检测页签红点
]]
function PetMainUI:CheckRedPointInTab()
    for i = 1, 5 do
        local ret = self:CheckRedPointVisibleInTab(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetMainUI:PetXiulianChanged()
    self:ResetRedPointInList()
    self:CheckRedPointInTab()
end

function PetMainUI:UpdateLeftViewPetStar()
    if self.m_pPetList == nil then return end
    for i = 1, #self.m_pPetList do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            local starListView = cellChild:getChildByName("bg_Head"):getChildByName("Stars")
            self:ShowStars(starListView, self.m_pPetList[i].star)
        end
    end
end

function PetMainUI:RefreshLeftView()
    self.m_pPetList = LRoleDataMgr.Pet.petlist
    self.m_curPetInd = 0
    self.m_pTableView:reloadData()
    LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.SelectedPet, self.m_pPetList[self.m_curPetInd + 1])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetMainUI:PetStarChanged()
    self:ResetRedPointInList()
    for i = 1, 5 do
        local ret = self:CheckRedPointVisibleInTab(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetMainUI:ResetRedPointInList()
    for i = 1, #self.m_pPetList do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            local redPointImg = cellChild:getChildByName("Prompt")
            redPointImg:setVisible(self:CheckRedPointVisible(i))
        end
    end
end

function PetMainUI:CheckTabBtnRedPoint()
    for i = 1, 5 do
        local ret = self:CheckRedPointVisibleInTab(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetMainUI:PetSkillChanged()
    self:ResetRedPointInList()
    local ret = self:CheckRedPointVisibleInTab(2)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {2, ret})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
检查宠物出站状态变更
@param1:pid:宠物id
]]
function PetMainUI:CheckPetFightStateChanged(pid)
    for i = 1, #self.m_pPetList do
        if self.m_pPetList[i].id == pid then
            local cell = self.m_pTableView:cellAtIndex(i - 1)
            if cell ~= nil then
                local cellChild = cell:getChildByTag(123)
                local ck = cellChild:getChildByName("CheckBox")
                if self.m_pPetList[i].fightPos > 0 then
                    ck:setSelected(true)
                else
                    ck:setSelected(false)
                end
                local redPointImg = cellChild:getChildByName("Prompt")
                redPointImg:setVisible(self:CheckRedPointVisible(i))
                LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.PetExpRedDot)
                self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            return
        end
    end
end

function PetMainUI:CheckPetLvChanged(pid)
    for i = 1, #self.m_pPetList do
        local cell = self.m_pTableView:cellAtIndex(i - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            if self.m_pPetList[i].id == pid then
                local headPanel = cellChild:getChildByName("bg_Head")
                local lvLabel = headPanel:getChildByName("Value")
                lvLabel:setString(self.m_pPetList[i].level)
            end
            local redPointImg = cellChild:getChildByName("Prompt")
            redPointImg:setVisible(self:CheckRedPointVisible(i))
        end
    end
    for i = 1, 5 do
        local ret = self:CheckRedPointVisibleInTab(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function PetMainUI:CheckPetNameChanged(pid)
    for i = 1, #self.m_pPetList do
        if self.m_pPetList[i].id == pid then
            local cell = self.m_pTableView:cellAtIndex(i - 1)
            if cell ~= nil then
                local cellChild = cell:getChildByTag(123)
                local headPanel = cellChild:getChildByName("bg_Head")
                local nameLabel = headPanel:getChildByName("Name")
                nameLabel:setString(self.m_pPetList[i].name)
            end
            return
        end
    end
end

function PetMainUI:InitUICtr()
    local panel = self.m_pUILayer:getChildByName("shenjiangListUI"):getChildByName("List")
    self.m_pListPanel = panel:getChildByName("Panel")
    self.m_pPetCell = panel:getChildByName("Item")
    self.m_pStarImg = panel:getChildByName("Star")

    self.m_pCellSize = self.m_pPetCell:getContentSize()

    
    self.m_pFormationBtn = panel:getChildByName("btn_buzhen")
    self.m_pFormationBtn:addClickEventListener(handler(self,PetMainUI.FormationClicked))
    self:MarkIntaractCObj(self.m_pFormationBtn)
    self.m_pFormationBtnRedPImg = self.m_pFormationBtn:getChildByName("Prompt")
    self.m_pFormationBtnRedPImg:setVisible(false)
    self.m_pBZBtnLabel = self.m_pFormationBtn:getChildByName("Text")

    --self:CheckTujianRedPoint()
    self:CheckFormationRedPoint()
end

function PetMainUI:FormationClicked(sender)
    if self.m_fIsOpen == nil or not self.m_fIsOpen then
        self.m_fIsOpen = true
        self.m_preUIInd =  self.m_curUIInd
        self:TabClicked(6)
        self.m_pBZBtnLabel:setString(GUITips.RSI_PET_DIS_TIPS4)
    else
        self.m_fIsOpen = false
        self:TabClicked(self.m_preUIInd)
        self.m_pBZBtnLabel:setString(GUITips.RSI_PET_DIS_TIPS3)
    end
end

function PetMainUI:InitTableView()
    local tableView
    if self.m_pListPanel == nil then
        --有可能是复用的UI，所以这个时候就是空的
        return
    else
        tableView = self.m_pListPanel:getChildByName("PetTableView")
        if tableView == nil then
            tableView = cc.TableView:create(self.m_pListPanel:getContentSize())
            tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
            tableView:setAnchorPoint(cc.p(0, 0))
            tableView:setDelegate()
            tableView:setSwallowsTouches(false)
            tableView:setBounceable(false)
            tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
            tableView:setName("PetTableView")
            self.m_pListPanel:addChild(tableView)
        else
            ScriptHandlerMgr:getInstance():removeObjectAllHandlers(tableView)
        end
    end
    

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
    self.m_pTableView = tableView
    self:MarkIntaractCObj(self.m_pTableView)
end

function PetMainUI:PetCellSelected(cellChild, ind)
    if self.m_curPetInd == ind then
        return
    end

    local oldCell = self.m_pTableView:cellAtIndex(self.m_curPetInd)
    if oldCell ~= nil then
        local oldCellChild = oldCell:getChildByTag(123)
        if oldCellChild ~= nil then
            local selectImg = oldCellChild:getChildByName("Choose")
            selectImg:setVisible(false)
            --oldCellChild:setSelected(false)
        end
    end
    self.m_curPetInd = ind
    --cellChild:setSelected(true)
    local selectImg = cellChild:getChildByName("Choose")
    selectImg:setVisible(true)
    
    LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.SelectedPet, self.m_pPetList[self.m_curPetInd + 1])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:ShowPetSoundEffect()
end

function PetMainUI:ShowPetSoundEffect()
    if #self.m_pPetList == 0 or self.m_curPetInd >= #self.m_pPetList then
        return
    end
    local curPet = self.m_pPetList[self.m_curPetInd + 1]
    local playFile = PetkaPaiManager:GetCV(curPet)
    if string.len(playFile) > 0 then
        LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, playFile)
        self:SendMsg(LGameMsg.m_audioMsg)

        -- local soundPath = curPet.baseData.cv
        -- LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, soundPath)
        -- self:SendMsg(LGameMsg.m_audioMsg)
    end

end

function PetMainUI:PetCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    self:PetCellSelected(cellChild, ind)
    --self:SelServerArea(ind)
end

function PetMainUI:PetCellAtIndex(sender, idx)
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

    local selectImg = cellChild:getChildByName("Choose")
    if idx == self.m_curPetInd then 
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
    return cell
end

--[[
显示宠物icon通用函数
headImg:头像ImageView
petId:宠物id 
bgImg:背景ImageView
petQuality:宠物品质
]]
-- function PetMainUI:ShowPetHeadImg(headImg, petId, bgImg, petQuality, isShiny)

--     local str = AppDef.ColorKuangArr[petQuality]
--     --bgImg:loadTexture(str,ccui.TextureResType.plistType)


    
--     local imgPath = Utils:GetMonsterIconRes(petId, AppDef.HeadIconResType.Square)
--     headImg:loadTexture(imgPath,ccui.TextureResType.localType)


--     if isShiny == true then
--         local imod = ImodAnim:createWithFile("item/equipLight")
--         imod:PlayActionRepeat(0,0.1)
--         local size = pHead:getContentSize()
--         imod:setPosition(cc.p(size.width/2, size.height/2))
--         headImg:addChild(imod,0,666)
--     else
--         headImg:removeChildByTag(666)
--     end
-- end

function PetMainUI:ShowStars(starLayout, star)
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

function PetMainUI:HandlePetFight(petInd)
    local pet = self.m_pPetList[petInd]
    if pet == nil then
        return
    end
    local cell = self.m_pTableView:cellAtIndex(petInd - 1)
    if cell ~= nil then
        local cellChild = cell:getChildByTag(123)
        self:PetCellSelected(cellChild, petInd - 1)
    end
    --请求出战
    if pet.fightPos > 0 then
        LuaNetSendMsg:QueryFormationPetPos(pet.id, 2)
    else
        LuaNetSendMsg:QueryFormationPetPos(pet.id, 1)
    end
end

function PetMainUI:CheckFormationRedPoint()
    local ret = false
    local list = LDataConstMgr:GetFormationDataList()
    local myFData = LRoleDataMgr.myFormation
    for i = 1, #list do
        ret = LRoleDataMgr:FormationCheckUp(i)
        if ret then
            break
        end
    end
    if ret then
        self.m_pFormationBtnRedPImg:setVisible(true)
    else
        self.m_pFormationBtnRedPImg:setVisible(false)
    end
    return ret
end
--[[
检测宠物是否有小红点
@param1:pind,宠物下表
@return:true,显示小红点，false不显示小红点
]]
function PetMainUI:CheckRedPointVisible(pind, ind)
    if self.m_curUIInd == 5 and ind == nil then
        return false
    end
    ind = ind or self.m_curUIInd
    if ind == 1 then
        --检查升级
        local ret = LRoleDataMgr:PetCheckLvUp(pind)
        return ret
    end

    if ind == 2 then
        --检查技能升级
        local ret = false
        local petData = self.m_pPetList[pind]
        for i = 1, AppDef.Pet.MaxSkillNum do
            local curSk = petData.skills[i]
            ret = LRoleDataMgr:PetCheckSkillLvUp(petData, i)
            if ret then
                return ret
            end
        end
        return ret
    end

    if ind == 3 then
        --检查升星
        local ret = false
        local petData = self.m_pPetList[pind]
        ret = LRoleDataMgr:PetCheckStarUp(petData)
        return ret
    end

    if ind == 5 then
        --检查修炼
        local ret = false
        local petData = self.m_pPetList[pind]
        for i = 1, AppDef.Pet.MaxXliulianType do
            ret = LRoleDataMgr:PetCheckXiulianUp(petData, i)
            if ret then
                return ret
            end
        end
        
        return ret
    end

    return false
    -- checkInd = checkInd or -1
    -- if checkInd == -1 or checkInd == 1 then
    --     --检查升级
    --     local ret = LRoleDataMgr:PetCheckLvUp(pind)
    --     if ret or checkInd == 1 then
    --         return ret
    --     end
    -- end

    -- if checkInd == -1 or checkInd == 2 then
    --     --检查技能升级
    --     local ret = false
    --     local petData = self.m_pPetList[pind]
    --     for i = 1, AppDef.Pet.MaxSkillNum do
    --         local curSk = petData.skills[i]
    --         ret = LRoleDataMgr:PetCheckSkillLvUp(petData, i)
    --         if ret then
    --             return ret
    --         end
    --     end
    --     if checkInd == 2 then
    --         return ret
    --     end
    -- end

    -- if checkInd == -1 or checkInd == 3 then
    --     --检查升星
    --     local ret = false
    --     local petData = self.m_pPetList[pind]
    --     ret = LRoleDataMgr:PetCheckStarUp(petData)
    --     if ret or checkInd == 3 then
    --         return ret
    --     end
    -- end

    -- if checkInd == -1 or checkInd == 4 then
    --     --检查修炼
    --     local ret = false
    --     local petData = self.m_pPetList[pind]
    --     for i = 1, AppDef.Pet.MaxXliulianType do
    --         ret = LRoleDataMgr:PetCheckXiulianUp(petData, i)
    --         if ret then
    --             return ret
    --         end
    --     end
        
    --     if checkInd == 4 then
    --         return ret
    --     end
    -- end
    -- if checkInd == 5 then
    --     --检查阵型
    --     local ret = false
    --     local list = LDataConstMgr:GetFormationDataList()
    --     local myFData = LRoleDataMgr.myFormation
    --     for i = 1, #list do
    --         ret = LRoleDataMgr:FormationCheckUp(i)
    --         if ret then
    --             return ret
    --         end
    --     end
    --     return ret
    -- end
    -- return false
end

function PetMainUI:ShowPetCellInfo(cell, ind)
   
    local curPet = self.m_pPetList[ind+1]
    cell.userObject = curPet.id
    local headPanel = cell:getChildByName("bg_Head")
    local headImg = headPanel:getChildByName("Icon")

    local colorImg = headPanel:getChildByName("Color")
    colorImg:setVisible(false)
    local attrImg = headPanel:getChildByName("Attribute")--属性
    local lvLabel = headPanel:getChildByName("Value")
    local nameLabel = headPanel:getChildByName("Name")
    local starListView = headPanel:getChildByName("Stars")
    --starListView:removeAllItems()

    
    local redPointImg = cell:getChildByName("Prompt")

    redPointImg:setVisible(self:CheckRedPointVisible(ind + 1))
    AppDef:ShowProAttrImg(attrImg, curPet.baseData.petType)
    
    lvLabel:setString(curPet.level)
    nameLabel:setString(curPet.name)
    local color = AppDef:GetPetQualityColor(curPet.baseData.quality)
    nameLabel:setTextColor(color)

    Utils:ShowPetHeadImg(headImg, curPet.baseData.pic, headPanel, curPet.baseData.quality, curPet:IsShiny())

    local function CheckBoxClicked(sender)
        local petInd = sender:getTag()
        self:HandlePetFight(petInd)
    end
    local ck = cell:getChildByName("CheckBox")
    if curPet.fightPos > 0 then
        ck:setSelected(true)
    else
        ck:setSelected(false)
    end
    ck:addClickEventListener(CheckBoxClicked)
    self:MarkIntaractCObj(ck)
    ck:setTag(ind+1)


    -- for i = 1, curPet.star do
    --     local star = self.m_pStarImg:clone()
    --     starListView:pushBackCustomItem(star)
    -- end
    self:ShowStars(starListView, curPet.star)
    --m_pStarImg
end

function PetMainUI:InitData()
    LRoleDataMgr.Pet:SortPetList()
    LRoleDataMgr:UpdatePetUpItems()
    self.m_pPetList = LRoleDataMgr.Pet.petlist
    self.m_pUILayer = nil
    self.m_pListPanel = nil--宠物列表层
    self.m_pPetCell = nil--宠物列表子节点
    self.m_pCellSize = nil--列表子节点尺寸
    self.m_pStarImg = nil--星星图片
    self.m_pTableView = nil
    --self.m_pTujianBtn = nil--图鉴按钮
    --self.btn_LianHua=nil--炼化按钮
    self.m_pFormationBtn = nil --布阵按钮
    self.m_pSubLayer = {}
    self.m_curUIInd = 0--当前子页签下表
    self.m_curPetInd = 0--当前选中宠物下标
end

function PetMainUI:InitViewSize()
    self:CreateUINode("csd/shenjiangListLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangListLayer.csb")
    -- local frameSize = cc.Director:getInstance():getVisibleSize()
    -- self.m_pUILayer:setContentSize(frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:MarkIntaractCObj(self.m_pUILayer)
end

--[[
初始化一级界面相关信息
]]
function PetMainUI:InitFCClass()
    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local function tabBtnClicked(ind)
        self:TabClicked(ind)
    end
    local tabValues = 
    {
        PetUIDef.TabNames,
        tabBtnClicked
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, tabValues)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)


    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, PetUIDef.MainTitle)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--[[
检测tab页签是否显示红点
]] 
function PetMainUI:CheckRedPointVisibleInTab(ind)

    if ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJJINENG,true) then
        return false
    elseif ind == 3 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJSHENGXING,true) then
        return false
    elseif ind == 4 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJEQUIP,true) then
        return false
    elseif ind == 5 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJXIULIAN,true) then
        return false
    end

    local ret = false
    for i = 1, #self.m_pPetList do
        ret = self:CheckRedPointVisible(i, ind)
        if ind == 1 and ret ==  false then
            ret =  Utils:TujianRedDotCheck()
        end
        if ret == true then
            return ret
        end
    end
    return ret
end

function PetMainUI:GoBack(index)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SelectTab, index)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end


function PetMainUI:TabClicked(ind)
    if  self.m_curUIInd == ind then
        return
    end
    if ind == 2 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJJINENG) then
        self:GoBack(self.m_curUIInd)
        return
    elseif ind == 3 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJSHENGXING) then
        self:GoBack(self.m_curUIInd)
        return
    elseif ind == 4 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJEQUIP) then
        self:GoBack(self.m_curUIInd)
        return
    elseif ind == 5 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJXIULIAN) then
        self:GoBack(self.m_curUIInd)
        return
    elseif ind == 6 and Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJBUZHEN) then
        self:GoBack(self.m_curUIInd)
        return
    end

    if self.m_curUIInd ~= 0 then
        self:HideCurUI()
    end
    self.m_curUIInd = ind
    self:ShowCurUI()
    if self.m_curUIInd ~= 6 then
        self.m_fIsOpen = false
        self.m_pBZBtnLabel:setString(GUITips.RSI_PET_DIS_TIPS3)
    end
    for i = 1, 5 do
        local ret = self:CheckRedPointVisibleInTab(i)
        LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {i, ret})
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self:ResetRedPointInList()
end

function PetMainUI:HideCurUI()
    if self.m_pSubLayer[self.m_curUIInd] == nil then
        return
    end
    self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(false)
end

function PetMainUI:ShowCurUI()
    
     if self.m_pSubLayer[self.m_curUIInd] == nil then
        self:DelayLoadSubUI(self.m_curUIInd)
    else
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, PetUIDef.TabNames[self.m_curUIInd])
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function PetMainUI:DelayLoadSubUI(tabInd)
    local ind = tabInd
    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        if self.m_curUIInd ~= ind then
            return
        end
        local curPet = self.m_pPetList[self.m_curPetInd + 1]
        self.m_pSubLayer[ind] = require(PetUIDef.SubUIPaths[ind]):New(curPet)
        self.m_pUILayer:addChild(self.m_pSubLayer[ind].m_pUILayer)
        self.m_pSubLayer[ind].m_pUILayer:setTag(ind)
        self.m_pSubLayer[self.m_curUIInd].m_pUILayer:setVisible(true)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end

function PetMainUI:onExit()
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHENJ_1)
    --Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_SHENJ_2)
    
    if self.isUseResBuffer then
        --没有真正删除，只是放缓存里面了，这个时候要删除子页签
        for i = 1, 6 do
            local subLayer = self.m_pSubLayer[i]
            if subLayer ~= nil then
                if subLayer.isUseResBuffer then
                    LGameMsg.m_baseMsgWithOne:Change(LResEvent.UnusedCsb,{subLayer.csbFilePath,subLayer.m_pUILayer})
                    self:SendMsg(LGameMsg.m_baseMsgWithOne)
                else
                    subLayer.m_pUILayer:removeFromParent()
                end
                subLayer.m_pUILayer = nil
            end
        end
    end
    self:Destory()
    self.m_pBZBtnLabel = nil
    self.m_pSubLayer = nil
    self.m_pListPanel = nil
    self.m_pPetCell = nil
    self.m_pStarImg = nil

    self.m_pCellSize = nil

    
    self.m_pFormationBtn = nil
    self.m_pFormationBtnRedPImg = nil
    self.m_pBZBtnLabel = nil
    
    self.m_pUILayer = nil
    self.m_curUIInd = nil
    self.m_curPetInd = nil
    self.m_pCellSize = nil
    self.m_pFormationBtn = nil
    self.m_pStarImg = nil
    self.m_pTableView = nil
end

function PetMainUI:InitTouchEvt()
    
end

function PetMainUI:updateGetPetUI()
    -- body
   -- self:CheckTujianRedPoint()
    --self:CheckFormationRedPoint()

    local ret = self:CheckRedPointVisibleInTab(1)
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.RedDotState, {1, ret})
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    self.m_pTableView:reloadData()
end 


return PetMainUI