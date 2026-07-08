--[[
lua里面的游戏逻辑控制
竞技场挑战界面
]]
local RankUI = LUIBase:New()
RankUI.__index = RankUI
RankUI.IsHideInBattle = true

local funcArr = {
    AppDef.EModuleID.EMID_RANK_Fuben,--副本排行榜
    AppDef.EModuleID.EMID_RANK_JinhJi,--竞技场排行榜
    AppDef.EModuleID.EMID_RANK_XueZhan,--血战排行榜
    AppDef.EModuleID.EMID_RANK_Lv,--等级排行榜
    AppDef.EModuleID.EMID_RANK_Pet,--神将排行榜
    AppDef.EModuleID.EMID_RANK_Power,--战斗力排行榜
    AppDef.EModuleID.EMID_RANK_Tujian,--图鉴排行榜
}

--local this = LTcpSocket
function RankUI:New(userData)
    --print("RankUI",userData)
	local o = LUIBase:New()
	setmetatable(o,RankUI)	
    o:Init(userData)
	return o
end

local SPEED = 300--/秒

function RankUI:Init(userData)
    --self.m_pGuideBtn = nil
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/RankingLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData(userData)
    self:initControlUI()
    --self:ShowInfo()
    self:TabClicked(self.m_ind,1)
end

function RankUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_rankCells = nil
    self.m_rewardCells = nil
    local types = {23,1,2,3,25}
    for i=1,#types do
        LRankDataMgr:Delete(types[i])
    end
    if LUILogic:GetUIInBufferInd("XueZhan.XueZhanMainUI") == 0 then
        LRankDataMgr:Delete(22)
    end
end

--[[
注册UI消息
]]
function RankUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRankEvent.RankListInfo,
        LUIArenaEvent.UpdateHeroListInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function RankUI:ProcessEvent(msg)
    if msg.msgId == LUIRankEvent.RankListInfo or msg.msgId == LUIArenaEvent.UpdateHeroListInfo then
        self:ShowInfo()
    end
end

function RankUI:InitData(userData)
    self.m_ind = userData or 1 
    self.m_rankCheckBoxs = {}
    self.m_rankList = {}
    self.m_rankCells = {}
    self.m_rewardCells = {}
    self.m_myRank = 0
    self.m_rType = 1 --(999-竞技场排名，22-血战排名)
end

function RankUI:initControlUI()
    --panel:setTouchEnabled(false)
    --信息界面
    local panel = self.m_pUILayer:getChildByName("Ranking")
    --排行榜
    self.m_rankCell = panel:getChildByName("Item")--排行榜cell
    self.m_rankRewardCell = panel:getChildByName("Reward")--排行榜奖励页签cell
    self.m_rankRewardIcon = panel:getChildByName("IconBg")
    local bg = panel:getChildByName("Image2")
    self.m_rankListView = bg:getChildByName("ListView")
    local list2 =  bg:getChildByName("CheckList")
    for i=1,2 do
        self.m_rankCheckBoxs[i] = list2:getChildByName("CheckBox_"..i)
        self.m_rankCheckBoxs[i].userObject = i
        self.m_rankCheckBoxs[i]:addClickEventListener(handler(self,RankUI.RankCheckBoxCallBack))
    end
    local myPanel = panel:getChildByName("JingjiPanel")
    self.m_myRankLabel1 = myPanel:getChildByName("MyRanking"):getChildByName("Text")
    self.m_myRewardPanel1 = myPanel:getChildByName("RankingReward")
    self.m_myStarLayer = myPanel:getChildByName("Panel_star")
    self.m_myStarLabel = self.m_myStarLayer:findChildByName("Icon1/Value")
    self.m_xuezhanLabel = bg:getChildByName("firstDay_tips")
    self.m_xuezhanLabel:setVisible(false)

    --通用底框设置
    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.UI_RANK_TITLE)
    self.tabNames = {
        GUITips.UI_RANK_FUBEN_TITLE,
        GUITips.UI_Title_Arena, 
        GUITips.UI_RANK_XUEZHAN_TITLE,
        GUITips.UI_RANK_LEVEL_TITLE,
        GUITips.UI_RANK_PET_TITLE,
        GUITips.UI_RANK_POWER_TITLE,
        GUITips.UI_PetArchive_TabName1,
    }

    local tabValues = 
    {
        self.tabNames,
        handler(self,RankUI.TabClicked)
    }
    Utils:SendMsg(LUIPopFClassBgEvent.AddTabBtn, tabValues)
    Utils:SendMsg(LUIPopFClassBgEvent.SelectTab, self.m_ind)
    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, RankUI.CloseUI))
end

function RankUI:TabClicked(ind,init)
    init = init or 0
    if init == 0 and self.m_ind == ind then
        return false
    end
    local funcId = funcArr[ind]
    if Utils:CheckModelNotOpened(funcId) then
        return false
    end
    --print("===========TabClicked==========",ind)
    self.m_ind = ind or 1
    self:ShowInfo()
    self:QueryInfo(ind)
    return true
end

function RankUI:QueryInfo(ind)
    ind  = ind or 0
    local types = {23,0,22,1,2,3,25}
    if ind == 0 or ind > #types or types[ind] == 0 then
        if ind == AppDef.RankIdx.Rank_JingJI and #LArenaDataMgr.m_rankList == 0 then
            LuaNetSendMsg:QueryArenaList(2)
        end
        return
    end
    local data = LRankDataMgr.m_ranks[types[ind]]
    if data == nil then
        --print("op",types[ind])
        LuaNetSendMsg:QueryRankList(types[ind])
    end
end

-------------------------------------------------------------排行榜---------------------------------------------------
function RankUI:SetData()
    self.m_rankList = {}
    self.m_myRank = 0
    self.m_rType = 0
    if self.m_ind == AppDef.RankIdx.Rank_FuBen then
        local ind = 23
        if LRankDataMgr.m_ranks[ind] ~= nil then
            self.m_rankList = LRankDataMgr.m_ranks[ind]
            if LRankDataMgr.m_myInfo[ind] ~= nil then
                self.m_myRank = LRankDataMgr.m_myInfo[ind].slotIndex or 0
            end
        end
    elseif self.m_ind == AppDef.RankIdx.Rank_JingJI then
        self.m_rankList = LArenaDataMgr.m_rankList
        self.m_myRank = LArenaDataMgr.m_myRank
        self.m_rType = 999
    elseif self.m_ind == AppDef.RankIdx.Rank_XueZhan then
        local ind = 22
        if LRankDataMgr.m_ranks[ind] ~= nil then
            self.m_rankList = LRankDataMgr.m_ranks[ind]
            if LRankDataMgr.m_myInfo[ind] ~= nil then
                self.m_myRank = LRankDataMgr.m_myInfo[ind].slotIndex or 0
            end
        end
        self.m_rType = ind
    elseif self.m_ind==AppDef.RankIdx.Rank_TuJian then
        local ind = 25
        if LRankDataMgr.m_ranks[ind] ~= nil then
            self.m_rankList = LRankDataMgr.m_ranks[ind]
            if LRankDataMgr.m_myInfo[ind] ~= nil then
                self.m_myRank = LRankDataMgr.m_myInfo[ind].slotIndex or 0
            end
        end
        self.m_rType = ind
    elseif self.m_ind > 3 and self.m_ind < 7 then
        local ind = self.m_ind-3
        if LRankDataMgr.m_ranks[ind] ~= nil then
            self.m_rankList = LRankDataMgr.m_ranks[ind]
            if LRankDataMgr.m_myInfo[ind] ~= nil then
                self.m_myRank = LRankDataMgr.m_myInfo[ind].slotIndex or 0
            end
        end
    end
end

function RankUI:ShowInfo()
    self:SetData()
    for i=1,2 do
        self.m_rankCheckBoxs[i]:setVisible(false)
    end
    self.m_myStarLayer:setVisible(false)
    if self.m_ind == AppDef.RankIdx.Rank_JingJI then--竞技场
        for i=1,2 do
            self.m_rankCheckBoxs[i]:setVisible(true)
        end
        self:RankCheckBoxCallBack(self.m_rankCheckBoxs[1])
    elseif self.m_ind == AppDef.RankIdx.Rank_XueZhan then--血战
        for i=1,2 do
            self.m_rankCheckBoxs[i]:setVisible(true)
        end
        self:RankCheckBoxCallBack(self.m_rankCheckBoxs[1])
        self.m_myStarLayer:setVisible(true)
        local star = 0
        if LRankDataMgr.m_myInfo[22] ~= nil then
            star = LRankDataMgr.m_myInfo[22].data or 0
        end
        self.m_myStarLabel:setString(star)--血战排行制作中
    elseif self.m_ind == AppDef.RankIdx.Rank_FuBen or (self.m_ind > 3 and self.m_ind <=7) then
        self:ShowRankList()
    end 
    self:ShowMyRank(self.m_myRankLabel1,self.m_myRewardPanel1)
end

function RankUI:ShowMyRank(rankLabel,rewardPanel)
    if rankLabel == nil or rewardPanel == nil then
        return
    end
    local str = ""..self.m_myRank
    if self.m_myRank == 0 then
        str = GUITips.RSI_WELFARE_MSG29
    end
    rankLabel:setString(str)
    if self.m_rType == 0 then
        rewardPanel:setVisible(false)
        return
    end
    local cfg = JsonConfig.GetRewardRankCfg(self.m_rType,self.m_myRank)
    if cfg == nil then
        rewardPanel:setVisible(false)
        return
    end
    rewardPanel:setVisible(true)
    local rewards = cfg.reward or {}
    for i=1,3 do
        local value = rewards[i]
        local iconImg = rewardPanel:getChildByName("Icon"..i)
        local numLabel = iconImg:getChildByName("Value")
        if value == nil or #value < 3 then
            iconImg:setVisible(false)
        else
            iconImg:setVisible(true)
            local imgPath = LDataConstMgr:GetRewardItemPicPath(value)
            Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
            numLabel:setString(value[3])
        end
    end
end

--排行榜，切换页签(非checkbox，button)
function RankUI:RankCheckBoxCallBack(sender)
    local idx = sender.userObject
    --print("RankUI:RankCheckBoxCallBack",idx)
    local otherIdx = 1
    if idx == 1 then
        otherIdx = 2 
    end
    self.m_rankCheckBoxs[idx]:setTouchEnabled(false)
    self.m_rankCheckBoxs[otherIdx]:setTouchEnabled(true)
    --选中切换
    local curImg = self.m_rankCheckBoxs[idx]:getChildByName("Choose")
    curImg:setVisible(true)
    local otherImg = self.m_rankCheckBoxs[otherIdx]:getChildByName("Choose")
    otherImg:setVisible(false)

    if idx == 1 then
        self:ShowRankList()
    else
        self:ShowRankRewardList()
    end
end

function RankUI:ShowRankList()
    if self.m_rewardListView ~= nil then
        self.m_rewardListView:setVisible(false)
        self.m_rewardListView:setEnabled(false)
    end
    self.m_rankListView:setVisible(true)
    self.m_rankListView:setEnabled(true)
    -- for i=1, #self.m_rankCells do
    --     self.m_rankListView:
    --     self.m_rankCells[i]:removeFromParent()
    -- end
    for i=1, #self.m_rankCells do
        if i>#self.m_rankList then
            
            table.remove(self.m_rankCells,i)
            self.m_rankListView:removeItem(i)
            i=i-1
        end
    end
    self.m_rankCells={}
    self.m_rankListView:removeAllItems()
    for i=1,#self.m_rankList do
        if self.m_rankCells[i] == nil then
            local cell = self.m_rankCell:clone()
            cell.userObject = i
            self.m_rankCells[i] = cell
            self.m_rankListView:pushBackCustomItem(self.m_rankCells[i])
            local iconImg = self.m_rankCells[i]:getChildByName("Icon_1")
            iconImg:setTouchEnabled(true)
            iconImg:addClickEventListener(handler(self,RankUI.OnHeadClick))
        end
        self:ShowOneRank(self.m_rankCells[i])
    end
    if self.m_ind == AppDef.RankIdx.Rank_XueZhan and #self.m_rankList == 0 then--血战
        self.m_xuezhanLabel:setVisible(true)
    else
        self.m_xuezhanLabel:setVisible(false) 
    end
end

function RankUI:ShowRankRewardList()
    self.m_rankListView:setVisible(false)
    self.m_rankListView:setEnabled(false)
    self.m_xuezhanLabel:setVisible(false) 
    if self.m_rewardListView == nil then
        self.m_rewardListView = Utils:CreateListView(self.m_rankListView,LISTVIEW_DIR_VERTICAL,0)
    end
    self.m_rewardListView:setVisible(true)
    self.m_rewardListView:setEnabled(true)
    local cfgDatas = JsonConfig.m_mapRewardRank[self.m_rType]
    for i=1,#cfgDatas do
        if self.m_rewardCells[i] == nil then
            local cell = self.m_rankRewardCell:clone()
            cell.userObject = i
            self.m_rewardCells[i] = cell
            self.m_rewardListView:pushBackCustomItem(self.m_rewardCells[i])
        end
        self:ShowOneRankReward(self.m_rewardCells[i],cfgDatas[i].id)
    end
end

function RankUI:ShowOneRank(sender)
    local idx = sender.userObject
    local data = self.m_rankList[idx]



    local numImgs = {}
    for i=1,3 do
        numImgs[i] = sender:getChildByName("Num_"..i)
        numImgs[i]:setVisible(false)
    end
    local numLabel = sender:getChildByName("Num_4")
    local powerLabel = sender:getChildByName("Power"):getChildByName("Value")
    local bangLayer = sender:getChildByName("Gangs")
    local bangLabel = bangLayer:getChildByName("Name")
    local iconImg = sender:getChildByName("Icon_1")
    local nameLabel = iconImg:getChildByName("Name")
    local lvLabel = iconImg:getChildByName("LevelNum")
    local mySignImg = sender:getChildByName("Lable")
    local starLayer = sender:getChildByName("Panel_star")
    local starNum = starLayer:findChildByName("Icon1/Value")
    local nameLabel1 = iconImg:getChildByName("Name_1")--拥有者
    local chapterLabel = starNum:getChildByName("jindu")
    local tujianLable = sender:getChildByName("text_1")


    iconImg.userObject = {data.Id,data.IdType or 0,data.value or 0}
    starLayer:setVisible(false)
    mySignImg:setVisible(false)
    bangLayer:setVisible(false)
    nameLabel1:setVisible(false)
    tujianLable:setVisible(false)
    if data.Id == LRoleDataMgr.MyHeroInfo.id then
        mySignImg:setVisible(true)
    end
    if self.m_ind == AppDef.RankIdx.Rank_FuBen or self.m_ind == AppDef.RankIdx.Rank_XueZhan then
        starLayer:setVisible(true)
        starNum:setString(data.data or 0)
        chapterLabel:setString("")
        if self.m_ind == AppDef.RankIdx.Rank_XueZhan then
            local cfg = JsonConfig.m_bloodBattle.getDefByID(data.value)
            if cfg ~= nil then
                local str = string.format(GUITips.RSI_XUEZHAN_TIP7,""..cfg.chapter)
                str = str..string.format(GUITips.RSI_XUEZHAN_TIP11,data.value)
                chapterLabel:setString(str)
            end
        end
    end
    if self.m_ind==AppDef.RankIdx.Rank_TuJian then
        tujianLable:setVisible(true)
        tujianLable:setString("图鉴值："..data.data)
    end
    numLabel:setString(""..idx)
    if idx > 0 and idx < 4 then
        numImgs[idx]:setVisible(true)
        numLabel:setString("")
    end
    if data.IdType == nil then
        data.IdType = 0
    end
    local zhanli = data.fightpower
    local name = data.name
    if data.IdType == 0 then
        data.head = Utils:CheckHeadId(data.head)
        if self.m_ind == AppDef.RankIdx.Rank_Pet then
            local cfg = JsonConfig.m_heroCfg.getDefByID(data.value or 0)
            if cfg ~= nil then
                name = cfg.name
                zhanli = data.data
                data.head = cfg.pic
            end
        end
    else 
        local cfg = JsonConfig.m_robotConfig.getDefByID(data.Id)
        if cfg ~= nil then
            name = cfg.name
            zhanli = cfg.zhanli
            data.head = cfg.mod
        end
    end

    local powerValue, isWan = Utils:getNewPowerStr(zhanli);
    powerLabel:setString(powerValue);
    if isWan == true then
        powerLabel:getChildByName("Wan"):setVisible(true)
        powerLabel:getChildByName("Wan"):setPositionX(powerLabel:getContentSize().width)
    else
        powerLabel:getChildByName("Wan"):setVisible(false)
    end
    
    -- powerLabel:setString(Utils:getPowerStr(zhanli))
    nameLabel:setString(""..name)
    local str = ""
    if data.level > 0 and self.m_ind ~= AppDef.RankIdx.Rank_Pet then
        str = GUITips.RSI_FACTION_MSG7..data.level
    end
    lvLabel:setString(str)
    local bangName = data.bangName
    if data.bangId > 0 and #bangName > 0 and self.m_ind ~= AppDef.RankIdx.Rank_Pet then
        bangLayer:setVisible(true)
    end
    bangLabel:setString(""..bangName)

    local str = ""
    if data.IdType == 0 then
        str = AppDef:GetHeroPicFileName(data.head,AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
        if self.m_ind == AppDef.RankIdx.Rank_Pet then
            str = "res2/Monster_Bust/"..data.head.."_tou.png"
            nameLabel1:setVisible(true)
            nameLabel1:setString("（"..GUITips.RSI_RANK_TIPS1.."："..data.name.."）")
        end
    else
        str = "res2/Monster_Bust/"..data.head.."_tou.png"
        --print(str)
    end
    Utils:SafeLoadTexture(iconImg,str,ccui.TextureResType.localType)
end

function RankUI:OnHeadClick(sender)
    local value = sender.userObject
    if value == nil or value[2] ~= 0 then
        Utils:ShowScrollTips(GUITips.UI_Arena_Tip12)
        return
    end
    if value[1] == LRoleDataMgr.MyHeroInfo.id then
        return
    end
    LRankDataMgr.m_value = 0
    if self.m_ind == AppDef.RankIdx.Rank_Pet then
        LRankDataMgr.m_value = value[3]
    end
    LuaNetSendMsg:QueryOtherPlayerInfo(value[1])
end

function RankUI:ShowOneRankReward(sender,id)
    local cfgData = JsonConfig.m_rewardRank.getDefByID(id)
    local idx = sender.userObject
    local numLabel = sender:getChildByName("Num")
    local number = ""..cfgData.rank[1]
    if cfgData.rank[2] ~= cfgData.rank[1] then
        number = number.."-"..cfgData.rank[2]
    end
    numLabel:setString(string.format(GUITips.UI_Arena_Msg9,number))
    local listView = sender:getChildByName("ListView")
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    for i=1,#cfgData.reward do
        local value = cfgData.reward[i]
        local cell = self.m_rankRewardIcon:clone()
        local iconImg = cell:getChildByName("Icon")
        local cntLabel = cell:getChildByName("Text_5")
        local imgPath = LDataConstMgr:GetRewardItemPicPath(value)
        Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
        cntLabel:setString(""..value[3])
        listView:pushBackCustomItem(cell)
    end
end
-------------------------------------------------------------排行榜-end--------------------------------------------------

function RankUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Common.RankUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

-- function RankUI:RegisterGuide()
--     if self.m_pAwardButton == nil then
--         return
--     end
--     Utils:RegisterGuide(GuideDef.StepId.Guide_JJ_1, self.m_pAwardButton, handler(self, RankUI.awardBtnTouched), nil, true)

--     -- local data = LDataConstMgr:GetGuideData(GuideDef.StepId.Guide_JJ_FINISH)
--     if self.m_pGuideBtn then
--         Utils:RegisterGuide(GuideDef.StepId.Guide_JJ_FINISH, self.m_pGuideBtn, function()
--             self:OnChallengeBtnTouched(self.m_pGuideBtn)
--         end, nil, true)
--     end
-- end

return RankUI