--[[
lua里面的游戏逻辑控制
]]

local OtherRoleWingUI = LUIBase:New()
OtherRoleWingUI.__index = OtherRoleWingUI

function OtherRoleWingUI:New()
    local o = LUIBase:New()
    setmetatable(o,OtherRoleWingUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function OtherRoleWingUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
    }
    self:RegistSelf(self,self.msgIds)
end

function OtherRoleWingUI:ProcessEvent(msg)
end

function OtherRoleWingUI:Init()
    self:RegistMsgs()

    self.m_pUILayer = cc.CSLoader:createNode("csd/WingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData()
    self:AddTouchEvt()
    self:ShowAttrCellInfo()
end

function OtherRoleWingUI:onExit()
    self:Destory()
    --self.m_pButton = nil    
end

function OtherRoleWingUI:AddTouchEvt()
    local function QuestionCallBack()
        self:ShowHelp()
    end
    self.m_pHelpBtn:addClickEventListener(QuestionCallBack)
	self:MarkIntaractCObj(self.m_pHelpBtn)
end

function OtherRoleWingUI:InitData()
    self.m_wingUI = self.m_pUILayer:getChildByName("WingUI")
    self.m_panel = self.m_wingUI:getChildByName("Panel")
    self.m_panel0 = self.m_wingUI:getChildByName("Panel_0")
    self.m_pButton = self.m_panel0:getChildByName("Button") --卸下
    self.m_pButton:setVisible(false)
    self.m_pUseText = self.m_pButton:getChildByName("Text") --卸下文本
    local wingView = self.m_wingUI:getChildByName("List")
    self.m_pWingCell = self.m_wingUI:getChildByName("Item")
    self.m_pWingCell:getChildByName("Name"):getChildByName("State"):setVisible(false)
    self.m_selChooseInd = 255     -- 选中索引
    self.m_pRoleModel = nil
    self.m_pWingAni = self.m_panel:getChildByName("RolePoint")
    local data = LRoleDataMgr.MyHeroInfo
    self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
            data.professional,  data:GetWeaponId(), data.LightEffect,
            data.WingsId, data:GetHorseId(), data:GetShenQiId()) 
    self.m_pWingAni:addChild(self.m_pRoleModel)

    self.m_attrList = self.m_panel0:getChildByName("ListView")
    self.m_pAttrCell = self.m_panel0:getChildByName("Attribute")
    self.m_pAttrCell:setVisible(false)
    self.m_pHelpBtn = self.m_panel0:getChildByName("btn_Help")
    self.dis = 6

    self.m_pCurName = self.m_panel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pOldWay = self.m_panel:getChildByName("Condition")
    self.m_pWayFontSize = self.m_pOldWay:getFontSize()
    self.m_pGetWay = CCAysLabel:create() -- 创建一个带颜色的文本框
    self.m_pGetWay:setPosition(self.m_pOldWay:getPosition())  -- 位置设为原始位置
--    self.m_pGetWay:setPosition(self.m_pOldWay:getPosition())  -- 位置设为原始位置
--    self.m_pGetWay:setAnchorPoint(cc.p(0.5,0.5))
    --self.m_pOldWay:removeFromParent()       -- 删除老节点
    self.m_color = self.m_pCurName:getTextColor()
    self.m_pGetWay:setName("NewCondition")
    self.m_panel:addChild(self.m_pGetWay) -- 添加到父节点

    local OtInfo = LRoleDataMgr.OtherHeroInfo.ChiBangExInfo
    self.m_selWingInd = OtInfo.useIndex       -- 穿戴索引
    self.fightPower = self.m_panel0:getChildByName("Power"):getChildByName("Value") --总战力
    self.fightPower:setString(GUITips.Item_Power.." : ".. Utils:getPowerStr(OtInfo.fightPower))
    self.m_pCurAttrs = {}
    for i=1,6 do
        self.m_pCurAttrs[i] = self.m_panel:getChildByName("Attribute"..i)
        self.m_pCurAttrs[i]:getChildByName("Value"):setVisible(false)
        self.m_pCurAttrs[i]:setVisible(false)
    end

    self:InitWingTabView(wingView)
    -- self:InitAttrTabView(attrView)    
end

function OtherRoleWingUI:ShowSelectWingAttr(idx)
    local wv = LRoleDataMgr.OtherHeroInfo.MyChiBangVec[idx+1]
    local wing = LDataConstMgr:GetWingConfigData(wv[1])
    self.m_pCurName:setString(wing.name)
    self.m_pGetWay:removeAllChildren()
    
    self.m_pOldWay:setString(wing.desc)
    local width = self.m_pOldWay:getContentSize().width
    local height = self.m_pOldWay:getContentSize().height
    self.m_pGetWay:triggleInit(wing.desc , self.m_pOldWay:getContentSize() , -132 , self.m_color , self.m_pWayFontSize,
        false,0,0,0,true,false)
    local size = self.m_pGetWay:getSize()
    self.m_pGetWay:setPositionX(self.m_pOldWay:getPositionX() - size.width/2)
    self.m_pGetWay:setPositionY(self.m_pOldWay:getPositionY() + size.height/2)
    self.m_pOldWay:setVisible(false)

    self:ShowWingAttr(wing)
end

function OtherRoleWingUI:ShowWingAttr(wing)
    if wing == nil then
        return
    end
    local data = LRoleDataMgr.OtherHeroInfo
    if data.WingsId == wing.id then
        self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Hero,  
            data.professional, data:GetWeaponId(), data.LightEffect,
            wing.id, 0, 0)
    else
        self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Wing,  
            data.professional, data:GetWeaponId(), data.LightEffect,
            wing.id, 0, 0)
    end
    self.m_pRoleModel:PlayStand(0)

    for k,v in pairs(self.m_pCurAttrs) do
        local attr = wing.attrs[k]
        if attr == nil then
            v:setVisible(false)
        else
            local acfg = LDataConstMgr:GetAttrConfigData(tonumber(attr[1]))
            if acfg ~= nil then
                v:setVisible(true)
                v:setString(acfg.attrName.." : "..attr[2])
            end
        end
    end
end

-- 翅膀列表初始化
function OtherRoleWingUI:InitWingTabView(wingView)
    local tableView = cc.TableView:create(wingView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(wingView:getAnchorPoint())
    tableView:setPosition(wingView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    wingView:getParent():addChild(tableView)

    local function tableCellTouched(sender,cell)
        self:LeftTableCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pWingCell:getContentSize().width
        local height = self.m_pWingCell:getContentSize().height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:WingTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local wings = LRoleDataMgr.OtherHeroInfo.MyChiBangVec
        local wingCnt = #wings -- 最大坐骑数量
        return wingCnt
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pWingTableView = tableView
    -- 显示选中翅膀属性
    local touchInd
    if self.m_selWingInd == 255 then
        touchInd = 0
    else
        touchInd = self.m_selWingInd
    end
    local cell = self.m_pWingTableView:cellAtIndex(touchInd)
    self:LeftTableCellTouched(cell)
end

function OtherRoleWingUI:ShowWingCommonCellInfo(cell, idx)
    local wv = LRoleDataMgr.OtherHeroInfo.MyChiBangVec[idx+1]
    local wing = LDataConstMgr:GetWingConfigData(wv[1])
    local OtInfo = LRoleDataMgr.OtherHeroInfo.ChiBangExInfo
    local text = cell:getChildByName("Name")
    local name = "No."..idx
    local icon =  string.format(AppDef.GUIRes.Res_Wing_File_Path, wing.id)
    cell:getChildByName("Icon"):loadTexture(icon)
    cell:getChildByName("Icon"):setTextureRect(cc.rect(0,0,211,105))
    cell:getChildByName("Icon"):setTextureRect(cc.rect(0,0,211,105))
    text:setString(wing.name)
    if OtInfo.useIndex == idx then
        cell:getChildByName("DressState"):setVisible(true)
    else
        cell:getChildByName("DressState"):setVisible(false)
    end
    if self.m_selChooseInd == idx then
        cell:getChildByName("Choose"):setVisible(true)
    else
        cell:getChildByName("Choose"):setVisible(false)
    end
end

function OtherRoleWingUI:WingTableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pWingCell:clone()
        
        local width = self.m_pWingCell:getContentSize().width
        local height = self.m_pWingCell:getContentSize().height
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(width/2,height/2))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end

    self:ShowWingCommonCellInfo(cellChild, idx)
    return cell
end

--选择翅膀
function OtherRoleWingUI:LeftTableCellTouched(cell)
    local ind
    if cell ~= nil then
        ind = cell:getIdx()
        if self.m_selChooseInd == ind then
            return
        end
        local cellChild = cell:getChildByTag(123)
        local oldCell = self.m_pWingTableView:cellAtIndex(self.m_selChooseInd)
        if oldCell ~= nil then
            local oldCellChild = oldCell:getChildByTag(123)
            if oldCellChild ~= nli then
                oldCellChild:getChildByName("Choose"):setVisible(false)
            end
        end
        cellChild:getChildByName("Choose"):setVisible(true)
    else
        ind = self.m_selWingInd
    end
    self.m_selChooseInd = ind
    self:ShowSelectWingAttr(ind)
end

function OtherRoleWingUI:ShowAttrCellInfo()
    self.m_attrList:removeAllItems()
    local OtInfo = LRoleDataMgr.OtherHeroInfo.ChiBangExInfo
    for k,v in pairs(OtInfo.attrs) do
        if tonumber(v[2]) ~= 0  then
            local cell = self.m_pAttrCell:clone()
            local acfg = LDataConstMgr:GetAttrConfigData(tonumber(v[1]))
            local value = cell:getChildByName("Value")
            Utils:ShowAttrLabelSec(cell, tonumber(v[1]), value, tonumber(v[2]))
            cell:setVisible(true)
            self.m_attrList:pushBackCustomItem(cell)
        end
    end
end

function OtherRoleWingUI:ShowHelp()
    local function closeMsgBox()
    end
    local userData =
    {
        loseCallback = closeMsgBox,
        okCallback = closeMsgBox,
        title = GUITips.RSI_WELFARE_MSG38,
        desc = GUITips.RSI_Help_Str1
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.PopWindow, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

return OtherRoleWingUI