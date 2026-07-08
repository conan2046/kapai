--[[
lua里面的游戏逻辑控制
神将装备分解
]]

local PetEquipResolveUI = LUIBase:New()
PetEquipResolveUI.__index = PetEquipResolveUI
--local this = LTcpSocket
function PetEquipResolveUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetEquipResolveUI)	
    o:Init()
	return o
end


function PetEquipResolveUI:Init()
    self.m_pUILayer = cc.CSLoader:createNode("csd/Fenjie2Layer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
    self:ShowMoney()
    if self.m_pPackageList == nil then
        LuaNetSendMsg:QueryPetEquip(1)
    end
end

function PetEquipResolveUI:onExit()
    self:Destory()
    for key,value in pairs(self.m_pItemLists) do 
       if self.m_pPackageList ~= nil and self.m_pPackageList[key] ~= nil then
           local index = self.m_pPackageList[key].m_uid
           if index ~= nil and index > 0 then
               value:onExit(true)
           end
       end
    end
    self.m_pItemLists = nil
    self.m_pPackageList = nil
    self.m_pUILayer = nil
    self.m_pRightTableView = nil
    
    self.m_selectIdx = nil
    self.m_suitDDs = nil
    self.m_suitType = nil
    self.m_wpos = nil

    self.m_checkBoxs = nil

    if self.m_pGridCell then
        self.m_pGridCell:release()
        self.m_pGridCell = nil
    end
    
    self.m_pItemLists = nil
    
    self.m_getListView = nil
    if self.m_getItemCell then
        self.m_getItemCell:release()
        self.m_getItemCell = nil
    end

    --下拉框选择套装
    self.m_pSuitBtn = nil
    self.m_suitDropDChooseImg = nil
    self.m_suitDropDNameLabel = nil
    self.m_suitDropDOpenImg = nil
    self.m_suitDropDCloseImg = nil
    self.m_suitDropDCloseBtn = nil
    self.m_suitDropDList = nil
    self.m_suitDropDCell = nil

    self.m_pPartBtn = nil
    self.m_partDropDChooseImg = nil
    self.m_partDropDNameLabel = nil
    self.m_partDropDOpenImg = nil
    self.m_partDropDCloseImg = nil
    self.m_partDropDCloseBtn = nil
    self.m_partDDPanel = nil
    self.m_resolveBtn = nil
    --帮助
    self.m_helpBtn = nil
    --金钱数值
    self.m_qnLabel = nil

    self.m_starStates = nil
    self.m_pGetItems = nil
    self.m_effectPlaying = nil
end

--[[
注册UI消息
]]
function PetEquipResolveUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.PetEquipResolveSuc,
        LUIPetEvent.GotPetEquip,
    }
    self:RegistSelf(self,self.msgIds)
end

function PetEquipResolveUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.PetEquipResolveSuc then
        self:ADAndRefreshPage()
        self.m_effectPlaying = false
        self.m_resolveBtn:setEnabled(true)
        self.m_pSuitBtn:setTouchEnabled(true)
        self.m_pPartBtn:setTouchEnabled(true)

    elseif msg.msgId == LUIPetEvent.GotPetEquip then
        self:RefreshIconItem()
    end
end

function PetEquipResolveUI:RefreshPage()
     self.m_resolveBtn:setEnabled(true)
     self:ClearResolveInfo()
end

function PetEquipResolveUI:ShowEffect()  
--     local function callback(frame)
--        --动画播放完成    
--        self.m_effectPlaying = false
--        self.m_resolveBtn:setEnabled(true)
--        self.m_pSuitBtn:setTouchEnabled(true)
--        self.m_pPartBtn:setTouchEnabled(true)

--        if self.m_uids == nil or #self.m_uids == 0 then 
--            self.m_uids = {}
--            return     
--        end
--        local count = 1
--        local ids = {}
--        for i=1,#self.m_uids do       
--            ids[count] = self.m_uids[i]
--            if i%200 == 0 or #self.m_uids == i then
--                LuaNetSendMsg:SendPetEquipFenjieReq(ids)
--                ids = {}
--                count = 0
--            end
--            count = count + 1
--        end
--        self.m_uids = {}
--     end

     if self.m_action == nil then
         self.m_action = cc.CSLoader:createTimeline("csd/Fenjie2Layer.csb")
         local timeline = ccs.Timeline:create()
         local frame = ccs.EventFrame:create()
         frame:setEvent("End")
         frame:setFrameIndex(300)
         timeline:addFrame(frame)
         self.m_action:addTimeline(timeline)
         self.m_pUILayer:runAction(self.m_action)
     end
     self.m_action:pause()
     --self.m_action:clearFrameEventCallFunc()    
     self.m_action:gotoFrameAndPlay(0,300,false)
     --self.m_action:setFrameEventCallFunc(callback)
     self.m_resolveBtn:setEnabled(false)

     self.m_effectPlaying = true
     self.m_resolveBtn:setEnabled(false)
     self.m_pSuitBtn:setTouchEnabled(false)
     self.m_pPartBtn:setTouchEnabled(false)
     if self.m_partBtnSign then
         self:PartBtnCallback()
     end
end

function PetEquipResolveUI:UpdateBagCell(idx,item)
    --print("UpdateBagCell",idx)
    if item == nil or idx < 1 then
        return
    end
    if self.m_pPackageList == nil then
        item:UpdateItem(nil)
        return
    end
    local temp = self.m_pPackageList[idx]
    if temp == nil or temp.m_uid < 1 then
        if idx >= #self.m_pPackageList then
            item:UpdateItem(nil)
        else
            self:UpdateBagAll()
        end
        table.remove(self.m_pPackageList,idx)
        return
    end
   
    local resFile = string.format("item/%s.png", temp.m_pic)
    local userDefine ={picFilePath = resFile,quality = temp.m_quality, star =temp.m_star, strengthenLv = temp.m_stoneLevel,suitId = temp.m_suitType}
    local itemValue = {}
    itemValue.userDefine = userDefine
    item:UpdateItem(itemValue)
end

function PetEquipResolveUI:UpdateBagAll()
    if self.m_pItemLists == nil or self.m_pPackageList == nil then
        return
    end
    for i=1,#self.m_pItemLists do
        local parent = self.m_pItemLists[i].m_pNode
        local ind = parent.userObject
        local temp = self.m_pPackageList[ind]
        if temp ~= nil then
            local resFile = string.format("item/%s.png", temp.m_pic)
            local userDefine ={picFilePath = resFile,quality = temp.m_quality, star =temp.m_star, strengthenLv = temp.m_stoneLevel}
            local itemValue = {}
            itemValue.userDefine = userDefine
            self.m_pItemLists[i]:UpdateItem(itemValue)
        else
            self.m_pItemLists[i]:UpdateItem(nil)
        end
    end 
end

function PetEquipResolveUI:CheckBagItemList(value)
    for i = 1, #self.m_pPackageList do
        if self.m_pPackageList[i].pos == value then
            return i
        end
    end
    return nil
end

function PetEquipResolveUI:IsSelected(ind)
    if ind < 1 or self.m_selectIdx[ind] == nil or self.m_selectIdx[ind] == 0 then
        return false
    end
    return true
end

function PetEquipResolveUI:ShowBag()
    for i = 1,#self.m_pItemLists do
        local parent = self.m_pItemLists[i].m_pNode
        local count = parent:getTag()
        if count <= self.m_itemGridNum then    
           self:UpdateBagCell(count,self.m_pItemLists[i]) 
        end
    end
end

function PetEquipResolveUI:UpdateBag() 
    self:RefreshIconItem()
    self:ClearResolveInfo()
end


function PetEquipResolveUI:InitData()
    self.m_selectIdx = {} --背包选中(多选)
    self.m_suitDDs = {}
    self.m_suitType = 0--选择套装
    self.m_wpos = 0--选择部位

    local panel = self.m_pUILayer:getChildByName("Panel")
    --背包部分
    local bagPanel = panel:getChildByName("RoleBag")
    --筛选按钮
    local btnPanel = bagPanel:getChildByName("Screen")
    self.m_checkBoxs = {}
    for i = 1,AppDef.MAX_PET_EQUIP_STAR do
        self.m_checkBoxs[i] = btnPanel:getChildByName("CheckBox_"..i)
        self.m_checkBoxs[i].userObject = i
    end
    --背包格
    local viewPanel = bagPanel:getChildByName("BagCheck")
    local rightView = viewPanel:getChildByName("BagCheck")
    self.m_pGridCell = rightView:getChildByName("Row")
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:retain()
    self.m_pGridCell:removeFromParent()
    
    self.m_pItemLists = {}
    self:InitRightTabView(rightView)
    self:RefreshIconItem()
   
    --分解部分
    local resolvePanel = panel:getChildByName("Fenjie")
    self.m_effectPanel = resolvePanel:getChildByName("Bg")
    --获取列表
    local getPanel = resolvePanel:getChildByName("RewardBg")
    self.m_getListView = getPanel:getChildByName("List")
    self.m_getItemCell = self.m_getListView:getChildByName("IconBg_1")
    self.m_getItemCell:retain()
    self.m_getItemCell:removeFromParent()

    --下拉框选择套装
    self.m_pSuitBtn = bagPanel:getChildByName("SuitBtn")
    self.m_suitDropDChooseImg = self.m_pSuitBtn:getChildByName("ChooseBg")
    self.m_suitDropDNameLabel = self.m_pSuitBtn:getChildByName("BtnName")
    self.m_suitDropDNameLabel:setString(GUITips.RSI_PET_SUIT_TIPS10)
    self.m_suitDropDOpenImg = self.m_pSuitBtn:getChildByName("OpenImage")
    self.m_suitDropDCloseImg = self.m_pSuitBtn:getChildByName("CloseImage")
    self.m_suitDropDCloseBtn = self.m_pSuitBtn:getChildByName("CloseBtn")
    self.m_suitDropDList = self.m_pSuitBtn:getChildByName("List")--下拉框列表
    self.m_suitDropDCell = bagPanel:getChildByName("ChooseSuit")
    local max = AppDef.Pet.MaxSuitTypeNum+1
    if self.m_suitDDs[max] == nil then
        self.m_suitDDs[max] = self.m_suitDropDCell:clone()
        self.m_suitDDs[max].userObject = 0
        local nameLabel = self.m_suitDDs[max]:getChildByName("BtnName")
        if nameLabel ~= nil then
            nameLabel:setString(GUITips.RSI_RESOLVE_TIP_5)
        end
        self.m_suitDropDList:pushBackCustomItem(self.m_suitDDs[max])
    end
     for i=1,AppDef.Pet.MaxSuitTypeNum do
        if self.m_suitDDs[i] == nil then
            self.m_suitDDs[i] = self.m_suitDropDCell:clone()
            self.m_suitDDs[i].userObject = i
            local nameLabel = self.m_suitDDs[i]:getChildByName("BtnName")
            local cfgData = LDataConstMgr:GetPetSuitCfgData(i)
            if cfgData ~= nil and nameLabel ~= nil then
                nameLabel:setString(cfgData.name)
            end
            self.m_suitDropDList:pushBackCustomItem(self.m_suitDDs[i])
        end
    end

    
    --下拉框选择部件
    self.m_pPartBtn = bagPanel:getChildByName("PositionBtn")
    self.m_partDropDChooseImg = self.m_pPartBtn:getChildByName("ChooseBg")
    self.m_partDropDNameLabel = self.m_pPartBtn:getChildByName("BtnName")
    self.m_partDropDNameLabel:setString(GUITips.RSI_PET_SUIT_TIPS11)
    self.m_partDropDOpenImg = self.m_pPartBtn:getChildByName("OpenImage")
    self.m_partDropDCloseImg = self.m_pPartBtn:getChildByName("CloseImage")
    self.m_partDropDCloseBtn = self.m_pPartBtn:getChildByName("CloseBtn")
    self.m_partDDPanel = self.m_pPartBtn:getChildByName("EquipPosition")--下拉框列表
    for i=1,AppDef.Pet.MaxEquipPosNum do 
        self["m_partDDChooseImg"..i] = self.m_partDDPanel:getChildByName("ChoosePosition_"..i)
        self["m_partDDChooseImg"..i].userObject = i
    end

    --分解按钮
    self.m_resolveBtn = resolvePanel:getChildByName("Btn")
    --帮助
    self.m_helpBtn = resolvePanel:getChildByName("Button_1")
    --金钱数值
    self.m_qnLabel = resolvePanel:getChildByName("QiannengBg"):getChildByName("Value")

    self.m_starStates = {}
    self.m_pGetItems = {}
    self.m_effectPlaying = false
end


function PetEquipResolveUI:ShowMoney()
    local myItemNum = LRoleDataMgr.MyHeroInfo:GetDetailData().xinXiuJingHua
    self.m_qnLabel:setString(myItemNum)
end

function PetEquipResolveUI:AddTouchEvt()  
    local function onResolve(sender)
        local function FuncResolve()
            self.m_uids = {}
            for k,v in pairs(self.m_selectIdx) do
                if v == 1 then
                    local data = self.m_pPackageList[k]
                    if data ~= nil and data.m_uid > 0 then
                        table.insert(self.m_uids,data.m_uid)
                    end
                end
            end
            if #self.m_uids > 0 then
                self:ShowEffect()                  
                local count = 1
                local ids = {}
                for i=1,#self.m_uids do       
                    ids[count] = self.m_uids[i]
                    if i%250 == 0 or #self.m_uids == i then
                        LuaNetSendMsg:SendPetEquipFenjieReq(ids)
                        ids = {}
                        --count = 0
                        break
                    end
                    count = count + 1
                end
                self.m_uids = {}
            end
        end

        local function onOk()
        end

        local b = false
        if self.m_selectIdx ~= nil and next(self.m_selectIdx) ~= nil then
            for k,v in pairs(self.m_selectIdx) do
                if v == 1 then
                    b = true
                    break
                end
            end
        end
        if not b then
            Utils:ShowDialogOKCancel(GUITips.RSI_RESOLVE_TIP_4,onOk)
            return
        end
        FuncResolve()                
    end
    self.m_resolveBtn:addClickEventListener(onResolve)

    local function callback(sender,eventType)
        local value = sender.userObject
        if self.m_effectPlaying then
            sender:setSelected(eventType == ccui.CheckBoxEventType.unselected)
            return
        end
        if eventType == ccui.CheckBoxEventType.selected then
            self:SelectStar(value,true)
        elseif eventType == ccui.CheckBoxEventType.unselected then
            self:SelectStar(value,false)           
        end
    end
    for i=1,AppDef.MAX_PET_EQUIP_STAR do
        self.m_checkBoxs[i]:addEventListener(callback)
    end

    local function onHelp(sender)
        local function OKCallback()
        end
        local str = GUITips.RSI_FENJIE_TIP6
        Utils:ShowDialogOKCancel(str,OKCallback)
    end
    self.m_helpBtn:addClickEventListener(onHelp)

    self.m_pSuitBtn:addClickEventListener(handler(self,PetEquipResolveUI.SuitBtnCallback))
    self.m_pPartBtn:addClickEventListener(handler(self,PetEquipResolveUI.PartBtnCallback))

    for i=1,#self.m_suitDDs do 
        self.m_suitDDs[i]:addClickEventListener(handler(self,PetEquipResolveUI.SuitSCallback))
    end

    for i=1,AppDef.Pet.MaxEquipPosNum do 
        self["m_partDDChooseImg"..i]:addClickEventListener(handler(self,PetEquipResolveUI.PartSCallback))
    end
end

function PetEquipResolveUI:LoadStar()
    if self.m_starStates == nil then return end
    for k,v in pairs(self.m_starStates) do
        if v == 1 then    
            self:LoadSelectInfo(k,true) 
        end      
    end
    self:LoadGetItem()
end

function PetEquipResolveUI:SuitSCallback(sender)
    local suitType = sender.userObject
    if suitType < 0 or suitType > AppDef.Pet.MaxSuitTypeNum then return end
    self.m_suitType = suitType
    self:SuitBtnCallback()
    local cfgData = LDataConstMgr:GetPetSuitCfgData(suitType)
    if cfgData ~= nil then
        self.m_suitDropDNameLabel:setString(cfgData.name)
    else
        self.m_suitDropDNameLabel:setString(GUITips.RSI_PET_SUIT_TIPS10)
    end
    self:UpdateBag()
    self:LoadStar()
end

function PetEquipResolveUI:PartSCallback(sender)
    local part = sender.userObject
    if part < 1 or part > AppDef.Pet.MaxEquipPosNum then return end

    if self.m_wpos == part then 
        self.m_wpos = 0
        self.m_partDropDNameLabel:setString(GUITips.RSI_PET_SUIT_TIPS11)
    else
        self.m_wpos = part
        self.m_partDropDNameLabel:setString(GUITips["Item_Info_PetEquipPos"..part])   
    end
    self:PartBtnCallback()
    self:UpdateBag()
    self:LoadStar()

    for i=1,AppDef.Pet.MaxEquipPosNum do
        local chooseImg = self["m_partDDChooseImg"..i]:getChildByName("ChooseBg")
        if chooseImg ~= nil then
            if i == self.m_wpos then
                chooseImg:setVisible(true)
            else
                chooseImg:setVisible(false)
            end
        end
    end
end

--套装下拉菜单显示
function PetEquipResolveUI:SuitBtnCallback(sender)
    if self.m_suitBtnSign == nil or not self.m_suitBtnSign then
        self.m_suitDropDList:setVisible(true)
        self.m_suitDropDOpenImg:setVisible(true)
        self.m_suitDropDCloseImg:setVisible(false)
        self.m_suitBtnSign = true
    else
        self.m_suitDropDList:setVisible(false)
        self.m_suitDropDOpenImg:setVisible(false)
        self.m_suitDropDCloseImg:setVisible(true)
        self.m_suitBtnSign = false
    end
end

--部位选择菜单显示
function PetEquipResolveUI:PartBtnCallback(sender)
    if self.m_partBtnSign == nil or not self.m_partBtnSign then
        self.m_partDDPanel:setVisible(true)
        self.m_partDropDOpenImg:setVisible(true)
        self.m_partDropDCloseImg:setVisible(false)
        self.m_partBtnSign = true
    else
        self.m_partDDPanel:setVisible(false)
        self.m_partDropDOpenImg:setVisible(false)
        self.m_partDropDCloseImg:setVisible(true)
        self.m_partBtnSign = false
    end
end

function PetEquipResolveUI:SelectStar(star,isSelected)
    if isSelected then 
        local sign = true
        for i=1,AppDef.MAX_PET_EQUIP_STAR do
           if self.m_starStates[i] == 1 then
               sign = false
               break
           end
        end
        if sign then
            self:ClearResolveInfo()
        end
        self.m_starStates[star] = 1      
        self:LoadSelectInfo(star,true)       
    else
        self.m_starStates[star] = 0
        self:LoadSelectInfo(star,false)
    end
    self:LoadGetItem()
end

function PetEquipResolveUI:SelectBagGrid(ind,isSelected)
    if self.m_selectIdx == nil then 
        self.m_selectIdx = {}
    end
    if isSelected then
        self.m_selectIdx[ind] = 1
    else
        self.m_selectIdx[ind]  = 0
    end
end



function PetEquipResolveUI:RefreshIconItem()

    if LRoleDataMgr.Pet.equipList == nil or LRoleDataMgr.Pet.equipList.m_petEquips == nil  then return end
    --背包中神将装备
    --self.m_indexTable = {}--key为m_pItemList索引，value为m_pPackageList索引
    local isAll = false
    if self.m_suitType == 0 and self.m_wpos == 0 then
        isAll = true
    end
    self.m_pPackageList = LRoleDataMgr:GetPetEquipBagInfo(self.m_suitType,self.m_wpos,isAll,true, false) 
    self.m_itemGridNum = 0--格子数量
    if self.m_pPackageList ~= nil then
        self.m_itemGridNum = #self.m_pPackageList
    end
    self.m_curGridNum = math.ceil(self.m_itemGridNum/5)
    if self.m_curGridNum < 5 then self.m_curGridNum = 5 end

    self:ShowBag()
    self.m_pRightTableView:reloadData()
end

function PetEquipResolveUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(rightView:getAnchorPoint())
    tableView:setPosition(rightView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    rightView:getParent():addChild(tableView)
    
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched",sender,cell,cell:getIdx())
        self:RightTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        --print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:RightTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return self.m_curGridNum
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    local function onTvTouchEnded(touch,event)
        local pos = touch:getLocation()
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    tableView:registerScriptHandler(onTvTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    --tableView:reloadData()
    self.m_pRightTableView = tableView
end

function PetEquipResolveUI:RightTableCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    --print("tableview touched " ..ind.." ") 
end 

--背包格点击
function PetEquipResolveUI:BagGridClicked(sender)
    if self.m_isDragging then return end

    local selectIcon = sender:getChildByName("SelectIcon")
    local state = not selectIcon:isVisible()
    
    local ind = sender:getTag()
    if ind > self.m_itemGridNum then
        return 
    end   
    
    self:BagGridSelect(ind,state)
    self:UpdateResolveInfo()  
    
    selectIcon:setVisible(state)
    if state then
        selectIcon:setLocalZOrder(9)
    end
end

--选中or取消
function PetEquipResolveUI:BagGridSelect(ind,state)
    local data = self.m_pPackageList[ind]     
    if data == nil then return end 
    self:SelectBagGrid(ind,state) 
end

function PetEquipResolveUI:BagGridTouched(sender, event)
    local ind = sender:getTag()
    if ind > self.m_itemGridNum or self.m_effectPlaying  then
        return 
    end

    if event == ccui.TouchEventType.began then
        sender:stopActionByTag(0xfe)
        local ac = performWithDelay(sender, function(sender)
            if self.m_startCheck == nil or self.m_startCheck == false then
                return
            end           
            local temp = self.m_pPackageList[ind]
            if temp == nil then
                return
            end
            local index = sender.userObject
            local pItem = self.m_pItemLists[index]
            if pItem then
                local itemValue = {}
                itemValue.itemData = temp
                itemValue.petId = 0
                LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetEquipTips, itemValue)
                self:SendMsg(LGameMsg.m_baseMsgWithOne)
            end
            self.m_startCheck = false
        end, 1)
        ac:setTag(0xfe)
        self.m_startCheck = true
        return
    end
    if self.m_startCheck then
        if event == ccui.TouchEventType.moved then
            local start = cc.p(sender:getTouchBeganPosition())
            local move = cc.p(sender:getTouchMovePosition())
            local dis = cc.pGetDistance(move, start)
            if dis > 10 then
                sender:stopActionByTag(0xfe)
                self.m_startCheck = false
            end
        elseif event == ccui.TouchEventType.ended then
            sender:stopActionByTag(0xfe)
            self.m_startCheck = false
            local point = cc.p(sender:getTouchEndPosition())
            point = sender:convertToNodeSpace(point)
            local rect = cc.rect(0, 0, sender:getContentSize().width, sender:getContentSize().height)
            if cc.rectContainsPoint(rect, point) then
                self:BagGridClicked(sender)
            end
        end
    end
    if event == ccui.TouchEventType.canceled then
        sender:stopActionByTag(0xfe)
        self.m_startCheck = false
    end
end

function PetEquipResolveUI:RightTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cell:addChild(cellChild)
        for i=1,5 do
            local bagGrid = cellChild:getChildByName("BagIcon"..i)
            bagGrid:setSwallowTouches(false)
            local index = idx*5+i
            bagGrid:setTag(index)
            local item = ItemCellUI:New(bagGrid)
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
            local ind = #self.m_pItemLists
            bagGrid.userObject = ind
            -- bagGrid:addClickEventListener(handler(self, PetEquipResolveUI.BagGridClicked))
            bagGrid:addTouchEventListener(handler(self, PetEquipResolveUI.BagGridTouched))
        end
    else
        cellChild = cell:getChildByTag(123)
        for i=1,5 do
            local bagGrid = cellChild:getChildByName("BagIcon"..i)
            local index = idx*5+i
            bagGrid:setTag(index)
        end
    end
    self:ShowRightCellInfo(cellChild, idx)
    return cell
end

function PetEquipResolveUI:ShowRightCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    --local min = idx * 5;
    for i = 1,  5 do
        local bagGrid = cellChild:getChildByName("BagIcon"..i)
        local index = bagGrid:getTag()
        local num = bagGrid.userObject
        local item = self.m_pItemLists[num]       
        self:UpdateBagCell(index,item)          
        self:ShowBagGridSelect(bagGrid)
    end
end

function PetEquipResolveUI:ShowSelectIcon(grid,idx)
    if grid == nil then 
        return
    end
    if self.m_selectIdx[idx] ~= nil and self.m_selectIdx[idx] == 1 then
        grid:setVisible(true)
        grid:setLocalZOrder(9)
    else
        grid:setVisible(false)
    end
end

function PetEquipResolveUI:ShowBagGridSelect(parent)
    if parent == nil then return end

    local grid = parent:getChildByName("SelectIcon")
    if grid == nil then return end
    self:ShowSelectIcon(grid,parent:getTag())
end

function PetEquipResolveUI:ClearChooseStar()
    if self.m_starStates == nil then return end
    for k,v in pairs(self.m_starStates) do
        if v == 1 then    
            self.m_starStates[k] = 0
            self.m_checkBoxs[k]:setSelected(false) 
        end      
    end
end

function PetEquipResolveUI:ClearResolveInfo()
    if self.m_pItemLists == nil then 
        self.m_pItemLists =  {}
    end
    for i=1,#self.m_pItemLists do
        local temp = self.m_pItemLists[i]
        if temp ~= nil then
            local selectIcon = temp.m_pUILayer:getParent():getChildByName("SelectIcon")
            selectIcon:setVisible(false)
        end
    end
    self.m_selectIdx = {}
    if self.m_getItems ~= nil then
        for k,v in ipairs(self.m_getItems) do
            v = 0
        end
    end
    local max = self.m_getListView:getChildrenCount()
    for i = 1,max do
        if self.m_pGetItems[i] ~= nil then
            self.m_pGetItems[i]:UpdateItem(nil)
            self.m_pGetItems[i].m_pUILayer:getParent():setVisible(false)
        end
    end
end

--刷新选中数据
function PetEquipResolveUI:LoadSelectInfo(star,isSelected)
    if self.m_pPackageList == nil or star < 1 then return end
    --修改选中信息
    for i=1,#self.m_pPackageList do
        local data = self.m_pPackageList[i]
        if data ~= nil and data.m_star == star then
            self:BagGridSelect(i,isSelected)
        end
    end
    --刷新界面
    for i=1,#self.m_pItemLists do
        local parent = self.m_pItemLists[i].m_pNode
        local ind = parent:getTag()
        local value = self.m_pPackageList[ind]
        if value ~= nil and value.m_star == star then
            self:ShowBagGridSelect(parent)
        end
    end
end

--[[
   合成部分数据更新
]]
function PetEquipResolveUI:UpdateResolveInfo()
    if self.m_selectIdx == nil or next(self.m_selectIdx) == nil then
        self:ClearResolveInfo()
        return
    end
    self:LoadGetItem()
end

--加载道具分解获得道具
function PetEquipResolveUI:UpdateGetItem()
    --强化、星级返回金钱
    local function getStoneMoney(stoneLv,star)
        local moneyVals = {}
        --基础金钱
        local starCfgData = LDataConstMgr:GetPetEquipStarCfgData(star)
        if starCfgData == nil then return moneyVals end
        moneyVals[starCfgData.reCycleMoneyType] = starCfgData.reCycleMoneyVal
		moneyVals[starCfgData.reCycleXinxiuType] = starCfgData.reCycleXinxiuVal
        for i=1,stoneLv do
            local cfgData = LDataConstMgr:GetPetEquipQHCfgData(i)
            if cfgData ~= nil then
               local moneyType = cfgData.costMoneyType
               local moneyVal = math.floor(math.floor(cfgData.costMoneyVal*starCfgData.costRatio/10000)*cfgData.fenJieRatio/10000)
               if moneyVals[moneyType] == nil then moneyVals[moneyType] = 0 end
               moneyVals[moneyType] = moneyVals[moneyType] + moneyVal
			   local xinxiuType = cfgData.costStarType
			   local xinxiuVal = math.floor(math.floor(cfgData.costStarVal*starCfgData.costRatio/10000)*cfgData.fenJieRatio/10000)
			   if moneyVals[xinxiuType] == nil then moneyVals[xinxiuType] = 0 end
               moneyVals[xinxiuType] = moneyVals[xinxiuType] + xinxiuVal
            end
        end
        return moneyVals
    end

    self.m_getItems = {}
    for k,v in pairs(self.m_selectIdx) do
        local itemInfo = self.m_pPackageList[k]
        if self.m_selectIdx[k] == 1 and itemInfo ~= nil and itemInfo.m_uid > 0 then            
            local mValues =  getStoneMoney(itemInfo.m_stoneLevel,itemInfo.m_star)
            if mValues ~= nil and next(mValues) ~= nil then
                for key,val in pairs(mValues) do
                    if self.m_getItems[key] == nil then
                        self.m_getItems[key] = 0
                    end
                    local cur = self.m_getItems[key]
                    self.m_getItems[key] = cur + val 
                end
            end                           
        end
    end
    local count = 1
    for k,v in pairs(self.m_getItems) do    
        if v > 0  then  
            local item = nil
            if self.m_pGetItems[count] == nil then
                item = self.m_getItemCell:clone()
                self.m_getListView:pushBackCustomItem(item)
            else
                item = self.m_pGetItems[count].m_pNode
                item:setVisible(true)
            end
            self.m_pGetItems[count] = Utils:GetItemCellValue(item, 0, k, true, true, v, self.m_pGetItems[count], false, true)
            count = count +1
        end
    end
    local max = self.m_getListView:getChildrenCount()
    for i = count,max do
        if self.m_pGetItems[i] ~= nil then
            self.m_pGetItems[i]:UpdateItem(nil)
            self.m_pGetItems[i].m_pNode:setVisible(false)
        end
    end
end

function PetEquipResolveUI:LoadGetItem()  
    self:UpdateGetItem()
end



function PetEquipResolveUI:ADAndRefreshPage()
    local offset = self.m_pRightTableView:getContentOffset()

    self:ShowMoney()
    self:ClearChooseStar()
    self:UpdateBag()       
    
    local min = self.m_pRightTableView:minContainerOffset().y
    local max = self.m_pRightTableView:maxContainerOffset().y
    local cellHeight = self.m_pGridCell:getContentSize().height
    offset.y = math.max(math.min(offset.y--[[+cellHeight]], max), min)
    self.m_pRightTableView:setContentOffset(offset)
end

return PetEquipResolveUI