local BangPaiFuBenRankUI = LUIBase:New()
BangPaiFuBenRankUI.__index = BangPaiFuBenRankUI


local BangPaiDef = require("View.BangPai.BangPaiDef")
local BPBuffs = require("ConfigData.guild_buff_dat")
local ScriptPath = "BangPai.BangPaiFuBenRankUI"

-- -----------------------------------
function BangPaiFuBenRankUI:New(chapterId)
    local o = {}
    setmetatable(o, BangPaiFuBenRankUI)
    o:Init(chapterId)
    return o
end

-- -----------------------------------
function BangPaiFuBenRankUI:Init(chapterId)
    self.Script = "BangPai.Fuben.BangPaiFuBenRankUI"
    self._chapterId = chapterId;
    self._chapterData = LRoleDataMgr.Faction.chapterArr[chapterId];
    self._curTab = 0;
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:initData()
    self:ShowCopyName();
    self:ChangeTab(1);
end

function BangPaiFuBenRankUI:initData()
    LuaNetSendMsg:QueryBangPaiFubenRank(self._chapterId)
end

function BangPaiFuBenRankUI:ShowCopyName()
    local tabParent = self.m_pUILayer:findChildByName("GangsPopup/Popup/CheckList");
    for i = 1, self._chapterData.copyNum do
        local copyData = self._chapterData.copyArr[i];
        local configData = JsonConfig.m_stageNodeConfig.getDefByID(copyData.id);
        tabParent:findChildByName("Type" .. i .. "/Text"):setString(configData.Name);
        tabParent:findChildByName("Type" .. i .. "/Choose/Text"):setString(configData.Name);
    end
end

-- -----------------------------------
function BangPaiFuBenRankUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

-- -----------------------------------
function BangPaiFuBenRankUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.GotRankData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiFuBenRankUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.GotRankData then
        self._tableView:reloadData();
    end
end

function BangPaiFuBenRankUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self, LUIBase.RemoveUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_FACTION_TITLE7)
end

-- -----------------------------------
function BangPaiFuBenRankUI:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsPopupLayer.csb");
end

-- -----------------------------------
function BangPaiFuBenRankUI:InitUIControl()
    self.m_pUILayer:findChildByName("GangsPopup/Popup"):setVisible(true);
    self.m_pUILayer:findChildByName("GangsPopup/SkillPopup"):setVisible(false);
    self._baseItemNode = self.m_pUILayer:findChildByName("GangsPopup/Popup/Item");
    self._baseItemNode:setVisible(false);

    local tabPanel = self.m_pUILayer:findChildByName("GangsPopup/Popup/Image2/ListView");
    tabPanel:setTouchEnabled(false)
    self._tableView = self:InitTableView(tabPanel);

    self.m_pGridCellSize = self._baseItemNode:getContentSize();


    local tabParent = self.m_pUILayer:findChildByName("GangsPopup/Popup/CheckList");
    for i = 1, 4 do
        local btn = tabParent:findChildByName("Type" .. i);
        btn.userData = i
        btn:addClickEventListener(function(sender)
            self:OnTabClicked(sender)
        end)
    end
end

function BangPaiFuBenRankUI:OnTabClicked(sender)
    local ind = sender.userData;
    self:ChangeTab(ind);
end

function BangPaiFuBenRankUI:ChangeTab(ind)
    if self._curTab == ind then
        return
    end
    self._curTab = ind;
    self:SetBtnState();
    self:ShowCurRank();
end

function BangPaiFuBenRankUI:SetBtnState()
    local tabParent = self.m_pUILayer:findChildByName("GangsPopup/Popup/CheckList");
    for i = 1, 4 do
        local btn = tabParent:findChildByName("Type" .. i);
        if i == self._curTab then
            btn:setTouchEnabled(false);
            btn:getChildByName("Choose"):setVisible(true);
        else
            btn:setTouchEnabled(true);
            btn:getChildByName("Choose"):setVisible(false);
        end
        btn.userData = i
        btn:addClickEventListener(function(sender)
            self:OnTabClicked(sender)
        end)
    end
end

function BangPaiFuBenRankUI:ShowCurRank()
    self._tableView:reloadData();
    if self._curTab == 0 then
        return 0
    end

    local copyData = self._chapterData.copyArr[self._curTab];
    local configData = JsonConfig.m_stageNodeConfig.getDefByID(copyData.id);
    self.m_pUILayer:findChildByName("GangsPopup/Popup/RankingReward/Icon1/Value"):setString(configData.max_damage[1][3])
    self.m_pUILayer:findChildByName("GangsPopup/Popup/RankingReward_0/Icon1/Value"):setString(configData.final_kill[1][3])
end

function BangPaiFuBenRankUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCellSize.width
        local height = self.m_pGridCellSize.height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function() 
        return self:GetRankNum()
    end

    return Utils:createTableView(cfg)
end

function BangPaiFuBenRankUI:GetRankNum()
    if self._curTab == 0 then
        return 0
    end
    return self._chapterData.copyArr[self._curTab].rankNum
end
-----------------------------------
function BangPaiFuBenRankUI:TableCellAtIndex(sender, idx)
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        cell = cc.TableViewCell:new()
        cellChild = self._baseItemNode:clone()
        cellChild:setVisible(true)
        cellChild:setAnchorPoint(cc.p(0, 0))
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)
        -- cellChild = Utils:CreateColorText2(cell, cellChild)
        cellChild:setTag(123)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, self._chapterData.copyArr[self._curTab].rankInfoArr[idx+1])
    end
    return cell
end
-----------------------------------
function BangPaiFuBenRankUI:updateItem(cell, info)
    --[[
    info.roleId = stream:ReadUInt();
        print("info.roleId",info.roleId)
        info.damage = stream:ReadULongInt();
        print("info.damage",info.damage)
        info.name = stream:ReadString();
        print("info.name",info.name)
        info.head = stream:ReadByte();
        info.power = stream:ReadUInt();
        info.level = stream:ReadWord();
        info.vipLv = stream:ReadByte();
    ]]
    local nameLabel = cell:getChildByName("Name");
    nameLabel:setString(info.name);
    local damageLabel = cell:findChildByName("Power/Value");
    damageLabel:setString(info.damage);
    local powerLabel = cell:findChildByName("Gangs/Value");
    -- powerLabel:setString(info.power);

    local powerValue, isWan = Utils:getNewPowerStr(info.power);
    powerLabel:setString(powerValue);
    if isWan == true then
        powerLabel:getChildByName("Wan"):setVisible(true)
        powerLabel:getChildByName("Wan"):setPositionX(powerLabel:getContentSize().width)
    else
        powerLabel:getChildByName("Wan"):setVisible(false)
    end

    local headImg = cell:getChildByName("Icon_1");
    local strImage = Utils:GetHeroIconRes(info.head, AppDef.HeadIconResType.Square)
    Utils:SafeLoadTexture(headImg,strImage,ccui.TextureResType.localType)

    if info.lastHitId == info.roleId then
        cell:getChildByName("Lable_0"):setVisible(true);
    else
        cell:getChildByName("Lable_0"):setVisible(false );
    end

    if info.rank == 1 then
        cell:getChildByName("Lable"):setVisible(true);
    else
        cell:getChildByName("Lable"):setVisible(false );
    end

    if info.rank <= 3 then
        for i = 1, 4 do
            if info.rank == i then
                cell:getChildByName("Num_" .. i):setVisible(true);
            else
                cell:getChildByName("Num_" .. i):setVisible(false);
            end
            
        end
    else
        for i = 1, 3 do
            cell:getChildByName("Num_" .. i):setVisible(false);
        end
        cell:getChildByName("Num_4"):setVisible(true)
        cell:getChildByName("Num_4"):setString(info.rank);
    end

end

function BangPaiFuBenRankUI:showTips(msg)
    Utils:ShowScrollTips(msg)
end

return BangPaiFuBenRankUI