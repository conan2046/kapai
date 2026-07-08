local FengShenStoryMainUI = LUIBase:New()
FengShenStoryMainUI.__index = FengShenStoryMainUI
FengShenStoryMainUI.IsHideInBattle = true
function FengShenStoryMainUI:New()
    local o = LUIBase:New()
    setmetatable(o,FengShenStoryMainUI) 
    o:Init()
    return o
end

--[[
注册消息
]]
function FengShenStoryMainUI:RegistMsgs()
    self.msgIds = 
    {
         LUIActivityEvent.RefreshFengShenStoryUI,
         --LUIActivityEvent.FengShenStoryFightEnd,
    }
    self:RegistSelf(self,self.msgIds)
end

function FengShenStoryMainUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshFengShenStoryUI then
        self:RefreshAll()
    -- elseif msg.msgId == LUIActivityEvent.FengShenStoryFightEnd then
    --     self:FightEndOpenBox()
    end
end


function FengShenStoryMainUI:Init()
    self.Script = "FengShenStory.FengShenStoryMainUI"
    self:CreateUINode("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:RefreshItem()
    self:UpdateUI()
    self:PlayAction()

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_FengShenStory)
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,FengShenStoryMainUI.CloseUI))
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.LieZhuan)

    LuaNetSendMsg:QueryFengShenStory(24)--请求数据
end

function FengShenStoryMainUI:InitData()
    --关卡
    local panel1 = self.m_pUILayer:getChildByName("Panel_1")
    self.m_levelPanels = {}
    for i=1,4 do
        if self.m_levelPanels[i] == nil then
            self.m_levelPanels[i] = {}
        end
        for k=1,3 do
            self.m_levelPanels[i][k] = panel1:getChildByName("chapter_"..i..k)
            self.m_levelPanels[i][k]:addClickEventListener(handler(self,FengShenStoryMainUI.OpenLevelUI))
        end
    end
    self.m_cntLabel = panel1:getChildByName("today"):getChildByName("num")
    self.m_chapterNameLabel = panel1:getChildByName("Image_78"):getChildByName("text2")
    self.m_chapterIdLabel = panel1:getChildByName("Image_78"):getChildByName("list")
    local boxPanel = panel1:getChildByName("Box1")
    self.m_boxBtn = boxPanel:getChildByName("Button1") --底关箱子
    self.m_boxBtn:addClickEventListener(handler(self,FengShenStoryMainUI.OpenBoxReward))
    self.m_openBoxBtn = boxPanel:getChildByName("Button") --开启状底关箱子
    self.m_openBoxBtn:addClickEventListener(handler(self,FengShenStoryMainUI.OpenBoxReward))
    --宝箱红点
    self.m_boxRedImg = self.m_boxBtn:getChildByName("Prompt")

    --章节列表
    local panel2 = self.m_pUILayer:getChildByName("Panel_2")
    local topView = panel2:getChildByName("TableView")
    self.m_pGridCell = topView:getChildByName("reel")
    self:InitTableView(topView)
    topView:setVisible(false)

    self.m_id = 0
    self.m_boxState  = 0
end

function FengShenStoryMainUI:PlayAction()
    local action = cc.CSLoader:createTimeline("csd/fengshenliezhuan/fengshenliezhuanlLayer.csb")
    self.m_pUILayer:runAction(action)
    action:pause()
    action:play("animation0",false)
end

function FengShenStoryMainUI:OpenLevelUI(sender)
    local id = sender.userObject
    if id == nil or id == 0 then
        Utils:ShowScrollTips(GUITips.RSI_FENGSHEN_SHILIAN_TIP1)
        return
    end
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "FengShenStory.FengShenStoryLevelUI",AppDef.UIType.PopWindow, id)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function FengShenStoryMainUI:OpenBoxReward(sender)
    local function rewardCallBack()
        --领取奖励
        LuaNetSendMsg:SendFengShenStoryBoxReq(self.m_id,self.m_boxLevelId)
    end
    --print("FengShenStoryMainUI:OpenBoxReward",self.m_boxId)
    if self.m_boxId == 0 then
        return
    end
    local cfg = JsonConfig.m_BoxReward.getDefByID(self.m_boxId)
    if cfg == nil then
        return
    end
    local isShowBtn = self:CheckBoxState()
    local tips = ""
    if self.m_boxState == 0 then
        tips = GUITips.RSI_BOX_TIP3
    end
    Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,cfg.reward,isShowBtn,tips,rewardCallBack)
end

function FengShenStoryMainUI:CheckBoxState()
    local data = LActivityManager:GetFengShenStoryData()
    if data.m_giftBoxs == nil or #data.m_giftBoxs == 0 then
        return false
    end
    for i=1,#data.m_giftBoxs do
        local value = data.m_giftBoxs[i]
        if value.chapterId == self.m_id --[[and value.m_levelId == self.m_boxLevelId]] then
            return true
        end 
    end
    return false
end

function FengShenStoryMainUI:FightEndOpenBox()
    local function rewardCallBack()
        --领取奖励
        LuaNetSendMsg:SendFengShenStoryBoxReq(chapterId,levelId)
    end

    local data = LActivityManager:GetFengShenStoryData()
    if data.m_giftBoxs == nil or #data.m_giftBoxs == 0 then
        self:UpdateUI()
        return
    end
    local chapterId = data.m_giftBoxs[1].chapterId
    local levelId = data.m_giftBoxs[1].levelId
    if chapterId == 0 or levelId == 0 then
        return
    end
    self:RefreshAll()
    --print("FengShenStoryMainUI:OpenBoxReward",self.m_boxId)
    local levelCfg = JsonConfig.m_stageNodeConfig.getDefByID(levelId)
    if levelCfg == nil then
        return
    end
    local cfg = JsonConfig.m_BoxReward.getDefByID(levelCfg.add_reward)
    if cfg == nil then
        return
    end
    local isShowBtn = true
    local tips = ""
    Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,cfg.reward,isShowBtn,tips,rewardCallBack)
end

function FengShenStoryMainUI:RefreshAll()
    self.m_id = 0
    self:RefreshItem()
    self:UpdateUI()
end

function FengShenStoryMainUI:RefreshItem()
    local data = LActivityManager:GetFengShenStoryData()
    self.m_startId = 1
    local max = #JsonConfig.m_vecFengShenStoryId
    if max > 0 then
        max = data.m_chapterId%max
        if data.m_chapterId > max then
            self.m_startId = data.m_chapterId - max +1
        end
    end
    self.m_curGridNum = max
    self.m_pTopTableView:reloadData()
end

function FengShenStoryMainUI:InitTableView(topView)
    local tableView = cc.TableView:create(topView:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(topView:getAnchorPoint())
    tableView:setPosition(topView:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    --tableView:setBounceable(false)
    --tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    topView:getParent():addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        self:TopViewCellTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TopViewCellAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView() 
        return self.m_curGridNum
    end

    local function scrollViewDisScroll(view)
        self.m_isDragging = view:isDragging()
    end

    tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:registerScriptHandler(scrollViewDisScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_pTopTableView = tableView
end

function FengShenStoryMainUI:TopViewCellTouched(cell)
    local ind = cell:getIdx()
    --print("FengShenStoryMainUI:TopViewCellTouched",ind)
    local offset = self.m_pTopTableView:getContentOffset()
    --print("offsetx",offset.x)
    if self.m_isDragging or self.m_id == ind+self.m_startId then
        return
    end
    self.m_id = ind+self.m_startId
    self:ShowChapter()
end

function FengShenStoryMainUI:TopViewCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setSwallowTouches(false)
        cell:addChild(cellChild)
    else
        cellChild = cell:getChildByTag(123)
    end
    self:ShowCellInfo(cellChild, idx)
    return cell
end

function FengShenStoryMainUI:ShowCellInfo(cellChild, idx)
    local chapterPanel = cellChild:getChildByName("Image_2")
    local chapterNameLabel = chapterPanel:getChildByName("Text_1")
    local chapterIdLabel = chapterPanel:getChildByName("Text_2")
    local iconImg = cellChild:getChildByName("Image_1")
    local passImg = cellChild:getChildByName("Image_3")
    passImg:setVisible(false)

    local chapterId = idx+self.m_startId
    local cfg = JsonConfig.GetFengShenStoryData(chapterId)
    if cfg == nil then
        return
    end
    local data = LActivityManager:GetFengShenStoryData()
    if data.m_chapterId == nil then
        return
    end
    local max = data.m_chapterId
    if data.m_giftBoxs ~= nil and #data.m_giftBoxs > 0 and data.m_giftBoxs[1].chapterId < max then
        max = data.m_giftBoxs[1].chapterId
    end
    if chapterId < max then
        passImg:setVisible(true)
    end
    chapterIdLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP7,chapterId))
    chapterNameLabel:setString(cfg.Name)
    local str = AppDef.FengShenStoryChapterIconArr[1]
    if chapterId%3 == 0 then
        str = AppDef.FengShenStoryChapterIconArr[2]
    end
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.plistType)
end


function FengShenStoryMainUI:UpdateUI()
    if self.m_id == 0 then
        local data = LActivityManager:GetFengShenStoryData()
        local idx = 0
        if data.m_giftBoxs ~= nil and #data.m_giftBoxs > 0 and data.m_giftBoxs[1].chapterId < data.m_chapterId then
            idx = 1
        end
        if self.m_curGridNum > 6 then
            Utils:MoveToTableIdx(self.m_pTopTableView,self.m_pGridCell,idx)
        else
            local offset =  self.m_pTopTableView:getContentOffset()
            offset.x = 0
            self.m_pTopTableView:setContentOffset(offset)
        end
        
        if data.m_chapterId ~= nil then
            self.m_id = data.m_chapterId-idx
        end
    end
    self:ShowChapter()
end

function FengShenStoryMainUI:ShowChapter()
    self.m_boxState  = 0
    self.m_boxId = 0
    local data = LActivityManager:GetFengShenStoryData()
    if data.m_chapterId == nil then
        return
    end
    for i=1,4 do
        for k=1,3 do
            self.m_levelPanels[i][k]:setVisible(false)
        end
    end
    if self.m_id == 0 then
        self.m_id = data.m_chapterId
    end
    local cfg = JsonConfig.GetFengShenStoryData(self.m_id)
    if cfg == nil then
        return
    end
    
    local list = data:GetChapterInfo(self.m_id)
    for i=1,4 do
        local node = self.m_levelPanels[i][list[i] or 1]
        node:setVisible(true)
        self:ShowLevel(node,i,cfg.Id)
    end
    --print("FengShenStoryMainUI:ShowChapter id",str)
    self.m_chapterNameLabel:setString(cfg.Name)
    self.m_chapterIdLabel:setString(""..self.m_id)

    if data.m_maxCnt == 0 then
        local configData = JsonConfig.m_config.getDefByID(4)
        if configData ~= nil then
            data.m_maxCnt = tonumber(configData.value)
        end
    end
    if data.m_maxCnt < data.m_cnt then
        data.m_maxCnt = data.m_cnt
    end
    self.m_cntLabel:setString(""..data.m_cnt.."/"..data.m_maxCnt)

    if self.m_boxState == 2 then
        self.m_boxBtn:setVisible(false)
        self.m_openBoxBtn:setVisible(true)
    else
        self.m_boxBtn:setVisible(true)
        self.m_openBoxBtn:setVisible(false)
        if self.m_boxState == 1 then
            self.m_boxRedImg:setVisible(true)
        else
            self.m_boxRedImg:setVisible(false)
        end
    end
end

--小节显示
function FengShenStoryMainUI:ShowLevel(node,idx,chapterId)
    local bgImg = node:getChildByName("Image_2")
    local iconImg = node:getChildByName("Icon")
    local nameLabel = node:getChildByName("Image_3"):getChildByName("Text_1")
    local curImg = node:getChildByName("Image_4")
    local bossImg = node:getChildByName("Image_1")
    curImg:setVisible(false)
    nameLabel:setString("")
    bgImg:setColor(CCWHITE)
    bgImg:setTouchEnabled(false)
    iconImg:setColor(CCWHITE)
    if bossImg ~= nil then
        bossImg:setColor(CCWHITE)
        bossImg:setTouchEnabled(false)
    end
    node.userObject = 0

    local id = chapterId*10+idx
    --print("FengShenStoryMainUI:ShowLevel id",id)
    local cfg = JsonConfig.m_stageNodeConfig.getDefByID(id)
    if cfg == nil then
        return
    end
    
    local data = LActivityManager:GetFengShenStoryData()
    if idx == 4 then
        bgImg:setVisible(false)
        self.m_boxLevelId = id 
        self.m_boxId = cfg.add_reward
        if data.m_giftBoxs ~= nil and #data.m_giftBoxs > 0 and data.m_giftBoxs[1].levelId == id then
            self.m_boxState = 1
        elseif id < data.m_curLevelId then
            self.m_boxState = 2
        end
    end
    nameLabel:setString(cfg.Name)
    node.userObject = id
    if data.m_curLevelId == id then
        curImg:setVisible(true)
    elseif data.m_curLevelId < id then
        bgImg:setColor(CCGRAY)
        iconImg:setColor(CCGRAY)
        if bossImg ~= nil then
            bossImg:setColor(CCGRAY)
        end
        node.userObject = 0
    end
    local fightCfg = JsonConfig.m_vecFightConfig.getDefByID(cfg.fightID)
    if fightCfg == nil then
        return
    end
    local monsterCfg = LDataConstMgr:GetMonsterData(fightCfg.show)--JsonConfig.m_MonsterBoss.getDefByID(fightCfg.show)
    if monsterCfg == nil then
        return
    end
    local str = Utils:GetMonsterIconRes(monsterCfg.pic, AppDef.HeadIconResType.Square)
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.localType)
end

function FengShenStoryMainUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "FengShenStory.FengShenStoryMainUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function FengShenStoryMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    self.m_boxId = nil
    self.m_boxState = nil
    self.m_id = nil
    self.m_boxLevelId = nil
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
end

function FengShenStoryMainUI:OnEnter()
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
end

return FengShenStoryMainUI