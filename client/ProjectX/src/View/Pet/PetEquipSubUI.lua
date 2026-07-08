--[[
lua里面的游戏逻辑控制
]]

local PetUIDef = require "View.Pet.PetUIDef"

local function Debug(log)
    
end
local PetEquipSubUI = LUIBase:New()
PetEquipSubUI.__index = PetEquipSubUI

function PetEquipSubUI:New(petData)
	local o = LUIBase:New()
	setmetatable(o,PetEquipSubUI)	
    o:Init(petData)
	return o
end


function PetEquipSubUI:Init(petData)
    self:RegistMsgs()
    self:InitMemberVariable()
    self:InitViewSize()
    self:InitUICtr()
    self:InitEvt()
    self:SetPetData(petData)
    self:SetCurLeftTab(1)
    self:SetCurRightTab(1,true)

    local bagInfo = LRoleDataMgr.Pet.equipList
    if bagInfo == nil or bagInfo.m_petEquips == nil or  next(bagInfo.m_petEquips) == nil or bagInfo.m_maxGridNum == 0 then
        LuaNetSendMsg:QueryPetEquip(1)
    elseif self.m_pPetBaseData ~= nil then
        self:RefreshBag()
    end
end

function PetEquipSubUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.SelectedPet,
        LUIPetEvent.GotPetEquip,
        LUIPetEvent.PetEquipChanged,
        LUIPetEvent.PetBagEquipChanged,
        LUIPetEvent.ChangePetLv,
        LUIPetEvent.ChangePetPower,
        LUIPetEvent.PetEquipAdd,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function PetEquipSubUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.SelectedPet then
        self.m_resetSuit = true
        self:SetPetData(msg.value)
        self:SetCurLeftTab(1,true)
        if self.m_curRightTab == 1 then
            self:SetCurRightTab(1,true)
            self:RefreshBag()
        end
    elseif msg.msgId == LUIPetEvent.GotPetEquip then
        self.m_resetSuit = true
        self:SetCurRightTab(self.m_curRightTab,true)
        self:RefreshBag()
    elseif msg.msgId == LUIPetEvent.PetEquipChanged then
        local data = msg.value
        if data ~= nil and data.id ~= nil and data.id == self.m_pPetId then
            local suit = Utils:deepCopy(self.m_pCurSuitInfo)
            self:SetPetData(msg.value)
            self:SetCurLeftTab(self.m_curLeftTab,true)
            self:ShowSuitEffect(suit)
            --self:GetSuitNum()
        end
    elseif msg.msgId == LUIPetEvent.PetBagEquipChanged then
        self:UpdataEquipData(msg.value1,msg.value2)
    elseif msg.msgId == LUIPetEvent.ChangePetLv then
        local value = msg.value
        if value ~= nil and value.pid ~= nil and value.pid == self.m_pPetId then
            self.m_petLv = value.lv
            self:ShowEquipOpenLv()
        end
    elseif msg.msgId == LUIPetEvent.ChangePetPower then
        local value = msg.value
        if value ~= nil and value.pid ~= nil and value.pid == self.m_pPetId then
            self.m_powerVal = value.power
            self:ShowPower()
        end
    elseif msg.msgId == LUIPetEvent.PetEquipAdd then
        local value = msg.value
        if value > 0 and self.suitCells ~= nil then
            local suitCell = self.suitCells[value]
            if suitCell ~= nil then
                local redDotImg = suitCell:getChildByName("RedDot")--红点
                if redDotImg ~= nil then
                    redDotImg:setVisible(false)
                end
            end
        end
    end
end


function PetEquipSubUI:SetPetData(petData)
    if petData == nil or petData.id == nil then return end
    self.m_pPetId = petData.id
    self.m_petLv = petData.level
    self.m_powerVal = petData.zhandouli
    self.m_pCurEquips = petData.petEquips --已装备列表
    self.m_pCurSuitInfo = petData.petSuits --当前套装信息
    self.m_pEquipAttrs = petData.equipAttrs 
    self.m_pPetBaseData = LPetDataMgr:FindPetDataById(petData.id)
    --self.m_pSignSuitId = 2--临时
    self:ShowPetInfo()
    --self:GetSuitNum()
end

function PetEquipSubUI:ShowPetInfo()
    if self.m_pPetId == nil or self.m_pPetId < 1 then
        return
    end
    --self:UnLoadAllIcon()
    self:ShowPetModel()
    self:ShowPower()
    self:ShowPetEquipList()
    self:ShowEquipOpenLv()
end

function PetEquipSubUI:InitViewSize()
    self:CreateUINode("csd/shenjiangEquipLayer.csb")
end

function PetEquipSubUI:onExit()
    --节点放在主节点上删除
    --self.m_pUILayer = nil
    self:UnLoadAllIcon()
    self.m_pPetId = nil--当前选中的宠物数据   
    self.m_pPetBaseData = nil 
    self.m_EquipCells = nil   
    self.m_pPartBtn = nil
    self.m_curRightTab = nil
    self.m_curLeftTab = nil
    self.m_chooseSuitId = nil
    self.m_chooseEquipPart = nil
    self.m_msg = nil
   
    self.m_pPartNumLabel = nil
    self.m_rSuitText = nil
    for i=1,#self.m_pItemLists do
       self.m_pItemLists[i]:onExit(true)
    end
    self.m_pItemLists = nil
    self.m_equipTableView:removeAllChildren()
    self.m_equipTableView = nil

    if self.m_redDotSign ~= nil and self.m_redDotSign then
        LPetDataMgr:DelPetEquipRedDot()
		LPetDataMgr:DelAllPetEquipRedDot()
        LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.PetEquipAdd,0)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    self:Destory()
end

--[[
初始化成员变量
]]
function PetEquipSubUI:InitMemberVariable()
    if self.m_EquipCells == nil then
        self.m_EquipCells = {}
    end 
    if self.m_pPartBtn == nil then
        self.m_pPartBtn = {}
    end
    if self.m_pPartNumLabel == nil then
        self.m_pPartNumLabel = {}
    end
    self.m_pItemLists = {}
    self.m_rSuitText = {}
    self.m_curGridNum = 0
    self.m_resetSuit = false
end

function PetEquipSubUI:InitUICtr()
    local node = self.m_pUILayer:getChildByName("EquipUI"):getChildByName("Bg")
    self.m_modelPanel = node:getChildByName("bg")

    self.m_pPetNode = self.m_modelPanel:getChildByName("Image"):getChildByName("BaseImage"):getChildByName("Node")
    self.m_pPetModelNode = self.m_pPetNode:getChildByTag(1)
    if self.m_pPetModelNode == nil then
        --UI有可能是从Res缓存里面读取的，这个时候ModelNode已经在上一次加载过了
        self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
        self.m_pPetNode:addChild(self.m_pPetModelNode)
        self.m_pPetModelNode:setTag(1)
    end
    self.m_pPowerLabel = self.m_modelPanel:getChildByName("bg_zhanli"):getChildByName("Value")
    for i=1,AppDef.Pet.MaxEquipPosNum do
        if self.m_EquipCells[i] == nil then
            local parent = self.m_modelPanel:getChildByName("EquipIcon"..i)
            self["m_openLabel"..i] = parent:getChildByName("Text")
			self["m_addIcon"..i] = parent:getChildByName("AddIcon")
            parent.userObject = i
            self.m_EquipCells[i] = ItemCellUI:New(parent,itemValue)
        end 
    end

    local attrPanel = self.m_modelPanel:getChildByName("Image_bg")
    self.m_pSuitBtn = attrPanel:getChildByName("Btn_1")  --装备套装
    self.m_pLSuitChooseImg = self.m_pSuitBtn:getChildByName("Choose")
    self.m_pLSuitLabel1 = self.m_pSuitBtn:getChildByName("Text_1")
    self.m_pLSuitLabel2 = self.m_pSuitBtn:getChildByName("Text_2")
    
    self.m_pSuitBtn:setTouchEnabled(true)
    self.m_pAttrBtn = attrPanel:getChildByName("Btn_2")  --装备属性
    self.m_pLAttrChooseImg = self.m_pAttrBtn:getChildByName("Choose")
    self.m_pLAttrLabel1 = self.m_pAttrBtn:getChildByName("Text_1")
    self.m_pLAttrLabel2 = self.m_pAttrBtn:getChildByName("Text_2")

    self.m_pFenjieBtn = attrPanel:getChildByName("Btn_3")
    self.m_pAttrBtn:setTouchEnabled(true)
    self.m_pTps1 = attrPanel:getChildByName("Tips_1")
    self.m_pTps2 = attrPanel:getChildByName("Tips_2")
    self.m_pAttrListView = attrPanel:getChildByName("ListView") --属性ListView
    self.m_pAttrCell = attrPanel:getChildByName("Attribute_1")--属性行
    self.m_pAttrCell:setVisible(false)
    self.m_pDescCell= attrPanel:getChildByName("Attr_Desc_1")--套装单个描述
    self.m_pDescCell:setVisible(false)

    local infoPanel = node:getChildByName("Equip")
    self.m_pSuitCheckBox  = infoPanel:getChildByName("CheckBox_1")  --套装切页
    self.m_pSuitCheckBox:setTouchEnabled(false)
    self.m_pRSuitTitle1 = self.m_pSuitCheckBox:getChildByName("Text")
    self.m_pRSuitTitle2 = self.m_pSuitCheckBox:getChildByName("Text_choose")
    self.m_pPartCheckBox  = infoPanel:getChildByName("CheckBox_2")  --部件切页
    self.m_pRPartTitle1 = self.m_pPartCheckBox:getChildByName("Text")
    self.m_pRPartTitle2 = self.m_pPartCheckBox:getChildByName("Text_choose")
    
    self.m_pPartPanel = infoPanel:getChildByName("EquipType") --部件内容
    self.m_pPartPanel:setVisible(false)
    for i=1,AppDef.Pet.MaxEquipPosNum do
        self.m_pPartBtn[i] = self.m_pPartPanel:getChildByName("Btn_"..i)
        self.m_pPartBtn[i].userObject = i
        self.m_pPartNumLabel[i] = self.m_pPartBtn[i]:getChildByName("Name"):getChildByName("Value")
    end
    self.m_pSuitListView = infoPanel:getChildByName("ListView") --套装Icon ListView
    --self.m_pSuitCell = infoPanel:getChildByName("Type_1")--套装Icon
    --self.m_pSuitCell:setVisible(false)
    
    self.m_descListView = node:getChildByName("DescList")
    self.m_pSuitDescTitleLabel1 = self.m_descListView:getChildByName("Desc_1")
    self.m_pSuitDescTitleLabel2 = self.m_descListView:getChildByName("Desc_2")   
    self.m_pSuitDescLabel1 = self.m_pSuitDescTitleLabel1:getChildByName("Text")
    self.m_pSuitDescLabel2 = self.m_pSuitDescTitleLabel2:getChildByName("Text")

    local gridPanel = node:getChildByName("EquipHave")
    if self.m_pGridListView == nil then
        self.m_pGridListView = gridPanel:getChildByName("ListView")
        self.m_pGridListView:setVisible(false)
        self.m_pGridListView:setTouchEnabled(false)
    end
    self.m_pGridCell = node:getChildByName("ItemList")
    self.m_pGridCell:setVisible(false)
    self.m_cellSize = self.m_pGridCell:getContentSize()--子元素尺寸
    if self.m_equipTableView == nil then
        self.m_equipTableView = self:InitTableView()
    end

    self.m_gridNum = gridPanel:getChildByName("ValueBg"):getChildByName("Text")
    self:InitRightSuitIconList()
    --Utils:DelayToCallFunc(self.m_pSuitListView, 0.01, handler(self,self.InitRightSuitIconList))

    local xinxiuPanel = node:getChildByName("GoldIcon4")
    self._XinXiuValue = xinxiuPanel:getChildByName("GoldNumBg"):getChildByName("Num")

    local addXinXiu = xinxiuPanel:getChildByName("AddBtn")
    local function addXinXiuEvent( sender )
        -- body
        if LUILogic:GetUIInBufferInd("Role.RoleMainUI") ~= 0 then
            LGameMsg.m_baseMsgWithOne:Change(LUIBagEvent.SelectTab, 5)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)     
            self:CloseUI()     
            return
        end
        self:CloseUI()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI,"Role.RoleMainUI" , AppDef.UIType.FirstClassLayer, 5)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    addXinXiu:addClickEventListener(addXinXiuEvent)

end

function PetEquipSubUI:InitEvt()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)


    local function SuitClicked(sender)
        self:SetCurLeftTab(1)
    end
    self.m_pSuitBtn:addClickEventListener(SuitClicked)
	self:MarkIntaractCObj(self.m_pSuitBtn)
    local function AttrClicked(sender)
        self:SetCurLeftTab(2)
    end
    self.m_pAttrBtn:addClickEventListener(AttrClicked)
	self:MarkIntaractCObj(self.m_pAttrBtn)
    local function suitChecked(sender,evnetType)
        self:SetCurRightTab(1)
        self:RefreshBag()
    end
    self.m_pSuitCheckBox:addEventListener(suitChecked)

    local function partChecked(sender,evnetType)
        self:SetCurRightTab(2)
        self:RefreshBag()
    end
    self.m_pPartCheckBox:addEventListener(partChecked)

    local function partCallBack(sender)
        self:ChooseEquipPart(sender.userObject)
        self:RefreshBag()
    end
    for i=1,AppDef.Pet.MaxEquipPosNum do
        self.m_pPartBtn[i]:addClickEventListener(partCallBack)    
		self:MarkIntaractCObj(self.m_pPartBtn[i])
    end

    local function equipCallBack(sender)
        local pos = sender.userObject
        local curData = self.m_pCurEquips[pos]
        if curData == nil then
            self:GetEquip(pos)
            return 
        end
        local itemValue = {}
        itemValue.itemData = curData
        itemValue.petId = self.m_pPetId
        itemValue.pos = pos
        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetEquipTips, itemValue)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
    for i=1,AppDef.Pet.MaxEquipPosNum do
        self.m_EquipCells[i].m_pNode:addClickEventListener(equipCallBack)
		self:MarkIntaractCObj(self.m_EquipCells[i].m_pNode)
    end

    local function fenjieCallBack(sender)
        if LUILogic:GetUIInBufferInd("Role.RoleMainUI") ~= 0 then
            LGameMsg.m_baseMsgWithOne:Change(LUIBagEvent.SelectTab, 5)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)     
            self:CloseUI()     
            return
        end
        self:CloseUI()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI,"Role.RoleMainUI" , AppDef.UIType.FirstClassLayer, 5)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pFenjieBtn:addClickEventListener(fenjieCallBack)   
	self:MarkIntaractCObj(self.m_pFenjieBtn) 
end

function PetEquipSubUI:ChooseEquipPart(pos)
    if pos == nil or pos < 1 or pos == self.m_chooseEquipPart or pos > AppDef.Pet.MaxEquipPosNum then
        return
    end
    self.m_chooseEquipPart = pos
    for i=1,AppDef.Pet.MaxEquipPosNum do
        local chooseImg = self.m_pPartBtn[i]:getChildByName("Choose")
        if i == pos then
            chooseImg:setVisible(true)
        else
            chooseImg:setVisible(false)
        end
    end
end

function PetEquipSubUI:ChooseSuitIcon(id)
    if id == nil or id < 1 or id == self.m_chooseSuitId then
        return
    end
    self.m_chooseSuitId = id
    local items = self.m_pSuitListView:getItems()
    if items == nil or #items == 0 then return end
    for k,v in pairs(items) do
        for i= 1,2 do
            local item = v:getChildByName("Equip_"..i)
            local chooseImg = item:getChildByName("Choose")
            local ind = (k-1)*2+i
            if ind == id then
                chooseImg:setVisible(true)
            else
                chooseImg:setVisible(false)
            end
        end
    end
    self:ShowRightSuitDesc(self.m_chooseSuitId)
end

function PetEquipSubUI:SetCurRightTab(ind,isForce)
    local force = isForce or false
    if ind == nil or (ind == self.m_curRightTab and not force) then
        return
    end
    self.m_curRightTab = ind
    if self.m_curRightTab == 1 then
        self:ShowRightSuitPanel(isForce)
        self.m_pSuitCheckBox:setSelected(true)
        self.m_pPartCheckBox:setSelected(false)
        self.m_pRSuitTitle1:setVisible(true)
        self.m_pRSuitTitle2:setVisible(false)
        self.m_pRPartTitle1:setVisible(false)
        self.m_pRPartTitle2:setVisible(true)
        self.m_pSuitCheckBox:setTouchEnabled(false)
        self.m_pPartCheckBox:setTouchEnabled(true)
        self.m_descListView:setTouchEnabled(true)
    else
        self:ShowRightPartPanel()
        self.m_pSuitCheckBox:setSelected(false)
        self.m_pPartCheckBox:setSelected(true)
        self.m_pRSuitTitle1:setVisible(false)
        self.m_pRSuitTitle2:setVisible(true)
        self.m_pRPartTitle1:setVisible(true)
        self.m_pRPartTitle2:setVisible(false)
        self.m_pSuitCheckBox:setTouchEnabled(true)
        self.m_pPartCheckBox:setTouchEnabled(false)
        self.m_descListView:setTouchEnabled(false)
    end
end

function PetEquipSubUI:SetCurLeftTab(ind,isForce)
    local force = isForce or false
    if ind == nil or (ind == self.m_curLeftTab and not force) then
        return
    end
    self.m_curLeftTab = ind
    if self.m_curLeftTab == 1 then
        self.m_pLSuitChooseImg:setVisible(true)
        self.m_pLSuitLabel1:setVisible(false)
        self.m_pLSuitLabel2:setVisible(true)
        self.m_pLAttrChooseImg:setVisible(false)
        self.m_pLAttrLabel1:setVisible(true)
        self.m_pLAttrLabel2:setVisible(false)
        self:ShowSuitInfo()
    else
        self.m_pLSuitChooseImg:setVisible(false)
        self.m_pLSuitLabel1:setVisible(true)
        self.m_pLSuitLabel2:setVisible(false)
        self.m_pLAttrChooseImg:setVisible(true)
        self.m_pLAttrLabel1:setVisible(false)
        self.m_pLAttrLabel2:setVisible(true)
        self:ShowAttrInfo()
    end
end



function PetEquipSubUI:RefreshIconItem()
--    self.m_indexTable = {}--key为m_pItemList索引,value为背包索引
--    local info = LRoleDataMgr.Equip.PackageList
--    local max = #info
--    self.m_pPackageList = info
--    for i = 1, max do
--        if info[i].m_id ~= 0 then
--            table.insert (self.m_pPackageList,info[i].m_pos)
--        end
--    end     
    self.m_curGridNum = 0                                                                                                                                                                                                                                                                                                              
    if self.m_equipBagData ~= nil then
        self.m_curGridNum = math.ceil(#self.m_equipBagData/4)
    end
    if self.m_curGridNum < 2 then self.m_curGridNum = 2 end
    self.m_equipTableView:reloadData()
end

function PetEquipSubUI:InitTableView()

    local parent = self.m_pGridListView:getParent()
    local tableView = parent:getChildByTag(999)
    if tableView ~= nil then
        tableView:removeFromParent()
    end
    local size = self.m_pGridListView:getContentSize()
    tableView = cc.TableView:create(size)
    local x,y = self.m_pGridListView:getPosition()
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setAnchorPoint(cc.p(0,0))
    tableView:setPosition(cc.p(x-size.width/2,y))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder( cc.TABLEVIEW_FILL_TOPDOWN)
    tableView:setTag(999)
    self.m_pGridListView:getParent():addChild(tableView)

    local function cellSizeForTable(sender,idx)
        return self.m_cellSize.width, self.m_cellSize.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return self.m_curGridNum
    end

    local function scrollViewDidScroll(view)
        self.m_isDragging = view:isDragging()
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)--此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)--此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)--此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)

    return tableView
end

function PetEquipSubUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cell:setTag(idx)
        local posX =  0-math.ceil(self.m_pGridCell:getContentSize().width/2)
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))  
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setTouchEnabled(false)
        cellChild:setVisible(true)
        cell:addChild(cellChild)

        for i=1,4 do
            local bagGrid = cellChild:getChildByName("ItemBg_"..i)
            bagGrid:setSwallowTouches(false)
			bagGrid:getChildByName("RedDot"):setVisible(false)
            local index = idx*4+i
            bagGrid:setTag(index)
            itemValue = {}
            itemValue.isChangeSize = true
            local item = ItemCellUI:New(bagGrid,itemValue)
            item:SetIsNonAutoFree(true)
            table.insert(self.m_pItemLists, item)
	        bagGrid.userObject = #self.m_pItemLists
            bagGrid:addClickEventListener(handler(self,PetEquipSubUI.EquipGridTouched))
			self:MarkIntaractCObj(bagGrid) 
        end
    else
        cellChild = cell:getChildByTag(123)
        for i=1,4 do
            local bagGrid = cellChild:getChildByName("ItemBg_"..i)
            local index = idx*4+i
            bagGrid:setTag(index)
        end
    end
    self:ShowTableCellInfo(cellChild, idx)
    return cell
end

function PetEquipSubUI:ShowTableCellInfo(cellChild, idx)
--    if self.m_equipBagData == nil or #self.m_equipBagData == 0 then 
--        return
--    end
    for i=1,4 do
        local bagGrid = cellChild:getChildByName("ItemBg_"..i)
		local reddot = bagGrid:getChildByName("RedDot");
		reddot:setVisible(false)
        local ind = bagGrid.userObject
        local index = idx*4+i
        
        local itemValue = {}
        if self.m_equipBagData == nil or index > #self.m_equipBagData then
            itemValue = nil
        else
            local data = self.m_equipBagData[index]
            if data.m_uid == 0 then
                itemValue = nil
            else
                local resFile = string.format("item/%s.png", data.m_pic)
                local userDefine ={picFilePath = resFile,quality = data.m_quality, star = data.m_star, strengthenLv = data.m_stoneLevel, locked = data.m_locked, suitId = data.m_suitType}
                itemValue.userDefine = userDefine
				--判断红点
				--根据套装type获取是否是新的装备
				if LPetDataMgr:IsPetEquipRedDotById(data.m_uid) == true then
					reddot:setVisible(true)
					reddot:setLocalZOrder(1)
				end
            end
        end               
        self.m_pItemLists[ind]:UpdateItem(itemValue)
    end
end

--装备背包点击
function PetEquipSubUI:EquipGridTouched(sender)
    if self.m_isDragging  or self.m_equipBagData == nil then
        return
    end
    local index = sender:getTag()
    local curData = self.m_equipBagData[index]
    if curData == nil then return end
    local itemValue = {}
    itemValue.itemData = curData
    itemValue.petId = self.m_pPetId
    itemValue.showCorrTips = true
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetEquipTips, itemValue)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
	--消除红点
	LPetDataMgr:DelPetEquipRedDotById(curData.m_uid)
	local reddot = sender:getChildByName("RedDot"):setVisible(false)
end

function PetEquipSubUI:ShowRightSuitPanel(isForce)
    self.m_pPartPanel:setVisible(false)
    self.m_pSuitListView:setVisible(true)
    if (self.m_resetSuit or self.m_chooseSuitId == nil) then
        local suitId = self:GetSelectSuit()
        self:ChooseSuitIcon(suitId)
        self.m_resetSuit = false
    end
    self:ShowRightSuitDesc(self.m_chooseSuitId)
    self:LoadRightSuitIconList(isForce)
end

function PetEquipSubUI:ShowRightPartPanel()
    self.m_pPartPanel:setVisible(true)
    self.m_pSuitListView:setVisible(false)
    self:ShowRightSuitDesc()
    self:ShowRightEquipPartInfo()
end

function PetEquipSubUI:ShowRightEquipPartInfo()
   if self.m_chooseEquipPart == nil then
        self:ChooseEquipPart(1)
   end
   local bagInfo = LRoleDataMgr.Pet.equipList
   for i=1,AppDef.Pet.MaxEquipPosNum do
        --self.m_pPartBtn[i] = self.m_pPartPanel:getChildByName("Btn_"..i)
        local num = 0
        if bagInfo ~= nil and bagInfo.m_partNums ~= nil then
            num = bagInfo.m_partNums[i] or 0
        end
        self.m_pPartNumLabel[i]:setString(""..num)
        local numColor = AppDef.UIColor.RED
        if num > 0 then
            numColor = AppDef.UIColor.GREEN
        end
        self.m_pPartNumLabel[i]:setTextColor(numColor)
   end
end

function PetEquipSubUI:ShowRightSuitDesc(suitId)
    if suitId == nil or suitId < 1 then
        self.m_pSuitDescTitleLabel1:setString("")
        self.m_pSuitDescTitleLabel2:setString("")
        self.m_pSuitDescLabel1:setString("")
        self.m_pSuitDescLabel2:setString("")
    else
        local suitCfgData = LDataConstMgr:GetPetSuitCfgData(suitId)
        for i=1,suitCfgData.maxAttrNum do
            if suitCfgData ~= nil then
                local suitStr = LDataConstMgr:GetHeroSkillDesc(suitCfgData.skillId[i], suitCfgData.skillLv[i])  
                --print("ShowRightSuitDesc",suitId,suitStr)         
                self["m_pSuitDescLabel"..i]:setString(Utils:DeleteString(suitStr,"%[","%]"))
            end
            local descTitle = string.format(GUITips.RSI_PET_SUIT_TIPS3,suitCfgData.name,suitCfgData.suitNum[i])
            self["m_pSuitDescTitleLabel"..i]:setString(descTitle)
        end
    end
end

function PetEquipSubUI:ShowBagGridNum()
    local bagInfo = LRoleDataMgr.Pet.equipList
    local num = 0 
    if bagInfo ~= nil then
        num = LRoleDataMgr.Pet.equipList.m_curGridNum
    end
    if num == nil or num < 0 then 
        num = 0
    end
    self.m_gridNum:setString(""..num.."/"..AppDef.Pet.MaxSuitEquipBagNum)
end

--初始化所有套装类型图标
function PetEquipSubUI:InitRightSuitIconList()
    if self.m_pSuitListView == nil then return end
    local num = math.ceil(AppDef.Pet.MaxSuitTypeNum/2)
    if self.suitCells == nil then self.suitCells = {} end
    for i=1,num do
        local suit = self.m_pSuitListView:getChildByName("Type_"..i)
        if suit ~= nil then
            suit:setTag(i)
            --suit:setVisible(true)       
            for k=1,2 do
                local suitType = (i-1)*2+k
                local suitCell = suit:getChildByName("Equip_"..k)
                suitCell.userObject = suitType
                self.suitCells[suitType] = suitCell
                self:ShowSuitIcon(suitCell,true)
            end        
        end
    end
end

--加载所有套装类型图标
function PetEquipSubUI:LoadRightSuitIconList(isForce)
    if self.m_pSuitListView == nil or self.m_pPetBaseData == nil then return end
    local force = isForce or false
    if not force then return end
    for i=1,AppDef.Pet.MaxSuitTypeNum do
        self:ShowSuitIcon(self.suitCells[i],false)
    end
   
--    if force then
--        local value = self.m_chooseSuitId
--        if AppDef.Pet.MaxSuitTypeNum - value < 4 then
--            value = AppDef.Pet.MaxSuitTypeNum - 4
--        end
--        local ind = math.ceil(value/2)-1
--        if ind < 0 then ind = 0 end
--        self.m_pSuitListView:jumpToItem(ind,cc.p(0,0),cc.p(0,0))
--    end
end

--显示单个套装图标
function PetEquipSubUI:ShowSuitIcon(sender,init)
    if sender == nil then return end
    local suitType = sender.userObject
    if suitType > AppDef.Pet.MaxSuitTypeNum then 
        sender:setVisible(false)
        return
    end
    if self.m_suitImg == nil then self.m_suitImg = {} end
    if init and self.m_suitImg[suitType] == nil then    
        self.m_suitImg[suitType] = sender:getChildByName("Icon") --图标
        self.m_suitImg[suitType].userObject = suitType
        local resFile = string.format("res2/Icon/ui_pet_icon/ui_tuteng_dongwu_%d.png", suitType)
        self.m_suitImg[suitType]:setVisible(false)
        Utils:AsyncLoadImg(self.m_suitImg[suitType], resFile, function(pTexture)
            self.m_suitImg[suitType]:setVisible(true)
            self.m_suitImg[suitType]:loadTexture(resFile, ccui.TextureResType.localType)
          end)
        sender:setTouchEnabled(true)
        sender:setSwallowTouches(false)
        return
    end

    local chooseImg = sender:getChildByName("Choose") --选中框
    local signImg = sender:getChildByName("Recommend") --推荐标记
    local nameLabel = sender:getChildByName("Name") --名称
    local numLabel = nameLabel:getChildByName("Value") --数量
    local redDotImg = sender:getChildByName("RedDot")--红点

    local numColor = AppDef.UIColor.RED
    local suitNum = 0
    local bagInfo = LRoleDataMgr.Pet.equipList
    if bagInfo ~= nil and bagInfo.m_petSuitNums ~= nil and #bagInfo.m_petSuitNums > 0 then
        suitNum = bagInfo.m_petSuitNums[suitType]       
    end
    if suitNum > 0 then
        numColor = AppDef.UIColor.BLUE
    else
        LPetDataMgr:DelPetSuitRedDot(suitType)
    end

    local suitcfgData =LDataConstMgr:GetPetSuitCfgData(suitType)
    if suitcfgData ~= nil then
        nameLabel:setString(suitcfgData.name)
    end
    numLabel:setString(""..suitNum)
    --numLabel:setTextColor(numColor)
    numLabel:enableOutline(numColor)

    signImg:setVisible(false)   
    if self.m_pPetBaseData ~= nil then
        for i=1,#self.m_pPetBaseData.tuijianSuit do
            if suitType ==  self.m_pPetBaseData.tuijianSuit[i] then
                signImg:setVisible(true)
                break
            end
        end
    end
    if self.m_chooseSuitId == nil or self.m_chooseSuitId < 1 or suitType ~= self.m_chooseSuitId then
        chooseImg:setVisible(false)
    else
        chooseImg:setVisible(true)
    end

    
    local suits = LPetDataMgr:GetPetEquipRedDot()
    if suits ~= nil and suits[suitType] ~= nil and suits[suitType] == 1 and suitNum > 0 then
        redDotImg:setVisible(true)
        self.m_redDotSign = true
    end

    local function suitIconCallBack(sender1)
        self:ChooseSuitIcon(sender1.userObject)
        self:RefreshBag()
    end
    sender:addClickEventListener(suitIconCallBack)
	self:MarkIntaractCObj(sender) 
end

--加载宠物装备(背包)
function PetEquipSubUI:LoadPetEquipBag()
    if self.m_curRightTab == nil  then return end
    if self.m_equipTableView == nil then
         self.m_equipTableView = self:InitTableView()
    end
    self:RefreshIconItem()
    self:ShowBagGridNum()
end

--[[
显示属性信息
]]
function PetEquipSubUI:ShowAttrInfo()
    self.m_pAttrListView:setVisible(true)
    self.m_pAttrListView:removeAllItems()
    self.m_pTps1:setVisible(false)
    self.m_pTps2:setVisible(false)
    if self.m_pEquipAttrs == nil or next(self.m_pEquipAttrs) == nil then
        if self.m_pLEquipNullDesc == nil then
            self.m_pLEquipNullDesc = self.m_pTps1:clone()
            self.m_pLEquipNullDesc:setVisible(true)
            --self.m_pLEquipNullDesc:getChildByName("Text"):setString("")
            self.m_pTps1:getParent():addChild(self.m_pLEquipNullDesc)
            self.m_pLEquipNullDesc:setPosition(self.m_pTps1:getPosition())
            self.m_pLEquipNullDesc:setAnchorPoint(self.m_pTps1:getAnchorPoint())
        end
        self.m_pLEquipNullDesc:setString(GUITips.RSI_PET_SUIT_TIPS6)        
        --self.m_pLEquipNullDesc:setFontSize(18)
        local size = self.m_pLEquipNullDesc:getAutoRenderSize()
        self.m_pLEquipNullDesc:setTextAreaSize(size)
        return
    end
    if self.m_pLEquipNullDesc ~= nil then
        self.m_pLEquipNullDesc:setString("")
    end
    local num = 0
    local attrTypes = {}
    local attrValues = {}
    for k,v in pairs(self.m_pEquipAttrs) do
        num = num +1
        table.insert(attrTypes,k)
        table.insert(attrValues,v)
    end
    num = math.ceil(num/2)
    for i=1,num do
        local attr = self.m_pAttrCell:clone()
        attr:setVisible(true)
        for k=1,2 do
            local attrSingle = attr:getChildByName("Name_"..k)
            local idx = (i-1)*2+k
            self:ShowEquipAttr(attrSingle,attrTypes[idx],attrValues[idx])
        end
        self.m_pAttrListView:pushBackCustomItem(attr)
    end
end

--[[
显示装备属性
]]
function PetEquipSubUI:ShowEquipAttr(sender,attrType,attrVal)
    local valueLabel = sender:getChildByName("Value")
    if attrType == nil or attrVal == nil then
        sender:setString("")
        valueLabel:setString("")
        return
    end
    
    local sign = false
    if attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
        sign = true
        attrVal = string.format("%.2f",attrVal/100)
    end  
    Utils:ShowAttrLabel(sender, attrType, valueLabel, attrVal, sign)
    local size = sender:getContentSize()
    local x,y = valueLabel:getPosition()
    valueLabel:setPosition(cc.p(size.width+5,y))
end

--[[
显示套装信息
]]
function PetEquipSubUI:ShowSuitInfo()
    if self.m_pLEquipNullDesc ~= nil then
        self.m_pLEquipNullDesc:setString("")
    end
    if self.m_pCurSuitInfo == nil or next(self.m_pCurSuitInfo) == nil then
        self.m_pTps1:setVisible(true)
        self.m_pTps2:setVisible(true)
        self.m_pAttrListView:setVisible(false)
        return
    end
    self.m_pAttrListView:setVisible(true)
    self.m_pAttrListView:removeAllItems()
    self.m_pTps1:setVisible(false)
    self.m_pTps2:setVisible(false)
    
    for k,v in pairs(self.m_pCurSuitInfo) do
        for i=1,#v do        
            local suitAttr = self.m_pDescCell:clone()
            suitAttr:setVisible(true)
            self:ShowSuitAttr(suitAttr,v[i])
            self.m_pAttrListView:pushBackCustomItem(suitAttr) 
        end      
    end
end

--[[
显示套装属性
]]
function PetEquipSubUI:ShowSuitAttr(sender,value)
    local suitCfgData = LDataConstMgr:GetPetSuitCfgData(value.id)
    if suitCfgData == nil then return end
    local descTitle = string.format(GUITips.RSI_PET_SUIT_TIPS3,suitCfgData.name,value.num)
    sender:setString(descTitle)

    local descLabel = sender:getChildByName("Text")
    local suitStr = LDataConstMgr:GetHeroSkillDesc(value.skillId, value.skillLv)
    descLabel:setString(""..Utils:DeleteString(suitStr,"%[","%]"))
end

--[[
显示宠物模型
]]
function PetEquipSubUI:ShowPetModel()
    if self.m_pPetBaseData == nil then
        self.m_pPetModelNode:setVisible(false)
        return
    end
    self.m_pPetModelNode:setVisible(true)
    self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.Monster, self.m_pPetBaseData.pic)
    self.m_pPetModelNode:PlayStand(self.m_pPetBaseData.defaultFace)
end

--[[
显示宠物装备（已穿）
]]
function PetEquipSubUI:ShowPetEquipList()
    for i=1,AppDef.Pet.MaxEquipPosNum do
        itemValue = nil
        local v = self.m_pCurEquips[i]
        if v ~= nil and v.m_quality > 0 and v.m_uid > 0 then
            local resFile = string.format("item/%s.png", v.m_pic)
            local userDefine ={picFilePath = resFile,quality = v.m_quality, star = v.m_star, strengthenLv = v.m_stoneLevel,suitId = v.m_suitType}
            itemValue = {}
            itemValue.userDefine = userDefine
        end
        self.m_EquipCells[i]:UpdateItem(itemValue)
    end
    local myItemNum = LRoleDataMgr.MyHeroInfo:GetDetailData().xinXiuJingHua
    self._XinXiuValue:setString(myItemNum)
end

function PetEquipSubUI:RefreshBag()
    local part = self.m_chooseEquipPart
    local suit = self.m_chooseSuitId
    if self.m_curRightTab == 1 then
        part = 0
    else
        suit = 0
    end
    self.m_equipBagData = LRoleDataMgr:GetPetEquipBagInfo(suit,part,false)
    self:LoadPetEquipBag()
end

function PetEquipSubUI:ShowPower()
    local str = ""
    if self.m_powerVal ~= nil then
        str = tostring(self.m_powerVal)
    end
    self.m_pPowerLabel:setString(str)
end

function PetEquipSubUI:UpdataEquipData(op,data)
    --if self.m_equipBagData == nil then return end
    if op == nil or data == nil then return end
    if op == 1 then
        --增
        --local check = self:CheckRightTab(data.m_suitType,data.m_wpos)
        --if not check then return end         
        self:SetCurRightTab(self.m_curRightTab,true)
        self:RefreshBag()     
    elseif op == 2 then
        --删
        local check = self:CheckRightTab(data.suitId,data.pos)
        if not check then return end    
        self:SetCurRightTab(self.m_curRightTab,true)
        self:RefreshBag()   
    elseif op == 3 then
        --改（强化）
        local check = self:CheckRightTab(data.m_suitType,data.m_wpos)
        if not check then return end
        local ind = self:CheckBagData(data.m_uid)
        if ind == 0 then return end 
        self:RefreshBag()
        return  
	elseif op == 9 or op == 10 then
		self:RefreshBag()
    end
end

function PetEquipSubUI:CheckBagData(uid)
    if uid == nil or uid < 1 then return 0 end
    for i = 1,#self.m_equipBagData do
        if self.m_equipBagData[i].m_uid == uid then
            return i
        end
    end
    return 0
end

function PetEquipSubUI:CheckRightTab(suitType,wPos)
    if self.m_curRightTab == 1 then
        if suitType ~= nil and suitType == self.m_chooseSuitId then
            return true
        end
    elseif self.m_curRightTab == 2 and wPos ~= nil and wPos == self.m_chooseEquipPart then
        return true
    end
    return false
end

function PetEquipSubUI:ShowEquipOpenLv()
    for i=1,AppDef.Pet.MaxEquipPosNum do      
        local str = ""
		self["m_addIcon"..i]:setVisible(true)
        if PetUIDef.EquipPosOpenLv[i] > self.m_petLv then
            str = string.format(GUITips.RSI_PET_SUIT_TIPS7,PetUIDef.EquipPosOpenLv[i]) 
			self["m_addIcon"..i]:setVisible(false)
        end
        self["m_openLabel"..i]:setString(str)
    end
end

function PetEquipSubUI:ShowSuitEffect(oldSuitInfo)
    if self.m_pCurSuitInfo == nil or next(self.m_pCurSuitInfo) == nil then return end
    local suitType = 0
    for k,v in pairs(self.m_pCurSuitInfo) do
        for i=1,#v do
            if oldSuitInfo[k] == nil or oldSuitInfo[k][i] == nil or oldSuitInfo[k][i].id < 1 then
                 suitType = v[i].id
                 break
            end
        end
    end
    if suitType == 0 then return end
    for i=1,AppDef.Pet.MaxEquipPosNum do       
        local curData = self.m_pCurEquips[i]   
        if curData ~= nil and curData.m_suitType == suitType then
            self:ShowIconEffect(i)
        end
    end
end

--Icon特效显示
function PetEquipSubUI:ShowIconEffect(ind)
    local parent = self.m_modelPanel:getChildByName("EquipIcon"..ind)
    if parent == nil then return end
    if self.m_imods == nil then self.m_imods = {} end
    if self.m_imods[ind] ~= nil then
        self.m_imods[ind]:removeFromParent()
		self.m_imods[ind] = nil
    end
    local size = parent:getContentSize()
    self.m_imods[ind] = Utils:CreateImod("res2/fx/pet_equip_tao",cc.p(size.width/2,size.height/2),parent,1)
    self.m_imods[ind]:PlayAction(0)  
    self.m_imods[ind].userObject = ind

    local function AniPlayEndCallback(sender)
        self.m_imods[sender.userObject] = nil
        sender:removeFromParent()    
    end
    self.m_imods[ind]:registerScriptEndCBHandler(AniPlayEndCallback)
end

function PetEquipSubUI:UnLoadAllIcon()
    if self.m_suitImg == nil then
        return
    end
    for i = 1, #self.m_suitImg do
        local res = string.format("res2/Icon/ui_pet_icon/ui_tuteng_dongwu_%d.png", self.m_suitImg[i].userObject)
        LGameMsg.m_resMsg:Change(LResEvent.UnLoadImgSync, res)
        self:SendMsg(LGameMsg.m_resMsg)
    end
    self.m_suitImg = nil
end

function PetEquipSubUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Pet.PetMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

--计算当前选中套装
function PetEquipSubUI:GetSelectSuit()
    if self.m_pPetBaseData == nil then return 1 end
    local suitId = 0
    --优先选择新获得
    local suits = LPetDataMgr:GetPetEquipRedDot()
    for k,v in pairs(suits) do
        if v == 1 then
            for i = 1,#self.m_pPetBaseData.tuijianSuit do
                if self.m_pPetBaseData.tuijianSuit[i] == k then
                    return k
                end
            end
            suitId = k
        end
    end
    if suitId > 0 then
        return suitId
    end
    --未装备部位是否有推荐套装
    for i=1,AppDef.Pet.MaxEquipPosNum do
        local v = self.m_pCurEquips[i]
        if (v == nil or v.m_uid == 0) and PetUIDef.EquipPosOpenLv[i] <= self.m_petLv then
             for j=1,#self.m_pPetBaseData.tuijianSuit do
                local tjSuit = self.m_pPetBaseData.tuijianSuit[j]
                local sign = LRoleDataMgr:CheckPetEquipBagInfo(tjSuit,i) 
                if sign then 
                    return tjSuit 
                end 
            end
        end
    end
    --推荐都没有,看是否可以组成套装
    self:GetSuitNum()
    for k,v in pairs(self.m_suits) do
        local suitCfgData = LDataConstMgr:GetPetSuitCfgData(k)
        for i= 1,#suitCfgData.suitNum do
            if v.num + 1 == suitCfgData.suitNum[i] then
                for j=1,AppDef.Pet.MaxEquipPosNum do
                    if v.parts ~= nil and v.parts[j] == nil and PetUIDef.EquipPosOpenLv[j] <= self.m_petLv then
                        local sign = LRoleDataMgr:CheckPetEquipBagInfo(k,j) 
                        if sign then 
                            return k 
                        end  
                    end
                end
            end
        end
    end
    --全部没有，查找排序最先的
    local full = true
    for i=1,AppDef.Pet.MaxEquipPosNum do
        local v = self.m_pCurEquips[i]
        if (v == nil or v.m_uid == 0) then
            local infos = LRoleDataMgr:GetPetEquipBagInfo(0,i,false) 
            if infos ~= nil and #infos > 0 then 
                return infos[1].m_suitType
            end
        else
            full = false
        end
    end
    return self.m_pPetBaseData.tuijianSuit[1]
end

--计算当前装备战斗力
function PetEquipSubUI:GetAttrPower(equipData)
    if equipData == nil or equipData.m_uid < 1 then return 0 end
    local power = LDataConstMgr:GetAttrPower(equipData.m_addTypes,equipData.m_addValues)
    local upRatio = 1
    local cfgData = LDataConstMgr:GetPetEquipQHCfgData(equipData.m_stoneLevel)
    if cfgData ~= nil then
        upRatio = cfgData.upRatio/10000
    end
    if equipData.m_baseTypes ~= nil and #equipData.m_baseTypes > 0 then
        power = power + LDataConstMgr:GetSingleAttrPower(equipData.m_baseTypes[1],math.floor(equipData.m_baseValues[1]*upRatio))
    end
    return power
end

--点击空的装备栏，选择装备
function PetEquipSubUI:GetEquip(part)
    
    local function selectEquip(suitType,part)
        local infos = LRoleDataMgr:GetPetEquipBagInfo(suitType,part,false)
        if infos == nil or #infos == 0 then
            return 0,0
        end
        if #infos == 1 then
            return infos[1].m_uid,infos[1].m_suitType
        end
        local uid = 0
        local maxPower = 0
        local suitId = suitType
        for i=1,#infos do
            local power = self:GetAttrPower(infos[i])
            if power > maxPower then
                maxPower = power
                uid = infos[i].m_uid
                suitId = infos[i].m_suitType
            end
        end
        return uid,suitId
    end

    --获取套装数量
    local function getSuitNum(suitType,part)
        local v = self.m_suits[suitType]
        if v == nil or v.num == nil or v.num == 0 or v.parts == nil or v.parts[part] ~= nil then return 0 end
        local suitCfgData = LDataConstMgr:GetPetSuitCfgData(suitType)
        if suitCfgData == nil then return 0 end
        for i= 1,#suitCfgData.suitNum do
            if v.num + 1 == suitCfgData.suitNum[i] then              
                return v.num
            end
        end
        return 0
    end

    local function suitSort(a,b)
        return a.num > b.num
    end

    if self.m_pPetId < 1 or part < 1 or part > AppDef.Pet.MaxEquipPosNum 
      or self.m_pPetBaseData == nil 
      or PetUIDef.EquipPosOpenLv[part] > self.m_petLv then
        return 
    end
    local uid = 0
	local suit = 0
    --先看推荐（套装优先）
    self:GetSuitNum()
    local suitInfo = {}
    for i=1,#self.m_pPetBaseData.tuijianSuit do
         local tjSuit = self.m_pPetBaseData.tuijianSuit[i]
         local snum = getSuitNum(tjSuit,part)
         if snum > 0 then
             value = {id = tjSuit,num = snum}
             table.insert(suitInfo,value)
         end
    end
    if #suitInfo > 0 then
        table.sort(suitInfo,suitSort)
        for i=1,#suitInfo do
            uid,suit = selectEquip(suitInfo[i].id,part)
            if uid > 0 then
                break
            end
        end
    end
    --再看推荐-非套装
    if uid == 0 then
        for i=1,#self.m_pPetBaseData.tuijianSuit do
            local tjSuit = self.m_pPetBaseData.tuijianSuit[i]
            uid,suit = selectEquip(tjSuit,part)
            if uid > 0 then
                break
            end
        end
    end
    --再看套装(非推荐)
    if uid == 0 then
        for k,v in pairs(self.m_suits) do
            local snum = getSuitNum(k,part)
            if snum > 0 then
                uid,suit = selectEquip(k,part) 
                if uid > 0 then
                    break
                end  
             end               
        end
    end
    --最后只看战斗力
    if uid == 0 then
        uid,suit = selectEquip(0,part)
    end
    if uid == 0 then
        Utils:ShowScrollTips(GUITips.RSI_PET_SUIT_TIPS13)
        return
    end
    LuaNetSendMsg:QueryPetEquip(2,uid,self.m_pPetId)
	local send = LPetDataMgr:DelPetSuitRedDot(suit,uid)
    if send then
--        LGameMsg.m_baseMsgWithOne:Change(LUIPetEvent.PetEquipAdd, suit)
--        self:SendMsg(LGameMsg.m_baseMsgWithOne)
        if self.m_msg == nil then
            self.m_msg = LUIMsg1.New(LUILogicEvent.InitUI)
        end
        self.m_msg:Change(LUIPetEvent.PetEquipAdd,suit)
        self:SendMsg(self.m_msg)      
    end
end

--计算套装件数
function PetEquipSubUI:GetSuitNum()
    self.m_suits = {}
    for i=1,AppDef.Pet.MaxEquipPosNum do
        local v = self.m_pCurEquips[i]
        if v ~= nil and v.m_quality > 0 and v.m_uid > 0 then
            if self.m_suits[v.m_suitType] == nil then 
                self.m_suits[v.m_suitType] = {}
            end
            if self.m_suits[v.m_suitType].num == nil then
                 self.m_suits[v.m_suitType].num = 1
            else
                self.m_suits[v.m_suitType].num = self.m_suits[v.m_suitType].num +1
            end
            if self.m_suits[v.m_suitType].parts == nil then
                self.m_suits[v.m_suitType].parts = {}
            end
            self.m_suits[v.m_suitType].parts[i] = 1
        end
    end
end

return PetEquipSubUI