local BangPaiZoneDef = require("View.BangPaiZone.BangPaiZoneDef")

local BangPaiActList = LUIBase:New()
BangPaiActList.__index = BangPaiActList

local CountOfColumn = 2

-- -----------------------------------
function BangPaiActList:New(bpUI)
    local o = {}
    setmetatable(o, BangPaiActList)
    o:Init(bpUI)
    return o
end

-- -----------------------------------
function BangPaiActList:Init(bpUI)
    self.m_pBpUI = bpUI
    self.m_initNetData = true
    --------------------------------------
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = 0

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    LuaNetSendMsg:QueryFactionTaskList()
    LuaNetSendMsg:QueryFactionActivityList()
end

-- -----------------------------------
function BangPaiActList:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
    self.m_selectIndex = nil
    self.m_buttonSize = nil
    self.m_initNetData = nil
end

-- -----------------------------------
function BangPaiActList:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.ReloadFactionTaskList,
        LUIBangPaiEvent.GetFactionTaskReward,
        LUIBangPaiEvent.ReloadFactionActivityList,
        LUIBangPaiEvent.FlushFactionActivity,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiActList:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.ReloadFactionTaskList then
        self:loadData(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.GetFactionTaskReward then
        self:GetAwardSuccess(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
        self:ReloadFactionActivityList(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
        self:SetActivity(LRoleDataMgr.Faction.Info.selfActivity)
    end
end

function BangPaiActList:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function BangPaiActList:InitViewSize()
    --做个热更报
    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildActivityLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end

-- -----------------------------------
function BangPaiActList:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")

    local pGuildActivity = panel:getChildByName("GuildActivity")
    local pBg = pGuildActivity:getChildByName("Bg")

    local pWhisperBtn = pBg:getChildByName("WhisperBtn")
    local pWhisperBtn1 = pBg:getChildByName("WhisperBtn1")

    self.m_pTablePanel = pBg:getChildByName("List")
    self.m_pGridCell = self.m_pTablePanel:getChildByName("Item")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)

    local pWhisperBtn = self.m_pGridCell:getChildByName("WhisperBtn")
    local pGetBtn = pWhisperBtn:getChildByName("GetBtn")
    self.m_buttonSize = pGetBtn:getContentSize()

    self.m_pTableView = self:InitTableView(self.m_pTablePanel)

    self:InitActivity()
end

function BangPaiActList:loadData(list)
    self.m_datas = list
    self.m_tableCount = math.ceil(#list / CountOfColumn)
    if self.m_pTableView ~= nil then
        local offset = nil
        if not self.m_initNetData then
            offset = self.m_pTableView:getContentOffset()
        end
        self.m_pTableView:reloadData()
        if offset then
           self.m_pTableView:setContentOffset(offset)
        end
        if self.m_initNetData then
            self.m_initNetData = false
        end
    end
end

function BangPaiActList:InitTableView(tbPanel)
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

function BangPaiActList:TableCellAtIndex(sender, idx)
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
        pWhisperBtn:addClickEventListener(handler(self, BangPaiActList.ClickItem))
		self:MarkIntaractCObj(pWhisperBtn)
        pWhisperBtn1:addClickEventListener(handler(self, BangPaiActList.ClickItem))
		self:MarkIntaractCObj(pWhisperBtn1)

        local pGetBtn = pWhisperBtn:getChildByName("GetBtn")
        pGetBtn:ignoreContentAdaptWithSize(false)
        pGetBtn:setContentSize(self.m_buttonSize)
        pGetBtn:addClickEventListener(handler(self, BangPaiActList.enterActClick))
		self:MarkIntaractCObj(pGetBtn)
        local pGetBtn1 = pWhisperBtn1:getChildByName("GetBtn")
        pGetBtn1:ignoreContentAdaptWithSize(false)
        pGetBtn1:setContentSize(self.m_buttonSize)
        pGetBtn1:addClickEventListener(handler(self, BangPaiActList.enterActClick))
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

function BangPaiActList:updateItem(cell, linfo, idx)
    if idx > #self.m_datas or linfo == nil then
        cell:setVisible(false)
        return
    end
    cell:setVisible(true)
    cell:setTag(idx)

    local pChooseBg = cell:getChildByName("ChooseBg")
    pChooseBg:setVisible(self.m_selectIndex == idx)

    local pGetBtn = cell:getChildByName("GetBtn")
    pGetBtn:setTag(idx)

    ------------------------------------------------
    local pIconBg = cell:getChildByName("IconBg")
    local pIcon = pIconBg:getChildByName("Icon")

    -- local missionType = linfo.missionType          --任务类型
    local missionType = linfo.missionId      --改为Id索引
    if missionType and BangPaiZoneDef.PicMap[missionType] then
        local missionPic = BangPaiZoneDef.PicMap[missionType].pic   --任务图片
        if missionPic then
            local missionScale = BangPaiZoneDef.PicMap[missionType].scale
            if missionType == 34 or missionType == 14 then
                Utils:SafeLoadTexture(pIcon, missionPic, UI_TEX_TYPE_LOCAL)
                --pIcon:loadTexture(missionPic, UI_TEX_TYPE_LOCAL)
            else
                Utils:SafeLoadTexture(pIcon, missionPic, UI_TEX_TYPE_PLIST)
                --pIcon:loadTexture(missionPic, UI_TEX_TYPE_PLIST)
            end
            pIcon:setScale(missionScale)
        end
    end

    --没有奖励可领取,不显示
    if missionType >= 7 and missionType <= 10 then
        pGetBtn:setVisible(false)
    else
        pGetBtn:setVisible(true)
    end

    ------------------------------------------------
    local pName = cell:getChildByName("Name")
    pName:setString(linfo.name)
    ------------------------------------------------
    local pTimes = pName:getChildByName("Times")
    local needCompleteNum = linfo.needCompleteNum
    local completeNum = linfo.completeNum
    if needCompleteNum > 0 then
        pTimes:setString(string.format("%d/%d", completeNum, needCompleteNum))
    else
        pTimes:setString("")
    end
    local _,y = pTimes:getPosition()
    pTimes:setPosition(cc.p(pName:getContentSize().width + 4, y))
    ------------------------------------------------
    local pHuoyue = cell:getChildByName("Huoyue")
    local pHuoyueText = pHuoyue:getChildByName("Text")
    --print("linfo.maxHuoYue =============>", linfo.maxHuoYue)
    if linfo.maxHuoYue <= 0 then
        --商店兑换没有上限
        if linfo.missionId == 13 then
            pHuoyue:setVisible(true)
            pHuoyueText:setString(tostring(linfo.curHuoYue))
        else
            pHuoyue:setVisible(false)
        end
        
    else
        pHuoyue:setVisible(true)
        local strTemp = string.format("(%d/%d)", linfo.curHuoYue, linfo.maxHuoYue)
        pHuoyueText:setString(strTemp)
    end
    
    ------------------------------------------------
    local taskState = linfo.buttonState
    local pButton = cell:getChildByName("GetBtn")
    local pBtnName = pButton:getChildByName("BtnName")
    if missionType ~= 34 and missionType ~= 36 then
       if taskState == 0 then
           pBtnName:setString(GUITips.RSI_FACTION_MSG30)
       else
           pBtnName:setString(GUITips.RSI_FACTION_MSG31)
       end
       local pRedImage = pButton:getChildByName("RedImage")
       pRedImage:setVisible(taskState == 1)
       pButton:setBright(taskState ~= 2)--0:未完成 1:已完成未领奖 2:已完成已领奖
       pButton:setEnabled(taskState ~= 2)
    else
       if linfo.isOpen == 3 then
            pBtnName:setString(GUITips.RSI_FACTION_MSG204)
       elseif linfo.isOpen == 4 then
            pBtnName:setString(GUITips.RSI_FACTION_MSG206)
       end
       local pRedImage = pButton:getChildByName("RedImage")
       pRedImage:setVisible(false)
       pButton:setBright(linfo.isOpen ~= 3)
       pButton:setEnabled(linfo.isOpen ~= 3)
    end

    if missionType == 11 or missionType == 12 then
        pBtnName:setString(GUITips.RSI_TARGET_RD_TIPS3)
    end 
    
    local pTimeBg = cell:getChildByName("TimeBg")
    local pTime = pTimeBg:getChildByName("Time")
    pTime:setString(linfo.time and linfo.time or GUITips.RSI_FACTION_MSG200)
    ------------------------------------------------
    local pDes = cell:getChildByName("Des")
    pDes:setString(linfo.desc)
end

function BangPaiActList:ClickItem(sender)
    if sender == nil or self.m_isDragging then
        return
    end
    local index = sender:getTag()
    local data = self.m_datas[index]

    local cfg = {item={},actItems={},btns={}}
    if data.missionId > 6 and data.missionId <= 14 then
        return
    end

    cfg.item[1] = BangPaiZoneDef.PicMap[data.missionId].pic
    cfg.item[2] = (data.missionType == 34 or data.missionType == 36 or data.missionId == 14)
    cfg.name = data.name
    cfg.count = data.completeNum
    cfg.maxCount = data.needCompleteNum
    cfg.desc = data.desc
    cfg.levelLimit = data.level
    cfg.actTime = data.time and data.time or GUITips.RSI_FACTION_MSG200
    local function getAwardConfig(id, num)
        if id == 1 or id == 3 or id == 4 then
            return {pic=BangPaiZoneDef.IconMap[id], num=num}
        end
        return {id=id, num=num}
    end
    if data.missionType == 34 or data.missionType == 36 then
        if data.buttonState ~= 0 then
            table.insert(cfg.btns, {GUITips.RSI_FACTION_MSG202, handler(self, BangPaiActList.joinCallback)})
        end

        for i=1,#data.awards do
            local id = data.awards[i]
            if GUITipsAwrdItemIdMap[id] or LItemMgr:getItem(id) then
                table.insert(cfg.actItems, {id=id, num=0})
            else
                local pic = BangPaiZoneDef.IconMap[id]
                if pic then
                    table.insert(cfg.actItems, {pic=pic, num=0})
                end
            end
        end
    else
        if data.buttonState == 0 then
            table.insert(cfg.btns, {GUITips.RSI_FACTION_MSG202, handler(self, BangPaiActList.joinCallback)})
        elseif data.buttonState == 1 then
            table.insert(cfg.btns, {GUITips.RSI_FACTION_MSG203, handler(self, BangPaiActList.getCallback)})
        end
        table.insert(cfg.actItems, getAwardConfig(data.awardItemId, data.awardItemNum))
        table.insert(cfg.actItems, getAwardConfig(data.awardType, data.awardValue))
    end
    Utils:InitUI("BangPai.BangPaiDetailPopup", AppDef.UIType.PopWindow, cfg)

    self.m_selectIndex = index
end

function BangPaiActList:enterActClick(sender)
    local index = sender:getTag()
    local data = self.m_datas[index]
    if data.missionType == 34 or data.missionType == 36 or data.missionId == 14 then
        if data.isOpen == 4 then
            self:JumpTo(data.missionType, 0, data.missionId)
        elseif data.isOpen == 3 then
            Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
        end
    else
        if data.missionId == 11 or data.missionId == 12 then
            Utils:SendMsg(LUIBangPaiEvent.CloseBangPaiPopup)
            Utils:OpenGodTree()
        else
            if data.buttonState == 0 then
                self:JumpTo(data.missionType, 0, data.missionId)
            elseif data.buttonState == 1 then
                self:GetAward(data.missionId)
            end
        end
    end
end

function BangPaiActList:JumpTo(taskType, time, taskId)
    if taskType == 1 then              --捐金币
        LuaNetSendMsg:QueryFactionJuanXianMsg()
    elseif taskType == 6 or taskType == 7 or taskType == 8 or taskType == 10 then--浇水
        Utils:SendMsg(LUIBangPaiEvent.CloseBangPaiPopup)

        if LRoleDataMgr.Faction:GetPlantFactionId() == 0 or (taskType == 8) then
            LuaNetSendMsg:QueryBangPaiEnterZone(LRoleDataMgr.Faction.Info.id)
        end
    elseif taskType == 9 or taskType == 20 or taskType == 34 then
        if taskType == 34 then
            for i=1,#self.m_datas do
                if self.m_datas[i].missionType == taskType then
                    if self.m_datas[i].isOpen == 3 then
                        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG204)
                        return
                    end
                    break
                end
            end
        end
        Utils:SendMsg(LUIFClassBgEvent.SelectTab, 1)
        self.m_pBpUI:TabClicked(1)
    elseif taskType == 36 then--帮战
    end

    local config = BangPaiZoneDef.PicMap[taskId]
    if config and config.tips and #config.tips > 0 then
        Utils:ShowScrollTips(config.tips)
    end
end

function BangPaiActList:GetAward(missionId)
    LuaNetSendMsg:QueryFactionGetTaskReward(missionId)
end

function BangPaiActList:joinCallback()
    local data = self.m_datas[self.m_selectIndex]
    self:JumpTo(data.missionType, data.time, data.missionId)
end

function BangPaiActList:getCallback()
    local data = self.m_datas[self.m_selectIndex]
    self:GetAward(data.missionId)
end

function BangPaiActList:GetAwardSuccess(missionId)
    for i = 1, #self.m_datas do
        local missId = self.m_datas[i].missionId
        if missionId == missId then
            self.m_datas[i].buttonState = 2
            self:FunRefresh(i)
            break
        end
    end
end

function BangPaiActList:FunRefresh(idx)
    local row = math.floor((idx-1) / CountOfColumn)
    local pCell = self.m_pTableView:cellAtIndex(row)
    if pCell then
        local cellChild = pCell:getChildByTag(123)
        if cellChild then
            if math.fmod(idx, 2) == 1 then
                local pWhisperBtn = cellChild:getChildByName("WhisperBtn")
                self:updateItem(pWhisperBtn, self.m_datas[idx], idx)
            else
                local pWhisperBtn1 = cellChild:getChildByName("WhisperBtn1")
                self:updateItem(pWhisperBtn1, self.m_datas[idx], idx)
            end
        end
    end
end

function BangPaiActList:InitActivity()
    local panel = self.m_pUILayer:getChildByName("Panel")
    local pGuildActivity = panel:getChildByName("GuildActivity")
    local pActivityNum = pGuildActivity:getChildByName("Bg"):getChildByName("ActivityNum")
    local pImageBg = pActivityNum:getChildByName("ImageBg")
    self.m_pLoadingBar = pImageBg:getChildByName("LoadingBar")

    self.m_pActivitys = {}
    for i=2,6 do
        table.insert(self.m_pActivitys, pImageBg:getChildByName("Num"..i))
    end

    self.m_pRewards = {}
    for i=1,5 do
        local pItem = pActivityNum:getChildByName("EquipIcon"..i)
        pItem:setTag(i)
        pItem:setTouchEnabled(true)
        pItem:getChildByName("Mark"):setLocalZOrder(2)
        pItem:addClickEventListener(handler(self, BangPaiActList.ActRewardClick))
        table.insert(self.m_pRewards, pItem)
    end

    Utils:SendMsg(LUIBangPaiEvent.FlushFactionActivity)

    local helpBtn = pActivityNum:getChildByName("HelpBtn")
    local function helpBtnEvent( ... )
        -- body
        local function OnOk()
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_BP_DES_TIPS2, OnOk)
    end
    helpBtn:addClickEventListener(helpBtnEvent)
end

function BangPaiActList:SetActivity(act)
    if self.m_maxAct == nil then
        return
    end
    -- print(debug.traceback())
    act = act or 0
    local max = self.m_maxAct or 100
    local pro = act/max
    self.m_pLoadingBar:setPercent(pro*100)
    local pDot = self.m_pLoadingBar:getChildByName("ImageDot")
    pDot:setPositionX(self.m_pLoadingBar:getContentSize().width*pro)
    pDot:getChildByName("Num"):setString(tostring(act))
end

function BangPaiActList:SetAllActivity(list)
    local cList = #list
    local cActs = #self.m_pActivitys
    for i=1,math.max(cList, cActs) do
        if i > cActs then
            break
        end
        if i <= cList then
            self.m_pActivitys[i]:setVisible(true)
            self.m_pActivitys[i]:setString(string.format(GUITips.RSI_BP_TIP55, list[i]))
        else
            self.m_pActivitys[i]:setVisible(false)
        end
    end
end

function BangPaiActList:SetAllReward(list)
    local cList = #list
    local cItem = #self.m_pRewards
    for i=1,math.max(cList, cItem) do
        local pItem = self.m_pRewards[i]
        if i > cList then
            pItem:setVisible(false)
        else
            self:SetOneReward(pItem, list[i])
            pItem:setVisible(true)
        end
        if i > cItem then
            break
        end
    end
end

function BangPaiActList:SetOneReward(pNode, pData)
    if pNode == nil or pData == nil or pData.rewards == nil or #pData.rewards == 0 then
        return
    end
    -- dump(pData, "pData--->")
    local tag = pNode:getTag()

    local info = LRoleDataMgr.Faction.Info
    self.m_items = self.m_items or {}
    local reward = pData.rewards[1]
    local itemId = reward.id
    local num = reward.num

    self.m_items[tag] = Utils:GetItemCellValue(pNode, 0, itemId, true, true, num, self.m_items[tag], nil, true)
    self.m_items[tag].m_pUILayer:setLocalZOrder(1)

    local pMark = pNode:getChildByName("Mark")
    pMark:setVisible(pData.state == 1)

    local pEffect = pNode:getChildByName("Effect")
    if info.selfActivity >= pData.activity and pData.state == 0 then
        if pEffect == nil then
            local size = pNode:getContentSize()
            pEffect = Utils:createAnimEffect(pNode, cc.p(size.width/2+2, size.height/2), "res2/fx/huoyuedujiangli")
            pEffect:setName("Effect")
            pEffect:setLocalZOrder(0)
        else
            pEffect:setVisible(true)
        end
    else
        if pEffect then
            pEffect:setVisible(false)
        end
    end
end

function BangPaiActList:ActRewardClick(sender)
    if sender == nil then
        return
    end
    if self.m_activityList == nil then
        return
    end
    local tag = sender:getTag()
    -- dump(tag, "tag---->")
    local actData = self.m_activityList[tag]
    -- dump(actData, "actData--->")
    if actData == nil then
        return
    end
    local info = LRoleDataMgr.Faction.Info
    if info.selfActivity >= actData.activity and actData.state == 0 then
        LuaNetSendMsg:QueryGetFactionActivity(1, actData.activity)
    else
        if actData.rewards and #actData.rewards > 0 then
            local itemId = actData.rewards[1].id
            if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then
                Utils:ShowItemTips(itemId)
            else--if itemId == AppDef.AwrdItem.AWRD_ITEM_COIN then
                Utils:ShowGoldTips(itemId)
            end
        end
    end
end

function BangPaiActList:ReloadFactionActivityList(datas)
    if datas == nil or datas[1] == nil then
        return
    end
    local activityList = datas[1].activityList
    if activityList == nil then
        return
    end
    self.m_activityList = activityList

    local actList = {}
    local num = #activityList
    for i=1,num do
        table.insert(actList, activityList[i].activity)
        if i == num then
            self.m_maxAct = actList[i]
        end
    end
    self:SetAllActivity(actList)
    self:SetAllReward(activityList)
    Utils:SendMsg(LUIBangPaiEvent.FlushFactionActivity)
end

return BangPaiActList