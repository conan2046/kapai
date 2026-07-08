--[[
lua里面的游戏逻辑控制
玩法界面，切标签时需要刷新
]]

local ActivityUI = LUIBase:New()
ActivityUI.__index = ActivityUI
-- local this = LTcpSocket
function ActivityUI:New()
    local o = LUIBase:New()
    setmetatable(o, ActivityUI)
    o:Init()
    return o
end


function ActivityUI:Init()
    -- self.m_pNode = cc.Node:create()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ActivityLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()

    LuaNetSendMsg:QueryDailyActivityList(1)
    LuaNetSendMsg:QueryDailyActivityList(2)
end

function ActivityUI:onExit()
    for i=1,#self.m_imod do
        if self.m_imod[i] ~= nil then
            self.m_imod[i]:removeFromParent()
        end
    end
    self.m_imod = nil
    self.m_pUILayer = nil
    self.m_pRightTableView = nil
    if self.m_button then
        self.m_button:release()
        self.m_button = nil
    end
    self:Destory()
end

--[[
注册UI消息
]]
function ActivityUI:RegistMsgs()
    self.msgIds =
    {
        LUIActivityEvent.RefreshPage,-- 刷新页面
        LUIActivityEvent.ShowBox,--显示宝箱
        LUIActivityEvent.ClickActivity,--点击指定玩法
        LUIActivityEvent.CloseActivityInfoUI,--去除选中
        LUIRoleTeamEvent.TeamMemberChanged, --用于退出队伍,快捷战斗
    }
    self:RegistSelf(self, self.msgIds)
end

function ActivityUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshPage then
        self:UpdateInfo()
    elseif msg.msgId == LUIActivityEvent.ShowBox then
        self:ShowBox()
    elseif msg.msgId == LUIActivityEvent.ClickActivity then
        self:ClickActivity(msg.value)
    elseif msg.msgId == LUIActivityEvent.CloseActivityInfoUI then
        self:CancelSelect()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        if self._functionId == nil then
            return
        end

        if self._functionId ~= AppDef.EActivityID.EAID_ADVANCE then
            return
        end

        self:CloseUI()

        LGameMsg.m_baseMsg:ChangeEventId(LUILoadingEvt.ShowLoading)
        LUIManager:SendMsg(LGameMsg.m_baseMsg)

        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Monopoly.MonopolyBaseUI",AppDef.UIType.Normal)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function ActivityUI:UpdateInfo()
    self:RefreshCell()
    self:RefreshBtnList()
end

function ActivityUI:ShowBox()
    self:ShowBoxList()
    self:UpdateBoxList()
end

function ActivityUI:CancelSelect()
     if self.m_selectItem ~= nil then
        self.m_selectItem:setVisible(false)
        self.m_selectItem = nil
    end
    self.m_selectIdx = -1
end

function ActivityUI:ClickActivity(id)
    local function showInfo(ind)
        if ind <= 0 then return end 
        local idx = math.ceil(ind/2)-1
        if idx < 0 then idx = 0 end
        Utils:MoveToTableIdx(self.m_pRightTableView, self.m_cell, idx)
        local cell = self.m_pRightTableView:cellAtIndex(idx)
        if cell ~= nil then
            local temp = 1
            if ind % 2 == 0 then temp = 2 end
            local cellChild = cell:getChildByTag(123)
            local taskPanel = cellChild:getChildByName("TaskBtn"..temp)
            if taskPanel ~= nil then
                self:ShowInfo(taskPanel)
            end
        end      
    end
    if self.m_tempActivityIdxList == nil then return end
    local info = LActivityManager.m_pActivityDataBuff
    if info == nil or #info <= 0 then
        return
    end  
    for i=1,#self.m_tempActivityIdxList do
        local ind = self.m_tempActivityIdxList[i]
        if #info < ind then break end
        if ind ~= nil and ind > 0 and info[ind] ~= nil and info[ind].id == id then    
            showInfo(i)                 
            break
        end
    end
end

function ActivityUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    --panel:setTouchEnabled(false)
    -- 标签按钮: ListView
    local btnPanel = panel:getChildByName("BtnList")
    self.m_button = btnPanel:getChildByName("Button")
    self.m_button:retain()
    --btnPanel:setVisible(false)
    --btnPanel:setTouchEnabled(false)
    self:InitListView(btnPanel)
    btnPanel:removeFromParent()
    -- 单个按钮
    
    
    self.m_clickIdx = 0
    -- 点击按钮（玩法类型0-全部）
    self.m_btnSelectImgs = { }
    self.m_btnRedDotImgs = { }
    self:LoadButtonList()

    -- TableView 活动图标
    local list = panel:getChildByName("ActivityBg")
    self.m_cell = list:getChildByName("ActivityList")
    self.m_selectIdx = -1
    self.m_tempActivityIdxList = { }
    -- 临时存储需要显示的活动索引
    self.m_curGridNum = 0
    self:InitRightTabView(list)
    list:retain()
    list:removeFromParent()
    --self:RefreshCell()

    --活跃度、宝箱
    local warPanel = panel:getChildByName("ActivityNum")
    warPanel:setLocalZOrder(1)
    local bg = warPanel:getChildByName("ImageBg")
    self.m_LoadingBar = bg:getChildByName("LoadingBar")
    self.m_barLabel = self.m_LoadingBar:getChildByName("ImageDot"):getChildByName("Num")
    self.m_grids = {}
	self.m_qualitys = {}
    self.m_numberLabel = {}
    self.m_icons = {}
    self.m_marks = {}
    self.m_boxState = {}
    self.m_imod = {}
    self.m_maxBoxNum = 5
    for i=1,self.m_maxBoxNum do
        self.m_grids[i] = warPanel:getChildByName("EquipIcon"..i)
        self.m_numberLabel[i] = bg:getChildByName("Num"..(i+1))
    end

end

function ActivityUI:InitListView(LeftView)
    local listView = ccui.ListView:create()
    listView:setDirection(LISTVIEW_DIR_VERTICAL)
    listView:setContentSize(LeftView:getContentSize())
    listView:setAnchorPoint(LeftView:getAnchorPoint())
    listView:setPosition(LeftView:getPosition())
    -- 关闭惯性滑动
    listView:setBounceEnabled(false)
    listView:setSwallowTouches(false)
    -- 设置间距
    listView:setItemsMargin(2)
    -- 隐藏滚动条
    listView:setScrollBarEnabled(false)
    LeftView:getParent():addChild(listView)
    self.m_leftListView = listView
end

function ActivityUI:LoadButtonList()
    self:LoadButton(AppDef.EActivityType.EAT_ALL)
    self:LoadButton(AppDef.EActivityType.EAT_PET)
    self:LoadButton(AppDef.EActivityType.EAT_EXP)
    self:LoadButton(AppDef.EActivityType.EAT_GOLD)
    self:LoadButton(AppDef.EActivityType.EAT_EQUIP)
    self:LoadButton(AppDef.EActivityType.EAT_OTHER) 
end

function ActivityUI:LoadButton(activityType)
    local btn = self.m_button:clone()
    btn:setTag(activityType)
    btn:setPosition(cc.p(0, 0))
    btn:setVisible(true)
    self.m_leftListView:addChild(btn)
    btn:setTouchEnabled(true)
    -- 不拦截点击
    btn:setSwallowTouches(false)
     -- 按钮名称
    local name = btn:getChildByName("BtnName")
    -- 选中图片
    self.m_btnSelectImgs[activityType] = btn:getChildByName("ChooseBg")
    -- 红点
    self.m_btnRedDotImgs[activityType] = btn:getChildByName("RedDot") 
    name:setString(GUITips["ActivityType" .. activityType])

    if activityType == self.m_clickIdx then
        self.m_btnSelectImgs[activityType]:setVisible(true)
        self.m_btnSelectImgs[self.m_clickIdx]:getParent():setTouchEnabled(false)
    else
        self.m_btnSelectImgs[activityType]:setVisible(false)
    end
    self.m_btnRedDotImgs[activityType]:setVisible(false)

    local function btnTouched(sender)
        self.m_selectIdx = -1
        local tag = sender:getTag()
        self.m_btnSelectImgs[self.m_clickIdx]:setVisible(false)
        self.m_btnSelectImgs[self.m_clickIdx]:getParent():setTouchEnabled(true)
        self.m_btnSelectImgs[tag]:setVisible(true)
        self.m_btnSelectImgs[tag]:getParent():setTouchEnabled(false)
        self.m_clickIdx = tag
        self:RefreshCell()
    end
    btn:addClickEventListener(btnTouched)
	self:MarkIntaractCObj(btn)
end

function ActivityUI:RefreshCell()
    local num = 0
    num,self.m_tempActivityIdxList = LActivityManager:GetNum(self.m_clickIdx)
    --print("LActivityManager:GetNum:",LActivityManager:GetNum(self.m_clickIdx))
    self.m_curGridNum = num/2
    if num%2 ~= 0 then
        self.m_curGridNum = self.m_curGridNum+1
    end

    self.m_pRightTableView:reloadData()
end

function ActivityUI:InitRightTabView(rightView)
    local tableView = cc.TableView:create(rightView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    -- cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(rightView:getAnchorPoint())
    tableView:setPosition(rightView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    rightView:getParent():addChild(tableView)

    local function tableCellTouched(sender, cell)
        -- print("tableCellTouched",sender,cell,cell:getIdx())
        self:RightTableCellTouched(cell)
    end
    local function cellSizeForTable(sender, idx)
        local width = self.m_cell:getContentSize().width
        local height = self.m_cell:getContentSize().height
        -- print("width=",width, "height",height)
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:RightTableCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        return self.m_curGridNum
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    -- tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
    -- 此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
    -- 此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    -- 此回调需要返回TableView中Cell的数量

    tableView:registerScriptHandler(scrollViewDisScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- tableView:reloadData()
    self.m_pRightTableView = tableView
end


--参加按钮
 function ActivityUI:EnterBtnTouched(data)
    self._functionId = data.id
    if self:TeamEvent() then
        return
    end

    if LRoleDataMgr.m_bIsCrossServer then
        local buffer = {
            -- [AppDef.EActivityID.EAID_ADVANCE] = true,
            [AppDef.EActivityID.EAID_PLANT] = true,
        }
        if buffer[data.id] then
            Utils:ShowScrollTips(GUITips.RSI_CROSSSERVER_TIPS_2)
            return
        end
    end
    self:CloseUI()
    EnterBtnTouched(data.id)
 end

 function ActivityUI:TeamEvent()
    if self._functionId == AppDef.EActivityID.EAID_ADVANCE then
        if LRoleDataMgr.MyHeroInfo:IsTeam() then
            local function okFunc()
                LuaNetSendMsg:QueryLeaveTeam()
            end
            local function canelFunc()
                
            end
            Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS14, okFunc,canelFunc)

            return true
        end
    end
    return false
end

function ActivityUI:ShowInfo(sender)
    local id = sender.userObject
    if id == nil or id == 0 or self.m_isDragging then
        return
    end
    if self.m_selectItem ~= nil then
        self.m_selectItem:setVisible(false)
    end
    self.m_selectItem = sender:getChildByName("Choose")
    if self.m_selectItem ~= nil then
        self.m_selectItem:setVisible(true)
    end
    local enterButton = sender:getChildByName("EnterBtn") --参加按钮
    if enterButton ~= nil then
        self.m_selectIdx = enterButton:getTag()
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.ActivityInfoUI",AppDef.UIType.PopWindow,id)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function ActivityUI:RightTableCellAtIndex(sender, idx)
    local function btnTouched(sender)--参加按钮
        if self.m_tempActivityIdxList == nil then
            return
        end
        local index = sender:getTag()
        local ind = self.m_tempActivityIdxList[index]
        if ind == nil or ind == 0 then
            return
        end

        local info = LActivityManager.m_pActivityDataBuff
        if info == nil or #info < ind then
            return
        end
        
        self:EnterBtnTouched(info[ind])
    end

    local function showInfo(sender)
        self:ShowInfo(sender)
    end

    local min = idx * 2
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_cell:clone()

        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cell:addChild(cellChild)
        cellChild:setTouchEnabled(false)
        
        for i = 1, 2 do
            local taskPanel = cellChild:getChildByName("TaskBtn"..i)
            taskPanel:setSwallowTouches(false)
            taskPanel:addClickEventListener(showInfo)
			self:MarkIntaractCObj(taskPanel)
            local enterButton = taskPanel:getChildByName("EnterBtn") --参加按钮
            enterButton:setTag(i+min)
            enterButton:addClickEventListener(btnTouched)
			self:MarkIntaractCObj(enterButton)
        end
    else
        cellChild = cell:getChildByTag(123)
        for i = 1, 2 do
            local taskPanel = cellChild:getChildByName("TaskBtn"..i)
            local enterButton = taskPanel:getChildByName("EnterBtn") --参加按钮
            enterButton:setTag(i+min)
        end
    end
    self:ShowRightCellInfo(cellChild, idx)

    return cell
end

function ActivityUI:ShowRightCellInfo(cellChild, idx)
    local min = idx * 2;
    for i = 1, 2 do
        local taskPanel = cellChild:getChildByName("TaskBtn"..i)
        self:RefreshActivityInfo(taskPanel, min+i)
    end
end

function ActivityUI:RefreshActivityInfo(taskPanel,index)
    if self.m_tempActivityIdxList == nil then
        return
    end
    
    local ind = self.m_tempActivityIdxList[index]
    if ind == nil or ind == 0 then
       taskPanel:setVisible(false)
       return
    end

    local info = LActivityManager.m_pActivityDataBuff
    if info == nil or #info < ind then
        return
    end

    --print("RefreshActivityInfo",index,info[ind].id,info[ind].type)
    taskPanel:setVisible(true)
    local cntTLabel = taskPanel:getChildByName("Times")
    local cntLabel = cntTLabel:getChildByName("Num")
    local nameLabel = taskPanel:getChildByName("TaskName")
    local iconImage = taskPanel:getChildByName("Icon")
    local signImage = taskPanel:getChildByName("State")
    local pointTLabel = taskPanel:getChildByName("Activity") --活跃度 
    local pointLabel = pointTLabel:getChildByName("Num")
    local enterButton = taskPanel:getChildByName("EnterBtn") --参加按钮
    local openLvLabel = taskPanel:getChildByName("OpenLevel")
    local quest_over = taskPanel:getChildByName("win") --任务完成
    local choose = taskPanel:getChildByName("Choose")
	local award = taskPanel:getChildByName("award")--奖励图标

    signImage:setVisible(false)
    pointTLabel:setVisible(false)
    cntTLabel:setVisible(false)
    quest_over:setVisible(false)
	
	

    if self.m_selectIdx == index then
        choose:setVisible(true)
    else
        choose:setVisible(false)
    end


    nameLabel:setString(info[ind].name)
    pointTLabel:setString(GUITips.RSL_AY_MSG1)
    openLvLabel:setString("")
	--print(info[ind].id,info[ind].name)
    if info[ind].id == 1 then
		award:loadTexture("item/equip3013.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 2 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 3 then
		award:loadTexture("item/equip3021.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 4 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 5 then
		award:loadTexture("item/equip5051.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 6 then
		award:loadTexture("item/equip3013.png",  ccui.TextureResType.localType)
        award:setVisible(true)
    elseif info[ind].id == 7 then
		award:loadTexture("item/equip3006.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 8 then
		award:loadTexture("item/equip5001.png",  ccui.TextureResType.localType)
        award:setVisible(true)
    elseif info[ind].id == 9 then
		award:loadTexture("item/equip5000.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 14 then
		award:loadTexture("item/equip3005.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 16 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 17 then
		award:loadTexture("item/equip3104.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 24 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 25 then
		award:loadTexture("item/equip3504.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 26 then
		award:loadTexture("item/equip3022.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 28 then
		award:loadTexture("item/equip3026.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 29 then
		award:loadTexture("item/equip10049.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 30 then
		award:loadTexture("item/equip3503.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 31 then
		award:loadTexture("item/equip5238.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 32 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 33 then
		award:loadTexture("item/equip557.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 34 then
		award:loadTexture("item/equip3026.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 35 then
		award:loadTexture("item/equip3006.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 36 then
		award:loadTexture("item/equip3026.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 37 then
		award:loadTexture("item/equip4406.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 38 then
		award:loadTexture("item/equip5235.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 39 then
		award:loadTexture("item/equip5235.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 40 then
		award:loadTexture("item/equip3022.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 41 then
		award:loadTexture("item/equip5235.png",  ccui.TextureResType.localType)
		award:setVisible(true)
	elseif info[ind].id == 43 then
		award:loadTexture("item/equip3105.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 44 then
		award:loadTexture("item/equip540.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 45 then
		award:loadTexture("item/equip3014.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 46 then
		award:loadTexture("item/equip3006.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 47 then
		award:loadTexture("item/equip520.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 49 then
		award:loadTexture("item/equip3106.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 50 then
		award:loadTexture("item/equip1802.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 51 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
		award:setVisible(true)	
	elseif info[ind].id == 52 then
		award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
        award:setVisible(true)	
    elseif info[ind].id == 53 then
		award:loadTexture("item/equip5051.png",  ccui.TextureResType.localType)
        award:setVisible(true)	
    else
        award:loadTexture("item/equip3007.png",  ccui.TextureResType.localType)
        award:setVisible(true)
	end
	
	
	
    if info[ind].state ~= 1 then 
        if info[ind].opentime == "全天" then
            openLvLabel:setString(info[ind].openLv..GUITips.UI_JiKaiqi)
        else
            pointTLabel:setVisible(true)
            pointTLabel:setString(GUITips.RSL_AY_MSG2..": "..info[ind].opentime)
            pointLabel:setString("")
        end
        enterButton:setVisible(false)
    else 
        local cntMax = LActivityManager:GetMaxCount(ind) --次数
        if cntMax ~= 999 then
            cntTLabel:setVisible(true) 
            --print("finishState:",info[ind].finishState)
            cntLabel:setString(info[ind].finishState)   
            if info[ind].id == AppDef.EActivityID.EAID_ORDEAL then
                cntTLabel:setString(GUITips.Activity_Cnt_3)
            else
                cntTLabel:setString(GUITips.Activity_Cnt_2)
            end
        end
        if LActivityManager:IsShowPoint(ind) then 
            pointTLabel:setVisible(true)
            pointLabel:setString(info[ind].activeVal)
        end
        if info[ind].isFinished then
            quest_over:setVisible(true)
            enterButton:setVisible(false)
        else
            enterButton:setVisible(true)
        end
    end 
    iconImage:loadTexture(AppDef.GUIRes["Activity_Name"..info[ind].id],ccui.TextureResType.localType)
    taskPanel.userObject = info[ind].id
end

function ActivityUI:RefreshBtnList()
    self:RefreshBtnRed(AppDef.EActivityType.EAT_ALL)
    self:RefreshBtnRed(AppDef.EActivityType.EAT_PET)
    self:RefreshBtnRed(AppDef.EActivityType.EAT_EXP)
    self:RefreshBtnRed(AppDef.EActivityType.EAT_EQUIP)
    self:RefreshBtnRed(AppDef.EActivityType.EAT_OTHER)
    self:RefreshBtnRed(AppDef.EActivityType.EAT_GOLD)
end

--显示宝箱
function ActivityUI:ShowBoxList()
    local function OnClick(sender)
        local idx = sender:getTag()
        local itemId = sender.userObject
        local state = self.m_boxState[idx]
        if state == 2 then
            local boxCofig = LActivityManager:GetBoxConfig()
            --点击领取宝箱
            LuaNetSendMsg:QueryDailyActivityList(3,boxCofig.m_activeVals[idx])
        elseif state == 3 then
            --tips
            local item = nil
            if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then
                item = 
		        {
		            itemType = "CItem",
		            itemData = LItemMgr:getItem(itemId)
		        }
            elseif itemId == AppDef.AwrdItem.AWRD_ITEM_COIN then
                item = 
		        {
		            itemType = "CItem",
		            itemData = LItemMgr:getItem(itemId)
		        }
            end
		    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
    end

    local function _CatItemImagePath(atype)
        local resid = GUITipsAwrdItemIdMap[atype]
        if not resid then
            --Debug("_CatItemImagePath error typeid "..atype)
            return ""
        end 
        local imagef = "item/equip"..resid..".png"
        return imagef
    end

    local boxCofig = LActivityManager:GetBoxConfig()
    local num = boxCofig.m_count
    if num == 0 then 
        return
    elseif num >  self.m_maxBoxNum then
        num = self.m_maxBoxNum
    end
    for i=1,num do
        local items = boxCofig.m_itemIdNums[i]
        if items == nil or items[1] == nil then 
            break
        end
        local itemId = items[1].itemId
        local itemNum = items[1].itemNum or 1

		local str = "Quality"
		self.m_qualitys[i]  = self.m_grids[i]:getChildByName(str)
        self.m_qualitys[i]:ignoreContentAdaptWithSize(false)
		local itemData = LItemMgr:getItem(itemId)
		local str = ""
		if itemData == nil then
			str = AppDef.ColorKuangArr[4]
		else
			str = AppDef.ColorKuangArr[itemData.m_quality]
		end
		self.m_qualitys[i]:loadTexture(str,ccui.TextureResType.plistType)
        --self.m_icons[i] = Utils:GetItemCellValue(self.m_grids[i], 0, itemId, true, false, num, self.m_icons[i], false)
        str = "Icon"
        self.m_icons[i]  = self.m_grids[i]:getChildByName(str)
        self.m_icons[i]:ignoreContentAdaptWithSize(false)
        local picName = ""
        if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then
            picName = LItemMgr:GetItemPicFileName(itemId)
        else
           picName = _CatItemImagePath(itemId)
           self.m_grids[i]:setTouchEnabled(false)
        end
        self.m_icons[i]:loadTexture(picName,ccui.TextureResType.localType)
        str = "Mark"
        self.m_marks[i] = self.m_grids[i]:getChildByName(str)
        self.m_marks[i]:setVisible(false)
        self.m_grids[i]:addClickEventListener(OnClick)
		self:MarkIntaractCObj(self.m_grids[i])
        self.m_grids[i].userObject = itemId
        self.m_grids[i]:setTag(i)
        self.m_numberLabel[i]:setString(""..boxCofig.m_activeVals[i]..GUITips.RSI_DA_MSG1)
    end
end

--
function ActivityUI:UpdateBoxList()
    if self.m_icons == nil then
        return
    end
    local boxInfo = LActivityManager:GetBoxInfo()
    local num = #self.m_icons
    if num == 0 then 
        return
    end
    local boxCofig = LActivityManager:GetBoxConfig()
    local val = boxInfo.m_activeVal  --活跃度
    for i=1,num do
        if boxCofig.m_activeVals[i] == nil or val < boxCofig.m_activeVals[i] then
            --self.m_marks[i]:setVisible(true)
            local itemId = boxCofig.m_itemIdNums[i][1].itemId
            if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then
                self.m_grids[i]:setTouchEnabled(true)
            end
            self.m_icons[i]:setColor(AppDef.UIColor.WHITE)
            self.m_boxState[i] = 3 --不可领取
            if self.m_imod[i] ~= nil then
                self.m_imod[i]:removeFromParent()
                self.m_imod[i] = nil
            end
			--[[if self.m_imod[i] == nil and (boxCofig.m_activeVals[i] == 20 or boxCofig.m_activeVals[i] == 60) then
                local size = self.m_grids[i]:getContentSize()
                self.m_imod[i] = Utils:CreateImod("res2/fx/gaojiwupin",cc.p(size.width/2,size.height/2),self.m_grids[i],0.8)
                self.m_imod[i]:PlayActionRepeat(0)
            end]]
        else
            --self.m_marks[i]:setVisible(false)
            if boxInfo.m_states[i] == 1 then
               self.m_grids[i]:setTouchEnabled(false)
               self.m_icons[i]:setColor(cc.c3b(0x7f,0x7f,0x7f))
               self.m_boxState[i] = 1 --已领取
               if self.m_imod[i] ~= nil then
                   self.m_imod[i]:removeFromParent()
                   self.m_imod[i] = nil
               end
            else
               self.m_grids[i]:setTouchEnabled(true)
               self.m_icons[i]:setColor(AppDef.UIColor.WHITE)
               self.m_boxState[i] = 2 --可领取
               if self.m_imod[i] ~= nil then
                   self.m_imod[i]:removeFromParent()
                   self.m_imod[i] = nil
               end
               if self.m_imod[i] == nil then
                   local size = self.m_grids[i]:getContentSize()
                   self.m_imod[i] = Utils:CreateImod("res2/fx/huoyuedujiangli",cc.p(size.width/2,size.height/2),self.m_grids[i],1)
                   self.m_imod[i]:setScale(1.5)
                   self.m_imod[i]:PlayActionRepeat(0)
               end
            end
        end
    end
    self.m_barLabel:setString(tostring(val))
    local maxVal = boxCofig.m_activeVals[num] 
    if maxVal == nil or maxVal == 0 then
        maxVal = 100
    end
    self.m_LoadingBar:setPercent(val*100/maxVal)
    local width = self.m_LoadingBar:getContentSize().width
    self.m_barLabel:getParent():setPosition(cc.p(width*val/maxVal,10))
end

function ActivityUI:RefreshBtnRed(activityType)
   if self.m_btnRedDotImgs == nil then
       return
   end
   local redImage = self.m_btnRedDotImgs[activityType]

   local red = LActivityManager:CheckRedDot(activityType)
   if red then
        redImage:setVisible(true)
   else
       redImage:setVisible(false)
   end
end

function ActivityUI:CloseUI()
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.ActivityMainUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

return ActivityUI