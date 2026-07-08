local BangPaiFuBenListCtrl = {}
BangPaiFuBenListCtrl.__index = BangPaiFuBenListCtrl

-- -----------------------------------
function BangPaiFuBenListCtrl:New(ctrl, node)
    local o = {}
    setmetatable(o, BangPaiFuBenListCtrl)
    o:Init(ctrl, node)
    return o
end

-- -----------------------------------
function BangPaiFuBenListCtrl:Init(ctrl, node)
    self.Script = "BangPai.BangPaiFuBenListCtrl"
    self._ctrl = ctrl
    self.m_pUILayer = node
    self._itemNodeArr = {}
    self:InitUIControl()
    self:setCloseCallback()
    self:ShowList();
end

function BangPaiFuBenListCtrl:ShowList()
    local list = JsonConfig.m_bpFubenConfig
    -- dump(list,"list")
    local sx = 0;
    local sy = 0;
    local width = 0;
    local contentSize =  self.m_pUILayer:getContentSize();
    local bgNode = self.m_pUILayer:getChildByName("bgNode");
    local bg = self.m_pUILayer:findChildByName("Image_35");
    local bgSize = bg:getContentSize();
    local bgsx = 0;
    local bgNum = 1;
    local bgx = bgSize.width;
    self._itemNodeArr = {}
    local targetX = 0
    local targetWidth = 0
    for i = 1, #list do
        local item
        if i % 2 == 1 then
            item = self._itemArr[1]:clone()
        else
            item = self._itemArr[2]:clone()
        end
        item:setVisible(true)
        table.insert(self._itemNodeArr,item)
        self.m_pUILayer:addChild(item)
        item:setTag(list[i].Id);
        local isOpen = self:ShowChapter(item, list[i])
        item:setPosition(sx, sy);
        local itemWidth = item:getContentSize().width;
        sx = sx + itemWidth;
        if isOpen  == true then
            targetX = sx;
            targetWidth = itemWidth;
        end
        if bgsx >= bgx then
            bgsx = bgsx - bgx;
            local tmp = bg:clone();
            bgNode:addChild(tmp)
            tmp:setPosition(bgNum * bgSize.width , sy);
            bgNum = bgNum + 1
        end
        bgsx = bgsx + item:getContentSize().width;
        local btn = item:getChildByName("Btn");
        btn.userData = list[i].Id;
        btn:addClickEventListener(function(sender)
            self:OnFubenClicked(sender)
        end)
    end
    contentSize.width = sx;
    self.m_pUILayer:setInnerContainerSize(contentSize)
    if targetX - targetWidth <= 0 then
        targetX = 0;
    end
    self.m_pUILayer:jumpToPercentHorizontal(targetX * 100 / contentSize.width);
end

function BangPaiFuBenListCtrl:UpdateChapterData(chId)
    local list = JsonConfig.m_bpFubenConfig;
    local itemNode = nil;
    local ind = 0
    local nextInd = 0
    for i = 1, #list do
        if list[i].Id == chId then
            ind = i
            itemNode = self.m_pUILayer:getChildByTag(list[i].Id);
            break
        end
    end
    if itemNode and ind > 0 then
        self:ShowChapter(itemNode, list[ind])
    end
    -- print("UpdateChapterData",ind,list[ind]:IsComplete())
    -- if ind < #list and list[ind]:IsComplete() then
    --     self:ShowChapter(itemNode, list[ind + 1])
    -- end
end

function BangPaiFuBenListCtrl:UpdateCopy(copyData)
    local list = JsonConfig.m_bpFubenConfig;
    for i = 1, #list do
        local myData = LRoleDataMgr:GetBPChapterData(list[i].Id);
        if myData and myData:GetCopyData(copyData.id) then
            self:ShowChapter(self._itemNodeArr[i],list[i]);
            break;
        end
    end
end

function BangPaiFuBenListCtrl:OnFubenClicked(sender)
    -- print("sender",sender.userData)
    self._ctrl:EnterFuben(sender.userData)
end

function BangPaiFuBenListCtrl:setVisible(visible)
    self.m_pUILayer:setVisible(visible)
end

function BangPaiFuBenListCtrl:isVisible()
    return self.m_pUILayer:isVisible()
end

function BangPaiFuBenListCtrl:ShowChapter(node, data)
    local nameLabel = node:findChildByName("Btn/UI_Panel/Name");
    nameLabel:setString(data.Name);
    local lockBtn = node:findChildByName("Btn/Lock");
    local progressNode = node:findChildByName("Btn/UI_Panel");
    local myData = LRoleDataMgr:GetBPChapterData(data.Id);
    if myData == nil then
        --未开放
        lockBtn:setVisible(true);
        progressNode:setVisible(false);
        node:findChildByName("Btn/Prompt"):setVisible(false);
        return false
    else
        lockBtn:setVisible(false);
        progressNode:setVisible(true);
        if myData:IsComplete() then
            node:findChildByName("Btn/UI_Panel/Battle"):setVisible(false);
            node:findChildByName("Btn/UI_Panel/Loading"):setVisible(false);
        else
            node:findChildByName("Btn/UI_Panel/Battle"):setVisible(true);
            local progressBar = node:findChildByName("Btn/UI_Panel/Loading/LoadingBar_1");
            progressBar:setPercent(100 - myData:GetProgress())
        end

        if myData:HasReward() then
            node:findChildByName("Btn/Prompt"):setVisible(true);
        else
            node:findChildByName("Btn/Prompt"):setVisible(false);
        end
        return true
    end
end

-- -----------------------------------
function BangPaiFuBenListCtrl:onExit()
    self.m_pUILayer = nil
end

-- -----------------------------------
function BangPaiFuBenListCtrl:ProcessEvent(msg)
    -- if msg.msgId == LUIBangPaiEvent.UpdateMyFactionInfo then
    --     self:setBasicUI()
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateGongGao then
    --     self:UpdateGongGao()
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateNameShow then
    --     self:updateBPNameVisible(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateManorInfo then
    --     self:setDetailUI()
    -- elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
    --     self:ReloadActivityData(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
    --     self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
    -- elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
    --     self:UpdateRedDot(msg.value)
    -- elseif msg.msgId == LUILogicEvent.changeBpNameSuc then
    --     self:setBpName()
    -- end
end

function BangPaiFuBenListCtrl:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
-- -----------------------------------
function BangPaiFuBenListCtrl:InitUIControl()
    self._itemArr = {self.m_pUILayer:getChildByName("Panel_1"),self.m_pUILayer:getChildByName("Panel_2")};

    self._itemArr[1]:setVisible(false);
    self._itemArr[2]:setVisible(false);
end

return BangPaiFuBenListCtrl