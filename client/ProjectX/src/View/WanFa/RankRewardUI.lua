--[[
lua里面的游戏逻辑控制
竞技场挑战界面
]]
local RankRewardUI = LUIBase:New()
RankRewardUI.__index = RankRewardUI
RankRewardUI.IsHideInBattle = true

--local this = LTcpSocket
function RankRewardUI:New()
    --print("RankRewardUI",userData)
	local o = LUIBase:New()
	setmetatable(o,RankRewardUI)	
    o:Init(userData)
	return o
end

local SPEED = 300--/秒

function RankRewardUI:Init()
    --self.m_pGuideBtn = nil
    self.Script = "WanFa.RankRewardUI"
    self:CreateUINode("csd/shijieboss/paimingjiangli.csb")

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:initControlUI()
    self:RankTabChange(self.m_tabBtns[1])
end

function RankRewardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

--[[
注册UI消息
]]
function RankRewardUI:RegistMsgs()
    self.msgIds = 
    {
        -- LUIRankEvent.RankListInfo,
        -- LUIArenaEvent.UpdateHeroListInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function RankRewardUI:ProcessEvent(msg)
    -- if msg.msgId == LUIRankEvent.RankListInfo or msg.msgId == LUIArenaEvent.UpdateHeroListInfo then
    --     self:ShowInfo()
    -- end
end

function RankRewardUI:InitData()
    self.m_tabBtns = {}
    self.m_tabImgs = {}
    self.m_rewardCells = {}
    for i=1,2 do
        self.m_rewardCells[i] = {}
    end
    self.m_ind = 1 
    self.m_rType = 0
end

function RankRewardUI:initControlUI()
    local panel = self.m_pUILayer:getChildByName("Popup")
    panel:setTouchEnabled(false)
    --页签
    local tabPanel = panel:getChildByName("CheckList")
    for i=1,2 do
        self.m_tabBtns[i] = tabPanel:getChildByName("Type"..i)
        self.m_tabBtns[i].userObject = i
        self.m_tabBtns[i]:addClickEventListener(handler(self,RankRewardUI.RankTabChange))
        self.m_tabImgs[i] = self.m_tabBtns[i]:getChildByName("Choose")
    end
    --奖励列表
    local layout = panel:findChildByName("bg/ListView")
    self.m_listView1 = Utils:CreateListView(layout,LISTVIEW_DIR_VERTICAL,1)
    self.m_listView2 = Utils:CreateListView(layout,LISTVIEW_DIR_VERTICAL,1)
    self.m_bangCell = panel:getChildByName("Item_bangpai")
    self.m_cell = panel:getChildByName("Item_geren")
    self.m_myBangReward = panel:getChildByName("Own_bangpai")
    self.m_myReward = panel:getChildByName("Own_geren")

    self.m_itemCell = self.m_bangCell:getChildByName("IconItem")
    self.m_itemCell:retain()
    self.m_itemCell:removeFromParent()
    
    --通用底框设置
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_WANFA_TIPS4)
    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, RankRewardUI.RemoveUI))
end

function RankRewardUI:RankTabChange(sender)
    local ind = sender.userObject
    if ind == 1 then
        self.m_tabBtns[1]:setTouchEnabled(false)
        self.m_tabImgs[1]:setVisible(true)
        self.m_tabBtns[2]:setTouchEnabled(true)
        self.m_tabImgs[2]:setVisible(false)
        self.m_rType = 32
    else
        self.m_tabBtns[2]:setTouchEnabled(false)
        self.m_tabImgs[2]:setVisible(true)
        self.m_tabBtns[1]:setTouchEnabled(true)
        self.m_tabImgs[1]:setVisible(false)
        self.m_rType = 31
    end
    self:ShowRewardList()
    self:ShowMyRank()
end

function RankRewardUI:ShowRewardList()
    self.m_listView1:setVisible(false)
    self.m_listView2:setVisible(false)
    local data =  LActivityManager:GetWorldBossData()
    local listView = self.m_listView1
    local cells = self.m_rewardCells[1]
    local info = data.m_leftRanks
    local cell = self.m_bangCell
    if self.m_rType == 31 then
        listView = self.m_listView2
        cells = self.m_rewardCells[2]
        info = data.m_rightRanks
        cell = self.m_cell
    end
    listView:setVisible(true)
    if info == nil then
        info = {}
    end
    for i=1,#info do
        local value = info[i]
        if cells[i] == nil then
            cells[i] = cell:clone()
            listView:pushBackCustomItem(cells[i])
        end
        self:ShowOneRank(cells[i],value)
    end
    local num = #info+1
    local cfgDatas = JsonConfig.m_mapRewardRank[self.m_rType]
    for i=1,#cfgDatas do
        local cfg = JsonConfig.m_rewardRank.getDefByID(cfgDatas[i].id)
        if cfg ~= nil and #cfg.rank > 1 and cfg.rank[2] > #info then
            if cells[num] == nil then
                cells[num] = cell:clone()
                listView:pushBackCustomItem(cells[num])
            end
            self:ShowOneReward(cells[num],cfg)
            num = num + 1
        end
    end
end

function RankRewardUI:ShowOneRank(sender,data)
    if data == nil then
        return
    end
    for i=1,3 do
        sender:getChildByName("Num_"..i):setVisible(false)
    end
    local numLabel = sender:getChildByName("Num_4")
    numLabel:setString("")
    if data.rank < 4 then
        sender:getChildByName("Num_"..data.rank):setVisible(true)
    else
        local number = ""..data.rank
        numLabel:setString(string.format(GUITips.UI_Arena_Msg9,number))
    end

    local nameLabel = sender:getChildByName("Name")
    local signImg = sender:getChildByName("Lable")
    local hurtLabel = sender:findChildByName("Power/Value")
    local itemPanel = sender:getChildByName("IconItem")
    local listView = sender:getChildByName("ListView")
    if itemPanel ~= nil then
        itemPanel:setVisible(false)
    end
    nameLabel:setString(data.name)
    hurtLabel:setString(Utils:getPowerStr(data.sorce))
    signImg:setVisible(false)
    if self.m_rType == 31 then
        if LRoleDataMgr.MyHeroInfo.id == data.id then
            signImg:setVisible(true)
        end
    elseif LRoleDataMgr.Faction.Info.id == data.id then
        signImg:setVisible(true)
    end
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    local cfgData = JsonConfig.GetRewardRankCfg(self.m_rType,data.rank)
    for i=1,#cfgData.reward do
        local value = cfgData.reward[i]
        local cell = self.m_itemCell:clone()
        local iconImg = cell:getChildByName("Icon")
        local cntLabel = cell:getChildByName("Value")
        local bgImg = cell:getChildByName("bg")
        local imgPath,color = LDataConstMgr:GetRewardItemPicPath(value)
        Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
        Utils:SafeLoadTexture(bgImg,AppDef.ColorKuangArr[color],ccui.TextureResType.plistType)
        cntLabel:setString(""..value[3])
        listView:pushBackCustomItem(cell)
    end
    --itemPanel:setVisible(false)
end

function RankRewardUI:ShowOneReward(sender,cfgData)
    local idx = sender.userObject
    for i=1,3 do
        sender:getChildByName("Num_"..i):setVisible(false)
    end
    local numLabel = sender:getChildByName("Num_4")
    numLabel:setString("")
    if cfgData.rank[2] < 4 then
        sender:getChildByName("Num_"..cfgData.rank[2]):setVisible(true)
    else
        local number = ""..cfgData.rank[1]
        if cfgData.rank[2] ~= cfgData.rank[1] then
            number = number.."-"..cfgData.rank[2]
        end
        numLabel:setString(string.format(GUITips.UI_Arena_Msg9,number))
    end

    local nameLabel = sender:getChildByName("Name")
    local signImg = sender:getChildByName("Lable")
    local hurtLabel = sender:findChildByName("Power/Value")
    local itemPanel = sender:getChildByName("IconItem")
    local listView = sender:getChildByName("ListView")
    if itemPanel ~= nil then
        itemPanel:setVisible(false)
    end
    nameLabel:setString(GUITips.RSI_WANFA_TIPS5)
    hurtLabel:setString("")
    signImg:setVisible(false)
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    for i=1,#cfgData.reward do
        local value = cfgData.reward[i]
        local cell = self.m_itemCell:clone()
        local iconImg = cell:getChildByName("Icon")
        local cntLabel = cell:getChildByName("Value")
        local bgImg = cell:getChildByName("bg")
        local imgPath,color = LDataConstMgr:GetRewardItemPicPath(value)
        Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
        Utils:SafeLoadTexture(bgImg,AppDef.ColorKuangArr[color],ccui.TextureResType.plistType)
        cntLabel:setString(""..value[3])
        listView:pushBackCustomItem(cell)
    end
end

function RankRewardUI:ShowMyRank()
    self.m_myBangReward:setVisible(false)
    self.m_myReward:setVisible(false)
    local myPanel = self.m_myBangReward
    local ind = 1
    if self.m_rType == 31 then
        myPanel = self.m_myReward
        ind = 2
    end
    myPanel:setVisible(true)
    local data = LActivityManager:GetWorldBossData()
    local hurt = data.m_hurts[ind]
    local hurtLabel = myPanel:findChildByName("Power/Value")
    local rankLabel = myPanel:findChildByName("Rank/Value")
    hurtLabel:setString(Utils:getPowerStr(hurt))
    local myRank = data.m_myRanks[ind]
    local str = GUITips.RSI_WELFARE_MSG29
    if myRank ~= nil and myRank > 0 then
        str = ""..myRank
    end
    rankLabel:setString(str)
end

function RankRewardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script = nil
end

return RankRewardUI