--[[
通用确定取消提示框
userData数据结构：
{
    （可选）closeCallback:  右上角关闭按钮回调
    （可选）cancelCallback:  取消按钮回调
    （可选）okCallback:  确定按钮回调
    （可选）checkBoxCallback:  checkBox按钮回调
    （可选）title:  提示框Title,默认显示“提示”
    （可选）desc:  提示框详细描述，默认不显示
    
    		{PItem1,PItem2,PItem3,...}
    （可选）approachList:  获取途径列表,数据结构如下：
    		{
    			{iconPath,callback},
    			{iconPath,callback},
    			{iconPath,callback},
    			...
    		}
    （可选）okBtnName: 确认按钮文字，缺省为“确认”
    （可选）cancelBtnName:取消按钮文字，缺省为“取消”
    （可选）checkBoxList:单选框列表，数据结构如下：
            {
                init,--初始选中，默认1
                text={"文字内容", "文字内容", ...},
                selectCallback=selectCallback --选中回调
            }
    （可选）descList:  提示框文字列表(格式为以"|"分隔的字符串)，默认不显示
     (可选)  TipsInfo : 提示花费道具购买次数，每天有可买次数,数据格式如下:
        {
            price, --价钱
            type,  --消耗物品图标(1、元宝 2、金币 3、绑元)
            buyNum, --已经购买次数
            maxBuyNum,最大购买次数
        }
    (可选)  spendInfo:提示找回资源几次，并显示消耗
    {
        findType, 1、金币找回 2、元宝找回
        findName,
        awardInfo, 奖励列表
        findTimes,
        oneSpend,
   }
   (可选)  recoveryAllInfo:一键找回所有资源,金币找回,元宝找回
   {
        findType, 1、金币找回 2、元宝找回
        cost,  消耗
   }
   (可选) lackItemInfo : 消耗材料提示, 用于快捷购买
   {
        PItem1,PItem2,PItem3,...
        useType, 3、绑元 1、元宝、2、金币
        -- itemId,
        -- itemNum,
        -- itemPrice,
   }
    （可选）itemList:  道具显示列表,数据结构如下：
   {
        itemData1,  --itemdata={id,num}
        itemData2,
   }
    （可选）BuffDic:
   {
        dis1,  
        dis2,
   }
   (可选) isMatch  是否是PK 
    ...后续按需要添加
    (可选)xueZhanCnt --血战剩余复活次数(不为nil显示血战重置提示界面,-1血战100关通关提示)

}
]]
local MsgBoxUI = LUIBase:New()
MsgBoxUI.__index = MsgBoxUI
--[[
userData:
userData[1]:maxNum
userData[2]:callback
]]
function MsgBoxUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,MsgBoxUI)	
    o:Init(userData)
	return o
end

function MsgBoxUI:Init(userData)
    self.m_pUILayer = cc.CSLoader:createNode("csd/MessageBoxLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:InitTouchEvt()
    self:UpdateUserData(userData)
end

--[[
注册UI消息
]]
function MsgBoxUI:RegistMsgs()
    self.msgIds = 
    {
        LUIMsgBoxEvent.ShowMsgBox,
        LUIMsgBoxEvent.HideMsgBox,
        LUILogicEvent.EnterBattle,
        LUILogicEvent.ExitBattle,
        LUIMsgBoxEvent.RegisterCloseGuide,
    }
    self:RegistSelf(self,self.msgIds)
end

function MsgBoxUI:ProcessEvent(msg)
    if msg:GetMsgId() == LUIMsgBoxEvent.ShowMsgBox then
        self:UpdateUserData(msg.value)
    elseif msg:GetMsgId() == LUIMsgBoxEvent.HideMsgBox then
        self.m_pUILayer:setVisible(false)
        self:UnSchedule()
    elseif msg:GetMsgId() == LUILogicEvent.EnterBattle then
        self:EnterBattle()
    elseif msg:GetMsgId() == LUILogicEvent.ExitBattle then
        self:ExitBattle()
    elseif msg:GetMsgId() == LUIMsgBoxEvent.RegisterCloseGuide then
        self:RegisterCloseGuide(msg.value)
    end
end

function MsgBoxUI:onExit()
    self.m_pCheckBoxCell:release()
    self.m_pCheckBoxCell = nil
    self.m_descScrollView = nil

    self._TipsPanel = nil
    self._TiliTipsPanel = nil
    self.m_pCloseBtn = nil
    self.m_pOKBtn1 = nil
    self.m_pOKBtn2 = nil
    self.m_pOKBtn3 = nil
    self.m_pCancelBtn = nil
    self.m_pTitleLabel = nil
    self.m_pTipsLabel = nil
    self.m_pCheckBox = nil
    self.m_pItemBg = nil
    self.m_pSpend = nil
    self.m_pItemListView = nil
    self._pTipsRecoveryAll = nil

    self.m_pItemCell = nil
    self.m_pTipsCell = nil
    self.m_pDescBg = nil
    self.m_pDescLabel = nil
    self.m_descSize = nil
    self.m_fontSize = nil
    self.m_pCheckBoxList = nil
    if self.m_pCheckBoxCell then
        self.m_pCheckBoxCell:release()
        self.m_pCheckBoxCell = nil
    end
    self.m_pDescList = nil
    if self.m_pDescLabelCell then
        self.m_pDescLabelCell:release()
        self.m_pDescLabelCell = nil
    end
    if self.m_pDescLineCell then
        self.m_pDescLineCell:release()
        self.m_pDescLineCell = nil
    end
    self.m_pLackItemBg = nil
    self.m_pGoldNum = nil
    self._lackItemList = nil
    self._lackItemCell = nil
    self.m_pBuffPanel= nil
    self.m_BuffDisc1= nil
    self.m_BuffDisc2= nil
    self.m_BuffText1_0 = nil
   
    self.m_BuffText1_1 = nil
    self.m_BuffText1_2 = nil
    self.m_BuffText1_3 = nil
    self.m_BuffText2_0  = nil
    self.m_BuffText1_4 = nil

    self.m_worldLeveltext= nil
    self.m_pDescScrollView = nil
    self.m_colorText = nil
    self.m_descSize = nil
    self.m_pUserData = nil
    self:Destory()
end

--[[
userData数据结构：
{
    （可选）closeCallback:  右上角关闭按钮回调
    （可选）cancelCallback:  取消按钮回调
    （可选）okCallback:  确定按钮回调
    （可选）checkBoxCallback:  checkBox按钮回调
    （可选）title:  提示框Title,默认显示“提示”
    （可选）tips:  提示框提示，相当于副标题吧
    （可选）desc:  提示框详细描述，默认不显示
    （可选）itemList:  道具显示列表,数据结构如下：
    		{PItem1,PItem2,PItem3,...}
    （可选）approachList:  获取途径列表,数据结构如下：
    		{
    			{iconPath,iconName,callback},
    			{iconPath,iconName,callback},
    			{iconPath,iconName,callback},
    			...
    		}
    （可选）okBtnName: 确认按钮文字，缺省为“确认”
    （可选）cancelBtnName:取消按钮文字，缺省为“取消”
    （可选）checkBoxList:单选框列表，数据结构如下：
            {
                init,--初始选中，默认1
                text={"文字内容", "文字内容", ...},
                selectCallback=selectCallback --选中回调
            }
    （可选）descList:  提示框文字列表(格式为以"|"分隔的字符串)，默认不显示
    （可选）AfterBattleShow:  战斗结束后显示
     (可选) 
    ...后续按需要添加
}
]]
function MsgBoxUI:UpdateUserData(userData)
	self:Reset()
	self.m_pUserData = userData
	if self.m_pUserData == nil then
		self.m_pUILayer:setVisible(false)
		return
	end
	
	self:CheckBtnVisible()
	self:ShowTextInfo()
	self:ShowApproachList()
	self:ShowItemList()
    self:ShowCheckBoxList()
    self:ShowTipPanel()
    self:ShowTiliTipPanel()
    self:ShowSpendUI()
    self:ShowRecoveryAllUI()
    self:ShowLackItemUI()
    self:ShowXueZhanPanel()
    self.m_bIsAfterBattleShow = self.m_pUserData.AfterBattleShow or false
    if self.m_bIsAfterBattleShow then
        self.m_Sign = true
    else
        self.m_pUILayer:setVisible(true)
    end
	local isShowTips = self.m_pUserData.showTips
	if isShowTips then
		self.checkbox:setVisible(true)
	end
end

function MsgBoxUI:ShowXueZhanPanel()
    if self.m_pUserData.xueZhanCnt == nil then
        return
    end
    local cnt = self.m_pUserData.xueZhanCnt or 0
    if cnt == -1 then
        self.m_xueZhan100Panel:setVisible(true)
        return
    end
    self.m_xueZhanPanel:setVisible(true) 
    self.m_xueZhanCntLabel:setString(""..cnt..GUITips.RSI_COUNT)
end

--[[
显示道具列表
]]
function MsgBoxUI:ShowItemList()
    if self.m_pUserData.itemList==nil then
         --self.m_pItemBg:setVisible(false)
      return 
    end
     self.m_pItemListView:removeAllChildren()
     self.m_pItemBg:setVisible(true)
    self.m_pItemListView:setVisible(true)
     local btns = {}
     for i=1,#self.m_pUserData.itemList do
        if self.m_pUserData.itemList[i] then
          local awardui = self.m_pItemCell:clone()
            --dump(self.m_pUserData.itemList[i],"显示道具列表1-------->")          
            awardui:setVisible(true)

            Utils:GetItemCellValue(awardui, 0, self.m_pUserData.itemList[i].id, true, true, self.m_pUserData.itemList[i].num, nil, true)
            self.m_pItemListView:addChild(awardui)
            awardui:setAnchorPoint(cc.p(0.5, 0.5))
            awardui:setPositionY(self.m_pItemListView:getContentSize().height / 2)
            awardui:setTag(i)
            table.insert(btns, awardui)
       end
    end
    Utils:AlignNodes(self.m_pItemListView, btns, {30}, 3, false)
end

--[[
显示获取途径提示
]]
function MsgBoxUI:ShowApproachList()
	if self.m_pUserData.approachList == nil then
		--self.m_pItemBg:setVisible(false)
		return
	end
	self.m_pItemBg:setVisible(true)
    self.m_pItemListView:setVisible(true)
	local listData = self.m_pUserData.approachList
	local num = #listData
	
	local function BtnCallback(sender)
		local ind = sender:getTag()
		self.m_pUserData.approachList[ind].callback()
		self.m_pUILayer:setVisible(false)

	end
    self.m_pItemListView:removeAllChildren()
    local pCenterY = self.m_pItemListView:getContentSize().height/2
    local btns = {}
	for i = 1,num do
		local btn = self.m_pTipsCell:clone()
        btn:setVisible(true)
        btn:setPressedActionEnabled(true)
		local nameLabel = btn:getChildByName("Name")
		if listData[i].iconName ~= nil then
            nameLabel:setVisible(true)
			nameLabel:setString(listData[i].iconName)
		else
			nameLabel:setVisible(false)
		end
        btn:loadTextures(listData[i].iconPath, "","", UI_TEX_TYPE_LOCAL)
        if listData[i].callback then
            btn:addClickEventListener(function(sender)
                self.m_pUILayer:setVisible(false)
                listData[i].callback()
            end)
			self:MarkIntaractCObj(btn)
        end
		self.m_pItemListView:addChild(btn)
        btn:setPositionY(pCenterY + (btn:getAnchorPoint().y-0.5)*btn:getContentSize().height)
		btn:setTag(i)
        table.insert(btns, btn)
	end
    Utils:AlignNodes(self.m_pItemListView, btns, {80}, 3, false)
end

function MsgBoxUI:ShowTextInfo()
	self:ShowTitle()
	self:ShowTips()
	self:ShowDesc()
    self:PKMatch()
    self:ShowDescList()
    self:ShowTiliTipPanel()
    self:ShowBuffInfo()
end

function MsgBoxUI:PKMatch()
    self.PkTime=5
    if self.m_pUserData.isMatch==true then
      self:UpdatePkTime()
      local function PkTimeUpdate()
         self:UpdatePkTime()
      end
      self.m_schedulerID=AppDef.Director:getScheduler():scheduleScriptFunc(PkTimeUpdate, 1.0, false)
    end
    
end
function  MsgBoxUI:UpdatePkTime()
    self.m_pOKBtn2:getChildByName("Text"):setString(GUITips.UI_Btn_OK.."("..self.PkTime..")")
    if self.PkTime<=0 then
     self:HandleOK()
    end 
    self.PkTime=self.PkTime-1
end

function MsgBoxUI:ShowDesc()
	if self.m_pUserData.desc ~= nil then
        -- self.m_pDescLabel:triggleInit(self.m_pUserData.desc, cc.size(self.m_descSize.width, 0), -132 , AppDef.UIColor.BROWN , self.m_fontSize ,
        -- false,0,0,0,true,false)   --ccWHITE
		self.m_pDescLabel:setString(self.m_pUserData.desc)
        local x = self.m_pDescLabel:getPositionX()
		self.m_pDescBg:setVisible(true)
        local descSize = self.m_pDescLabel:getSize()
        local viewSize = self.m_pDescScrollView:getContentSize()
        if viewSize.height < descSize.height then
            self.m_pDescScrollView:setInnerContainerSize(cc.size(viewSize.width, descSize.height+20))
        end
        self.m_pDescLabel:setPosition(cc.p(x, self.m_pDescScrollView:getInnerContainerSize().height))
	else
		self.m_pDescBg:setVisible(false)
	end

end

function MsgBoxUI:CreateColorText(parent, oldText, newName, strContent)
    local newText = CCAysLabel:create()
    newText:setName(newName)
    --newText:setPosition(oldText:getPosition())
    newText:setAnchorPoint(cc.p(0,0))
    parent:addChild(newText)
    local fontSize = oldText:getFontSize()
    newText:triggleInit(strContent,cc.size(fontSize*#strContent,fontSize),-130,oldText:getTextColor(),fontSize,false,0,0,0,true,false)
    return newText
end
--显示buff信息
function  MsgBoxUI:ShowBuffInfo()
    if self.m_pUserData.BuffDic==nil then
        return
    end
    self.m_pBuffPanel:setVisible(true)
    self.m_pItemBg:setVisible(false)
    self.m_pTipsLabel:setVisible(false)
    --self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[1])
    if self.m_pUserData.BuffDic.dis1[2] and self.m_pUserData.BuffDic.dis1[3] then
        self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[1])
        self.m_BuffText1_1:setString(self.m_pUserData.BuffDic.dis1[2])
        self.m_BuffText1_2:setString(self.m_pUserData.BuffDic.dis1[3])
        self.m_BuffText1_4:setVisible(false)
        self.m_BuffText1_0:setVisible(true)
        self.m_BuffText1_1:setVisible(true)
        self.m_BuffText1_2:setVisible(true)
    else
        self.m_BuffText1_4:setString(self.m_pUserData.BuffDic.dis1[1])
        self.m_BuffText1_4:setVisible(true)
        self.m_BuffText1_0:setVisible(false)
        self.m_BuffText1_1:setVisible(false)
        self.m_BuffText1_2:setVisible(false)

    end
    
    self.m_worldLeveltext:setPositionX(140)
    self.m_worldLeveltext:setString(self.m_pUserData.BuffDic.dis1[4]) 
    if self.m_pUserData.BuffDic.dis2ColorText then
        self.m_BuffText2_0:setVisible(false)
        local parent = self.m_BuffText2_0:getParent()
        if self.m_colorText == nil then
            self.m_colorText = CCAysLabel:createWithFixedWidth(parent:getContentSize().width - 50,self.m_BuffText2_0:getFontSize(),self.m_BuffText2_0:getTextColor())
            parent:addChild(self.m_colorText)
        end
            self.m_colorText:setString(self.m_pUserData.BuffDic.dis2)
            self.m_colorText:setVisible(true)
            local contentSize = parent:getContentSize()
            local textSize = self.m_colorText:getSize()
            local px = (contentSize.width - textSize.width)/2
            local py = (contentSize.height - textSize.height) + 50
            self.m_colorText:setPosition(cc.p(px,py))
    else
        if self.m_colorText then
            self.m_colorText:setVisible(false)
        end
        self.m_BuffText2_0:setString(self.m_pUserData.BuffDic.dis2) 
        self.m_BuffText2_0:setVisible(true)
    end
    

     -- msgs.dis1 = msg   
     -- msgs.dis2=GUITips.RSI_WORLDLEVLE4
     -- BuffDic=msgs
    -- for i=1,#self.m_pUserData.BuffDic.dis1 do
    --    self


    -- end 
    -- self.m_worldLeveltext:setPositionX(140)
    -- self.m_worldLevel:setVisible(true)
    -- self.m_pItemBg:setVisible(false)
    -- self.m_pTipsLabel:setVisible(false)
    -- self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[1])
    -- self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[2])
    -- self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[3])
    -- self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis1[4])
    -- self.m_BuffText1_0:setString(self.m_pUserData.BuffDic.dis2)
end

function MsgBoxUI:ShowDescList()
	if self.m_pUserData.descList == nil then
        self.m_pDescList:setVisible(false)
        if self.m_descScrollView ~= nil then
            self.m_descScrollView:setVisible(false)
        end
        return
    end 

    local s = string.sub(self.m_pUserData.descList,-1)
    if s ==  "|" then
      s = string.sub(self.m_pUserData.descList,1,-2)
    end
    local infos = {}
    infos = string.split(s,"|")
    if infos == nil or #infos == 0 then 
        return
    end
    local len = #infos 
    local fontSize = self.m_pDescLabelCell:getFontSize()
    local size =len * (fontSize+fontSize*1.5)+fontSize*2
    local ContentSize = self.m_pDescList:getContentSize()
   
    self.m_pDescList:setVisible(true)
    if self.m_descScrollView == nil then
        self.m_descScrollView = Utils:CreateScrollView(self.m_pDescList,self.m_pDescList:getParent(),ccui.ScrollViewDir.vertical,cc.size(ContentSize.width,size))
    end
    self.m_descScrollView:setVisible(true)
    self.m_descScrollView:removeAllChildren()
    local temp = size-ContentSize.height
    local x,y = self.m_pDescLabelCell:getPosition()
    local x1,y1 = self.m_pDescLineCell:getPosition()
    for i=1,len do
        local ttf = self:CreateColorText(self.m_descScrollView,self.m_pDescLabelCell,"Text"..i,infos[i])
        local y2 = y-(fontSize+fontSize*1.5)*(i-1)+temp
        ttf:setPosition(cc.p(x,y2))
        if i ~= len then
            local line = self.m_pDescLineCell:clone()
            self.m_descScrollView:addChild(line)
            line:setPosition(cc.p(x1,y2-fontSize*2))
        end
    end
end

function MsgBoxUI:ShowTipPanel()
    -- body
    if self.m_pUserData.TipsInfo == nil then
        self._TipsPanel:setVisible(false)
        return
    end
    self._TipsPanel:setVisible(true)
    local icon = self._TipsPanel:getChildByName("GoldIcon")
    print("ShowTipPanel self.m_pUserData.TipsInfo.price ====================>")
    icon:getChildByName("Text_49"):setString(self.m_pUserData.TipsInfo.price)

    if self.m_pUserData.TipsInfo.useType == 60000 then
        icon:loadTexture("res/UI/ui_common/ui_icon_jinbi.png", ccui.TextureResType.plistType)
    elseif self.m_pUserData.TipsInfo.useType == 60003  then
        icon:loadTexture("res/UI/ui_common/ui_bg_bangyuan.png", ccui.TextureResType.plistType)
    end

    local tipsImage = self._TipsPanel:getChildByName("TipsImage")
    local buyTimes = tipsImage:getChildByName("Times");
    local str = string.format("%d/%d", self.m_pUserData.TipsInfo.buyNum, self.m_pUserData.TipsInfo.maxBuyNum)
    buyTimes:setString(str)
end

function MsgBoxUI:ShowTiliTipPanel()
    -- body
    if self.m_pUserData.TiliTipsInfo == nil then
        self._TiliTipsPanel:setVisible(false)
        return
    end
    self._TiliTipsPanel:setVisible(true)
    local icon = self._TiliTipsPanel:getChildByName("GoldIcon")
    icon:getChildByName("Text_49"):setString(self.m_pUserData.TiliTipsInfo.price)

    if self.m_pUserData.TiliTipsInfo.useType == 60000 then
        icon:loadTexture("res/UI/ui_common/ui_icon_jinbi.png", ccui.TextureResType.plistType)
    elseif self.m_pUserData.TiliTipsInfo.useType == 60001 or self.m_pUserData.TiliTipsInfo.useType == 60003  then
        icon:loadTexture("res/UI/ui_common/ui_bg_bangyuan.png", ccui.TextureResType.plistType)
    end
end
function MsgBoxUI:ShowTitle()
	if self.m_pUserData.title ~= nil then
		self.m_pTitleLabel:setString(self.m_pUserData.title)
	else
		self.m_pTitleLabel:setString(GUITips.UI_Title_Tishi)
	end
end

function MsgBoxUI:ShowTips()
	if self.m_pUserData.tips ~= nil then
		self.m_pTipsLabel:setString(self.m_pUserData.tips)
		self.m_pTipsLabel:setVisible(true)
	else
		self.m_pTipsLabel:setVisible(false)
	end
end

function MsgBoxUI:ShowCheckBoxList()
    self.m_pCheckBoxList:setVisible( self.m_pUserData.checkBoxList ~= nil )
    if self.m_pUserData.checkBoxList == nil then
        return
    end

    local function selectCallback(sender, event)
        if event == ccui.CheckBoxEventType.selected then
            if self.m_pUserData.checkBoxList.selectCallback ~= nil then
                self.m_pUserData.checkBoxList.selectCallback(sender:getTag())
            end
            local items = self.m_pCheckBoxList:getItems()
            for i=1,#items do
                if items[i] ~= sender then
                    items[i]:setSelected(false)
                end
            end
        else
            local haveSelected = false
            local items = self.m_pCheckBoxList:getItems()
            for i=1,#items do
                if items[i]:isSelected() then
                    haveSelected = true
                    break
                end
            end
            if not haveSelected then
                sender:setSelected(true)
            end
        end
    end

    self.m_pCheckBoxList:removeAllItems()
    local cfg = self.m_pUserData.checkBoxList
    for i=1,#cfg.text do
        local pCell = self.m_pCheckBoxCell:clone()
        pCell:setTag(i)
        pCell:addEventListener( selectCallback )
        pCell:setSelected(i == cfg.init)

        local pText = pCell:getChildByName("Text")
        pText:setString(cfg.text[i])

        self.m_pCheckBoxList:pushBackCustomItem(pCell)
    end
end

function MsgBoxUI:CheckBtnVisible()
    --TODO:后期根据需求改
    self.m_pOKBtn3:setVisible(false)
	if self.m_pUserData.okCallback == nil then
		self.m_pOKBtn1:setVisible(false)
		self.m_pOKBtn2:setVisible(false)
		self.m_pCancelBtn:setVisible(false)
	elseif self.m_pUserData.okCallback ~= nil and self.m_pUserData.cancelCallback == nil then
		self.m_pOKBtn1:setVisible(true)
		self.m_pCancelBtn:setVisible(false)
		self.m_pOKBtn2:setVisible(false)
	elseif self.m_pUserData.okCallback ~= nil and self.m_pUserData.cancelCallback ~= nil then
		self.m_pOKBtn1:setVisible(false)
		self.m_pCancelBtn:setVisible(true)
		self.m_pOKBtn2:setVisible(true)
	end

	if self.m_pUserData.checkBoxCallback == nil then
		self.m_pCheckBox:setVisible(false)
	else
    -- self.m_pDescBg:addChild(newLabel0
        self.m_pCheckBox:setVisible(true)
        self.m_pCheckBox:setSelected(false)
    end

    if self.m_pUserData.okBtnName then
        self.m_pOKBtn1:getChildByName("Text"):setString(self.m_pUserData.okBtnName)
        self.m_pOKBtn2:getChildByName("Text"):setString(self.m_pUserData.okBtnName)
    else
        self.m_pOKBtn1:getChildByName("Text"):setString(GUITips.UI_Btn_OK)
        self.m_pOKBtn2:getChildByName("Text"):setString(GUITips.UI_Btn_OK)
    end

    if self.m_pUserData.autoSelect ~= nil and self.m_pUserData.autoSelect then
        local btnName = GUITips.RSI_PREVIEW_MSG1
        if self.m_pUserData.okBtnName then
            btnName = self.m_pUserData.okBtnName .. GUITips.RSI_PREVIEW_MSG4
        end
        local function TimerCallBack(dt)
            if self.coolTime < 1 then
                self:HandleOK()
                return
            end
            self.coolTime = self.coolTime - 1
--            print("TimerCallBack self.coolTime", self.coolTime)

            local strTime = string.format(btnName, self.coolTime)
            if self.m_pUserData.cancelCallback == nil then
                self.m_pOKBtn1:getChildByName("Text"):setString(strTime)
            else
                self.m_pOKBtn2:getChildByName("Text"):setString(strTime)
            end
            
        end
        self:UnSchedulerAutoSel()
        if self.m_pUserData.autoTime ~= nil then
            self.coolTime = self.m_pUserData.autoTime
        else
            self.coolTime = 5
        end
        local strTimeTemp = string.format(btnName, self.coolTime)
        if self.m_pUserData.cancelCallback == nil then
            self.m_pOKBtn1:getChildByName("Text"):setString(strTimeTemp)
        else
            self.m_pOKBtn2:getChildByName("Text"):setString(strTimeTemp)
        end 
        self.m_schedulerAutoSelID = Utils:schedule(nil, TimerCallBack, 1)
    end

    if self.m_pUserData.cancelBtnName then
        self.m_pCancelBtn:getChildByName("Text"):setString(self.m_pUserData.cancelBtnName)
    else
        self.m_pCancelBtn:getChildByName("Text"):setString(GUITips.UI_Btn_Cancel)
    end
end

function MsgBoxUI:UnSchedulerAutoSel( ... )
    -- body
    if self.m_schedulerAutoSelID then
        Utils:unschedule(nil, self.m_schedulerAutoSelID)
        self.m_schedulerAutoSelID = nil
    end
end




--找回经验弹出框
function MsgBoxUI:ShowSpendUI()
    -- body
    if self.m_pUserData.spendInfo == nil then
        return
    end
    local config = JsonConfig.GetRevertData(self.m_pUserData.spendInfo.funcId)
    local cellData = self.m_pUserData.spendInfo;
    self.m_pSpend:setVisible(true)
    self.m_pItemBg:setVisible(true)
    self.m_pItemListView:setVisible(false)

    --您确认花费%d%s找回活动-%s资源吗？
    local desc = string.format(GUITips.RSI_GS_TIP_RECOVERY_DESC,self.m_pUserData.spendInfo.cost[3],AppDef.AwrdItemName[self.m_pUserData.spendInfo.cost[1]],config.name);
    self.m_pSpend:getChildByName("desc"):setString(desc)


    local str = AppDef:GetMoneyIconById(cellData.cost[1])
    self.m_pSpend:findChildByName("SpendText/Icon"):loadTexture(str, ccui.TextureResType.plistType)
    local numLabel = self.m_pSpend:findChildByName("SpendText/Icon/Text")
    numLabel:setString(cellData.cost[3]);

    self.m_pSpend:getChildByName("Bg"):setVisible(false)

    -- if self.m_pUserData.spendInfo.findType == 1 then
    --     str = string.format(GUITips.RSI_GS_TIP_RECOVERY_NORMAL, self.m_pUserData.spendInfo.findName)
    -- else
    --     str = string.format(GUITips.RSI_GS_TIP_RECOVERY_PERFECT, self.m_pUserData.spendInfo.findName)
    -- end    
    
    -- local pos = cc.p(self.m_pTipsLabel:getPosition())
    -- local anchor = self.m_pTipsLabel:getAnchorPoint()
    -- local textSize = self.m_pTipsLabel:getContentSize()
    -- local fontSize = self.m_pTipsLabel:getFontSize()
    -- local fontColor = self.m_pTipsLabel:getTextColor()
    -- local posX = pos.x-anchor.x*textSize.width
    -- local pAysLabel = self.m_pTipsLabel:getParent():getChildByTag(1019)
    -- if pAysLabel == nil then
    --     pAysLabel = CCAysLabel:createWithFixedWidth(textSize.width + 130, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
    --     pAysLabel:setPosition(cc.p(posX, pos.y+(1-anchor.y)*textSize.height))
    --     self.m_pTipsLabel:getParent():addChild(pAysLabel, self.m_pTipsLabel:getLocalZOrder(), 1019)
    -- end
    -- pAysLabel:setVisible(true)
    -- pAysLabel:setPositionX(posX - 25)
    -- if self.m_pUserData.spendInfo.findType == 1 then
    --     pAysLabel:setPositionX(posX - 25)
    -- else
    --     pAysLabel:setPositionX(posX - 45)
    -- end
    -- pAysLabel:setString(str)

--     local bg = self.m_pSpend:getChildByName("Bg")
--     local subBtn = bg:getChildByName("Button_1")
--     local maxFindTimes = self.m_pUserData.spendInfo.leftTimes
--     local curIndex = maxFindTimes
--     LGameMsg.m_baseMsgWithOne:Change(LUIResRecoveryEvent.convertBuyTimes, curIndex)
--     self:SendMsg(LGameMsg.m_baseMsgWithOne)
--     local txt = bg:getChildByName("Text")
--     local spendText = self.m_pSpend:getChildByName("SpendText")
--     local goldIcon = spendText:getChildByName("Icon")
--     local goldCost = goldIcon:getChildByName("Text")
--     local coinIcon = spendText:getChildByName("Icon_2")
--     local coinCost = coinIcon:getChildByName("Text")
--     local strTimes = string.format("%d/%d", curIndex, maxFindTimes)
--     txt:setString(strTimes)

--     local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
--     local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
-- --显示奖励
--     self:showAwardList(curIndex)

--     if self.m_pUserData.spendInfo.findType == 1 then
-- --金币找回
--         goldIcon:setVisible(false)
--         coinIcon:setVisible(true)
--         coinCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
--         coinCost:setTextColor(UICOLOR_GREEN)
-- --        print("myMoney", self.m_pUserData.spendInfo.oneSpend * curIndex, myMoney)
--         if self.m_pUserData.spendInfo.oneSpend * curIndex > myMoney then
--           coinCost:setTextColor(UICOLOR_RED)
--         end
--     else
-- --元宝找回
--         coinIcon:setVisible(false)
--         goldIcon:setVisible(true)
--         goldCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
-- --        print("myGold", self.m_pUserData.spendInfo.oneSpend * curIndex, myGold)
--         goldCost:setTextColor(UICOLOR_GREEN)
--         if self.m_pUserData.spendInfo.oneSpend * curIndex > myGold then
--             goldCost:setTextColor(UICOLOR_RED)
--         end
--     end
    
--     local scheduler =  AppDef.Director:getScheduler()
--     local isAutoSub = false
--     local function stillSub( dt )
--         -- body
--         isAutoSub = true
--         curIndex = curIndex - 1
--         if curIndex < 1 then
--             curIndex = 1
--             return
--         end

--         LGameMsg.m_baseMsgWithOne:Change(LUIResRecoveryEvent.convertBuyTimes, curIndex)
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)
        
--         local strTimes = string.format("%d/%d", curIndex, maxFindTimes)
--         txt:setString(strTimes)
--         if self.m_pUserData.spendInfo.findType == 1 then
--             coinCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
--             coinCost:setTextColor(UICOLOR_GREEN)
-- --        print("myMoney", self.m_pUserData.spendInfo.oneSpend * curIndex, myMoney)
--             if self.m_pUserData.spendInfo.oneSpend * curIndex > myMoney then
--               coinCost:setTextColor(UICOLOR_RED)
--             end
--         else
--             goldCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
--             goldCost:setTextColor(UICOLOR_GREEN)
--             if self.m_pUserData.spendInfo.oneSpend * curIndex > myGold then
--                 goldCost:setTextColor(UICOLOR_RED)
--             end
--         end
-- --刷新奖励
--         self:showAwardList(curIndex)
--     end

--     local function timerEvent()
--         -- body
--         self:UnSchedule()
--         self.m_schedulerID = scheduler:scheduleScriptFunc(stillSub, 0.1, false)
--     end
    
--     local function subEvent( pTouch, pEvent )
--         -- body
--         if pEvent == ccui.TouchEventType.began then
--             timerEvent()
--         elseif pEvent == ccui.TouchEventType.ended then
--             if not isAutoSub then
--                 stillSub()
--             end
--             self:UnSchedule()
--             isAutoSub = false
--         end
--     end
--     subBtn:addTouchEventListener(subEvent)
--     --self:MarkIntaractCObj(subBtn)
--     local isAutoAdd = false
--     local function stillAdd(dt)
--         -- body
--         isAutoAdd = true
--         curIndex = curIndex + 1
--         if curIndex > maxFindTimes then
--             curIndex = maxFindTimes
--             return
--         end

--         LGameMsg.m_baseMsgWithOne:Change(LUIResRecoveryEvent.convertBuyTimes, curIndex)
--         self:SendMsg(LGameMsg.m_baseMsgWithOne)

--         local strTimes = string.format("%d/%d", curIndex, maxFindTimes)
--         txt:setString(strTimes)
--         if self.m_pUserData.spendInfo.findType == 1 then
--             coinCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
--             coinCost:setTextColor(UICOLOR_GREEN)
-- --        print("myMoney", self.m_pUserData.spendInfo.oneSpend * curIndex, myMoney)
--             if self.m_pUserData.spendInfo.oneSpend * curIndex > myMoney then
--               coinCost:setTextColor(UICOLOR_RED)
--             end
--         else
--             goldCost:setString(tostring(self.m_pUserData.spendInfo.oneSpend * curIndex))
--             goldCost:setTextColor(UICOLOR_GREEN)
--             if self.m_pUserData.spendInfo.oneSpend * curIndex > myGold then
--                 goldCost:setTextColor(UICOLOR_RED)
--             end
--         end
-- --刷新奖励
--         self:showAwardList(curIndex)
--     end

--     local function timerAddEvent()
--         -- body
--         self:UnSchedule()
--         self.m_schedulerID = scheduler:scheduleScriptFunc(stillAdd, 0.1, false)
--     end

--     local addBtn = bg:getChildByName("Button_2")
--     local function addEvent( pTouch, pEvent )
--         -- body
--         if pEvent == ccui.TouchEventType.began then
--             timerAddEvent()
--         elseif pEvent == ccui.TouchEventType.ended then
--             if not isAutoAdd then
--                 stillAdd()
--             end
--             self:UnSchedule()
--             isAutoAdd = false
--         end
--     end
--     addBtn:addTouchEventListener(addEvent)
--     --self:MarkIntaractCObj(addBtn)
end

function MsgBoxUI:showAwardList( times )
    -- body
    local btns = {}
    self.m_pItemListView:removeAllChildren()
    local rate = 1
    if self.m_pUserData.spendInfo.findType == 1 then
        rate = 0.75
    end

--    print("awardInfo ***********", #self.m_pUserData.spendInfo.awardInfo)
    local size = #self.m_pUserData.spendInfo.awardInfo
    if size > 4 then
        local listView  = self.m_pItemListView:getChildByTag(100106)
        if listView == nil then
            listView = ccui.ListView:create()
            listView:setDirection(LISTVIEW_DIR_HORIZONTAL)
            listView:setContentSize(self.m_pItemListView:getContentSize())
            listView:setAnchorPoint(cc.p(0, 0))
            listView:setPosition(cc.p(5, 0))
            -- 关闭惯性滑动
            listView:setBounceEnabled(false)
            listView:setSwallowTouches(false)
            -- 隐藏滚动条
            listView:setScrollBarEnabled(false)
            self.m_pItemListView:addChild(listView, 5)
            listView:setTag(100106)
        end

        for i = 1, size do
            local data = self.m_pUserData.spendInfo.awardInfo[i]
            -- local awardui = cc.Sprite:create()
            -- awardui:setContentSize(cc.size(88, 88))
            local awardui = self.m_pItemCell:clone()
            awardui:setVisible(true)
            if not data.isDisCount then
                rate = 1
            end
            local preValue = data.awardNum / self.m_pUserData.spendInfo.leftTimes
            Utils:GetItemCellValue(awardui, 0, data.awardType, true, true, math.floor(preValue * times * rate), nil, true)
            awardui:setAnchorPoint(cc.p(0.5, 0.5))
            awardui:setTag(i)
            listView:pushBackCustomItem(awardui)
        end
    else
        for i = 1, #self.m_pUserData.spendInfo.awardInfo do
            local data = self.m_pUserData.spendInfo.awardInfo[i]
            local preValue = data.awardNum / self.m_pUserData.spendInfo.leftTimes
            local awardui = self.m_pItemCell:clone()
            awardui:setVisible(true)
            if not data.isDisCount then
                rate = 1
            end
            Utils:GetItemCellValue(awardui, 0, data.awardType, true, true, math.floor(preValue * times * rate), nil, true)
            self.m_pItemListView:addChild(awardui)
            awardui:setAnchorPoint(cc.p(0.5, 0.5))
            awardui:setPositionY(self.m_pItemListView:getContentSize().height / 2)
            awardui:setTag(i)
            table.insert(btns, awardui)
        end
        Utils:AlignNodes(self.m_pItemListView, btns, {30}, 3, false)
    end
end

function MsgBoxUI:UnSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

--一键找回所有资源提示
function MsgBoxUI:ShowRecoveryAllUI()
    -- body
    if self.m_pUserData.recoveryAllInfo == nil then
        return
    end
    self._pTipsRecoveryAll:setVisible(true)
    local des = self._pTipsRecoveryAll:getChildByName("Text_1")
    des:setVisible(false)
    local str
    if self.m_pUserData.recoveryAllInfo.findType == 1 then
        str = GUITips.RSI_GS_TIP_RECOVERYAll_NORMAL
    else
        str = GUITips.RSI_GS_TIP_RECOVERYALL_PERFECT
    end    
    
    local pos = cc.p(des:getPosition())
    local anchor = des:getAnchorPoint()
    local textSize = des:getContentSize()
    local fontSize = des:getFontSize()
    local fontColor = des:getTextColor()
    local posX = pos.x-anchor.x*textSize.width
    local pAysLabel = des:getParent():getChildByTag(1020)
    if pAysLabel == nil then
        pAysLabel = CCAysLabel:createWithFixedWidth(textSize.width + 130, fontSize, cc.c3b(fontColor.r,fontColor.g, fontColor.b), false)
        pAysLabel:setPosition(cc.p(posX, pos.y+(1-anchor.y)*textSize.height))
        des:getParent():addChild(pAysLabel, des:getLocalZOrder(), 1020)
    end
    pAysLabel:setVisible(true)
    -- if self.m_pUserData.spendInfo.findType == 1 then
    --     pAysLabel:setPositionX(posX - 25)
    -- else
    --     pAysLabel:setPositionX(posX - 45)
    -- end
    pAysLabel:setString(str)


    local text = self._pTipsRecoveryAll:getChildByName("Text")
    local goldIcon = text:getChildByName("GoldIcon")
    local goldValue = goldIcon:getChildByName("Text")
    local coinIcon = text:getChildByName("CoinIcon")
    local coinValue = coinIcon:getChildByName("Text")
    if self.m_pUserData.recoveryAllInfo.findType == 1 then
        goldIcon:setVisible(false)
        coinIcon:setVisible(true)
        coinValue:setString(tostring(self.m_pUserData.recoveryAllInfo.cost))
        coinValue:setTextColor(UICOLOR_GREEN)
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        if self.m_pUserData.recoveryAllInfo.cost > myMoney then
            coinValue:setTextColor(UICOLOR_RED)
        end
    else
        goldIcon:setVisible(true)
        coinIcon:setVisible(false)
        goldValue:setString(tostring(self.m_pUserData.recoveryAllInfo.cost))
        goldValue:setTextColor(UICOLOR_GREEN)
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        if self.m_pUserData.recoveryAllInfo.cost > myGold then
            goldValue:setTextColor(UICOLOR_RED)
        end
    end

end


--升级缺少材料提示
function MsgBoxUI:ShowLackItemUI()
    -- body
    if self.m_pUserData.lackItemInfo == nil then
        return
    end
    self.m_pLackItemBg:setVisible(true)
    self.m_pGoldNum:setVisible(true)
    local bdGold = self.m_pGoldNum:getChildByName("Icon_1"):getChildByName("Text")
    bdGold:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().BindTongBao)
    local gold = self.m_pGoldNum:getChildByName("Icon_2"):getChildByName("Text")
    gold:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)

    self._lackItemList:removeAllChildren()
    local btns = {}
    for i = 1, #self.m_pUserData.lackItemInfo do
        local data = self.m_pUserData.lackItemInfo[i]
        --最多一次购买200个
        if data.num > 200 then
            data.num = 200
        end
        local awardui = self._lackItemCell:clone()
        awardui:setVisible(true)
        local name = awardui:getChildByName("Text")
        name:setString(data.name)

        local color = AppDef:GetItemQualityColor(data.quality)
        name:setTextColor(color)

        local numBg = awardui:getChildByName("NumBg")
        local value = numBg:getChildByName("Text")
        value:setString(tostring(data.num))
        --元宝
        local spendIcon1 = awardui:getChildByName("SpendIcon_1")
        local cost1 = spendIcon1:getChildByName("Text")
        --金币
        local spendIcon2 = awardui:getChildByName("SpendIcon_2")
        local cost2 = spendIcon2:getChildByName("Text")
        --绑定元宝
        local spendIcon3 = awardui:getChildByName("SpendIcon_3")
        local cost3 = spendIcon3:getChildByName("Text")

        if self.m_pUserData.useType == 2 then
            spendIcon1:setVisible(false)
            spendIcon2:setVisible(true)
            spendIcon3:setVisible(false)
            cost2:setString(tostring(data.num * data.price))
        elseif self.m_pUserData.useType == 3 then
            spendIcon1:setVisible(false)
            spendIcon2:setVisible(false)
            spendIcon3:setVisible(true)
            cost3:setString(tostring(data.num * data.price))
        else
            spendIcon1:setVisible(true)
            spendIcon2:setVisible(false)
            spendIcon3:setVisible(false)
            cost1:setString(tostring(data.num * data.price))
        end
        
--减操作
        local num = data.num
        local subBtn = numBg:getChildByName("Button_1")
        local function subEvent( sender )
            -- body
            num = num - 1
            value:setString(tostring(num))
        end
        subBtn:addClickEventListener(subEvent)
        --self:MarkIntaractCObj(subBtn)
--加操作
        local addBtn = numBg:getChildByName("Button_2")
        local function addEvent( sender )
            -- body
            num = num + 1
            value:setString(tostring(num))
        end
        addBtn:addClickEventListener(addEvent)
        --self:MarkIntaractCObj(addBtn)

        Utils:GetItemCellValue(awardui, 0, data.id, true, true, data.num, nil, true)
        self._lackItemList:addChild(awardui)
        awardui:setAnchorPoint(cc.p(0, 0))
        awardui:setPositionY(63)
        awardui:setTag(i)
        table.insert(btns, awardui)
    end
    self._lackItemCell:setVisible(false)
    Utils:AlignNodes(self._lackItemList, btns, {60}, 3, false)
   
    
end

function MsgBoxUI:InitData()
    local panel = self.m_pUILayer:getChildByName("MessageBoxUI")

    --TODO:隐藏
    self._TipsPanel = panel:getChildByName("TipsPanel"):setVisible(false)
    panel:getChildByName("List"):setVisible(false)

    self._TiliTipsPanel = panel:getChildByName("TiliTipsPanel"):setVisible(false)

    self.m_pCloseBtn = panel:getChildByName("bg"):getChildByName("Btn_close")
    self.m_pOKBtn1 = panel:getChildByName("Btn_Confirm")
    self.m_pOKBtn2 = panel:getChildByName("Btn_Confirm2")
    self.m_pOKBtn2:getChildByName("Time"):setVisible(false)
    self.m_pOKBtn3 = panel:getChildByName("Btn_Confirm3")
    self.m_pCancelBtn = panel:getChildByName("Btn_Confirm1")
    self.m_pTitleLabel = panel:getChildByName("bg"):getChildByName("Title")
    self.m_pTipsLabel = panel:getChildByName("TipsText")
    self.m_pCheckBox = panel:getChildByName("CheckBox")
    self.m_pItemBg = panel:getChildByName("IconBg1")
    self.m_pSpend = panel:getChildByName("Spend")
    self.m_pItemListView = self.m_pItemBg:getChildByName("ListView")
    self._pTipsRecoveryAll = panel:getChildByName("TipsPanel_0")

    self.m_pItemCell = self.m_pItemBg:getChildByName("IconBtn")
    self.m_pTipsCell = self.m_pItemBg:getChildByName("SystemBtn")
    self.m_pTipsCell:setTouchEnabled(true)
    self.m_pDescBg = panel:getChildByName("DesBg1")
    self.m_pDescLabel = self.m_pDescBg:getChildByName("Content")
    self.m_descSize = self.m_pDescLabel:getContentSize()
    self.m_fontSize = self.m_pDescLabel:getFontSize()
    self.m_pCheckBoxList = panel:getChildByName("CheckBoxList")
    self.m_pCheckBoxCell = self.m_pCheckBoxList:getChildByName("CheckBox1")
    self.m_pCheckBoxCell:retain()
    self.m_pCheckBoxCell:removeFromParent(false)
    self.m_pDescList = panel:getChildByName("List")
    self.m_pDescLabelCell = self.m_pDescList:getChildByName("Text")
    self.m_pDescLineCell = self.m_pDescList:getChildByName("LineImage")
    self.m_pDescLabelCell:retain()
    self.m_pDescLabelCell:removeFromParent(false)
    self.m_pDescLineCell:retain()
    self.m_pDescLineCell:removeFromParent(false)
    self.m_pDescList:setVisible(false)
    self.m_pDescList:setTouchEnabled(false)
    self.m_pLackItemBg = panel:getChildByName("IconBg2")
    self.m_pGoldNum = panel:getChildByName("GoldNum")
    self._lackItemList = self.m_pLackItemBg:getChildByName("ListView")
    self._lackItemCell = self.m_pLackItemBg:getChildByName("IconBtn_0")
    self._lackItemCell:setVisible(false)
    self.m_pBuffPanel=panel:getChildByName("WorldLevel")
    self.m_BuffDisc1=self.m_pBuffPanel:getChildByName("Image_1")
    self.m_BuffDisc2=self.m_pBuffPanel:getChildByName("Image_2")
    self.m_BuffText1_0=self.m_BuffDisc1:getChildByName("Text")
    self.m_BuffText1_1=self.m_BuffDisc1:getChildByName("Text_1")
    self.m_BuffText1_2=self.m_BuffDisc1:getChildByName("Text_2")
    self.m_BuffText1_3=self.m_BuffDisc1:getChildByName("Text_3")
    self.m_BuffText1_4=self.m_BuffDisc1:getChildByName("Text_0")
    self.m_BuffText2_0  = self.m_BuffDisc2:getChildByName("Text")
    local size = self.m_BuffText1_3:getContentSize()
    self.m_worldLeveltext=Utils:CreateColorText2(self.m_BuffDisc1,self.m_BuffText1_3,size)
  
    local anchor = self.m_pDescLabel:getAnchorPoint()
    local newLabel = CCAysLabel:createWithFixedWidth(self.m_descSize.width,self.m_fontSize,AppDef.UIColor.BROWN);
    local newPos = cc.p(self.m_pDescLabel:getPosition())
    newPos.x = newPos.x - (self.m_descSize.width - self.m_descSize.width*(1-anchor.x))
    newPos.y = newPos.y - (self.m_descSize.height - self.m_descSize.height*anchor.y)
    --newLabel:setAnchorPoint(self.m_pDescLabel:getAnchorPoint())
    newLabel:setPosition(newPos)
    
    newLabel:setName("NewCondition")

    local pCttScrollView = ccui.ScrollView:create()
    pCttScrollView:setIgnoreAnchorPointForPosition(false)
    pCttScrollView:setDirection(ccui.ScrollViewDir.vertical)
    pCttScrollView:setAnchorPoint(cc.p(0,0))
    pCttScrollView:setPosition(cc.p(2,2))
    pCttScrollView:setContentSize(cc.size(self.m_pDescBg:getContentSize().width-4, self.m_pDescBg:getContentSize().height-4))
    pCttScrollView:addChild(newLabel)
    self.m_pDescBg:addChild(pCttScrollView)

    self.m_pDescLabel:removeFromParent()
    self.m_pDescLabel = newLabel
    self.m_pDescScrollView = pCttScrollView
    self.m_descSize = cc.size(self.m_descSize.width-15, 0)

    local newLabel = Sy
    self.m_pUserData = nil

    -- self.m_pCheckBoxItemList = {}
	local function tablefunc(sender, event)
		if event == ccui.CheckBoxEventType.selected then
			LRoleDataMgr.MyHeroInfo.equip_fenjie_tips = false
		elseif event == ccui.CheckBoxEventType.unselected then
			LRoleDataMgr.MyHeroInfo.equip_fenjie_tips = true
		end
	end
	self.checkbox = panel:getChildByTag(1188)
	self.checkbox:addEventListener(tablefunc)
	self.checkbox:setSelected(false)

    self.m_xueZhanPanel = panel:getChildByName("XueZhanFuHuoPanel")
    local label = self.m_xueZhanPanel:getChildByName("Text_xuezhan")
    self.m_xueZhanCntLabel = label:getChildByName("Num")
    self.m_xueZhan100Panel = panel:getChildByName("XueZhan100Panel")
end

function MsgBoxUI:Reset()
	--self.m_pCloseBtn:setVisible(false)
    self.m_pOKBtn1:setVisible(false)
    self.m_pOKBtn2:setVisible(false)
    self.m_pOKBtn3:setVisible(false)
    self.m_pCancelBtn:setVisible(false)
    --self.m_pTitleLabel:setVisible(false)
    self.m_pTipsLabel:setVisible(false)
    local pAysLabel = self.m_pTipsLabel:getParent():getChildByTag(1019)
    if pAysLabel then
        pAysLabel:setVisible(false)
    end
    self._pTipsRecoveryAll:setVisible(false)
    self.m_pCheckBox:setVisible(false)
    self.m_pItemBg:setVisible(false)
    self.m_pSpend:setVisible(false)
    self.m_pItemListView:setVisible(false)
    self.m_pItemCell:setVisible(false)
    self.m_pTipsCell:setVisible(false)
    self.m_pDescBg:setVisible(false)
    self.m_pCheckBoxList:setVisible(false)
    self._TipsPanel:setVisible(false)
    self._TiliTipsPanel:setVisible(false)
    self.m_pCheckBoxList:removeAllItems()
    self.m_pDescScrollView:setInnerContainerSize(self.m_pDescScrollView:getContentSize())
    self.m_pLackItemBg:setVisible(false)
    self.m_pGoldNum:setVisible(false)
    self.m_pBuffPanel:setVisible(false)
    self.m_xueZhanPanel:setVisible(false)
    self.m_xueZhan100Panel:setVisible(false)
    --self.m_pDescLabel:setVisible(false)
    -- local panel = self.m_pUILayer:getChildByName("MessageBoxUI")
    -- local pChilodren = panel:getChildren()
    -- for i=1,#pChilodren do
    --     pChilodren[i]:setVisible(false)
    -- end
    self.m_Sign = false
end

function MsgBoxUI:InitTouchEvt()
   -- self.m_pUserData.okCallback()

    local function CloseCallBack(sender)
       self:HandleClose()
    end
    self.m_pCloseBtn:addClickEventListener(CloseCallBack)
	--self:MarkIntaractCObj(self.m_pCloseBtn)

    local function OKCallBack(sender)
       self:HandleOK()
    end
    self.m_pOKBtn1:addClickEventListener(OKCallBack)
	--self:MarkIntaractCObj(self.m_pOKBtn1)
    self.m_pOKBtn2:addClickEventListener(OKCallBack)
	--self:MarkIntaractCObj(self.m_pOKBtn2)
    local function CancelCallBack(sender)
       self:HandleCancel()
    end
    self.m_pCancelBtn:addClickEventListener(CancelCallBack)
	--self:MarkIntaractCObj(self.m_pCancelBtn)
    local function CheckBoxCallback(_,_)
        self:HandleCheckBox()
    end

    self.m_pCheckBox:addEventListener(CheckBoxCallback)
end

function MsgBoxUI:HandleClose()
    self:UnSchedule()
    if self.m_pUserData == nil then
         return
    end
	if self.m_pUserData.closeCallback ~= nil then
		self.m_pUserData.closeCallback()
	end
	self.m_pUILayer:setVisible(false)
    if self.m_guideStep then
        for k,v in pairs(self.m_guideStep) do
            Utils:SendMsg(LUIGuideEvent.UnRegisterStep, v)
            self.m_guideStep[k] = nil
        end
        self.m_guideStep = {}
    end
end

function MsgBoxUI:HandleOK()
    if self.m_pUserData.xueZhanCnt ~= nil and self.m_pUserData.xueZhanCnt == 0 then
        Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP26)
        return
    end

    if self.m_pUserData.okCallback ~= nil then
        self:UnSchedule()
		self.m_pUserData.okCallback()
	end
    self:UnSchedulerAutoSel()
	self.m_pUILayer:setVisible(false)
end

function MsgBoxUI:HandleCancel()
    if self.m_pUserData.cancelCallback ~= nil then
        self:UnSchedule()
		self.m_pUserData.cancelCallback()
	end
    self:UnSchedulerAutoSel()
	self.m_pUILayer:setVisible(false)
end

function MsgBoxUI:HandleCheckBox()
    if self.m_pUserData.checkBoxCallback ~= nil then
        self:UnSchedule()
        self.m_pUserData.checkBoxCallback(self.m_pCheckBox:isSelected())
    end
end

-- function MsgBoxUI:HandleXueZhanBtn()
--     if self.m_pUserData.xueZhanCnt == 0 then
--         Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP26)
--         return
--     end
--     if self.m_pUserData.xunZanCallback ~= nil then
--         self:UnSchedule()
--         self.m_pUserData.xunZanCallback()
--     end
--     self:UnSchedulerAutoSel()
--     self.m_pUILayer:setVisible(false)
-- end


function MsgBoxUI:EnterBattle()
	----print("--------------------------EnterBattle-------------------------------")
	self.m_bIsAfterBattleShow = false--战斗内能操作了
    self.m_pUILayer:setVisible(false)
end

function MsgBoxUI:ExitBattle()
	self.m_bIsAfterBattleShow = false
	local function DelayShowUI()
		self.m_pUILayer:setVisible(true)
	end
    if self.m_Sign then
	    Utils:DelayToCallFunc(self.m_pUILayer, 0.2,DelayShowUI) 
        self.m_Sign = false
    end
end

function MsgBoxUI:RegisterCloseGuide(stepId)
    self.m_guideStep = self.m_guideStep or {}
    self.m_guideStep[stepId] = stepId
    Utils:RegisterGuide(stepId, self.m_pCloseBtn, handler(self, MsgBoxUI.HandleClose), nil, true)
end

return MsgBoxUI