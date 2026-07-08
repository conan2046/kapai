--[[
lua里面的游戏逻辑控制
]]

local WingAttrUI = LUIBase:New()
WingAttrUI.__index = WingAttrUI

function WingAttrUI:New()
    local o = LUIBase:New()
    setmetatable(o,WingAttrUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function WingAttrUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWingDataEvent.SetWingState,
        LUIWingDataEvent.UpgradWing,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function WingAttrUI:ProcessEvent(msg)
    if msg.msgId == LUIWingDataEvent.SetWingState then
        -- dump({self.m_pUseIdModel:Get(), msg.value, 0xff}, "msg.value-->")
        self.m_pUseIdModel:Set(msg.value)
        if msg.value ~= 0xff then
            -- dump(msg.value, "msg.valuemsg.valuemsg.valuemsg.value-->")
            if self.m_pChooseIdModel:Get() == msg.value then
                local ind = self:GetIdx(msg.value)
                self.m_pChooseIndModel:Set(ind)
            else
                self.m_pChooseIdModel:Set(msg.value)
            end
            Utils:MoveToTableIdx(self.m_pWingTableView, self.m_pWingCell, self.m_pChooseIndModel:Get())
        end
    elseif msg.msgId == LUIWingDataEvent.UpgradWing then
        self:RefreshWingsInfo()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    end
end

function WingAttrUI:Init()
    self.m_pChooseIndModel = BaseModel:New(nil, handler(self, WingAttrUI.UpdateChooseInd))
    self.m_pUseIndModel = BaseModel:New(nil, handler(self, WingAttrUI.UpdateUseInd))
    self.m_pChooseIdModel = BaseModel:New(nil, handler(self, WingAttrUI.UpdateChooseId))
    self.m_pUseIdModel = BaseModel:New(nil, handler(self, WingAttrUI.UpdateUseId))
    -----------------------------------
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

function WingAttrUI:onExit()
    self:Destory()
    --self.m_pButton = nil    
end

function WingAttrUI:GetIdx(id)
    for k,v in pairs(LRoleDataMgr.MyHeroInfo.MyChiBangVec) do
        if v[1] == id then
            return k - 1
        end
    end
    return 0
end

function WingAttrUI:AddTouchEvt()
    local function UseCallback(sender)
        local wv = LRoleDataMgr.MyHeroInfo.MyChiBangVec[self.m_pChooseIndModel:Get() + 1]
        if wv ~= nil and wv[2] then
            dump({self.m_pUseIdModel:Get() , self.m_pChooseIdModel:Get()})
            if self.m_pUseIdModel:Get() == self.m_pChooseIdModel:Get() then -- 脱下
                LuaNetSendMsg:QueryChiBangInfo(3, 0xff)
            else
                LuaNetSendMsg:QueryChiBangInfo(3, self.m_pChooseIdModel:Get())
            end
        else
            LuaNetSendMsg:QueryChiBangInfo(5, self.m_pChooseIdModel:Get())
        end
    end
    self.m_pButton:addClickEventListener(UseCallback)
	self:MarkIntaractCObj(self.m_pButton)
    local function QuestionCallBack()
        self:ShowHelp()
    end
    self.m_pHelpBtn:addClickEventListener(QuestionCallBack)
	self:MarkIntaractCObj(self.m_pHelpBtn)
end

function WingAttrUI:InitData()
    self.m_wingUI = self.m_pUILayer:getChildByName("WingUI")
    self.m_panel = self.m_wingUI:getChildByName("Panel")
    self.m_panel0 = self.m_wingUI:getChildByName("Panel_0")
    self.m_pButton = self.m_panel0:getChildByName("Button") --卸下
    self.m_pUseText = self.m_pButton:getChildByName("Text") --卸下文本
    self.m_pRedDot = self.m_pButton:getChildByName("RedDot") --红点
    self.m_pWingCell = self.m_wingUI:getChildByName("Item")
    self.m_pRoleModel = nil
    self.m_pWingAni = self.m_panel:getChildByName("RolePoint")
    local data = LRoleDataMgr.MyHeroInfo
    self.m_pRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
            data.professional, data:GetWeaponId(), data.LightEffect,
            data.WingsId, data:GetHorseId(), data:GetShenQiId()) 
    self.m_pWingAni:addChild(self.m_pRoleModel)

    self.m_attrList = self.m_panel0:getChildByName("ListView")
    self.m_pAttrCell = self.m_panel0:getChildByName("Attribute")
    self.m_pHelpBtn = self.m_panel0:getChildByName("btn_Help")
    self.dis = 6

    self.m_pCurName = self.m_panel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pOldWay = self.m_panel:getChildByName("Condition")
    self.m_pWayFontSize = self.m_pOldWay:getFontSize()
    self.m_pGetWay = CCAysLabel:create() -- 创建一个带颜色的文本框
    self.m_pGetWay:setPosition(self.m_pOldWay:getPosition())  -- 位置设为原始位置
    self.m_color = self.m_pCurName:getTextColor()
    self.m_pGetWay:setName("NewCondition")
    self.m_panel:addChild(self.m_pGetWay) -- 添加到父节点

    local OtInfo = LRoleDataMgr.MyHeroInfo:GetChiBangOtherInfo()
    self.fightPower = self.m_panel0:getChildByName("Power"):getChildByName("Value") --总战力
    self.fightPower:setString(Utils:getPowerStr(OtInfo.fightPower))
    self.m_pCurAttrs = {}
    for i=1, 6 do
        self.m_pCurAttrs[i] = self.m_panel:getChildByName("Attribute"..i)
        self.m_pCurAttrs[i]:setVisible(false)
        self.m_pCurAttrs[i]:getChildByName("Value"):setVisible(false)
    end

    local wingView = self.m_wingUI:getChildByName("List")
    self:InitWingTabView(wingView)
    
    -- 显示选中翅膀属性
    self.m_pChooseIdModel:Set(OtInfo.useIndex)
    self.m_pUseIdModel:Set(OtInfo.useIndex)
    if self.m_pUseIndModel:Get() ~= BaseModel.InValid then
        Utils:MoveToTableIdx(self.m_pWingTableView, self.m_pWingCell, self.m_pUseIndModel:Get())
    end
end

function WingAttrUI:UpdateButton(idx)
    local wv = LRoleDataMgr.MyHeroInfo.MyChiBangVec[idx + 1]
    if wv == nil then
        return
    end
    -- dump({idx, wv}, "UpdateButton-->")
    if not wv[2] then    -- 激活
        self.m_pUseText:setString(GUITips.UI_Shenqi_Active)
        self.m_pRedDot:setVisible(Utils:GetRedDotState(RedDotDef.ID.YuYiXXBase+wv[1]))
    else
        self.m_pRedDot:setVisible(false)
        if self.m_pUseIdModel:Get() == wv[1] then
            self.m_pUseText:setString(GUITips.UI_Btn_Equip_PutOff)
        else
            self.m_pUseText:setString(GUITips.UI_Btn_Equip_PutOn)
        end
    end
end

function WingAttrUI:ShowSelectWingAttr(idx)
    local wv = LRoleDataMgr.MyHeroInfo.MyChiBangVec[idx + 1]
    if wv == nil then
        return
    end
    local wing = LDataConstMgr:GetWingConfigData(wv[1])
    self.m_pCurName:setString(wing.name)
    self.m_pGetWay:removeAllChildren()
    
    self.m_pOldWay:setString(wing.desc)
    self.m_pGetWay:triggleInit(wing.desc , self.m_pOldWay:getContentSize() , -132 , self.m_color , self.m_pWayFontSize,
        false,0,0,0,true,false)
    local size = self.m_pGetWay:getSize()
    self.m_pGetWay:setPositionX(self.m_pOldWay:getPositionX() - size.width/2)
    self.m_pGetWay:setPositionY(self.m_pOldWay:getPositionY() + size.height/2)
    self.m_pOldWay:setVisible(false)

    self:ShowWingAttr(wing)

    self:UpdateButton(idx)
end

function WingAttrUI:ShowWingAttr(wing)
    if wing == nil then
        return
    end
    local data = LRoleDataMgr.MyHeroInfo
    -- dump({self.m_pUseIdModel:Get() , wing.id}, "ShowWingAttr-->")
    if self.m_pUseIdModel:Get() == wing.id then
        self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Hero,  
            data.professional, 1, data.LightEffect,
            self.m_pUseIdModel:Get(), 0, 0)
    else
        self.m_pRoleModel:InitAni(AppDef.CEnum.ModelAniType.Wing,  
            data.professional, 1, data.LightEffect,
            wing.id, 0, 0)
        self.m_pRoleModel:setPositionY(-30)
    end
    self.m_pRoleModel:PlayStand(0)

    for k,v in pairs(self.m_pCurAttrs) do
        local attr = wing.attrs[k]
        if attr == nil then
            v:setVisible(false)
        else
            local type = tonumber(attr[1])
            local acfg = LDataConstMgr:GetAttrConfigData(type)
            if acfg ~= nil then
                v:setVisible(true)
                if type > AppDef.EAttrType.EAT_RESISIT_CRIT then
                    v:setString(acfg.attrName.." : "..string.format("%.2f",attr[2]/100).."%")
                else
                    v:setString(acfg.attrName.." : "..attr[2])
                end
            end
        end
    end
end

-- 翅膀列表初始化
function WingAttrUI:InitWingTabView(wingView)
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
        local size = self.m_pWingCell:getContentSize()
        return size.width, size.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:WingTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #LRoleDataMgr.MyHeroInfo.MyChiBangVec
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    self.m_pWingTableView = tableView

    tableView:reloadData()
end

function WingAttrUI:ShowWingCommonCellInfo(cellChild, idx)
    self:ShowWingCellInfo(cellChild, LRoleDataMgr.MyHeroInfo.MyChiBangVec[idx+1])
end

function WingAttrUI:WingTableCellAtIndex(sender, idx)
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

function WingAttrUI:ShowWingCellRedDot(cell, isShow)
    if cell == nil then
        return
    end
    local pRedDot = cell:getChildByName("RedDot")
    if pRedDot then
        pRedDot:setVisible(isShow)
    end
end

function WingAttrUI:UpdateChooseState(cell, wv, ind)
    if ind and self.m_pWingTableView ~= nil then
        local pCell = self.m_pWingTableView:cellAtIndex(ind)
        if pCell == nil then
            return
        end
        cell = pCell:getChildByTag(123)
    end
    if cell == nil then
        return
    end
    cell:getChildByName("Choose"):setVisible(self.m_pChooseIdModel:Get() == wv[1])
end

function WingAttrUI:UpdateDressState(cell, wv, ind)
    if ind and self.m_pWingTableView ~= nil then
        local pCell = self.m_pWingTableView:cellAtIndex(ind)
        if pCell == nil then
            return
        end
        cell = pCell:getChildByTag(123)
    end
    if cell == nil or wv == nil then
        return
    end
    cell:getChildByName("DressState"):setVisible(self.m_pUseIdModel:Get() == wv[1])
end

function WingAttrUI:ShowWingCellInfo(cell, wv)
    local wing = LDataConstMgr:GetWingConfigData(wv[1])
    
    local icon = nil
    if wv[2] then
       icon =  string.format(AppDef.GUIRes.Res_Wing_File_Path, wing.id)
    else
       icon =  string.format(AppDef.GUIRes.Res_Wing_File_Un_Path, wing.id)
    end
    if icon ~= nil then
        cell:getChildByName("Icon"):loadTexture(icon)
        cell:getChildByName("Icon"):setTextureRect(cc.rect(0,0,211,105))
        cell:getChildByName("Icon"):setTextureRect(cc.rect(0,0,211,105))
    end

    local text = cell:getChildByName("Name")
    text:setString(wing.name)

    if wv[2] then
        text:getChildByName("State"):setVisible(false)
    else
        text:getChildByName("State"):setVisible(true)
        text:getChildByName("State"):setPosition(cc.p(text:getContentSize().width, text:getContentSize().height/2))
    end

    self:UpdateDressState(cell, wv, ind)
    self:UpdateChooseState(cell, wv, ind)

    self:ShowWingCellRedDot(cell, Utils:GetRedDotState(RedDotDef.ID.YuYiXXBase+wv[1]))
end

--选择翅膀
function WingAttrUI:LeftTableCellTouched(cell)
    if cell ~= nil then
        self.m_pChooseIndModel:Set(cell:getIdx())
    end
end

function WingAttrUI:RefreshWingsInfo()
    self:ShowAttrCellInfo()
    for k,v in pairs(LRoleDataMgr.MyHeroInfo.MyChiBangVec) do
        local cell = self.m_pWingTableView:cellAtIndex(k - 1)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            self:ShowWingCellInfo(cellChild, v)
        end
    end
end

function WingAttrUI:ShowAttrCellInfo()
    self.m_attrList:removeAllItems()
    local OtInfo = LRoleDataMgr.MyHeroInfo.ChiBangExInfo
    for k,v in pairs(OtInfo.attrs) do
        if tonumber(v[2]) ~= 0  then
            local cell = self.m_pAttrCell:clone()
            local value = cell:getChildByName("Value")
            local k = tonumber(v[1])
            local acfg = LDataConstMgr:GetAttrConfigData(k)
            Utils:ShowAttrLabelSec(cell, k, value, v[2])
            cell:setVisible(true)
            self.m_attrList:pushBackCustomItem(cell)
        end
    end
end

function WingAttrUI:ShowHelp()
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

function WingAttrUI:DealUpdateRedDotState(data)
    if data == nil or data.id == nil then
        return
    end
    local wid = data.id - RedDotDef.ID.YuYiXXBase
    for k,v in pairs(LRoleDataMgr.MyHeroInfo.MyChiBangVec) do
        if v and #v > 0 and v[1] == wid then
            local cell = self.m_pWingTableView:cellAtIndex(k - 1)
            if cell ~= nil then
                local cellChild = cell:getChildByTag(123)
                self:ShowWingCellRedDot(cellChild, data.isShow)
            end
            break
        end
    end
    if self.m_pChooseIdModel:Get() == wid then
        self.m_pRedDot:setVisible(Utils:GetRedDotState(data.isShow))
    end
end

function WingAttrUI:UpdateChooseInd(new, old)
    if new == nil then
        return
    end
    -- dump({new, old}, "UpdateChooseInd--->")
    if LRoleDataMgr.MyHeroInfo.MyChiBangVec[new + 1] then
        local id = LRoleDataMgr.MyHeroInfo.MyChiBangVec[new + 1][1]
        if id then
            self.m_pChooseIdModel:Set(id)
        end
    end

    if old then
        local pCell = self.m_pWingTableView:cellAtIndex(old)
        if pCell then
            self:ShowWingCommonCellInfo(pCell:getChildByTag(123), old)
        end
    end
    local pCell = self.m_pWingTableView:cellAtIndex(new)
    if pCell then
        self:ShowWingCommonCellInfo(pCell:getChildByTag(123), new)
    end
    self:ShowSelectWingAttr(new)
    self:UpdateButton(self.m_pChooseIndModel:Get())
end

function WingAttrUI:UpdateChooseId(new, old)
    if new == nil then
        return
    end
    -- dump({new, old}, "UpdateChooseId--->")
    local ind = self:GetIdx(new)
    if ind >= 0 then
        self.m_pChooseIndModel:Set(ind)
    end
end

function WingAttrUI:UpdateUseInd(new, old)
    if new == nil then
        return
    end
    -- dump({new, old}, "UpdateUseInd--->")
    if old and old ~= BaseModel.InValid then
        local wv = LRoleDataMgr.MyHeroInfo.MyChiBangVec[old + 1]
        self:UpdateDressState(nil, wv, old)
    end
    if new ~= BaseModel.InValid then
        local wv = LRoleDataMgr.MyHeroInfo.MyChiBangVec[new + 1]
        self:UpdateDressState(nil, wv, new)
    end

    if new == self.m_pChooseIndModel:Get() or new == BaseModel.InValid then
        self:ShowSelectWingAttr(self.m_pChooseIndModel:Get())
    end
    self:UpdateButton(self.m_pChooseIndModel:Get())
end

function WingAttrUI:UpdateUseId(new, old)
    if new == nil then
        return
    end
    -- dump({new, old}, "UpdateUseId--->")
    if new == 0xff then
        self.m_pUseIndModel:Set(BaseModel.InValid)
        return
    end
    local ind = self:GetIdx(new)
    if ind >= 0 then
        self.m_pUseIndModel:Set(ind)
    end
end

return WingAttrUI