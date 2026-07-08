--[[
lua里面的游戏逻辑控制
]]

local NoticeUI = LUIBase:New()
NoticeUI.__index = NoticeUI

function NoticeUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,NoticeUI)	
    o:Init(data)
	return o
end

function NoticeUI:Init(data)
    self.Script = "NoticeUI"
    self.m_pNoticeBg1 = nil
    self.m_pNoticeBg2 = nil
    self.m_pNotice1 = nil
    self.m_pNotice2 = nil
    self.m_pSendBtn = nil
    self.m_pScrollView = nil
    ----------------------------------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = data
    self.m_selectIndex = 0
    ----------------------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
end

function NoticeUI:onExit()
    self:Destory()
    self.m_pNoticeBg1 = nil
    self.m_pNoticeBg2 = nil
    self.m_pNotice1 = nil
    self.m_pNotice2 = nil
    self.m_pSendBtn = nil
    self.m_pScrollView = nil
    ----------------------------------------------------------------
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = nil
end

function NoticeUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/NoticeLayer.csb")
    local viewsize = AppDef.frameSize
    self.m_pUILayer:setContentSize(viewsize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

function NoticeUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.RSI_TITLE_ACCOUNT)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

-- -----------------------------------
function NoticeUI:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local pBtnList = panel:getChildByName("BtnList")
    local pListBg = pBtnList:getChildByName("ListBg")
    self.m_pTablePanel = pListBg:getChildByName("List")
    self.m_pGridCell = pListBg:getChildByName("Btn")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setAnchorPoint(cc.p(0, 0))

    local pNoticeBg1 = panel:getChildByName("NoticeBg_1")
    self.m_pNoticeBg1 = pNoticeBg1
    
    self.m_pScrollView = pNoticeBg1:getChildByName("ScrollView")
    self.m_pScrollView:setScrollBarEnabled(false)
    
    local pNotice1 = pNoticeBg1:getChildByName("Text")
    self.m_pNotice1 = Utils:CreateColorText2(nil, pNotice1, cc.size(self.m_pScrollView:getContentSize().width-18, 0))
    self.m_pNotice1:retain()
    self.m_pNotice1:removeFromParent(false)
    self.m_pScrollView:addChild(self.m_pNotice1)
    self.m_pNotice1:release()

    local pNoticeBg2 = panel:getChildByName("NoticeBg_2")
    pNoticeBg2:setVisible(false)
    self.m_pNoticeBg2 = pNoticeBg2

    self.m_pNotice2 = pNoticeBg2:getChildByName("Content")

    local pSendBtn = panel:getChildByName("Btn")
    pSendBtn:setVisible(false)
    self.m_pSendBtn = pSendBtn
    pSendBtn:addClickEventListener(handler(self, NoticeUI.SendClick))
	self:MarkIntaractCObj(pSendBtn)
    self.m_pTableView = self:InitTableView(self.m_pTablePanel)
    if self.m_pTableView then
        self.m_tableCount = #self.m_datas
        self.m_pTableView:reloadData()
        if self.m_tableCount > 0 then
            self:TableCellTouched(0)
        end
    end
end

function NoticeUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height+10
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

    cfg.tableCellTouched = function(sender, cell)
        return self:TableCellTouched(cell:getIdx())
    end

    return Utils:createTableView(cfg)
end

function NoticeUI:TableCellTouched(idx)
    idx = idx + 1
    if idx == self.m_selectIndex or self.m_isDragging then
        return
    end
    local tmp = self.m_selectIndex
    self.m_selectIndex = idx
    if tmp > 0 then
        self.m_pTableView:updateCellAtIndex(tmp-1)
    end
    self.m_pTableView:updateCellAtIndex(idx-1)
    self:UpdateRight()
end

function NoticeUI:TableCellAtIndex(sender, idx)
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
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end

function NoticeUI:updateItem(cell, info, idx)
    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(self.m_selectIndex == idx)
    -----------------------------------------------------
    local pTitle = cell:getChildByName("Title")
    if pTitle then
        pTitle:setVisible(info.id > 0)
        if info.id > 0 then
            local pText = pTitle:getChildByName("Text")
            if pText then
                local arr = {"最新", "活动", "火热", "火爆"}
                pText:setString(arr[info.id] or "")
            end
        end
    end
    -----------------------------------------------------
    local pName = cell:getChildByName("Name")
    pName:setString(info.title)
    -----------------------------------------------------
end

function NoticeUI:SendClick(sender)
    if self.m_pNotice2 == nil then
        return
    end
    local content = se;f.m_pNotice2:getString()
    if #content == 0 then
        Utils:ShowScrollTips(GUITips.RSI_INPUT_ERROR)
        return
    end
end

function NoticeUI:UpdateRight()
    if self.m_pNotice1 == nil then
        return
    end
    if self.m_selectIndex == 0 or self.m_selectIndex > #self.m_datas then
        return
    end
    local info = self.m_datas[self.m_selectIndex]
    if info.opType == 0 then--文本
        self.m_pNotice1:setString(info.text)
        local nSize = self.m_pNotice1:getSize()
        local sSize = self.m_pScrollView:getContentSize()
        local siSize = self.m_pScrollView:getInnerContainerSize()
        siSize.height = math.max(nSize.height, sSize.height)
        self.m_pScrollView:setInnerContainerSize(siSize)
        self.m_pNotice1:setPosition(cc.p(0, siSize.height))---nSize.height/2
    elseif info.opType == 1 then--跳转
    elseif info.opType == 2 then
    end
end

return NoticeUI