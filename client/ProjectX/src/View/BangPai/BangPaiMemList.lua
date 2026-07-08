local BangPaiMemList = LUIBase:New()
BangPaiMemList.__index = BangPaiMemList

-- -----------------------------------
function BangPaiMemList:New()
    local o = {}
    setmetatable(o, BangPaiMemList)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiMemList:Init()
    self.Script = "BangPai.BangPaiMemList"
    self.m_tableCount = 0
    self.m_isDragging = false
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_pMyTableCell = nil
    self.m_datas = nil
    self.m_selectIndex = -1
    self.m_buttons = {}
    self.m_pReddot = nil
    self.m_pReddot3 = nil
    self.m_pMask = nil

    self.m_selectHeroData = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()

    LuaNetSendMsg:QueryFactionMemberList()
    LuaNetSendMsg:QueryFactionInfo()
end

-- -----------------------------------
function BangPaiMemList:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_tableCount = nil
    self.m_isDragging = nil
    self.m_pTableView = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_pMyTableCell = nil
    self.m_datas = nil
    self.m_selectIndex = nil
    Utils:FreeTable(self.m_buttons)
    self.m_buttons = nil
    self.m_pReddot = nil
    self.m_pReddot3 = nil
    self.m_pMask = nil

    self.m_selectHeroData = nil
    Utils:SendMsg(LUIMsgBoxEvent.HideMsgBox)
end

-- -----------------------------------
function BangPaiMemList:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiEvent.LoadMemberList,
        LUIBangPaiEvent.UpdateMyFactionInfo,
        LUIBangPaiEvent.UpdateMemberWeiJie,
        LUIBangPaiEvent.DelMemberByRoleId,
        LUIBangPaiEvent.UpdateBangZhuChuangWei,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiMemList:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.LoadMemberList then
        self:LoadMemberList(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.UpdateMyFactionInfo then
        self:setMenuState()
    elseif msg.msgId == LUIBangPaiEvent.UpdateRedDot then
        self:UpdateRedDot(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.UpdateMemberWeiJie then
        self:UpdateMemberWeiJie(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.DelMemberByRoleId then
        self:DelMemberByRoleId(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.UpdateBangZhuChuangWei then
        self:UpdateBangZhuChuangWei(msg.value)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:UpdateRedDot(msg.value)
    end
end

function BangPaiMemList:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    Utils:SendMsg(LUIPopFClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
end

-- -----------------------------------
function BangPaiMemList:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsMemberLayer.csb")
    Utils:SendMsg(LUIPopFClassBgEvent.SetTitle, GUITips.RSI_BP_TIP13)

end

-- -----------------------------------
function BangPaiMemList:InitUIControl()
    local panel = self.m_pUILayer:getChildByName("Panel")
    self.m_pMask = self.m_pUILayer:getChildByName("Panel_1")
    self.m_pMask:setSwallowTouches(false)

    local pMember = panel:getChildByName("Member")
    local pBg = pMember:getChildByName("Bg")

    self.m_pTablePanel = pBg:getChildByName("List")
    self.m_pGridCell = pBg:getChildByName("Name")
    self.m_pGridCell:setVisible(false)
    self.m_pGridCell:setTouchEnabled(false)

    local pBtnList = pMember:getChildByName("BtnList")
    
    local pBtn1 = pBtnList:getChildByName("Btn1")
    local pBtn2 = pBtnList:getChildByName("Btn2")
    --local pBtn3 = pBtnList:getChildByName("Btn3")
    local pBtn4 = pBtnList:getChildByName("Btn4")

    pBtn1:addClickEventListener(function(sender)
        self:joinApplyCallback()
    end)
	self:MarkIntaractCObj(pBtn1)
    pBtn2:addClickEventListener(function(sender)
        self:invokeCallback()
    end)
	self:MarkIntaractCObj(pBtn2)
 --    pBtn3:addClickEventListener(function(sender)
 --        self:rewardCallback()
 --    end)
	-- self:MarkIntaractCObj(pBtn3)
    pBtn4:addClickEventListener(function(sender)
        self:leaveCallback()
    end)
	self:MarkIntaractCObj(pBtn4)
    self.m_buttons[pBtn1:getName()] = pBtn1
    self.m_buttons[pBtn2:getName()] = pBtn2
    -- self.m_buttons[pBtn3:getName()] = pBtn3
    for k,v in pairs(self.m_buttons) do
        v:setVisible(false)
    end
    self.m_pReddot = pBtn1:getChildByName("Prompt")
    local _ = self.m_pReddot and self.m_pReddot:setVisible(Utils:GetRedDotState(RedDotDef.ID.BPShenQing))
    
    -- self.m_pReddot3 = pBtn3:getChildByName("Reddot")
    -- local _ = self.m_pReddot3 and self.m_pReddot3:setVisible(Utils:GetRedDotState(RedDotDef.ID.BPJiangLi))
end

function BangPaiMemList:LoadMemberList(list)
    local myId = LRoleDataMgr.MyHeroInfo:Getid()
    local myBangPaiChenYuanIdx = -1
    for i=1,#list do
        if myId == list[i].roleId then
            myBangPaiChenYuanIdx = i
            break
        end
    end

    local pScrollViewSize = self.m_pTablePanel:getContentSize()
    if myId > 0 and myBangPaiChenYuanIdx >= 0 then
        local info = list[myBangPaiChenYuanIdx]

        local viewcell = self.m_pGridCell:clone()
        viewcell:setPosition(cc.p(self.m_pGridCell:getPosition()))
        viewcell:setVisible(true)
        self:updateItem(viewcell, info, 0, true)

        self.m_pGridCell:getParent():addChild(viewcell)

        self.m_pMyTableCell = viewcell

        pScrollViewSize.height = pScrollViewSize.height - viewcell:getContentSize().height
        self.m_pTablePanel:setContentSize(pScrollViewSize)

        table.remove(list, myBangPaiChenYuanIdx)

        self:TableCellTouched(-1)
    end

    self.m_pTableView = self:InitTableView(self.m_pTablePanel)

    self.m_datas = list
    self.m_tableCount = #list
    if self.m_pTableView ~= nil then
        self.m_pTableView:reloadData()
    end
end

function BangPaiMemList:InitTableView(tbPanel)
    if self.m_pTableView ~= nil then
        return self.m_pTableView
    end

    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx+1)
    end

    cfg.numberOfCellsInTableView = function()
        return self.m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        self.m_isDragging = view:isDragging()
    end

    cfg.tableCellTouched = function(sender, cell)
        return self:TableCellTouched(cell:getIdx()+1)
    end

    return Utils:createTableView(cfg)
end

function BangPaiMemList:TableCellTouched(idx)
    if idx < 0 then
        return
    end
    if idx == self.m_selectIndex then
        if idx > 0 then
            self:showBtnList(idx)
        end
        return
    end

    if self.m_pMyTableCell ~= nil then
        self:setSelect(self.m_pMyTableCell, idx == -1)
    end

    self.m_selectIndex = idx
    if self.m_pTableView ~= nil then
        local offset = self.m_pTableView:getContentOffset()
        self.m_pTableView:reloadData()
        self.m_pTableView:setContentOffset(offset)
    end
end

function BangPaiMemList:TableCellAtIndex(sender, idx)
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
        self:updateItem(cellChild, self.m_datas[idx], idx)
    end
    return cell
end

function BangPaiMemList:updateItem(cell, info, idx, bMyItem)
    local color = bMyItem and cc.c4b(0,255,0,255) or cc.c4b(110,56,48,255)
    
    self:setSelect(cell, self.m_selectIndex == idx)

    local bShowBg = (bMyItem) or (math.fmod(idx, 2) == 1)
    local bgSp = cell:getChildByName("Bg")
    bgSp:setVisible(bShowBg)

    local filestr = Utils:GetHeroIconRes(info.roleHead, AppDef.HeadIconResType.Square)
    local pRoleBg = cell:getChildByName("RoleBg")
    local pRoleImage = pRoleBg:getChildByName("RoleImage")
    pRoleImage:loadTexture(filestr)

    local pLv = pRoleBg:getChildByName("Text_82")
    pLv:setString(info.roleLevel)
    pLv:setTextColor(bMyItem and color or cc.c4b(0xff,0xff,0xff,0xff))

    local pRoleName = cell:getChildByName("RoleName")
    pRoleName:setString(info.roleName)
    pRoleName:setTextColor(color)

    local pLevelNum = cell:getChildByName("LevelNum")
    pLevelNum:setString(tostring(info.roleLevel))
    pLevelNum:setTextColor(color)

    local pPositionName = cell:getChildByName("PositionName")
    self:updateItemWeiJie(cell, info.roleWeiJie)
    pPositionName:setTextColor(color)

    local pContributionNum = cell:getChildByName("ContributionNum")
    pContributionNum:setString(tostring(info.gongXian))
    pContributionNum:setTextColor(color)

    local pHuoyue = cell:getChildByName("Huoyue")
    pHuoyue:setString(tostring(info.activity or 0))
    pHuoyue:setTextColor(color)

    local pPowerNum = cell:getChildByName("PowerNum")
    pPowerNum:setString(Utils:getPowerStr(info.zhandouli))
    pPowerNum:setTextColor(color)

    local function getTimeString(time)
        if 0 == time then
            return GUITips.RSI_FACTION_MSG43
        else
            local day = math.floor(time / (24 * 3600))
            local hour = math.floor(time / 3600)
            if day > 0 then
                return string.format("%d%s", day, GUITips.RSI_FACTION_MSG44)
            elseif hour > 0 then
                return string.format("%d%s", hour, GUITips.RSI_FACTION_MSG45)
            else
                return string.format("%d%s", math.floor(time / 60), GUITips.RSI_FACTION_MSG46)
            end
        end
    end

    local pOnlineTime = cell:getChildByName("OnlineTime")
    local str = getTimeString(info.lastOnlineTime)
    pOnlineTime:setString(str)
    pOnlineTime:setTextColor(color)

    if bMyItem then
        local function myCellTouched(sender)
            self:TableCellTouched(-1)
        end
        cell:setTouchEnabled(true)
        cell:addClickEventListener(myCellTouched)
		self:MarkIntaractCObj(cell)
    end

    local pVIPImage = cell:getChildByName("VIPImage")
    if info.vip and info.vip > 0 then
        pVIPImage:setVisible(true)
        pVIPImage:getChildByName("Num"):setString(tostring(info.vip))
    else
        pVIPImage:setVisible(false)
    end
end

function BangPaiMemList:updateItemWeiJie(cell, roleWeiJie)
    local pPositionName = cell:getChildByName("PositionName")
    pPositionName:setString(Utils:getPostName(roleWeiJie))
end

function BangPaiMemList:setSelect(cell, bSelected)
    if cell == nil then
        return
    end
    local pChooseSp = cell:getChildByName("ChooseBg")
    pChooseSp:setVisible(bSelected)
end

function BangPaiMemList:setMenuState()
    local info = LRoleDataMgr.Faction.Info
    if info ~= nil and info.selfRank < 3 then
        for k,v in pairs(self.m_buttons) do
            v:setVisible(true)
        end
    end
end

function BangPaiMemList:joinApplyCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    Utils:InitUI("BangPai.BangPaiApplyPopup",AppDef.UIType.SecondClassLayer)
end

function BangPaiMemList:invokeCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    Utils:InitUI("BangPai.BangPaiInvitePopup",AppDef.UIType.SecondClassLayer)
end

function BangPaiMemList:rewardCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    LuaNetSendMsg:QueryTakeFactionAward()
end

function BangPaiMemList:leaveCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    local function OKCallback()
        LuaNetSendMsg:QueryFactionExit()
        Utils:DeleteUI("BangPai.BangPaiUI")
    end
    local function CancelCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        cancelCallback = CancelCallback,
        desc = GUITips.RSI_BP_TIP2,
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BangPaiMemList:UpdateRedDot(data)
    if data.id == RedDotDef.ID.BPShenQing then
        local _ = self.m_pReddot and self.m_pReddot:setVisible(data.isShow)
    -- elseif data.id == RedDotDef.ID.BPJiangLi then
    --     local _ = self.m_pReddot3 and self.m_pReddot3:setVisible(data.isShow)
    end
end

function BangPaiMemList:showBtnList(index)
    local rank = LRoleDataMgr.Faction.Info.selfRank
    if(LRoleDataMgr.MyHeroInfo:IsMe(self.m_datas[index].roleId)) then
        return
    end
    local optionName = {}
    table.insert(optionName, {GUITips.RSI_FRIEND_CHECKINFO, handler(self, BangPaiMemList.checkInfoCallback)})
    --table.insert(optionName, {GUITips.RSI_FRIEND_INVITE_TEAM, handler(self, BangPaiMemList.InviteItemCallback)})
    table.insert(optionName, {GUITips.RSI_FRIEND_ADD, handler(self, BangPaiMemList.addFriendCallback)})
    --table.insert(optionName, {GUITips.RSI_FRIEND_SEND_MAIl, handler(self, BangPaiMemList.sendMailCallback)})

    if(rank == AppDef.FactionInfo.BPRT_BANGZHU or rank == AppDef.FactionInfo.BPRT_ZHANGLAO) then
        if(rank < self.m_datas[index].roleWeiJie) then
            table.insert(optionName, {GUITips.RSI_FRIEND_ADJUST_POS, handler(self, BangPaiMemList.adjustPosCallback)})
            table.insert(optionName, {GUITips.RSI_FRIEND_OUT_FACTION, handler(self, BangPaiMemList.letOutCallback)})

            if(rank == AppDef.FactionInfo.BPRT_BANGZHU) then
                table.insert(optionName, {GUITips.RSI_FRIEND_PASS_POS, handler(self, BangPaiMemList.passPosCallback)})
            end
        end
    end

    local Data = LRoleData:New()
    Data.id = self.m_datas[self.m_selectIndex].roleId
    Data.professional = self.m_datas[self.m_selectIndex].roleHead
    Data.name = self.m_datas[self.m_selectIndex].roleName
    Data.level = self.m_datas[self.m_selectIndex].roleLevel
    self.m_selectHeroData = Data

    if self.m_pMask then
        optionName.pos = cc.p(self.m_pMask:getTouchEndPosition())
    end
    
    Utils:SendMsg(LUILogicEvent.ShowCommomBtnList, optionName)
end

function BangPaiMemList:checkInfoCallback()
    LuaNetSendMsg:QueryOtherPlayer(self.m_datas[self.m_selectIndex].roleId)
end

function BangPaiMemList:InviteItemCallback()
    LuaNetSendMsg:QueryTeamInvite(self.m_datas[self.m_selectIndex].roleId)
end

function BangPaiMemList:addFriendCallback()
    LuaNetSendMsg:QueryAddFriend(self.m_datas[self.m_selectIndex].roleId)
end

function BangPaiMemList:sendMailCallback()
    Utils:DeleteUI("BangPai.BangPaiUI")
    Utils:SendMsg(LUIMailEvent.OpenWriteMail, LRoleDataMgr.MyHeroInfo.name)
end

function BangPaiMemList:adjustPosCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    if self.m_datas[self.m_selectIndex] == nil then
        return
    end
    local rank = LRoleDataMgr.Faction.Info.selfRank
    local otherRank = self.m_datas[self.m_selectIndex].roleWeiJie
    self.m_posIndex = 1

    local temp = {}
    temp[1] = AppDef.FactionInfo.BPRT_ZHANGLAO
    temp[2] = AppDef.FactionInfo.BPRT_HUFA
    temp[3] = AppDef.FactionInfo.BPRT_BANGZHONG

    for i=1,#temp do
        if temp[i] == otherRank then
            self.m_posIndex = i
            break
        end
    end
    
    local function okCallback()
        if self.m_datas == nil or self.m_datas[self.m_selectIndex] == nil then
            return
        end
        LuaNetSendMsg:QueryFactionChangePostIndex(self.m_datas[self.m_selectIndex].roleId, temp[self.m_posIndex])
    end

    local function selectCallback(idx)
        self.m_posIndex = idx
    end

    local data = {
        title = GUITips.RSI_FACTION_MSG205,
        okCallback = okCallback,
        checkBoxList = {
            init = self.m_posIndex,
            text = {},
            selectCallback = selectCallback,
        },
    }

    if(rank <= AppDef.FactionInfo.BPRT_ZHANGLAO) then
        table.insert(data.checkBoxList.text, string.format("%s %s", Utils:getPostName(2), GUITips.RSI_FACTION_MSG8)) -- 长老
        table.insert(data.checkBoxList.text, string.format("%s %s", Utils:getPostName(3), GUITips.RSI_FACTION_MSG9)) -- 护法
        table.insert(data.checkBoxList.text, string.format("%s %s", Utils:getPostName(4), GUITips.RSI_FACTION_MSG10)) -- 帮众
    end
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, data)
end

function BangPaiMemList:letOutCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    local function okCallback()
        if self.m_datas == nil or self.m_datas[self.m_selectIndex] == nil then
            return
        end
        LuaNetSendMsg:QueryFactionFireMember(self.m_datas[self.m_selectIndex].roleId)
    end

    local function cancelCallback()
    end

    local str = GUITips.RSI_FACTION_MSG4 .. self.m_datas[self.m_selectIndex].roleName .. GUITips.RSI_FACTION_MSG5
    local data = {
        desc = str,
        okCallback = okCallback,
        cancelCallback = cancelCallback,
    }
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, data)
end

function BangPaiMemList:passPosCallback()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    local function okCallback()
        LuaNetSendMsg:QueryNominateFactionBoss(self.m_datas[self.m_selectIndex].roleId)
    end

    local function cancelCallback()
    end

    local str = GUITips.RSI_FACTION_MSG6 .. self.m_datas[self.m_selectIndex].roleName .. GUITips.RSI_FACTION_MSG7
    local data = {
        desc = str,
        okCallback = okCallback,
        cancelCallback = cancelCallback,
    }
    Utils:SendMsg(LUIMsgBoxEvent.ShowMsgBox, data)
end

function BangPaiMemList:UpdateMemberWeiJie(data)
    local index = 1
    for i=1,#self.m_datas do
        if self.m_datas[i].roleId == data.roleId then
            self.m_datas[i].roleWeiJie = data.rank
            index = i
            break
        end
    end

    local pCell = self.m_pTableView:cellAtIndex(index - 1)
    if pCell ~= nil then
        local pItem = pCell:getChildByTag(123)
        self:updateItemWeiJie(pItem, self.m_datas[index].roleWeiJie)
    end
end

function BangPaiMemList:DelMemberByRoleId(roleId)
    if roleId <= 0 then
        return
    end

    local index = 0
    for i=1,#self.m_datas do
        if self.m_datas[i].roleId == roleId then
            index = i
            table.remove(self.m_datas, i)
            break
        end
    end
    if index <= 0 then
        return
    end
    self.m_selectIndex = -1
    self.m_tableCount = #self.m_datas
    local offset = self.m_pTableView:getContentOffset()
    self.m_pTableView:reloadData()

    local min = self.m_pTableView:minContainerOffset().y
    local max = self.m_pTableView:maxContainerOffset().y
    local cellHeight = self.m_pGridCell:getContentSize().height
    offset.y = math.max(math.min(offset.y+cellHeight, max), min)
    
    self.m_pTableView:setContentOffset(offset)
end

function BangPaiMemList:UpdateBangZhuChuangWei(roleId)
    if roleId <= 0 then
        return
    end
    --update other weijie
    local index = 0
    for i=1,#self.m_datas do
        if self.m_datas[i].roleId == roleId then
            self.m_datas[i].roleWeiJie = AppDef.FactionInfo.BPRT_BANGZHU
            index = i
            break
        end
    end
    
    if index <= 0 then
        return
    end
    local pCell = self.m_pTableView:cellAtIndex(index - 1)
    if pCell ~= nil then
        local pItem = pCell:getChildByTag(123)
        self:updateItemWeiJie(pItem, self.m_datas[index].roleWeiJie)
    end

    --update my weijie
    self:updateItemWeiJie(self.m_pMyTableCell, LRoleDataMgr.Faction.Info.selfRank)
end

return BangPaiMemList