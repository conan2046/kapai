
local BangPaiKeji = LUIBase:New()
BangPaiKeji.__index = BangPaiKeji
--local this = LTcpSocket
    
local CountOfColumn = 2

function BangPaiKeji:New()
	local o = {}
	setmetatable(o,BangPaiKeji)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function BangPaiKeji:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiWarEvent.UpdateBpKejiUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BangPaiKeji:ProcessEvent(msg)
    print("ProcessEvent msg.msgId ===>", msg.msgId, LUIBangPaiWarEvent.UpdateBpKejiUI)
    if msg.msgId == LUIBangPaiWarEvent.UpdateBpKejiUI then
        self:loadData()
        self:updateUI()
    end
end

function BangPaiKeji:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildKejiLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    --Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback, handler(self, self.RemoveUI))

    local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "BangPai.BangPaiKeji")
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.RSI_BP_KJ_TIP1)
    Utils:SendMsg(LUIFClassBgEvent.AddTabBtn, nil)

    self:initUIControl()
    self._inited = false
    self:loadData()
    self:updateUI()
end

function BangPaiKeji:initUIControl( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
    local keji = panel:getChildByName("Keji")
    -----------------------------------------------------------
    local title = keji:getChildByName("Title")

    local infomation1 = title:getChildByName("Information1")
    local name1 = infomation1:getChildByName("Name")
    self._bpLevel = name1:getChildByName("Text")
    
    local infomation5 = title:getChildByName("Information5")
    local name5 = infomation5:getChildByName("Name")
    self._bpMoney = name5:getChildByName("Text")
    local infomation4 = title:getChildByName("Information4")
    local name4 = infomation4:getChildByName("Name")
    self._bpBangGong = name4:getChildByName("Text")

    local helpBtn = title:getChildByName("HelpBtn")
    helpBtn:addClickEventListener(function ( sender )
        -- body
        local function OnOk()
            -- print("HelpBtn $$$$$$$$$$$$$")
            -- Utils:SendMsg(LUIBangPaiWarEvent.UpdateBpKejiUI)
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_Help_Str14, OnOk)
    end)

    -------------------------------------------------------------
    local Bg = keji:getChildByName("Bg")
    local listView = Bg:getChildByName("List")
    self.m_pGridCell = listView:getChildByName("Item")
    
    self.m_pGridCell:removeFromParent()
    self.m_pGridCell:retain()

    local pWhisperBtn = self.m_pGridCell:getChildByName("WhisperBtn")
    local pGetBtn = pWhisperBtn:getChildByName("GetBtn")
    self.m_buttonSize = pGetBtn:getContentSize()
    self._tableView = self:InitTableView(listView)

end

function BangPaiKeji:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    return Utils:createTableView(cfg)
end

function BangPaiKeji:TableCellAtIndex(sender, idx)
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

        local pWhisperBtn = cellChild:getChildByName("WhisperBtn")
        pWhisperBtn:setSwallowTouches(false)
        local pWhisperBtn1 = cellChild:getChildByName("WhisperBtn1")
        pWhisperBtn1:setSwallowTouches(false)
        pWhisperBtn:addClickEventListener(handler(self, BangPaiKeji.ClickItem))
        self:MarkIntaractCObj(pWhisperBtn)
        pWhisperBtn1:addClickEventListener(handler(self, BangPaiKeji.ClickItem))
        self:MarkIntaractCObj(pWhisperBtn1)

        local pGetBtn = pWhisperBtn:getChildByName("GetBtn")
        pGetBtn:ignoreContentAdaptWithSize(false)
        pGetBtn:setContentSize(self.m_buttonSize)

        pGetBtn:addClickEventListener(handler(self, BangPaiKeji.enterActClick))
        self:MarkIntaractCObj(pGetBtn)
        local pGetBtn1 = pWhisperBtn1:getChildByName("GetBtn")
        pGetBtn1:ignoreContentAdaptWithSize(false)
        pGetBtn1:setContentSize(self.m_buttonSize)
        pGetBtn1:addClickEventListener(handler(self, BangPaiKeji.enterActClick))
        self:MarkIntaractCObj(pGetBtn1)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        local pWhisperBtn = cellChild:getChildByName("WhisperBtn")
        local pWhisperBtn1 = cellChild:getChildByName("WhisperBtn1")
        local index = idx * CountOfColumn + 1
        self:updateItem(pWhisperBtn, self.m_datas[index], index)
        self:updateItem(pWhisperBtn1, self.m_datas[index+1], index+1)
    end
    return cell
end

function BangPaiKeji:updateItem(cell, linfo, idx)
    if idx > #self.m_datas or linfo == nil then
        cell:setVisible(false)
        return
    end
    cell:setVisible(true)
    cell:setTag(idx)

    

    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(self.m_selectIndex == idx)

    local pGetBtn = cell:getChildByName("GetBtn")
    local missionType = linfo.buffType          --任务类型
    pGetBtn:setTag(missionType)
    pGetBtn.userObject = linfo

    local redDot = pGetBtn:getChildByName("RedImage")
    redDot:setVisible(false)

    if linfo.level < LRoleDataMgr.Faction.Info.level then
        if linfo.effectType > 0 then
            if linfo.BpCost.id == AppDef.AwrdItem.AWRD_ITEM_BPMONEY then
                if tonumber(linfo.BpCost.num)  <= LRoleDataMgr.Faction.Info.bpMoney then
                    redDot:setVisible(true)
                    self._isHasRedDot = true
                end
            end
        else
            if tonumber(linfo.cost)  <= LRoleDataMgr.Faction.Info.bpMoney then
                redDot:setVisible(true)
                self._isHasRedDot = true
            end
        end
    end

    local pIconBg = cell:getChildByName("IconBg")
    local pIcon = pIconBg:getChildByName("Icon")
    pIcon:setPosition(cc.p(pIconBg:getContentSize().width / 2, pIconBg:getContentSize().height / 2))

    local iconPath
    if linfo.pic == nil or #linfo.pic < 1 then
        iconPath = "res/res2/Icon/ui_bangpai_icon/bg_101.png"
    else
        iconPath = "res/res2/Icon/ui_bangpai_icon/"..linfo.pic..".png"
    end
    
    pIcon:loadTexture(iconPath, UI_TEX_TYPE_LOCAL)

    -- ------------------------------------------------
    local pName = cell:getChildByName("Name")
    pName:setString(linfo.name)
    ------------------------------------------------
    local pTimes = pName:getChildByName("Times")
    pTimes:setString(string.format("(Lv%d)", linfo.level))
    
    local pConsume = cell:getChildByName("Consume")
    local pValue = pConsume:getChildByName("Text")
    if linfo.effectType > 0 then
        pValue:setString(linfo.BpCost.num)
    else
        pValue:setString(linfo.cost)
    end

    local newDes = cell:getChildByTag(10087)
    if newDes ~= nil then
        newDes:removeFromParent()
    end

    local Des = cell:getChildByName("Des")
    local desColor1 = Utils:CreateColorText3(Des, false)
    desColor1:setName("NewDes")
    desColor1:setTag(10087)
    desColor1:setString(GUITips.RSI_BP_DES_TIPS3..linfo.des)
    desColor1:setVisible(true)

end

function BangPaiKeji:ClickItem( sender )
    -- body
    if sender == nil or self.m_isDragging then
        return
    end
    self.m_selectIndex = index
end

function BangPaiKeji:enterActClick( sender )
    -- body

    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end

    if sender == nil or self.m_isDragging then
        return
    end
    
    local data = sender.userObject
    --dump(data, "ClickItem ===========>")
    if data.effectType > 0 then
        LuaNetSendMsg:QueryBpSkilllevelUp(45, 2, data.buffType, 0)
    else
        local type = sender:getTag()
        --print("type ==========,", type)
        LuaNetSendMsg:QuerylevelUpKeji(43, type)
    end
end

function BangPaiKeji:loadData( ... )
    -- body
    self.m_datas = {}
    --dump(LRoleDataMgr.Faction.Info.kejiInfo, "sel Data ===========>")
    for i=1, #LRoleDataMgr.Faction.Info.kejiInfo do
        local data = LRoleDataMgr.Faction.Info.kejiInfo[i]
        -- print("loadData ===", data.buffLevel, data.buffType)
        local attrData = LDataConstMgr:getBpKejiDataByLevel(data.buffLevel, data.buffType)
        if attrData ~= nil and attrData.isShow then
            table.insert(self.m_datas, attrData)
        end
    end
    
    self.m_tableCount = math.ceil(#self.m_datas / CountOfColumn)
    -- print("loadData ============", self.m_tableCount, LRoleDataMgr.Faction.Info.level)
    self.m_selectIndex = 0
    self._isHasRedDot = false
end

function BangPaiKeji:updateUI()
    -- body
    self._bpLevel:setString(LRoleDataMgr.Faction.Info.level)
    self._bpMoney:setString(LRoleDataMgr.Faction.Info.bpMoney)
    self._bpBangGong:setString(LRoleDataMgr.Faction.Info.selfBangGong)
    local offset = self._tableView:getContentOffset()
    --print("updateUI =====>" ,offset.x, offset.y)
    self._tableView:reloadData()
    if self._inited then
        self._tableView:setContentOffset(offset)
    end
    --小红点检测
    local curRed = Utils:GetRedDotState(RedDotDef.ID.BPKeji)
    if curRed ~= self._isHasRedDot then
        Utils:SetRedDotState(RedDotDef.ID.BPKeji, self._isHasRedDot)
    end
    self._inited = true
end

function BangPaiKeji:onExit()
    self.m_pUILayer = nil
    self:Destory()
    self._pCell = nil
    self._tableView = nil
end

return BangPaiKeji