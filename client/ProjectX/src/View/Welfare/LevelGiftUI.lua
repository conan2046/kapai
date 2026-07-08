local LevelGiftUI = LUIBase:New()
LevelGiftUI.__index = LevelGiftUI

function LevelGiftUI:New()
    local o = LUIBase:New()
    setmetatable(o,LevelGiftUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function LevelGiftUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWelfareEvent.RefreshLevelGiftPage,
    }
    self:RegistSelf(self,self.msgIds)
end

function LevelGiftUI:ProcessEvent(msg)
    if msg.msgId == LUIWelfareEvent.RefreshLevelGiftPage then
        local cell = self.m_GiftTblView:cellAtIndex(msg.value)
        if cell ~= nil then
            local cellChild = cell:getChildByTag(123)
            local button = cellChild:getChildByName("btn_Get")
            local get = cellChild:getChildByName("Mark")
            button:setVisible(false)
            get:setVisible(true)
        end
        LGameMsg.m_baseMsgWithOne:Change(LUIOnlineAwardEvent.KaifuReddotRefresh,2)
        self:SendMsg(LGameMsg.m_baseMsgWithOne)
    end
end

function LevelGiftUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/LevelGiftLayer.csb")
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
end

function LevelGiftUI:onExit()
    self:Destory()
end

function LevelGiftUI:AddTouchEvt()
    -- local function SweepCallback(sender)
    --     local petCoye = LDataConstMgr:GetCopyData()._PetCopyList
    --     local ind = self.m_curCopyBtn:getTag()
    --     local copy = petCoye[ind]
    -- end
    -- self.m_pSweepBtn:addClickEventListener(SweepCallback)
end

function LevelGiftUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("LevelGiftUI")

    -- 列表区域
    self.m_GiftTblBg = self.m_panelUI:getChildByName("ListView")
    self.m_GiftTblView = nil

    -- 等级控件
    self.m_pLevelCell = self.m_panelUI:getChildByName("Item")
    -- 礼物背景
    self.m_pGiftBg = self.m_pLevelCell:getChildByName("Item")
    self.m_pGiftBg:setTouchEnabled(false)
    self:InitLevelGiftTable(self.m_GiftTblBg)
end

--[[
登录列表初始化
]]
function LevelGiftUI:InitLevelGiftTable(tableBg)
    local tableView = cc.TableView:create(tableBg:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(tableBg:getAnchorPoint())
    tableView:setPosition(tableBg:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(true)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableBg:getParent():addChild(tableView)
    local function tableCellTouched(sender,cell)
        -- self:LevelGiftCellTouched(cell)  -- 不用处理点击
    end
    local function cellSizeForTable(sender,idx)
        local size = self.m_pLevelCell:getContentSize()
        return size.width, size.height
    end
    local function tableCellAtIndex(sender, idx)
        return self:LevelGiftCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return #LRoleDataMgr.MyHeroInfo.m_pLevelWard
    end
    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_GiftTblView = tableView
end

--[[
礼包列表
]]
function LevelGiftUI:InitGiftList(cell, idx)
    local list = cell:getChildByName("ListView")
    local button = cell:getChildByName("btn_Get")
    local get = cell:getChildByName("Mark")
    local giftState = button:getChildByName("Text")
    local info = LRoleDataMgr.MyHeroInfo.m_pLevelWard[idx]
    local str = string.format(GUITips.UI_Text_Level_Index, info.level)
    cell:getChildByName("Title"):setString(str)
    button:setTag(info.levelId)

    function giftButtonTouch(sender)
        LuaNetSendMsg:QueryKaifuHuodong(7, 2, sender:getTag())
    end
    button:addClickEventListener(giftButtonTouch)
	self:MarkIntaractCObj(button)
    --[[
    按钮显示
    ]]
    local info = LRoleDataMgr.MyHeroInfo.m_pLevelWard[idx]
    --dump(info,"等级礼包------------------------》")
    if LRoleDataMgr.MyHeroInfo.level >= info.level then
        if info.canBuy then  -- 可以领
            button:setVisible(true)
            button:setTouchEnabled(true)
            button:setBright(true)
        else
            get:setVisible(true)
            button:setVisible(false)
        end
    else
        get:setVisible(false)
        button:setVisible(true)
        button:setBright(false)
    end

    --[[
    礼物显示
    ]]
    list:removeAllChildren()
    for i= 1, #info.ItemId do
        local itemId = info.ItemId[i]
        local grid = self.m_pGiftBg:clone()
        if itemId==AppDef.AwrdItem.AWRD_ITEM_PETEQUIP then
                             --   GetItemCellValue(grid, type, itemId, showQuality, showNum, num,            pItem, isOpenTouch, isChangeSize, pid, pstar)
           local itemUI = Utils:GetItemCellValue(grid,0,itemId,true,false,info.ItemNum[i], nil, true,true,info.ItemNum[i],info.value[i])
        else
          local itemUI = Utils:GetItemCellValue(grid, 0, itemId, true, true, info.ItemNum[i], nil, true)
        end
        list:pushBackCustomItem(grid)
    end
end

--[[
加载指定等级
]]
function LevelGiftUI:LevelGiftCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pLevelCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0,0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:InitGiftList(cellChild, idx + 1)
    return cell
end

--[[
点击指定礼物
]]
function LevelGiftUI:VipGiftBagCellTouched(cell)
    local idx = cell:getIdx()
    local item = 
    {
        itemType = "",
        itemData = self.m_itemUIs[idx + 1].m_pItem,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

return LevelGiftUI