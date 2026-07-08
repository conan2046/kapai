
local BangPaiXiuLian = LUIBase:New()
BangPaiXiuLian.__index = BangPaiXiuLian
--local this = LTcpSocket
function BangPaiXiuLian:New()
	local o = LUIBase:New()
	setmetatable(o,BangPaiXiuLian)	
    o:Init()
	return o
end

--注册事件
-- -----------------------------------
function BangPaiXiuLian:RegistMsgs()
    self.msgIds = 
    {
        LUIBangPaiWarEvent.UpdateSkillUpUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BangPaiXiuLian:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiWarEvent.UpdateSkillUpUI then
        self:loadData(msg.value)
        self:updateUI()
    end
end

function BangPaiXiuLian:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/GuildSkillLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self._isHasRedDot = false
    self:RegistMsgs()
    self:initUIControl()
    LuaNetSendMsg:QueryBpSkilllevelUpData(44)
end

function BangPaiXiuLian:initUIControl( ... )
    -- body
    local panel = self.m_pUILayer:getChildByName("Panel")
    --------------------------------------------------------------
    local skillBg = panel:getChildByName("SkillBg")
    local list = skillBg:getChildByName("List")
    self._skillList = {}
    for i=1, 8 do
        local strTemp = string.format("SkillIconBg%d", i)
        local item = list:getChildByName(strTemp)
        table.insert(self._skillList, item)
        item:setTag(i)
        item:addClickEventListener(handler(self, BangPaiXiuLian.selectSkillEvent))

    end
    --------------------------------------------------------------
    local skillDescribeBg = panel:getChildByName("SkillDescribeBg")
    local describeTitle1 = skillDescribeBg:getChildByName("DescribeTitle1")
    self._skillName = describeTitle1:getChildByName("TitleName")
    local describeText = describeTitle1:getChildByName("DescribeText")
    self._curDes = describeText:getChildByName("Name1"):getChildByName("Text")
    self._nextDes = describeText:getChildByName("Name2"):getChildByName("Text")
    local describeTitle2 = skillDescribeBg:getChildByName("DescribeTitle2")
    local describeText2 = describeTitle2:getChildByName("DescribeText")
    self._playerLv = describeText2:getChildByName("Name1"):getChildByName("Text")
    self._banggong = describeText2:getChildByName("Name2"):getChildByName("Text")
    self._costCoin = describeText2:getChildByName("Name3"):getChildByName("Text")

    local bangGongBg = skillDescribeBg:getChildByName("CoinBg")
    self._bangGongValue = bangGongBg:getChildByName("Value")
    local bangGongAddBtn = bangGongBg:getChildByName("Button")
    bangGongAddBtn:addClickEventListener(function ( sender )
        -- body
        if LRoleDataMgr.m_bIsCrossServer then
            Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG119)
            return
        end
        LuaNetSendMsg:QueryFactionJuanXianMsg()
    end)

    local coinBg = skillDescribeBg:getChildByName("CoinBg_0")
    self._coinValue = coinBg:getChildByName("Value")
    local addButton = coinBg:getChildByName("Button")
    addButton:addClickEventListener(function ( sender )
        -- body
        if Utils:CheckModelNotOpened(AppDef.EActivityID.EAID_SHAKEMONEYTREE,true) then
            if ind == 1 then
                Utils:OpenShop(1,2386)
            else
                Utils:ShowScrollTips(GUITips.RSI_ITEM_MSG_5)
            end
            return
        end
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.MoneyTreeMainUI",AppDef.UIType.FirstClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)

    local skillBtn = skillDescribeBg:getChildByName("SkillBtn1")
    skillBtn:addClickEventListener(function ( sender )
        -- body

        if LRoleDataMgr.m_bIsCrossServer then
            Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
            return
        end

        if self.m_datas == nil then
            return
        end

        local data = self.m_datas[self._curSelcet]
        if data == nil then
            return
        end

        local type = LDataConstMgr:getIsCanEnough(data)
        print("type ====", type)
        if type == 1 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS1)
            return 
        elseif type == 2 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS2)
            return
        elseif type == 3 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
            return
        end

        LuaNetSendMsg:QueryBpSkilllevelUp(45, 1, data.buffType, 0)
    end)
    self._skillBtnRedDot = skillBtn:getChildByName("RedDot")

    local SkillBtn2 = skillDescribeBg:getChildByName("SkillBtn2")
    SkillBtn2:addClickEventListener(function ( sender )
        -- body

        if LRoleDataMgr.m_bIsCrossServer then
            Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
            return
        end

        if self.m_datas == nil then
            return
        end

        local data = self.m_datas[self._curSelcet]
        if data == nil then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS)
            return
        end

        local type = LDataConstMgr:getIsCanEnough(data)
        print("type ====", type)
        if type == 1 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS1)
            return 
        elseif type == 2 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS2)
            return
        elseif type == 3 then
            Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
            return
        end

        LuaNetSendMsg:QueryBpSkilllevelUp(45, 1, data.buffType, 1)
    end)
    self._skillBtnRedDot2 = SkillBtn2:getChildByName("RedDot")
    self._curSelcet = 0
end

function BangPaiXiuLian:selectSkillEvent( sender )
    -- body
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end

    if sender == nil then
        Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS)
        return
    end
    local index = sender:getTag()
    if self._curSelcet == index then
        return
    end

    if self._curSelcet > 0 then
        local item = self._skillList[self._curSelcet]
        item:getChildByName("Choose"):setVisible(false)
    end
    self._curSelcet = index
    local item = self._skillList[self._curSelcet]
    item:getChildByName("Choose"):setVisible(true)
    self:updateRightUI(index)
end

function BangPaiXiuLian:loadData( skillData )
    -- body
    self.m_datas = {}
    for i=1, #skillData do
        local data = skillData[i]
        local attrData = LDataConstMgr:getBpKejiDataByLevel(data.level, data.id)
        if attrData ~= nil then
            if attrData.effectType > 0 and attrData.isShow then
                table.insert(self.m_datas, attrData)
            end
        end
    end
--    dump(self.m_datas, "sel Data ===========> 22222222222222 ")
end

function BangPaiXiuLian:updateUI( ... )
    -- body
    self._isHasRedDot = false
    for i=1, #self.m_datas do
        local data = self.m_datas[i]
        local item = self._skillList[i]
        local skilIcon = item:getChildByName("SkillIcon")
        local iconPath
        if data.pic == nil or #data.pic < 1 then
            iconPath = "res/res2/Icon/ui_bangpai_icon/bg_101.png"
        else
            iconPath = "res/res2/Icon/ui_bangpai_icon/"..data.pic..".png"
        end
        skilIcon:loadTexture(iconPath, UI_TEX_TYPE_LOCAL)
        local upImage = item:getChildByName("UpImage")
        if LDataConstMgr:getIsCanEnough(data) > 0 then
            upImage:setVisible(false)
        else
            self._isHasRedDot = true
        end

        local lv = item:getChildByName("Text")
        lv:setString(data.level)

        local skillNameBg = item:getChildByName("SkillNameBg")
        local name = skillNameBg:getChildByName("SkillName")
        name:setString(data.name)

    end
    --默认显示1
    if self._curSelcet <= 0 then
        self._curSelcet = 1
    end

    local item = self._skillList[self._curSelcet]
    item:getChildByName("Choose"):setVisible(true)
    self:updateRightUI(self._curSelcet)

    --小红点检测
    local curRed = Utils:GetRedDotState(RedDotDef.ID.BPXiuLian)
    if curRed ~= self._isHasRedDot then
        Utils:SetRedDotState(RedDotDef.ID.BPXiuLian, self._isHasRedDot)
    end

    self._skillBtnRedDot:setVisible(self._isHasRedDot)
    self._skillBtnRedDot2:setVisible(self._isHasRedDot)

end

function BangPaiXiuLian:updateRightUI(index)
    -- body
    if self.m_datas == nil then
        return
    end

    local data = self.m_datas[index]
    if data == nil then
        return
    end
    self._curDes:setString(data.des)
    local nextLevel = data.level + 1 
    if nextLevel > 20 then
        self._nextDes:setString(GUITips.RSI_GS_TIP17)
    else
        local attrData = LDataConstMgr:getBpKejiDataByLevel(nextLevel, data.buffType)
        if attrData ~= nil then
            self._nextDes:setString(attrData.des)
        end
    end

    local bangGong = 0
    local coin = 0
    for i=1, #data.playerCost do
        if data.playerCost[i].id == AppDef.AwrdItem.AWRD_ITEM_COIN then
            coin = data.playerCost[i].num
        elseif data.playerCost[i].id == AppDef.AwrdItem.AWRD_ITEM_BANGGONG then
            bangGong = data.playerCost[i].num
        end
    end
    self._banggong:setString(bangGong)
    self._costCoin:setString(coin)
    local maxLv = LDataConstMgr:getLVMaxByType(data.buffType)
    self._playerLv:setString(tostring(maxLv))

    self._bangGongValue:setString(LRoleDataMgr.Faction.Info.selfBangGong)
    local myCoin = Utils:getGoldStr()
    self._coinValue:setString(myCoin)

    local namesStr = data.name .. " " .. "LV" .. data.level
    self._skillName:setString(namesStr)
end


function BangPaiXiuLian:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return BangPaiXiuLian