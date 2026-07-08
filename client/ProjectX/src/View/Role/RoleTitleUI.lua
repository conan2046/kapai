local RoleTitleUI = LUIBase:New()
RoleTitleUI.__index = RoleTitleUI
--local this = LTcpSocket
function RoleTitleUI:New(tilteId)
	local o = LUIBase:New()
	setmetatable(o,RoleTitleUI)	
    o:Init(tilteId)
	return o
end

--[[
注册消息
]]
function RoleTitleUI:RegistMsgs()
    self.msgIds = 
    {
        LUITitleEvent.updateTitleUI,
        LUITitleEvent.updateMedalShow,
        LUITitleEvent.updateShowMedelSuc,
    }
    self:RegistSelf(self,self.msgIds)
end

function RoleTitleUI:ProcessEvent(msg)
    if msg.msgId == LUITitleEvent.updateTitleUI then
        self:updateUI()
    end

    if msg.msgId == LUITitleEvent.updateMedalShow then
        self:updateMedalShow()
    end

    if msg.msgId == LUITitleEvent.updateShowMedelSuc then
        self:updateDetailUI(self._selectIndex)
        self.m_pTitleTableView:reloadData()
    end

end

function RoleTitleUI:Init(tilteId)

    --print("tilteId = ", tilteId)
    if tilteId then
        self._titleId = tilteId
    else
        self._titleId = 0
    end
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/TitleLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end

    self:RegistMsgs();
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:AddTouchEvt();
    --dump(LRoleDataMgr.MedalList, "firstData")
    self:initData();
    self:initLeftUI();

    self:initUI();
    self:ShowRoleModel();
    self:updateUI()
    self:SetDefaultMedal()
--默认显示第一个称号
    self:showFirstMedal()
    LuaNetSendMsg:QueryMedalList()
end

function RoleTitleUI:isAlreadyShowFirstMedal()
    -- body
    for i=1, #LRoleDataMgr.MedalList do
        local data = LRoleDataMgr.MedalList[i]
        if data.state == 1 then
            return true
        end
    end
    return false
end

function RoleTitleUI:showFirstMedal()
    -- body
    if self:isAlreadyShowFirstMedal() then
        return
    end

    if #LRoleDataMgr.MedalList <= 0 then
        return
    end

    local data = LRoleDataMgr.MedalList[1]
    LuaNetSendMsg:QueryShowMedal(2, data.id, 1)

end

function RoleTitleUI:ShowRoleModel()
    local data = LRoleDataMgr.MyHeroInfo
    --print("RoleTitleUI:ShowRoleModel",data.model)
    local sign = false
    if self.m_pRoleModel == nil then
        sign = true
    end
    self.m_pRoleModel = Utils:CreateBigRoleModel(data:GetModel(),self.m_pRoleModel)
    if sign then
        self._roleAnim:addChild(self.m_pRoleModel)
        self._roleAnim:setScale(0.5)
    end
    -- if self.m_pRoleMode == nil then
    --     self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
    --                                         data:GetModel(), 
    --                                         data:GetWeaponId(), 
    --                                         data.LightEffect,
    --                                         data.WingsId,
    --                                         0,
    --                                         data:GetShenQiId())
    --     self._roleAnim:addChild(self.m_pRoleModel)
    -- else
    --     self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Hero, 
    --                                         data:GetModel(),
    --                                         data:GetWeaponId(), 
    --                                         data.LightEffect,
    --                                         data.WingsId,
    --                                         0,
    --                                         data:GetShenQiId())
    -- end
    -- self.m_pRoleModel:PlayStand(0)
end

function RoleTitleUI:onExit()
    self:Destory()
    self:exitEvent()
end

function RoleTitleUI:AddTouchEvt()

    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_Title)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)

    local panel = self.m_pUILayer:getChildByName("Panel")
--    panel:setSwallowTouches(false)
    local titleBg = panel:getChildByName("TitleBg")
    local powerBg = titleBg:getChildByName("PowerBg")
    
--    AllAttribute
    self.AllAttribute = powerBg:getChildByName("AllAttribute")

    --问号
    local HelpBtn = powerBg:getChildByName("HelpBtn")
    local function OnBtnHelpButtonClick(sender)
        local userData =
        {
            title = GUITips.UI_Title_Tishi,
            desc = GUITips.RSI_HL_TIP12,
        }

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.FirstClassLayer, userData)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    HelpBtn:addClickEventListener(OnBtnHelpButtonClick)
	self:MarkIntaractCObj(HelpBtn)
    --前往挑战
    self.challenge = powerBg:getChildByName("Button1")
    local function OnBtnChallengeButtonClick(sender)
        local isExit = false
        if self._ChallengeType == AppDef.medalChallengeType.RL_MEDAL_BATTLE then
            isExit = Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_WF_ARENA)
        elseif self._ChallengeType == AppDef.medalChallengeType.RL_MEDAL_TOWER then
            -- if Utils:CheckModelNotOpened(AppDef.EActivityID.EAID_TOWER) then
            --     return
            -- end
            -- EnterBtnTouched(AppDef.EActivityID.EAID_TOWER)
        elseif self._ChallengeType == AppDef.medalChallengeType.RL_MEDAL_VIP then
            --isExit = Utils:OpenFunction(AppDef.EModuleID.EMID_KAPAI_VIP)
        end
        if isExit then
            LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Role.RoleTitleUI")
            self:SendMsg(LGameMsg.m_initUIMsg)
        end
    end
    self.challenge:addClickEventListener(OnBtnChallengeButtonClick)
	self:MarkIntaractCObj(self.challenge)
    self.challenge:setVisible(false)

    self._ChallengeType = AppDef.medalChallengeType.RL_MEDAL_NONE

    --显示
    self._showBtn = powerBg:getChildByName("Button2")
    local function OnBtnShowButtonClick(sender)
--        print("self._selectIndex", self._selectIndex)
        if self._selectIndex > -1 then
            local data = LRoleDataMgr.MedalList[self._selectIndex + 1]
            if data ~= nil then
                if data.state == 1 then
                    LuaNetSendMsg:QueryShowMedal(2, data.id, 0);
                else
                    LuaNetSendMsg:QueryShowMedal(2, data.id, 1);
                end
            end
        end
    end
    self._showBtn:addClickEventListener(OnBtnShowButtonClick)
	self:MarkIntaractCObj(self._showBtn)
end

function RoleTitleUI:initData()
    
     self._showList1 = false --展开已获得称号
     self._showList2 = false --展开未获得称号
     self._lastChooseIndex = -1
     self._lastChooseIndexNotGain = -1

     local panel = self.m_pUILayer:getChildByName("Panel")
     self._leftViewList = panel:getChildByName("BtnList")
     local BtnList = panel:getChildByName("BtnList")

     self._leftList1 = BtnList:getChildByName("BtnList1")
     self._leftList1Height = self._leftList1:getContentSize().height
     self._leftList1:setTouchEnabled(false);
     self._leftList2 = BtnList:getChildByName("BtnList2")
     self._leftList2:setTouchEnabled(false);
     self._Btn1 = BtnList:getChildByName("Button1")
     self._ChooseBg1 = self._Btn1:getChildByName("ChooseBg")
     
     self._OpenImage1 = self._Btn1:getChildByName("OpenImage")
     self._CloseImage1 = self._Btn1:getChildByName("CloseImage")

     local function OnBtn1ButtonClick(sender)
        self:showHasTitleList(not self._showList1);
        if self._selectIndex > 0 then
            self:updateDetailUI(self._selectIndex)
        end
     end
     self._Btn1:addClickEventListener(OnBtn1ButtonClick)
	self:MarkIntaractCObj(self._Btn1)
     self._Btn2 = BtnList:getChildByName("Button2")
     self._Btn2PosY = self._Btn2:getPositionY();
     self._ChooseBg2 = self._Btn2:getChildByName("ChooseBg")
     self._OpenImage2 = self._Btn2:getChildByName("OpenImage")
     self._CloseImage2 = self._Btn2:getChildByName("CloseImage")

     local function OnBtn2ButtonClick(sender)
        self:showNotHasTitleList(not self._showList2)
        if self._notGainSelect > -1 then
            self:updateNotGainDetailUI(self._notGainSelect)
        end
     end
     self._Btn2:addClickEventListener(OnBtn2ButtonClick)
	self:MarkIntaractCObj(self._Btn2)
     self._pCell = panel:getChildByName("SubcontrolBtn2")

     self._pCellNotGain = panel:getChildByName("SubcontrolBtn1")

      
     local roleBg = panel:getChildByName("TitleBg"):getChildByName("RoleBg")
     local basebg =  roleBg:getChildByName("Bg"):getChildByName("BaseBg")
     self._titleSprite = basebg:getChildByName("TitleSprite")
     self._titleSprite:setVisible(false)

     self._baseBg = basebg
     self._titleSpriteImage = basebg:getChildByName("Image_Sprite")

     self._roleAnim = basebg:getChildByName("Node")

     self._attributeTxt1 = roleBg:getChildByName("AttributeBg"):getChildByName("Text1")
     self._attributeTxt1:setVisible(false)
     self._attributeTxt2 = roleBg:getChildByName("AttributeBg"):getChildByName("Text2")
     self._attributeTxt2:setVisible(false)
     self._attributeTxt3 = roleBg:getChildByName("AttributeBg"):getChildByName("Text3")
     self._attributeTxt3:setVisible(false)
     self._attributeTxt4 = roleBg:getChildByName("AttributeBg"):getChildByName("Text4")
     self._attributeTxt4:setVisible(false)

     self._getCondition = roleBg:getChildByName("AttributeBg_0"):getChildByName("Text")

     local powerBg = panel:getChildByName("TitleBg"):getChildByName("PowerBg")
     local power = powerBg:getChildByName("Power")
     power:setVisible(true)

     self._powerTxt = power:getChildByName("Value")
     self._powerDes = powerBg:getChildByName("ListView")
     self._powerDes:setScrollBarEnabled(false)
     self._AttributeCell = powerBg:getChildByName("Attribute")

     self._selectIndex = -1;
     self._notGainSelect = -1;
end


function RoleTitleUI:initUI()
    
    self._ChooseBg1:setVisible(false)
    self._OpenImage1:setVisible(false)
    self._CloseImage1:setVisible(true)

    self._ChooseBg2:setVisible(false)
    self._OpenImage2:setVisible(false)
    self._CloseImage2:setVisible(true)
end

function RoleTitleUI:updateUI()
    local medalinfo = LRoleDataMgr.MedalList;

    self.m_pTitleTableView:reloadData();
    self._medalAllList = LDataConstMgr.m_medalTable
    self._showMedalList = {}
--增加字段, 控制显示

    for i = 1, #self._medalAllList do
        local medalId = self._medalAllList[i].id
        if self._medalAllList[i].isShow == 1 and not LRoleDataMgr:isHaveTheMedal(medalId) then
            table.insert(self._showMedalList, self._medalAllList[i])
        end
    end
    self.m_pNotGainTitleTableView:reloadData()
end

function RoleTitleUI:showHasTitleList(b)
    if self._showList1 == b then
        return
    end
    self._showList1 = b
    self._ChooseBg2:setVisible(false)
    self._ChooseBg1:setVisible(true)

    self._OpenImage1:setVisible(self._showList1)
    self._CloseImage1:setVisible(not self._showList1)
    self.m_pTitleTableView:setVisible(self._showList1)
    self.m_pNotGainTitleTableView:setVisible(false)
    self._showList2 = false

    if #LRoleDataMgr.MedalList > 0 then
        local distance = self._leftList1Height
        if self._Btn2PosY > self._Btn2:getPositionY() + 200 then
            self._Btn2:stopAllActions()
            local action = cc.MoveBy:create( 0.1, cc.p(0, distance))
            self._Btn2:runAction(action)
        else
            self._Btn2:stopAllActions()
            local action = cc.MoveBy:create( 0.1, cc.p(0, -distance))
            self._Btn2:runAction(action)
        end
    end
    
end


function RoleTitleUI:showNotHasTitleList(b)
    if self._showList2 == b then
        return
    end
    self._showList2 = b
    self._ChooseBg2:setVisible(true)
    self._ChooseBg1:setVisible(false)

    self._OpenImage2:setVisible(self._showList2)

    self._CloseImage2:setVisible(not self._showList2)
    self.m_pNotGainTitleTableView:setVisible(self._showList2)
    self.m_pTitleTableView:setVisible(false)
    self._showList1 = false

    if self._Btn2PosY > self._Btn2:getPositionY() + 200 then
        local distance = self._leftList1Height
        local action = cc.MoveBy:create( 0.1, cc.p(0, distance))
        self._Btn2:stopAllActions()
        self._Btn2:runAction(action)
    end

end



function RoleTitleUI:initLeftUI()
    self:initAlreadyGainView();
    self:initNotGainView()
end
 
function RoleTitleUI:SetDefaultMedal()

    self._selectIndex = 0
    self.m_pTitleTableView:setVisible(false)
    self.m_pNotGainTitleTableView:setVisible(false)
    if #LRoleDataMgr.MedalList > self._titleId then
        
        local cell =  self.m_pTitleTableView:cellAtIndex(self._titleId);

        local cellChild = cell:getChildByTag(123)
            
        local chooseBg = cellChild:getChildByName("ChooseBg")
        chooseBg:setVisible(true)

        if  self._lastChooseIndex >= 0 then
            local lastSelectCell = self.m_pTitleTableView:cellAtIndex(self._lastChooseIndex);
            local cellChildGain = lastSelectCell:getChildByTag(123)
            cellChildGain:getChildByName("ChooseBg"):setVisible(false)
        end

        self._lastChooseIndex = self._titleId

        self:updateDetailUI(self._titleId)

        self:showHasTitleList(not self._showList1);

        self._showBtn:setVisible(true)

    else
        
        local cell =  self.m_pNotGainTitleTableView:cellAtIndex(self._titleId);
--        --print("RoleTitleUI:SetDefaultMedal _titleId = ", self._titleId)
        Utils:MoveToTableIdx(self.m_pNotGainTitleTableView, self._pCell, self._titleId)
        local cellChild = cell:getChildByTag(123)
        local chooseBg = cellChild:getChildByName("ChooseBg")
        chooseBg:setVisible(true)

        if  self._lastChooseIndexNotGain >= 0 then
            local lastSelectCellNotGain = self.m_pNotGainTitleTableView:cellAtIndex(self._lastChooseIndexNotGain);
            local cellChildNotGain = lastSelectCellNotGain:getChildByTag(123)
            cellChildNotGain:getChildByName("ChooseBg"):setVisible(false)
        end

        self._lastChooseIndexNotGain = self._titleId
        self:updateNotGainDetailUI(self._titleId)
        self:showNotHasTitleList(not self._showList2);

        self._showBtn:setVisible(false)
    end
    self:updateMedalShow();     
end

function RoleTitleUI:initAlreadyGainView()
    local tableView = cc.TableView:create(self._leftList1:getContentSize())
    tableView:setContentSize(self._leftViewList:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._leftList1:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
--        --print("tableCellTouched", cell:getIdx())
        self:TitleTableCellTouched(cell)

    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCell:getContentSize().width
        local height = self._pCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:TitleTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #LRoleDataMgr.MedalList
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_pTitleTableView = tableView
end


--点击选中处理
function RoleTitleUI:TitleTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
    self._showBtn:setVisible(true)
    -- if self._lastChooseIndex == ind then
    --     return
    -- end

    local chooseBg = cellChild:getChildByName("ChooseBg")
    chooseBg:setVisible(true)

    if  self._lastChooseIndex >= 0 then
        local lastSelectCell = self.m_pTitleTableView:cellAtIndex(self._lastChooseIndex);
        if lastSelectCell then
            local cellChildTemp = lastSelectCell:getChildByTag(123)
            if self._lastChooseIndex ~= ind then
                cellChildTemp:getChildByName("ChooseBg"):setVisible(false)
            end
        end
    end

    self._lastChooseIndex = ind
    --print("tableview touched " ..ind) 
    self._selectIndex = ind
    self:updateDetailUI(ind)
end 

function RoleTitleUI:TitleTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(cellChild:getContentSize().width / 2, cellChild:getContentSize().height / 2))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)

    else
        cellChild = cell:getChildByTag(123)
    end
    --print("cell idx"..idx)
    self:ShowTitleCellInfo(cellChild, idx)
    return cell
end

function RoleTitleUI:ShowTitleCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    if cellChild ~= nil then
        local chooseBg = cellChild:getChildByName("ChooseBg")

        if self._lastChooseIndex == idx then
            chooseBg:setVisible(true)
        else
            chooseBg:setVisible(false)
        end

        local data = LRoleDataMgr.MedalList[idx + 1]
        local detail = LDataConstMgr:GetMedalNote(data.id)
        if detail ~= nil then
            local string = detail.name
            local name = cellChild:getChildByName("BtnName")

            local titleImage = cellChild:getChildByName("TitleImage")
            local strImage = "res/UI/cm_chenghao/chenghao".. data.id ..".png"
            local lastSprite = cellChild:getChildByTag(10088)
            if lastSprite ~= nil then
                lastSprite:removeFromParent()
            end
            local sprite = Utils:CreateSpriteWithFrame(cellChild, titleImage, strImage)
            sprite:setTag(10088)

            local colIdx = LDataConstMgr:GetMedalColorIdx(idx + 1);
            local color = AppDef:GetQualityColor(colIdx)
            name:setTextColor(color)
            name:setString(string)
        end

        local checkbox = cellChild:getChildByName("CheckBox")

        if data.ware == 1 then
            checkbox:setSelected(true)
        else
            checkbox:setSelected(false)
        end
        
        --佩戴称号
        local function OnSelect(sender,evnetType)
	        local id = data.id;
            local _use = 1;
            if data.ware == 1 then
                _use = 0
            else
                --最多勾选5个
                local wearNum = self:getWearNum()
                if wearNum >= 5 then
                    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, GUITips.RSI_TITLE_TIP_MAX)
                    self:SendMsg(LGameMsg.m_scrollTipsMsg)
                    sender:setSelected(false)
                    return
                end
            end
	        LuaNetSendMsg:QueryShowMedal(3, id, _use);
        end
        checkbox:addEventListener(OnSelect)

        local showSigh = cellChild:getChildByName("Image_1")
        showSigh:setLocalZOrder(5)
        if data.state == 1 then
            showSigh:setVisible(true)
        else
            showSigh:setVisible(false)
        end

    end
end

function RoleTitleUI:getWearNum()
    -- body
    local num = 0
    for i = 1, #LRoleDataMgr.MedalList do
        local data = LRoleDataMgr.MedalList[i]
        if data.ware == 1 then
            num = num + 1
        end
    end
    return num
end


function RoleTitleUI:updateDetailUI(ind)
  
    local data = LRoleDataMgr.MedalList[ind + 1]
    if data == nil then
        return
    end

    local dataInfo = LDataConstMgr:GetMedalNote(data.id)
    local showBtnTxt = self._showBtn:getChildByName("Text")
    if data.state == 1 then
        showBtnTxt:setString(GUITips.RSI_TITLE_HIDE)
    else
        showBtnTxt:setString(GUITips.RSI_TITLE_SHOW)
    end

    self:updateAttribuytUI(dataInfo)
end

function RoleTitleUI:updateNotGainDetailUI(index)
  
     local dataInfo = self._showMedalList[index + 1]
     self:updateAttribuytUI(dataInfo) 
     self.challenge:setVisible(false)
     local ind = dataInfo.id
     if ind == 5 or ind == 6 or ind == 7 or ind == 8 or ind == 19 or ind == 20 or ind == 24 then
        self.challenge:setVisible(true)
        self._ChallengeType = AppDef.medalChallengeType.RL_MEDAL_BATTLE
    end

    if ind == 9 or ind == 10 or ind == 23 or ind == 25 then
        self.challenge:setVisible(true)
        self._ChallengeType = AppDef.medalChallengeType.RL_MEDAL_TOWER
    end

    if ind == 18 then
        self.challenge:setVisible(true)
        self._ChallengeType = AppDef.medalChallengeType.RL_MEDAL_VIP
    end

end

function RoleTitleUI:updateAttribuytUI(dataInfo)

    self._getCondition:setString(dataInfo.desc)

     local desInfo = {}
     local attrTypeArr = {}
     local attrValueArr = {}

    local madelValue = {}
    for j=1, 33 do
        local value = LDataConstMgr:GetMedalAttrValue(dataInfo.id, j)
        if value > 0 then
            self:addMedalValue(j, value, madelValue)
            table.insert(attrTypeArr, j)
            table.insert(attrValueArr, value)
        end
    end

    for i=1, #madelValue do
        local data = madelValue[i]
        local name = LDataConstMgr:GetItemAttrName(data.id)

        local strAttr 
        if data.id > AppDef.EAttrType.EAT_RESISIT_CRIT then
            strAttr = name.."："..string.format("%.2f", data.value/100).."%"
        else
            strAttr = string.format(name.."：%d", data.value)
        end
        print("attr name =", strAttr)
        table.insert(desInfo, strAttr)
     end

    --Utils:dump(desInfo)
     self._attributeTxt1:setVisible(false)
     self._attributeTxt2:setVisible(false)
     self._attributeTxt3:setVisible(false)
     self._attributeTxt4:setVisible(false)
     for i = 1, #desInfo do 
        if i == 1 then
            self._attributeTxt1:setVisible(true)
            self._attributeTxt1:setString(desInfo[i])
        end

        if i == 2 then
            self._attributeTxt2:setVisible(true)
            self._attributeTxt2:setString(desInfo[i])
        end

        if i == 3 then
            self._attributeTxt3:setVisible(true)
            self._attributeTxt3:setString(desInfo[i])
        end

        if i == 4 then
            self._attributeTxt4:setVisible(true)
            self._attributeTxt4:setString(desInfo[i])
        end

     end
--     print("RoleTitleUI:updateMedalShow dataInfo.id", dataInfo.id)
--     self._titleSpriteImage:loadTexture("res/UI/cm_chenghao/chenghao".. dataInfo.id ..".png", ccui.TextureResType.plistType)
     local strImage = "res/UI/cm_chenghao/chenghao".. dataInfo.id ..".png"
     local lastSprite = self._baseBg:getChildByTag(10086)
     if lastSprite ~= nil then
        lastSprite:removeFromParent()
     end
     local sprite = Utils:CreateSpriteWithFrame(self._baseBg, self._titleSpriteImage, strImage)
     sprite:setTag(10086)
end

function RoleTitleUI:addMedalValue( type, value,  list)
    -- body
    local medelData = {}
    medelData.id = type
    medelData.value = value
    local index = self:findMadelInfo(type, list)
    if index <= 0 then
        table.insert(list, medelData)
    else
        list[index].value = list[index].value + value
    end
end

function RoleTitleUI:updateMedalShow()
     local fightPwoer = 0;
     for i = 1, #LRoleDataMgr.MedalList do
        local data = LRoleDataMgr.MedalList[i]
        if data.ware then
            fightPwoer =  fightPwoer + data.zhandouli
        end
     end

     self._powerTxt:setString(Utils:getPowerStr(fightPwoer * 1.5))
     self._powerDes:removeAllItems()

     local medelValue = {}
     local zhandouli

     local attrTypeArr = {}
     local attrValueArr = {}
     for i = 1, #LRoleDataMgr.MedalList do
        local data = LRoleDataMgr.MedalList[i]
--只要获得就有加成
--        if data.ware == 1 then
            for j=1, 33 do
                local value = LDataConstMgr:GetMedalAttrValue(data.id, j)
                if value > 0 then
                    self:addMedalValue(j, value, medelValue)
                    table.insert(attrTypeArr, j)
                    table.insert(attrValueArr, value)
                end
            end
--        end
     end

     local zhandouli = LDataConstMgr:GetAttrPower(attrTypeArr, attrValueArr)
     self._powerTxt:setString(Utils:getPowerStr(zhandouli))

     table.sort(medelValue,function(a,b) return a.id < b.id end)

--     dump(medelValue, "updateMedalShow +++++++++++++")
     for i=1, #medelValue do
        local data = medelValue[i]
        local pItem = self._AttributeCell:clone()
        local valueStr = pItem:getChildByName("Value")
        Utils:ShowAttrLabelSec(pItem, data.id, valueStr, data.value)
        self._powerDes:pushBackCustomItem(pItem)
     end

end

function RoleTitleUI:findMadelInfo(type, madelList)
    -- body
    for i=1, #madelList do
        if madelList[i].id == type then
            return i
        end
    end
    return -1
end

--未获得的称号
function RoleTitleUI:initNotGainView()
    local tableView = cc.TableView:create(self._leftList2:getContentSize())
    --print("width = ".. self._leftList2:getContentSize().width .. "height = " .. self._leftList2:getContentSize().height);
    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self._leftViewList:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._leftList2:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched".. cell:getIdx())
        self:NotGainTitleTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._pCellNotGain:getContentSize().width
        local height = self._pCellNotGain:getContentSize().height
        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
        --print("cellSizeForTable idx = ".. idx )
        return self:NotGainTitleTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #self._showMedalList
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)

    self.m_pNotGainTitleTableView = tableView
end


--点击选中处理
function RoleTitleUI:NotGainTitleTableCellTouched(cell)
    
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)

    self._showBtn:setVisible(false)

    -- if self._lastChooseIndexNotGain == ind then
    --     return
    -- end

    local chooseBg = cellChild:getChildByName("ChooseBg")
    chooseBg:setVisible(true)

    if  self._lastChooseIndexNotGain >= 0 then
        local lastSelectCell  = self.m_pNotGainTitleTableView:cellAtIndex(self._lastChooseIndexNotGain);
        if lastSelectCell then
            local cellChildTemp = lastSelectCell:getChildByTag(123)
            if self._lastChooseIndexNotGain ~= ind then
                cellChildTemp:getChildByName("ChooseBg"):setVisible(false)
            end
        end
    end

    self._lastChooseIndexNotGain = ind
    self._notGainSelect = ind
    self:updateNotGainDetailUI(ind)

end 

function RoleTitleUI:NotGainTitleTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._pCellNotGain:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(cellChild:getContentSize().width / 2, cellChild:getContentSize().height / 2))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    --print("cell idx"..idx)
    self:NotGainShowTitleCellInfo(cellChild, idx)
    return cell
end

function RoleTitleUI:NotGainShowTitleCellInfo(cellChild, idx)
    --print("cell idx"..idx)
    if cellChild ~= nil then
        local chooseBg = cellChild:getChildByName("ChooseBg")
        
        if self._lastChooseIndexNotGain == idx then
            chooseBg:setVisible(true)
        else
            chooseBg:setVisible(false)
        end

        local data = self._showMedalList[idx + 1]
        local detail = LDataConstMgr:GetMedalNote(data.id)
        if detail ~= nil then
            local string = detail.name
            local name = cellChild:getChildByName("BtnName")

            local titleImage = cellChild:getChildByName("TitleImage")
            local strImage = "res/UI/cm_chenghao/chenghao".. data.id ..".png"
            local lastSprite = cellChild:getChildByTag(10087)
            if lastSprite then
                lastSprite:removeFromParent()
            end
            local sprite = Utils:CreateSpriteWithFrame(cellChild, titleImage, strImage)
            if sprite then
                sprite:setTag(10087)
            end

            local colIdx = LDataConstMgr:GetMedalColorIdx(idx + 1);
            local color = AppDef:GetPetQualityColor(colIdx)
            name:setTextColor(color)
            name:setString(string)
        end
    end
end

function RoleTitleUI:WearMedal(id, val)
--[[
	ObjScrollView *scrollView = (ObjScrollView*)this->getChildByTag(TAG_LIST_VIEW);
	if (ObjScrollCell *cellNode = (ObjScrollCell*)scrollView->getCellByIndex(_WearPos))
		cellNode->removeChildByTag(222);

	vector<MedalInfo>& medallist = DATA_MGR->Hero.MedalList;
	medallist[_WearPos].state = 0;
	for (int i = 0;i != medallist.size();i++)
	{
		if(id == medallist[i].id && medallist[i].state)
		{
			_WearPos = i;
			//TipsMgr::GetInstance()->SetCenterTip(CCSTR_FMT2("[c3]%s%s[/c3]",RES_STRC(DataConsts::RSI_HL_TIP4),DATA_CST->GetMedalNote(id, 0).c_str()));
			DATA_MGR->Hero.MyHeroInfo.MedalId = id;
			break;
		}
	}
	
    if(ark_hero *hero = (ark_hero *)this->getChildByTag(TAG_HERO_IMOD))
		hero->SetMedalType(id);

	ObjScrollCell *scrollNode = (ObjScrollCell*)scrollView->getCellByIndex(_WearPos);
	CCSprite *node = (CCSprite*)scrollView->getChildByTag(222);
	if(NULL != node)
		node->setPosition(ccp(40, -30));
	else
	{
		node = CCSprite::createWithSpriteFrameName("hm_show.mydp");
		node->setScale(0.8f);
		node->setPosition(ccp(40, -30));
		scrollNode->addChild(node, 100, 222);
	}
	if(val != 0)
	{
		ShowPdBtnState(STATE_PDBTN_XX);
	}
    else
    {
		ShowPdBtnState(STATE_PDBTN_PD);
		node->removeFromParent();
	}
]]
end

function RoleTitleUI:exitEvent( ... )
    -- body
    self.m_pUILayer = nil
    self._showList1 = nil
    self._showList2 = nil
    self._lastChooseIndex = nil
    self._lastChooseIndexNotGain = nil
    self._leftViewList = nil
    self._leftList1 = nil
    self._leftList1Height = nil
    self._leftList2 = nil
    self._Btn1 = nil
    self._ChooseBg1 = nil
    self._OpenImage1 = nil
    self._CloseImage1 = nil
    self._Btn2 = nil
    self._Btn2PosY = nil
    self._ChooseBg2 = nil
    self._OpenImage2 = nil
    self._CloseImage2 = nil
    self._pCell = nil
    self._pCellNotGain = nil
    self._titleSprite = nil
    self._baseBg = nil
    self._titleSpriteImage = nil
    self._roleAnim = nil
    self._attributeTxt1 = nil
    self._attributeTxt2 = nil
    self._attributeTxt3 = nil
    self._attributeTxt4 = nil
    self._getCondition = nil
    self._powerTxt = nil
    self._powerDes = nil
    self._AttributeCell = nil
    self._selectIndex = nil
    self._notGainSelect = nil
    self._ChallengeType = nil
end
return RoleTitleUI