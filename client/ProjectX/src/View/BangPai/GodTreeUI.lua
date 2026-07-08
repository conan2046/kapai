local GodTreeUI = LUIBase:New()
GodTreeUI.__index = GodTreeUI

-----------------------------------
function GodTreeUI:New()
    local o = {}
    setmetatable(o, GodTreeUI)
    o:Init()
    return o
end

-----------------------------------
function GodTreeUI:Init()
    self.Script = "BangPai.GodTreeUI"
    self._TreeInfo = nil

    self.m_pRipeTime = nil
    self.m_pEXPNum = nil
    self.m_pExpText = nil
    self.m_pExpProg = nil
    self.m_pRobTime = nil
    self.m_pRobbedExp = nil
    self.m_pLeftYBPrayTimes = nil
    self.m_pLeftNormalPrayTimes = nil

    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_datas = nil
    self.m_selectIndex = -100

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:RegisterQuik()
end

-----------------------------------
function GodTreeUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script = nil
    self._TreeInfo = nil

    self.m_pRipeTime = nil
    self.m_pEXPNum = nil
    self.m_pExpText = nil
    self.m_pExpProg = nil
    self.m_pRobTime = nil
    self.m_pRobbedExp = nil
    self.m_pLeftYBPrayTimes = nil
    self.m_pLeftNormalPrayTimes = nil

    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_datas = nil
    self.m_selectIndex = nil
end

-----------------------------------
function GodTreeUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")

    local pMessageBg = pPanel:getChildByName("MessageBg")
    local pMessage1 = pMessageBg:getChildByName("Message1")
    local pEXPBg1 = pMessage1:getChildByName("EXPBg1")
    self.m_pEXPNum = pEXPBg1:getChildByName("Num")

    local pRipeTime = pMessage1:getChildByName("RipeTime")
    self.m_pRipeTime = pRipeTime:getChildByName("Time")

    local pEXPBg2 = pMessage1:getChildByName("EXPBg2")
    self.m_pExpProg = pEXPBg2:getChildByName("LoadingBar")
    self.m_pExpText = pEXPBg2:getChildByName("Time")

    local pMessage2 = pMessageBg:getChildByName("Message2")
    local pRobTime = pMessage2:getChildByName("RobTime")
    self.m_pRobTime = pRobTime:getChildByName("Time")

    local pRobEXP = pMessage2:getChildByName("RobEXP")
    self.m_pRobbedExp = pRobEXP:getChildByName("Time")

    local pBtnBg = pMessageBg:getChildByName("BtnBg")
    local pText1 = pBtnBg:getChildByName("Text1")
    self.m_pLeftYBPrayTimes = pText1:getChildByName("Num")

    local pText2 = pBtnBg:getChildByName("Text2")
    self.m_pLeftNormalPrayTimes = pText2:getChildByName("Num")

    local pButton1 = pBtnBg:getChildByName("Button1")
    pButton1:addClickEventListener(function(sender)
        self:ybPray()
    end)
	self:MarkIntaractCObj(pButton1)
    local pButton2 = pBtnBg:getChildByName("Button2")
    pButton2:addClickEventListener(function(sender)
        self:nomalPray()
    end)
	self:MarkIntaractCObj(pButton2)
    local pTreeBg = pPanel:getChildByName("TreeBg")
    local pDecBg = pTreeBg:getChildByName("DecBg")
    local pViewBg = pDecBg:getChildByName("ViewBg")
    local pList = pDecBg:getChildByName("List")
    local pDecRow = pList:getChildByName("DecRow")
    pDecRow:setVisible(false)

    self.m_pGridCell = pDecRow
    self.m_pTableView = self:InitTableView(pList)
end


function GodTreeUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local size = self.m_pGridCell:getContentSize()
        return size.width, size.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view) end
    cfg.tableCellTouched = function(sender, cell) end

    return Utils:createTableView(cfg)
end

function GodTreeUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)

        local pText = cellChild:getChildByName("Text")
        local anchor = pText:getAnchorPoint()
        local pos = cc.p(pText:getPosition())

        self.m_textSize = pText:getContentSize()

        local fontSize = pText:getFontSize()
        local fontColor = pText:getTextColor()

        local pAysLabel = CCAysLabel:createWithFixedWidth(self.m_textSize.width, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
        pAysLabel:setPosition(cc.p(pos.x-anchor.x*self.m_textSize.width, pos.y+(1-anchor.y)*self.m_textSize.height))
        pAysLabel:setName(pText:getName())

        pText:getParent():addChild(pAysLabel)
        pText:removeFromParent()
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx)
    end
    return cell
end

function GodTreeUI:updateItem(cell, info, idx)
    local pText = cell:getChildByName("Text")
    pText:setString(info)
end

-----------------------------------
function GodTreeUI:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.ReloadGodTreeInfo,
    }
    self:RegistSelf(self, self.msgIds)
end

-----------------------------------
function GodTreeUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.ReloadGodTreeInfo then
        self:LoadData(msg.value)
    end
end

function GodTreeUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-----------------------------------
function GodTreeUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/GodTreeLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- ----------------------------------
function GodTreeUI:RegisterQuik()
    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_BP_TIP4)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)
end

function GodTreeUI:LoadData(info)
    self._TreeInfo = info
    self.m_pRipeTime:setString(info.RipeTimeString)
    self.m_pEXPNum:setString(tostring(info.PrayExp))

    local curExp = info.TreeExp
    local maxExp = info.MaxTreeExp
    self.m_pExpText:setString(string.format("%d/%d", curExp, maxExp))

    local ratio = math.min(math.max(curExp/maxExp, 0), 1) * 100
    self.m_pExpProg:setPercent(ratio)

    self.m_pRobTime:setString(info.RobTimeString)
    self.m_pRobbedExp:setString(tostring(info.RobbedExp))
    self.m_pLeftYBPrayTimes:setString(tostring(info.LeftYBPrayTimes))
    self.m_pLeftNormalPrayTimes:setString(tostring(info.LeftNormalPrayTimes))

    self.m_datas = self._TreeInfo.VecLog
    self.m_tableCount = #self.m_datas
    if self.m_pTableView ~= nil then 
        self.m_pTableView:reloadData()
    end
end

function GodTreeUI:ybPray()
    if self._TreeInfo.LeftYBPrayTimes <= 0 then
        Utils:ShowScrollTips(GUITips.RSI_BP_TIP33)
        return
    end

    if not LRoleDataMgr.isNextTimeRemond[AppDef.Remond.PrayGodTree] then
        local str = string.format("%s[c3]%d[/c3]%s", GUITips.RSI_BP_TIP10, self._TreeInfo.PrayCost, GUITips.RSI_BP_TIP11)
        local function OKCallback()
            self:PrayGodTree()
        end
        local function CancelCallback()
        end
        local function checkBoxCallback(isSelected)
            LRoleDataMgr.isNextTimeRemond[AppDef.Remond.PrayGodTree] = isSelected
        end
        local msgData = {
            okCallback = OKCallback,
            cancelCallback = CancelCallback,
            checkBoxCallback = checkBoxCallback,
            desc = str,
        }
        Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, msgData)
        return
    end
    self:PrayGodTree()
end

function GodTreeUI:nomalPray()
    LuaNetSendMsg:QueryFactionGodTreePray(LRoleDataMgr.Faction:GetPlantFactionId(), 1)
end

function GodTreeUI:PrayGodTree()
    LuaNetSendMsg:QueryFactionGodTreePray(LRoleDataMgr.Faction:GetPlantFactionId(), 2)
end

return GodTreeUI