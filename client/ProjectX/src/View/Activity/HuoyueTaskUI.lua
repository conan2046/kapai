
local HuoyueTaskUI = LUIBase:New()
HuoyueTaskUI.__index = HuoyueTaskUI
--local this = LTcpSocket
function HuoyueTaskUI:New(parent)
    local o = LUIBase:New()
    setmetatable(o,HuoyueTaskUI)  
    o:Init(parent)
    return o
end

--注册事件
-- -----------------------------------
function HuoyueTaskUI:RegistMsgs()
    self.msgIds = 
    {
        LUITaskDataEvent.GotDailyTaskInfo,
        LUITaskDataEvent.GotDailyRewardInfo,
        LUITaskDataEvent.DailyTaskUpdate,
        LUITaskDataEvent.GotDailyTaskReward,
        LUIRoleDataChangeEvent.HuoyueChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HuoyueTaskUI:ProcessEvent(msg)
    if msg.msgId == LUITaskDataEvent.GotDailyTaskInfo then
        self:GotTaskList(msg.value)
        --self:refrashUI(msg.value)
    elseif msg.msgId == LUITaskDataEvent.GotDailyRewardInfo then
        self:ShowHuoyue(msg.value)
        self:CheckRedDot()
    elseif msg.msgId == LUITaskDataEvent.GotDailyTaskReward then
        self:OnGotReward(msg.value)
        self:CheckRedDot()
    elseif msg.msgId == LUITaskDataEvent.DailyTaskUpdate then
        self:GotTaskUpdate(msg.value)
        self:CheckRedDot()
    elseif msg.msgId == LUIRoleDataChangeEvent.HuoyueChanged then
        self:HuoyueUpdate()
        self:CheckRedDot()
    end
end

function HuoyueTaskUI:CheckRedDot()
    local hasReward = false
    for i = 1,#self._taskList do
        if self._taskList[i].state == 1 then
            hasReward = true
            break
        end
    end
    for i = 1,#self._rewardList do
        if self._rewardList[i].state == 1 then
            hasReward = true
            break
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.DaliyTask, hasReward)
end

function HuoyueTaskUI:HuoyueUpdate()
    self.m_pUILayer:findChildByName("Renwu/Content/TitleBg"):setVisible(true);
    local huoyue  = LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_HuoYue);
    -- print("huoyue",huoyue)
    local lastConfig = JsonConfig.GetDailyTaskConfig(147);
    local maxHuoyue = lastConfig.condition[2];
    local list = JsonConfig.GetDailyHuoyueRewardConfig();
    local rate = math.floor(huoyue*100 / maxHuoyue);
    self._huoyueBar:setPercent(rate);
    self.m_pUILayer:findChildByName("Renwu/Content/TitleBg/LoadingBg/Icon/Value"):setString(huoyue);
    local function getData(id)
        for i = 1, #self._rewardList do
            if self._rewardList[i].task_id == id then
                return self._rewardList[i]
            end
        end
        return nil
    end
    for i = 1, #list do
        local data = getData(list[i].id)
        if data and data.state == 2 then
            self._huoyueBoxNodeArr[i]:getChildByName("Close"):setVisible(false);
            self._huoyueBoxNodeArr[i]:getChildByName("Open"):setVisible(true);
        else
            self._huoyueBoxNodeArr[i]:getChildByName("Close"):setVisible(true);
            self._huoyueBoxNodeArr[i]:getChildByName("Open"):setVisible(false);
        end
        if data and data.state == 1 then
            local ani = self._huoyueBoxNodeArr[i]:findChildByName("Node/effect");
            if ani == nil then
                ani = Utils:ReceivableEffect(0.8);
                local size = self._huoyueBoxNodeArr[i]:getContentSize();
                self._huoyueBoxNodeArr[i]:getChildByName("Node"):addChild(ani);
                ani:setName("effect")
                --ani:setPosition(cc.p(size.width/2,size.height/2))
            end
        else
            local ani = self._huoyueBoxNodeArr[i]:findChildByName("Node/effect");
            if ani then
                ani:removeFromParent()
            end
        end
        
    end
end

function HuoyueTaskUI:OnGotReward(taskId)
    for i = 1,#self._taskList do
        if self._taskList[i].task_id == taskId then
            self._taskList[i].state = 2

            self:SortTask();
            self:refrashUI();
            -- self:OnGotTaskReward(self._taskList[i], i);
            return
        end
    end

    for i = 1,#self._rewardList do
        if self._rewardList[i].task_id == taskId then
            self._rewardList[i].state = 2
            self:OnGotBoxReward(self._rewardList[i], i);
            return
        end
    end
end

function HuoyueTaskUI:OnGotTaskReward(taskData, tind)
    local tebleCellNode = self.m_pTableView:cellAtIndex(tind - 1)
    if not tebleCellNode then
        return
    end
    local cellChild = tebleCellNode:getChildByTag(123)
    if not cellChild then
        return
    end
    self:ShowTaskBtnState(taskData, cellChild);
end

function HuoyueTaskUI:OnGotBoxReward(taskData, tind)
    self:ShowHuoyue(self._rewardList)
end

function HuoyueTaskUI:GotTaskList(list)
    -- print("GotTaskList")
    self._taskList = list;
    
    self:SortTask()
    self:refrashUI();
end

function HuoyueTaskUI:SortTask()
    --0未完成 1完成 2已领奖
    table.sort(self._taskList, function(a, b)
        if a.state == b.state then
            return a.task_id > b.task_id
        else
            if a.state == 2 then
                return false
            elseif b.state ==  2 then
                return true
            else
                return a.state > b.state;
            end
            
        end
    end)
end

function HuoyueTaskUI:GotTaskUpdate(list)
    -- print("GotTaskUpdate",list)
    -- dump(list,"list")
    local hasRewardTask = false;
    local hasDaliyTask = false;
    local rewardList = {}
    local taskList = {}
    for i = 1, #list do
        local data = JsonConfig.GetDailyTaskConfig(list[i].task_id)
        if data then
            if data.type == 0 then
                table.insert(rewardList,list[i])
            else
                table.insert(taskList,list[i])
            end
        end
    end
    local function getOldTask(id)
        for i = 1, #self._taskList do
            if self._taskList[i].task_id == id then
                return self._taskList[i]
            end
        end
        return nil
    end

    local function getData(id)
        for i = 1, #self._rewardList do
            if self._rewardList[i].task_id == id then
                return self._rewardList[i]
            end
        end
        return nil
    end

    
    if #taskList > 0 then
        for i = 1, #taskList do
            local task = getOldTask(taskList[i].task_id)
            if task then
                task.taskActiveNum = taskList[i].taskActiveNum
                task.state = taskList[i].state
            else

                table.insert(self._taskList, taskList[i])
            end
        end
        self:SortTask()
        self:refrashUI();
    end

    if #rewardList > 0 then
        for i = 1, #rewardList do
            local task = getData(rewardList[i].task_id)
            if task then
                task.taskActiveNum = rewardList[i].taskActiveNum
                task.state = rewardList[i].state
            else

                table.insert(self._rewardList, rewardList[i])
            end
        end
        self:HuoyueUpdate();
    end
end

function HuoyueTaskUI:Init(parent)
    self.Script = "Activity.HuoyueTaskUI"
    self:CreateUINode("csd/huodong/RenwuLayer.csb");
    parent:addChild(self.m_pUILayer);

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData()
    self:initUI()
    self:InitTouchEvt();
    -- self:ShowHuoyue()
    self:refrashUI(false)

    LuaNetSendMsg:QueryGotTaskList(2);
    LuaNetSendMsg:QueryGotTaskList(0);
end

function HuoyueTaskUI:initData()
    self._taskList = {}
    self._rewardList = {}
    self._listView = self.m_pUILayer:findChildByName("Renwu/Content/ListView");
    self._rewardsCell = self.m_pUILayer:findChildByName("Renwu/Item");
    self._rewardsCell:setVisible(false)
    self._itemCell = self.m_pUILayer:findChildByName("Renwu/itemBase");
    self._itemCell:setVisible(false)

    self._huoyueBoxNodeArr = {};
    for i = 1, 4 do
        table.insert(self._huoyueBoxNodeArr,self.m_pUILayer:findChildByName("Renwu/Content/TitleBg/LoadingBg/Panel_" .. i));
    end
    self._huoyueBar = self.m_pUILayer:findChildByName("Renwu/Content/TitleBg/LoadingBg/LoadingBar");

    self.m_pUILayer:findChildByName("Renwu/Content/TitleBg"):setVisible(false);
end

-- function HuoyueTaskUI:SetBoxEffect1()
--     local bgAnim = "res2/animation/effect_tuitu_1"
--     local m_pBgAni = ImodAnim:create()
--     m_pBgAni:initAnimWithNameSync(bgAnim)
--     m_pBgAni:PlayActionRepeat(0)
--     m_pBgAni:setScale(0.8)
--     return m_pBgAni
-- end

function HuoyueTaskUI:initUI( ... )
    -- body
    self:initListTableView()
    self.m_pTableView:reloadData()

    -- self._jinbiFind:setString("0")
    -- self._goldFind:setString("0")
end

function HuoyueTaskUI:InitTouchEvt()
    local function onRewardClicked(sender)
        self:OnRewardBoxClicked(sender.userData)
    end

    for i = 1, #self._huoyueBoxNodeArr do
        self._huoyueBoxNodeArr[i].userData = i;
        self._huoyueBoxNodeArr[i]:addClickEventListener(onRewardClicked);
    end
end

function HuoyueTaskUI:OnRewardBoxClicked(ind)
    local list = JsonConfig.GetDailyHuoyueRewardConfig();


    if not self._rewardList[ind] or not list[ind] then
        return
    end

    local curData = self._rewardList[ind]


    local function OkBtn()
        if curData.state == 2 or curData.state == 0 then
            return
        end
        LuaNetSendMsg:QueryGotTaskAward(0, curData.task_id)
        -- LuaNetSendMsg:QueryGetBangPaiHuoyueReward(list[ind].huoyueId); 
    end
    if curData.state == 1 then
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,list[ind].reward,true,GUITips.RSI_GS_TIP_RECOVERY_SURE,OkBtn,nil);
    else
        Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,list[ind].reward,false,"",nil,nil);
    end

end

function HuoyueTaskUI:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

function HuoyueTaskUI:initListTableView()
    local tableView = cc.TableView:create(self._listView:getContentSize())
--    --print("width = ".. self._listView:getContentSize().width .. "height = " .. self._listView:getContentSize().height);
--    --print("width = ".. tableView:getContentSize().width .. "height = " .. tableView:getContentSize().height);
    tableView:setContentSize(self._listView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(cc.p(0, 0))
    tableView:setPosition(cc.p(0, 0))
    tableView:setDelegate()
    tableView:setSwallowsTouches(true)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self._listView:addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        --print("tableCellTouched", cell:getIdx())
        self:expTableCellTouched(cell)
    end

    local function cellSizeForTable(sender,idx)
        local width = self._rewardsCell:getContentSize().width
        local height = self._rewardsCell:getContentSize().height
--        --print("cellSizeForTable width = "..width .. " cellSizeForTable height = ",height)
        return width, height
    end

    local function tableCellAtIndex(sender, idx)
--        --print("cellSizeForTable idx = ".. idx )
        return self:expTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local size = #self._taskList
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
    self.m_pTableView = tableView
end

function HuoyueTaskUI:expTableCellTouched(cell)
    local ind = cell:getIdx()
    local cellChild = cell:getChildByTag(123)
end

function HuoyueTaskUI:expTableCellAtIndex(sender, idx)

    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._rewardsCell:clone()
        cellChild:findChildByName("Panel/ListView"):setSwallowTouches(false)
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)         
    else
        cellChild = cell:getChildByTag(123)
    end
    --print("cell idx"..idx)
    self:ShowExpCellInfo(cellChild, idx)
    return cell
end

function HuoyueTaskUI:ShowExpCellInfo(cellChild, idx)
    -- body
    if cellChild == nil then
        return
    end

    if self._taskList[idx + 1] == nil then
        return
    end

    local data = self._taskList[idx + 1];

    local config = JsonConfig.GetDailyTaskConfig(data.task_id)

    cellChild:findChildByName("Panel/Text"):setString(config.des);

    cellChild:findChildByName("Panel/Times"):setString(data.taskActiveNum .. "/" .. config.condition[2]);
    local listView = cellChild:findChildByName("Panel/ListView");
    listView:removeAllItems();
    for i = 1, #config.reward do
        local itemCell = self._itemCell:clone();
        itemCell:setVisible(true)
        listView:pushBackCustomItem(itemCell);
        local itemNode = nil
        itemNode = Utils:ShowItemByConfigData(config.reward[i], itemCell, itemNode, true)
    end

    self:ShowTaskBtnState(data, cellChild);
    local btn = cellChild:findChildByName("Panel/Btn");
    btn.userData = idx + 1;
    local function onBtnClicked(sender)
        local ind = sender.userData
        self:onTaskBtnClicked(ind)
    end
    btn:addClickEventListener(onBtnClicked);

    btn = cellChild:findChildByName("Panel/Btn_0");
    btn.userData = idx + 1;
    local function onBtnClicked(sender)
        local ind = sender.userData
        self:onTaskBtnClicked(ind)
    end
    btn:addClickEventListener(onBtnClicked);
    -- if self._recoveryData == nil then
    --     return
    -- end

    -- local cellData = self._recoveryData[idx + 1]
    -- local config = JsonConfig.GetRevertData(cellData.funcId)
    -- local nameLabel = cellChild:findChildByName("title/name")
    -- nameLabel:setString(config.name)
    -- local timeValue = cellChild:getChildByName("times")
    -- timeValue:setString( string.format(GUITips.UI_Activity_LeftTimes, cellData.leftTimes))
    -- local listView = cellChild:getChildByName("item_layer")
    -- listView:removeAllItems()
    -- for i = 1, cellData.awardNum do
    --     local itemInfo = cellData.awardInfo[i]
    --     local awardIcon = self._itemCell:clone()
    --     awardIcon:setVisible(true)
    --     awardIcon:setTouchEnabled(true)
    --     awardIcon:setSwallowTouches(false)
    --     Utils:GetItemCellValue(awardIcon, 0, itemInfo.awardId, true, true, itemInfo.awardNum, nil, true)

    --     awardIcon:getChildByName("Name"):setString(Utils:getItemNameByID(itemInfo.awardId))
    --     listView:pushBackCustomItem(awardIcon)
    -- end 

    -- local str = AppDef:GetMoneyIconById(cellData.cost[1])
    -- cellChild:findChildByName("buyBtn/GoldIcon/Icon"):loadTexture(str, ccui.TextureResType.plistType)
    -- local numLabel = cellChild:findChildByName("buyBtn/GoldIcon/Num")
    -- numLabel:setString(cellData.cost[3]);
    -- local normalBackBtn = cellChild:getChildByName("buyBtn")
    -- local function normalBackEvent(sender)
    --     self:ShowFindDialog(cellData)
    -- end
    -- normalBackBtn:addClickEventListener(normalBackEvent)
end

function HuoyueTaskUI:ShowTaskBtnState(data, cellChild)
    local btn = cellChild:findChildByName("Panel/Btn");
    local rewardBtn = cellChild:findChildByName("Panel/Btn_0");
    local gotImg = cellChild:findChildByName("Panel/Get");
    local info = JsonConfig.GetDailyTaskConfig(data.task_id);
    if  data.state == 0 then
        rewardBtn:setVisible(false);
        if info.jump == 0 then
            btn:setVisible(false);
        else
            btn:setVisible(true);
            gotImg:setVisible(false);
            -- btn:findChildByName("Text"):setString(GUITips.RSI_TARGET_RD_TIPS3);
        end
        
    elseif  data.state == 1 then
        rewardBtn:setVisible(true);
        btn:setVisible(false);
        gotImg:setVisible(false);
        -- btn:findChildByName("Text"):setString(GUITips.RSI_XUEZHAN_TIP5);
    else
        gotImg:setVisible(true);
        btn:setVisible(false);
        rewardBtn:setVisible(false);
    end
end

function HuoyueTaskUI:onTaskBtnClicked(ind)
    if self._taskList[ind] == nil then
        return
    end

    local data = self._taskList[ind];
    if data.state == 0 then
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.TaskLayer")
        self:SendMsg(LGameMsg.m_initUIMsg)
        -- Utils:SendMsg(LUILogicEvent.DeleteUI, "Activity.TaskLayer");
        local info = JsonConfig.GetDailyTaskConfig(data.task_id);
        if info.jump == AppDef.EModuleID.EMID_KAPAI_EQUIPSRENGTH or info.jump == AppDef.EModuleID.EMID_KAPAI_EQUIP_jinglian then
            local datas =  LRoleDataMgr.Pet.equipList.m_petEquips
            local tab = 1
            if info.jump == AppDef.EModuleID.EMID_KAPAI_EQUIP_jinglian then
                tab = 2
            end
            for k,v in pairs(datas) do
                Utils:OpenFunction(info.jump, {tab, v.m_uid})
                return
            end
            Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips2)
        elseif info.jump == AppDef.EModuleID.EMID_KAPAI_FABAO_QIANGHUA then
            local datas =  LRoleDataMgr.Pet.faBaoList.m_petFaBaos

            for k,v in pairs(datas) do
                local cfg = JsonConfig.m_faBaoConfig.getDefByID(v.m_id)
                if cfg.equip == 1 then
                    Utils:OpenFunction(info.jump, {1, k})
                    return
                end
            end
            Utils:SendMsg(LUILogicEvent.ShowScrollTips,GUITips.UI_Title_PetFaBao_Tips1)
        else


        --     if LRoleDataMgr.Faction.Info.id <= 0 then
        --     Utils:OpenFunction(AppDef.EModuleID.EMID_BANGPAI, 4)
        -- else
        --     --Utils:SetRedDotState(RedDotDef.ID.BPSkillUpgrade, true)
        --     Utils:OpenFunction(AppDef.EModuleID.EMID_BPXINXI)
        -- end
            if info.jump == AppDef.EModuleID.EMID_BPFUBEN
            or info.jump == AppDef.EModuleID.EMID_BPXINXI then
                if LRoleDataMgr.Faction.Info.id <= 0 then
                    Utils:ShowScrollTips(GUITips.RSI_FACTION_TIP1)
                    Utils:OpenFunction(AppDef.EModuleID.EMID_BANGPAI, 4)
                else
                    --Utils:SetRedDotState(RedDotDef.ID.BPSkillUpgrade, true)
                    Utils:OpenFunction(info.jump)
                end
            else
                Utils:OpenFunction(info.jump)
            end
            
        end

    elseif data.state == 1 then
        LuaNetSendMsg:QueryGotTaskAward(2, data.task_id)
    end
end

function HuoyueTaskUI:ShowHuoyue(dataArr)
    self._rewardList = dataArr;
    self:HuoyueUpdate();
    
end

function HuoyueTaskUI:ShowFindDialog(cellData)
    -- body
    local function OKCallback()
        local myValue = LRoleDataMgr:GetMoney(cellData.cost[1])
        if cellData.cost[3] > myValue then
            Utils:ShowScrollTips(string.format(GUITips.RSI_GS_TIP_RECOVERY_LIMIT,AppDef.AwrdItemName[cellData.cost[1]]))
            return
        end
        LuaNetSendMsg:QueryResRecovery(2, cellData.funcId, cellData.leftTimes)
    end

    local function cancelCallback()

    end
    Utils:ShowResRecovery(cellData, OKCallback, cancelCallback)
end

function HuoyueTaskUI:ShowFindAllDialog( findType,  cost)
    -- body
    local function OKCallback()
        if cost <= 0 then
            return
        end
        LuaNetSendMsg:QueryResRecovery(3, findType)
    end

    local function cancelCallback()

    end
    Utils:ShowResRecoveryAll(findType, cost, OKCallback, cancelCallback)
end

function HuoyueTaskUI:refrashUI(isTurnToOffset)
    -- self._recoveryData = LRoleDataMgr.recoveryData;
    self._offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()
    
    if isTurnToOffset then
        self.m_pTableView:setContentOffset(self._offset)
    end
end

function HuoyueTaskUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return HuoyueTaskUI