--[[
lua里面的游戏逻辑控制
玩法-每日Boss
]]

local DailyBossUI = LUIBase:New()
DailyBossUI.__index = DailyBossUI
--战斗中是否隐藏
DailyBossUI.IsHideInBattle = true
function DailyBossUI:New()
    local o = LUIBase:New()
    setmetatable(o, DailyBossUI)
    o:Init()
    return o
end


function DailyBossUI:Init()
    -- self.m_pNode = cc.Node:create()
    self.m_pUILayer = cc.CSLoader:createNode("csd/DailyBossLayer.csb")
    local frameSize = AppDef.frameSize
    self.m_pUILayer:setContentSize(frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()

    LuaNetSendMsg:QueryDailyBoss(3)
    LuaNetSendMsg:QueryDailyBoss(8)
end

function DailyBossUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    if self.m_bossInfo then
        self.m_bossInfo:release()
        self.m_bossInfo = nil
    end
    self.m_bossListView = nil
    self.m_isDragging = nil

    self.m_getStarCntLabel = nil
    self.m_timesLabel = nil
    self.m_addBtn = nil
    self.m_leftBtn = nil
    self.m_rightBtn = nil

    --奖励
    self.m_rewardListView = nil
    self.m_itemListView = nil
    self.m_starListView = nil
    self.m_loadingBar = nil
    
    self.m_imod = nil
    self.m_initBossIndex = nil
    self.m_initRewardIndex = nil

    
end

--[[
注册UI消息
]]
function DailyBossUI:RegistMsgs()
    self.msgIds =
    {
        LUIDailyBossEvent.DailyBossShowBossInfo, --显示每日Boss玩法Boss信息
        LUIDailyBossEvent.DailyBossShowAward,    --显示每日Boss玩法奖励信息
        LUIDailyBossEvent.DailyBossUpdateTime,   --更新每日Boss玩法次数、星级
        LUIDailyBossEvent.DailyBossDrawState,    --每日Boss玩法奖励领取状态更新
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

function DailyBossUI:ProcessEvent(msg)
     print("DailyBossUI:ProcessEvent",msgId)
    if msg.msgId == LUIDailyBossEvent.DailyBossShowBossInfo then
        self:LoadBossList()
        self:ShowCnt()
    elseif msg.msgId == LUIDailyBossEvent.DailyBossShowAward then
        self:LoadAwardList()
        self:ShowGetStar()
    elseif msg.msgId == LUIDailyBossEvent.DailyBossUpdateTime then
        self:DailyBossUpdateTime(msg.value)
    elseif msg.msgId == LUIDailyBossEvent.DailyBossDrawState then
        self:LoadAwardList()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        if self._selectIndex ~= nil then
            self:requestFigght(self._selectIndex)
            self._selectIndex = nil
        end
    end
end

function DailyBossUI:DailyBossUpdateTime(index)
    self:ShowGetStar()
    self:ShowCnt()
    if index > 0 then
       self:ShowBossStar(index)
    end
end

function DailyBossUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel")
    --信息
    local infoPanel = panel:getChildByName("List")
    --Boss信息ListView
    self.m_bossListView = infoPanel:getChildByName("ListView")
    self.m_isDragging = false
    self.m_bossInfo = infoPanel:getChildByName("BossBg")
    self.m_bossInfo:retain()
    self.m_bossInfo:removeFromParent()

    self.m_getStarCntLabel = infoPanel:getChildByName("AllStars"):getChildByName("Num")--获得星数
    local TimesPanel = infoPanel:getChildByName("Times")
    self.m_timesLabel = TimesPanel:getChildByName("Num")--次数
    self.m_addBtn = TimesPanel:getChildByName("Star")--增加次数按钮
    self.m_addBtn:setTouchEnabled(true)
    self.m_leftBtn = infoPanel:getChildByName("LeftArrow")
    self.m_leftBtn:setTouchEnabled(true)
    self.m_leftBtn.userObject = 1
    self.m_rightBtn = infoPanel:getChildByName("RightArrow")
    self.m_rightBtn:setTouchEnabled(true)
    self.m_rightBtn.userObject = 2

    --奖励
	self.m_rewardListView = panel:getChildByName("Reward")
    local awardPanel = panel:getChildByName("Reward"):getChildByName("Panel"):getChildByName("ImageBg")
    self.m_itemListView = awardPanel:getChildByName("BtnList")
    self.m_starListView = awardPanel:getChildByName("StarsList")
    self.m_loadingBar = awardPanel:getChildByName("LoadingBar")
    
    self.m_imod = {}
	self.m_initBossIndex = 0
	self.m_initRewardIndex = 0
end


function DailyBossUI:AddTouchEvt()
    --点击移动
    local function OnMoveCallBack(sender)
        if self.m_bossNum == nil or self.m_bossNum == 0 or self.m_isDragging then
            return
        end
        --if self.m_boosLVPercent == nil then self.m_boosLVPercent = 0 end
        local data = sender.userObject
        local percent =  Utils:GetScrollViewXPercent(self.m_bossListView)
        local sign = 100/(self.m_bossNum-4)    
        local temp = math.ceil(percent/sign)   
        percent =  temp* sign                                                                                  
        if data == 1 then
            percent = percent - sign   --左移
        else 
            percent = percent + sign   --右移
        end
        if percent < 0 then percent = 0 end
        if percent > 100 then percent = 100 end
--        if percent == 100 then
--            self.m_rightBtn:setVisible(false)
--        elseif percent == 0 then
--            self.m_leftBtn:setVisible(false)
--        else
--            self.m_rightBtn:setVisible(true)
--            self.m_leftBtn:setVisible(true)
--        end
        print("current percent", percent)
        self.m_bossListView:scrollToPercentHorizontal(percent,1,true)
    end
    self.m_leftBtn:addClickEventListener(OnMoveCallBack)
	self:MarkIntaractCObj(self.m_leftBtn)
    self.m_rightBtn:addClickEventListener(OnMoveCallBack)
	self:MarkIntaractCObj(self.m_rightBtn)

    --增加次数
    local function OnAddCountClick(sender)
        local function okFunc()
            LuaNetSendMsg:QueryDailyBoss(10)
        end
        local function canelFunc()
           
        end
        local info = LActivityManager:GetDailyBossData()
        if info == nil or info.m_meiriBossTime > 0 then
            Utils:ShowScrollTips(GUITips.UI_Arena_Tip5)
        else
            local str = Utils:JointString(GUITips.UI_Arena_Tip1,500)
            Utils:ShowDialogOKCancel(str, okFunc,canelFunc)  
        end        
    end
    self.m_addBtn:addClickEventListener(OnAddCountClick)
	self:MarkIntaractCObj(self.m_addBtn)
end

function DailyBossUI:LoadBossList()
	self.m_initBossIndex = 0
    if self.m_bossListView == nil then return end
	local info = LActivityManager:GetDailyBossData()
	local awardnum = info.m_awardInfos
    local max = #info.m_bossInfos
    for i=1,max do
        local boss = self:ShowBossInfo(info.m_bossInfos[i],i)
        if boss ~= nil then
            self.m_bossListView:pushBackCustomItem(boss)
            boss:setTag(i)
        end
    end
    self.m_bossNum = max
	self:MovetoBoss()
end

function DailyBossUI:MovetoBoss()
	print("current Boss index", self.m_initBossIndex)
	if self.m_initBossIndex == 0 then
		return
	end
	local percent =  Utils:GetScrollViewXPercent(self.m_bossListView)
    local sign = 100/(self.m_bossNum-4)    
    local temp = math.ceil(percent/sign)   
    percent =  temp* sign                                                                                
    percent = percent + sign * (self.m_initBossIndex -1) --右移
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end
	performWithDelay(self.m_bossListView, function()
		self.m_bossListView:scrollToPercentHorizontal(percent,1,true)
	end, 0.1)
end

function DailyBossUI:ShowBossInfo(info,idx)
    local function OnFightCallBack(sender)
        local index = sender.userObject
        self._selectIndex = index
        if not self:teamEvent() then
            self:requestFigght(index)
        end 
    end

    if info == nil then return nil end
    local boss = self.m_bossInfo:clone()
    local choose = boss:getChildByName("ChooseBg")
    choose:setVisible(false)
    local modelNode = display.newNode()
    boss:addChild(modelNode)
    modelNode:setPosition(cc.p(125, 146))

    local levelPanel = boss:getChildByName("LevelBg")
    local difficultyLabel = levelPanel:getChildByName("Value")
    local nameLabel = boss:getChildByName("BossName"):getChildByName("Name")
    local expLabel = boss:getChildByName("EXPBg"):getChildByName("Num")
	local awardList = boss:getChildByName("ListView")
	--awardList:setPosition(cc.p(150, 75))
	local item = boss:getChildByName("Item")
    local starPanel = boss:getChildByName("StarsList")
    local btn = boss:getChildByName("Button")
    btn:addClickEventListener(OnFightCallBack)
	self:MarkIntaractCObj(btn)
    btn.userObject = idx
    for i = 1,3 do
        local bossStar = starPanel:getChildByName("StarBg"..i):getChildByName("Star")
		if info.getStar < 3 and self.m_initBossIndex == 0 then
			self.m_initBossIndex = idx
		end
        if info.getStar >= i then
            bossStar:setVisible(true)
        else
            bossStar:setVisible(false)
        end
    end

    --difficultyLabel:setString(GUITips.RSI_RMD_LV..":"..info.monsterLv)
    local level = LRoleDataMgr.MyHeroInfo.level
    local str = GUITips.RSI_RMD_LV..":"
    difficultyLabel:setString(str..info.monsterLv)
    if level < info.monsterLv then
        str = str.."[c1]"..info.monsterLv.."[/c]"
    else
        str = str.."[c3]"..info.monsterLv.."[/c]"
    end
    
    local rmdLvText = Utils:CreateColorText2(levelPanel, difficultyLabel)
    rmdLvText:setString(str)
    rmdLvText:setScaleX(difficultyLabel:getScaleX())
    rmdLvText:setRotation(difficultyLabel:getRotation())
    rmdLvText:setPositionY(6)
    nameLabel:setString(info.monsterName)
    expLabel:setString(tostring(info.dropExp))
      -- info.dropExp = stream:ReadUInt()          --经验
      --    info.itemId=stream:ReadWord()          --物品id
      --   info.itemNum=stream:ReadUInt()   
	for i=1,2 do
        if i==1 then
            local node = item:clone()
            local userDefine ={picFilePath = "item/equip3007.png", quality = 0, num = info.dropExp}
            local itemValue = {}
            itemValue.userDefine = userDefine
            itemValue.isShowNum = true
            itemValue.isShowQualityBg = true
            ItemCellUI:New(node, itemValue)
            if node ~= nil then
               awardList:pushBackCustomItem(node)
            end
        elseif i==2 then
            local node = item:clone()
          -- Utils:GetItemCellValue(grid, type, itemId, showQuality, showNum, num, pItem, isOpenTouch, isChangeSize, pid, pstar)
             Utils:GetItemCellValue(node,0,info.itemId,true,true,info.itemNum,nil,true,true)
            -- local userDefine ={picFilePath = "item/equip3007.png", quality = 0, num = info.dropExp}
            -- local itemValue = {}
            -- itemValue.userDefine = userDefine
            -- itemValue.isShowNum = true
            -- itemValue.isShowQualityBg = true
            -- ItemCellUI:New(node, itemValue)
            if node ~= nil then
               awardList:pushBackCustomItem(node)
            end
        end
        
    end
    self:ShowBossModel(modelNode,idx,info.monsterID)
    return boss
end

function DailyBossUI:teamEvent( ... )
    -- body
    if LRoleDataMgr.MyHeroInfo:IsTeam() then
        local function okFunc()
            LuaNetSendMsg:QueryLeaveTeam()
        end
        local function canelFunc()
            
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS16, okFunc,canelFunc)
        return true
    end
    return false
end

function DailyBossUI:requestFigght( index )
    -- body
	local data = LActivityManager:GetDailyBossData()
	if data.m_meiriBossTime <= 0 then
		local msg = GUITips.RSI_BOSSFIGHTTIPS
		LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,msg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
		return
	end
    local info = LActivityManager:GetDailyBossData().m_bossInfos
    LuaNetSendMsg:QueryDailyBoss(7,info[index].vecIndex)
end

function DailyBossUI:ShowBossStar(index)
    local bossPanel = self.m_bossListView:getChildByTag(index)
    if bossPanel == nil then return end
    local getStar = LActivityManager:GetDailyBossData().m_bossInfos[index].getStar
    local starPanel = bossPanel:getChildByName("StarsList")
    for i = 1,3 do
        local bossStar = starPanel:getChildByName("StarBg"..i):getChildByName("Star")
        if getStar >= i then
            bossStar:setVisible(true)
        else
            bossStar:setVisible(false)
        end
    end
end

function DailyBossUI:ShowBossModel(node,idx,id)
    if node == nil then return end
    self.m_pBossModel = {}
    if self.m_pBossModel[idx] == nil then
        self.m_pBossModel[idx] = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, id)
        node:addChild(self.m_pBossModel[idx])
    else
        self.m_pBossModel[idx]:InitAni(AppDef.CEnum.ModelAniType.Monster, id)
    end
    self.m_pBossModel[idx]:PlayStand(0)
end

--显示获得星星数量
function DailyBossUI:ShowGetStar()
    local function getPercent(getStar)
        if self.m_starNum == nil or self.m_starNum <= 1 then return 0 end
        local percent = 100
        local temp = 1/(self.m_starNum-1)*100
        if getStar < 2 then
            percent = 0
        elseif getStar == 2 then
            percent = temp/2
        elseif getStar == 3 then
            percent = temp
        else
            local number1 = getStar%3 --余数
            local number2 = math.ceil(getStar/3)--除数
            if number1 == 0 then number1 = 3 end
            percent = (number2-1)*temp+temp*(number1/3)
        end
        return percent
    end

    local info = LActivityManager:GetDailyBossData()
    self.m_getStarCntLabel:setString(tostring(info.m_bossAwardStar))

    --更新进度条
    self.m_loadingBar:setPercent(getPercent(info.m_bossAwardStar))
end

--显示挑战次数
function DailyBossUI:ShowCnt()
    local info = LActivityManager:GetDailyBossData()
    self.m_timesLabel:setString(tostring(info.m_meiriBossTime))
end

--加载奖励信息
function DailyBossUI:LoadAwardList()
    self:LoadAwardItemList()
    self:LoadAwardStarList()
end

--加载奖励道具信息
function DailyBossUI:LoadAwardItemList()
    local function OnDrawCallBack(sender)
        local index = sender.userObject
        local data = LActivityManager:GetDailyBossData()
        local info = data.m_awardInfos
        if info[index].drawState == 1  or data.m_bossAwardStar < info[index].needStar  then
            Utils:ShowItemTips(info[index].itemID[1])
        else
            LuaNetSendMsg:QueryDailyBoss(9,index-1)
        end
    end

    if self.m_itemListView == nil then return end
    local info = LActivityManager:GetDailyBossData().m_awardInfos
    self.m_itemIcon={}
    self.m_itemMask={}
    for i=1,#info do
        local itemPanel = self.m_itemListView:getChildByName("EquipIcon_"..i)
        self.m_itemIcon[i] = itemPanel:getChildByName("Icon")
        self.m_itemMask[i] = itemPanel:getChildByName("Image")
        itemPanel.userObject = i
        itemPanel:addClickEventListener(OnDrawCallBack)
		self:MarkIntaractCObj(itemPanel)
        if info[i].itemType[1] == 1 then
            self.m_itemIcon[i]:loadTexture(LItemMgr:GetItemPicFileName(info[i].itemID[1]),ccui.TextureResType.localType)
            local numLabel = itemPanel:getChildByName("Num")
            numLabel:setString(tostring(info[i].itemNum[1]))
            self:ShowDrawState(i)
        end  
    end
	self:MovetoReward()
end

--加载奖励需要星数
function DailyBossUI:LoadAwardStarList()
	self.m_initRewardIndex = 0
    if self.m_starListView == nil then return end
    local data = LActivityManager:GetDailyBossData()
    local info = data.m_awardInfos
    self.m_starIcon = {}
    for i=1,#info do
        local itemPanel = self.m_starListView:getChildByName("StarImage_"..i)
        self.m_starIcon[i] = itemPanel:getChildByName("Star")
        if data.m_bossAwardStar >= info[i].needStar  then
            self.m_starIcon[i]:setVisible(true)
        else
            self.m_starIcon[i]:setVisible(false)
        end
    end
    self.m_starNum = #info
end

function DailyBossUI:MovetoReward()
	print("current Boss index", self.m_initRewardIndex)
	if self.m_initRewardIndex == 0 then
		return
	end
	local percent =  Utils:GetScrollViewXPercent(self.m_rewardListView)
    local sign = 100/7    
    local temp = math.ceil(percent/sign)   
    percent =  temp* sign                                                                                
    percent = percent + sign * (self.m_initRewardIndex - 1) --右移
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end
	performWithDelay(self.m_rewardListView, function()
		self.m_rewardListView:scrollToPercentHorizontal(percent,1,true)
	end, 0.1)
end

--显示领取状态
function DailyBossUI:ShowDrawState(index)
    local data = LActivityManager:GetDailyBossData()
    local info = data.m_awardInfos
    if #info < index then return end

    if info[index].drawState == 1 then   
        self.m_itemMask[index]:setVisible(true)
        self.m_itemIcon[index]:setColor(UICOLOR_WHITE)
        --self.m_itemIcon[index]:getParent():setTouchEnabled(false)
        if self.m_imod[index] ~= nil then
            self.m_imod[index]:removeFromParent()
            self.m_imod[index] = nil
        end
    else       
        if data.m_bossAwardStar >= info[index].needStar then
            self.m_itemMask[index]:setVisible(false)
            self.m_itemIcon[index]:setColor(UICOLOR_WHITE)
            --self.m_itemIcon[index]:getParent():setTouchEnabled(true)
            if self.m_imod[index] == nil then
                 local size = self.m_itemIcon[index]:getContentSize()
                 self.m_imod[index] = Utils:CreateImod("res2/fx/list",cc.p(size.width/2,size.height/2),self.m_itemIcon[index],1.2)
                 self.m_imod[index]:PlayActionRepeat(0)
            end
			if self.m_initRewardIndex == 0 then
				self.m_initRewardIndex = index
			end
        else
             self.m_itemMask[index]:setVisible(true)
            self.m_itemIcon[index]:setColor(cc.c3b(0x7f,0x7f,0x7f))
            --self.m_itemIcon[index]:getParent():setTouchEnabled(false)
        end
    end
    self.m_itemIcon[index]:getParent():setTouchEnabled(true)
end
return DailyBossUI