
local PetChangeUI = LUIBase:New()
PetChangeUI.__index = PetChangeUI
--local this = LTcpSocket
function PetChangeUI:New()
	local o = LUIBase:New()
	setmetatable(o,PetChangeUI)	
    o:Init()
	return o
end

local EVERYLINENUM = 6

--注册事件
-- -----------------------------------
function PetChangeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFormationEvent.PetFight,
        LUIKaPaiPetEvent.ChangePetInitData,
        LUIFormationEvent.ChangeShowPos,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetChangeUI:ProcessEvent(msg)
    if msg.msgId == LUIFormationEvent.PetFight then
        self:updateUI(msg.value)
    elseif msg.msgId == LUIKaPaiPetEvent.ChangePetInitData then
        self:initData(msg.value, false)
        self:initControlUI()
        self:RegisterGuide()
    elseif msg.msgId == LUIFormationEvent.ChangeShowPos then
        self:updateUIAfterChangePos(msg.value)
    end
end

function PetChangeUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxionghuanjiang.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()

    local function closeCallback()
        self:closeUI()
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    

end

function PetChangeUI:initData( changeData, isShowAllPet)
    -- body
    self._ownPetList = {}
    self._petId = changeData.pid
    self._selectPos = changeData.pos
    if isShowAllPet then
        self._ownPetList = LRoleDataMgr.Pet.petlist
    else
        for i=1, #LRoleDataMgr.Pet.petlist do
            local petData = LRoleDataMgr.Pet.petlist[i]
            local showPos = LRoleDataMgr.Pet:GetPetPos(petData.id)
            if showPos < 1 then
                table.insert(self._ownPetList, petData)
            end
        end
    end

    -- dump(self._ownPetList, "===============>")

    self:SortPetList()

    self._showAll = isShowAllPet
    self._lastIdx = 0
    self._guideBtn = nil

end


function PetChangeUI:SortPetList( ... )
    -- body
    local function sortFuc(a, b)
        return PetkaPaiManager:getPetChangePriority(a) > PetkaPaiManager:getPetChangePriority(b)
    end
    table.sort(self._ownPetList, sortFuc)
end


-- yingxionghuanjiangUI
function PetChangeUI:initControlUI( ... )
    local yingxionghuanjiangUI = self.m_pUILayer:getChildByName("yingxionghuanjiangUI")
    -- yingxionghuanjiangUI:setTouchEnabled(false)
    self._TableViewPanel = yingxionghuanjiangUI:getChildByName("TableView")
    self._pCell = yingxionghuanjiangUI:getChildByName("ItemCell")
    self._pCell:setVisible(false)
    -- self._pCell:removeFromParent()
    -- self._pCell:retain()

    self._CheckBox = yingxionghuanjiangUI:getChildByName("CheckBox")
    self._CheckBox:addClickEventListener(function ( sender )
        -- body
        self:initData({pid=self._petId, pos=self._selectPos}, not self._showAll)
        self.m_pPetTableView:reloadData()
    end)

    self:InitPetTabView()
    self.m_pPetTableView:reloadData()
end

function PetChangeUI:InitPetTabView()
    local tableView = cc.TableView:create(self._TableViewPanel:getContentSize())
    tableView:setContentSize(self._TableViewPanel:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._TableViewPanel:addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:TableCellTouched(sender, cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        return self:PetTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = 0
        if self._ownPetList then
            if #self._ownPetList % EVERYLINENUM == 0 then
                size = #self._ownPetList / EVERYLINENUM
            else
                size = math.floor(#self._ownPetList / EVERYLINENUM) + 1 
            end
        end
        return size
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    --tableView:reloadData()
    self.m_pPetTableView = tableView
end


--点击选中处理
function PetChangeUI:TableCellTouched(sender, cell)
    -- local ind = cell:getIdx()
    -- local cellChild = cell:getChildByTag(123)
end 


function PetChangeUI:PetTableCellAtIndex(sender, idx)

    local function petGridTouched(sender)--选中
        if self.m_isDragging then
            return
        end
        local ind = sender:getTag()
        if self._lastIdx > 0 then
            local lastidx = math.floor((self._lastIdx - 1) / EVERYLINENUM)
            local lastSelcetFace = self.m_pPetTableView:cellAtIndex(lastidx)
            if lastSelcetFace ~= nil then
                local cellChild = lastSelcetFace:getChildByTag(123)
                if cellChild ~= nil then
                    local i = (self._lastIdx - 1) % EVERYLINENUM + 1
                    local lastItem = cellChild:getChildByTag(i)
                    if lastItem ~= nil then
                        -- lastItem:getChildByName("Choose"):setVisible(false)
                    end
                end
            end
        end
         
        -- sender:getChildByName("Choose"):setVisible(true)
        self._lastIdx = ind;
    end


    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i=1, EVERYLINENUM do
            local giftGrid = cellChild:getChildByName("Item"..i)
            --实现选中状态
            -- giftGrid:setBright(true)
            giftGrid:setSwallowTouches(false)
            local index = idx * EVERYLINENUM + i 
            giftGrid:setTag(index)
            giftGrid:addClickEventListener(petGridTouched) 
            self:MarkIntaractCObj(giftGrid)
            giftGrid:setTouchEnabled(true)
            giftGrid:setSwallowTouches(false)
            -- giftGrid:getChildByName("Choose"):setVisible(false)
            -- cellChild:pushBackCustomItem(giftGrid)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end      
    else
        cellChild = cell:getChildByTag(123)
        for i=1, EVERYLINENUM do
            local index = idx*EVERYLINENUM+i
            local giftGrid = cellChild:getChildByName("Item"..i)
            giftGrid:setTag(index)
            self:showKaPaiInfo(cellChild, giftGrid, index)
        end
    end
    
    return cell
end

function PetChangeUI:showKaPaiInfo(cellChild, giftGrid, index)
    -- body
    if cellChild == nil then
        return
    end
    if index > #self._ownPetList then
        giftGrid:setVisible(false)
        return
    end
    local petData = self._ownPetList[index]
    self:showItemInfo(giftGrid, petData)

end

function PetChangeUI:showItemInfo(giftGrid, petData)
    -- body
    -- dump(petData, "showItemInfo ==============>")
    if petData == nil then
        return
    end

    if petData.baseData == nil then
        petData.baseData = LDataConstMgr:GetPetData(petData.id)
        --默认数据
        if petData.baseData == nil then
            petData.baseData = LDataConstMgr:GetPetData(57)
        end
    end

    giftGrid:setVisible(true)

    local Quality = giftGrid:getChildByName("Quality")
    Quality:setTouchEnabled(false)
    -- print("petData.quality", petData.baseData.quality)
    local peQuality = petData.baseData.quality
    local QualityPath = AppDef:GetQualityColorKuang(peQuality)
    Utils:SafeLoadTexture(Quality, QualityPath, ccui.TextureResType.plistType)

    local name = giftGrid:getChildByName("Name")
    name:setString(petData.name.. "   +"..petData.breakLevel)

    local Quality_Level = giftGrid:getChildByName("Quality_Level")
    local lVBgPath = AppDef.ColorDengjiArr[petData.baseData.quality]
    Utils:SafeLoadTexture(Quality_Level, lVBgPath, ccui.TextureResType.plistType)
    
    local level = giftGrid:getChildByName("Level")
    level:setString(petData.level)

    local shangzhen = giftGrid:getChildByName("Panel_shangzhen")


    local icon = giftGrid:getChildByName("Panel_icon"):getChildByName("Icon")
    local imagePath = Utils:GetMonsterIconRes(petData.baseData.pic, AppDef.HeadIconResType.Body)
    -- print("imagePath =============>", imagePath)
    if cc.FileUtils:getInstance():isFileExist(imagePath) then
        Utils:SafeLoadTexture(icon, imagePath, ccui.TextureResType.localType)
    end
    local StarList = giftGrid:getChildByName("StarList")
    PetkaPaiManager:ShowStars(StarList, petData.star)

    local Button = giftGrid:getChildByName("Button")
    Button:setTag(petData.id)
    Button:addClickEventListener(handler(self, PetChangeUI.IntoWrok))

    local Prompt = Button:getChildByName("Prompt")
    local selectPetData = LRoleDataMgr.Pet:GetPetById(self._petId)
    local showRedDot = self._petId < 1 or selectPetData.baseData.quality < peQuality
    Prompt:setVisible(showRedDot)

    local txt = Button:getChildByName("Text")
    local showPos = LRoleDataMgr.Pet:GetPetPos(petData.id)
    if showPos > 0 then
        if self._petId == petData.id or self._petId <= 0 then
            Button:setTouchEnabled(false)
            Button:setBright(false)
        else
            Button:setTouchEnabled(true)
            Button:setBright(true)
        end
        shangzhen:setVisible(true)
        txt:setString(GUITips.RSI_ZQX_HERO_FORMATION_CHANGE)
    else
        Button:setTouchEnabled(true)
        Button:setBright(true)
        txt:setString(GUITips.RSI_ZQX_HERO_FORMATION)
        shangzhen:setVisible(false)
    end
    
    if self._guideBtn == nil then
        self._guideBtn = Button
    end
end

function PetChangeUI:HandlePetFight(petId)
    --请求出战
    -- local newPetData = LRoleDataMgr.Pet:GetPetById(petId)
    -- local petData = LRoleDataMgr.Pet:GetPetById(self._petId)
    -- print("PetChangeUI:HandlePetFight ===>", newPetData.fightPos)
    -- if newPetData.fightPos > 0 then
    --     --两个都已上阵替换位置
    --     -- LuaNetSendMsg:QueryFormationChangePos(petData.fightPos, newPetData.fightPos)

    -- else
    --     --上阵
    --     print("HandlePetFight self._petId ==", self._petId, self._selectPos, petId, newPetData.name)
    --     LuaNetSendMsg:QueryFormationPetPos(petId, self._selectPos)
    -- end

    LuaNetSendMsg:QueryFormationPetPos(petId, self._selectPos)
    self:closeUI()
end

--上阵
function PetChangeUI:IntoWrok( sender )
    -- body
    local tag = sender:getTag()
    self._ShangZhenBtn = sender
    self._selectPid = tag
    self:HandlePetFight(tag)

end

function PetChangeUI:updateUI( showPos )
    -- body
    if self._ShangZhenBtn == nil then
        return
    end

    local tag = self._ShangZhenBtn:getTag()
    local petData = LRoleDataMgr.Pet:GetPetByFightPos(showPos)
    if petData and tag ~= petData.id then
        return
    end

    local BtnTxt = self._ShangZhenBtn:getChildByName("Text")
    BtnTxt:setString(GUITips.RSI_ZQX_HERO_FORMATION_ON)
    self._ShangZhenBtn:setTouchEnabled(false)
    self._ShangZhenBtn:setBright(false)

end


function PetChangeUI:updateUIAfterChangePos( value )
    -- body
    if self._selectPid == nil then
        return
    end
    --更换位置
    LRoleDataMgr.Pet.ShowPosList[value[2]] = self._petId
    LRoleDataMgr.Pet.ShowPosList[value[1]] = self._selectPid

    self:closeUI()

end

function PetChangeUI:closeUI( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "KaPaiPet.PetChangeUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end


function PetChangeUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep, GuideDef.StepId.Guide_Pet_9)
    self.m_pUILayer = nil
    self:Destory()
    Utils:CheckGuide(GuideDef.StepId.Guide_Pet_10, true)
end

function PetChangeUI:RegisterGuide()
    if self._guideBtn ~= nil then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Pet_9, self._guideBtn, function()
            self:IntoWrok(self._guideBtn)
        end, nil, true)
    end
end

return PetChangeUI