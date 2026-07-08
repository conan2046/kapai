local CopyRewardUI = LUIBase:New()
CopyRewardUI.__index = CopyRewardUI

function CopyRewardUI:New()
    local o = LUIBase:New()
    setmetatable(o,CopyRewardUI)  
    o:Init()
    return o
end

function CopyRewardUI:Init(ind)
    self.Script = "Instances.CopyRewardUI"
    self.m_tableCount = 0
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_pTablePanel = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:InitData()
end

--[[
注册UI消息
]]
function CopyRewardUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function CopyRewardUI:ProcessEvent(msg)
   -- if msg.msgId == LUIActivityEvent.RefreshInstances then
   -- end
end

-- -----------------------------------
function CopyRewardUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode("csd/CleanRecordLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function CopyRewardUI:InitUIControl()
    local pCleanRecord = self.m_pUILayer:getChildByName("CleanRecord")
    if pCleanRecord == nil then
        return
    end
    local pBg = pCleanRecord:getChildByName("Bg")
    if pBg == nil then
        return
    end
    self.m_pTablePanel = pBg:getChildByName("ListView")
    self.m_pTableView = self.m_pTablePanel:getChildByName("TableView")
    if self.m_pTableView == nil then
        self.m_pTableView = self:InitTableView(self.m_pTablePanel)
        self.m_pTableView:setName("TableView")
    end
    self.m_pGridCell = pBg:getChildByName("Record_1")
    self.m_pGridCellSize = self.m_pGridCell:getContentSize()
    self.m_pItemModel = pBg:getChildByName("Item")
end

function CopyRewardUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUISecondClassBgEvent.SetTitle, GUITips.UI_Text_Copy_Title)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function CopyRewardUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        return self.m_pGridCellSize.width, self.m_pGridCellSize.height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return self.m_tableCount
    end

    return Utils:createTableView(cfg)
end

function CopyRewardUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)

        local pRewardList = cellChild:getChildByName("RewardList")
        local _ = pRewardList and pRewardList:setSwallowTouches(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:setItem(cellChild, self.m_datas[idx+1], idx+1)
    end
    return cell
end

function CopyRewardUI:UpdateUserData()
    self:InitData()
end

function CopyRewardUI:onExit()
    self:Destory()  
    self.m_pUILayer = nil
    self.m_pTablePanel = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pGridCellSize = nil
    self.m_pItemModel = nil
end

function CopyRewardUI:InitData()
    local copydata = LDataConstMgr.m_CopyData.SweepData
    if copydata == nil or copydata.items == nil or #copydata.items <= 0 then
        return
    end
    if self.m_pTableView == nil or self.m_pGridCell == nil or self.m_pItemModel == nil then
        return
    end
    
    self.m_datas = copydata.items
    self.m_tableCount = #copydata.items
    self.m_pTableView:reloadData()
end

function CopyRewardUI:CreateItem(awardType, awardNum)
    local pItem = self.m_pItemModel:clone()
    Utils:GetItemCellValue(pItem, 0, awardType, true, true, awardNum, nil, true)
    return pItem
end

function CopyRewardUI:setItem(pCell, data, index)
    if pCell == nil or data == nil or index == nil then
        return false
    end
    if data.sweepAward == nil or #data.sweepAward <= 0 then
        return false
    end
    local pName = pCell:getChildByName("Name")
    local _ = pName and pName:setString(string.format(GUITips.UI_Text_Copy_Sweep_Times2, index))

    local pRewardList = pCell:getChildByName("RewardList")
    if pRewardList == nil then
        return false
    end
    pRewardList:setTouchEnabled(#data.sweepAward > 5)
    pRewardList:removeAllItems()
    for i=1,#data.sweepAward do
        local awardType = data.sweepAward[i].awardType
        local awardNum = data.sweepAward[i].awardNum
        local pItem = self:CreateItem(awardType, awardNum)
        if pItem then
            pRewardList:pushBackCustomItem(pItem)
        end
    end
end

return CopyRewardUI