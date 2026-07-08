local JingJieUI = LUIBase:New()
JingJieUI.__index = JingJieUI

function JingJieUI:New()
    local o = LUIBase:New()
    setmetatable(o,JingJieUI)  
    o:Init()
    return o
end

function JingJieUI:RegistMsgs()
  self.msgIds = 
  {
    LUIJingJieEvent.UpdateInfo,
  }
  self:RegistSelf(self,self.msgIds)
end

function JingJieUI:ProcessEvent(msg)    
  if msg.msgId==LUIJingJieEvent.UpdateInfo then
	self:PlayEffect()
	self:LoadData()
  end
end

function JingJieUI:Init()
	self.m_IconStr="res/UI/Icon/ui_jingjie_icon/%s.png"
	self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/JingjieLayer.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
	ccui.Helper:doLayout(self.m_pUILayer)
	local function onNodeEvent(event)        
		if "exit" == event then
			self:onExit()
		end
	end
	self.m_pUILayer:registerScriptHandler(onNodeEvent)
	self:RegistMsgs()
	self:InitViewSize()
	self:LoadData()
end

function JingJieUI:InitViewSize()
	local jingjieui = self.m_pUILayer:getChildByName("JingjieUI")
	local panel = jingjieui:getChildByName("Panel")
	self.jiantou = panel:getChildByName("Image_jiantou")
	self.panelLeft = panel:getChildByName("Panel_L")
	self.panelRight = panel:getChildByName("Panel_R")
	self.panelEnd = panel:getChildByName("Panel_End")
	self.panelTupo = panel:getChildByName("Panel_tupo")
	
	self.effectNode = panel:getChildByName("effect_jingjietupo_1")

	local helpBtn = self.panelLeft:getChildByName("title_bg"):getChildByName("Btn_xiangxi")
	helpBtn:addClickEventListener( handler(self, JingJieUI.ShowHelp) )
	self:MarkIntaractCObj(helpBtn)

	local endhelpBtn = self.panelEnd:getChildByName("title_bg"):getChildByName("Btn_xiangxi")
	endhelpBtn:addClickEventListener( handler(self, JingJieUI.ShowHelp) )
	self:MarkIntaractCObj(endhelpBtn)

	local button = self.panelTupo:getChildByName("Button")
	button:addClickEventListener( handler(self, JingJieUI.TupoClicked) )
	self:MarkIntaractCObj(button)

	Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.JingJie)
end

function JingJieUI:LoadData()
	self.m_otherInfo=LRoleDataMgr.MyHeroInfo.jingJieOtherInfo
	dump(self.m_otherInfo, "===================>>>>>>>>>>>>>>>")
	if self.m_otherInfo.curId >= #JsonConfig.m_jingjieConfig.getList() then
		self.panelLeft:setVisible(false)
		self.panelRight:setVisible(false)
		self.panelEnd:setVisible(true)
		self:InitJingJieEnd()
		self:InitTupo(true)
		return
	end
	self:InitJingJieLeft()
	self:InitJingJieRight()
	self:InitTupo(false)
end

function JingJieUI:InitJingJieLeft()
	local panel_0 = self.panelLeft:getChildByName("Panel_0")
	local bgLeft = self.panelLeft:getChildByName("bg_L")
	local panelShuXing = self.panelLeft:getChildByName("Panel_shuxing")
	if self.m_otherInfo.curId == 0 then
		panel_0:setVisible(true)
		bgLeft:setVisible(false)
		panelShuXing:setVisible(false)
		return
	end
	panel_0:setVisible(false)
	bgLeft:setVisible(true)
	panelShuXing:setVisible(true)
	local curinfo = JsonConfig.m_jingjieConfig.getDefByID(self.m_otherInfo.curId)
	local name = bgLeft:getChildByName("Panel_name"):getChildByName("name")
	name:setString(curinfo.name)
	name:setColor(AppDef:GetQualityColor(curinfo.quality))
	local icon = bgLeft:getChildByName("Icon")
	icon:loadTexture(string.format(self.m_IconStr,curinfo.icon),ccui.TextureResType.plistType)

	local addname = panelShuXing:getChildByName("Text")
	addname:setString(string.format(GUITips.RSI_JINGJIE_TIPS1, tostring(curinfo.name)))

	local attrcell = panelShuXing:getChildByName("Attribute1")
	local m_attrList = panelShuXing:getChildByName("Attr_List")
	m_attrList:removeAllItems()
	for k,v in pairs(curinfo.attr) do
		local cell = attrcell:clone()  
		local value = cell:getChildByName("Value") 
		value:setPositionX(cell:getContentSize().width+40) 
		Utils:ShowAttrLabelSec(cell, v[1], value,v[2])
		m_attrList:pushBackCustomItem(cell)
	end
end

function JingJieUI:InitJingJieRight()
	local bgLeft = self.panelRight:getChildByName("bg_L")
	local panelShuXing = self.panelRight:getChildByName("Panel_shuxing")
	self.panelRight:setVisible(true)
	local nextinfo = JsonConfig.m_jingjieConfig.getDefByID(self.m_otherInfo.curId + 1 )
	local name = bgLeft:getChildByName("Panel_name"):getChildByName("name")
	name:setString(nextinfo.name)
	name:setColor(AppDef:GetQualityColor(nextinfo.quality))
	local icon = bgLeft:getChildByName("Icon")
	icon:loadTexture(string.format(self.m_IconStr,nextinfo.icon),ccui.TextureResType.plistType)

	local addname = panelShuXing:getChildByName("Text")
	addname:setString(string.format(GUITips.RSI_JINGJIE_TIPS1, tostring(nextinfo.name)))

	local attrcell = panelShuXing:getChildByName("Attribute1")
	local m_attrList = panelShuXing:getChildByName("Attr_List")
	m_attrList:removeAllItems()
	for k,v in pairs(nextinfo.attr) do
		local cell = attrcell:clone()  
		local value = cell:getChildByName("Value") 
		value:setPositionX(cell:getContentSize().width+40) 
		Utils:ShowAttrLabelSec(cell, v[1], value,v[2])
		m_attrList:pushBackCustomItem(cell)
	end
end

function JingJieUI:InitJingJieEnd()
	local bgLeft = self.panelEnd:getChildByName("bg_L")
	local panelShuXing = self.panelEnd:getChildByName("Panel_shuxing")
	self.panelEnd:setVisible(true)
	local curinfo = JsonConfig.m_jingjieConfig.getDefByID(self.m_otherInfo.curId)
	local name = bgLeft:getChildByName("Panel_name"):getChildByName("name")
	name:setString(curinfo.name)
	name:setColor(AppDef:GetQualityColor(curinfo.quality))
	local icon = bgLeft:getChildByName("Icon")
	icon:loadTexture(string.format(self.m_IconStr,curinfo.icon),ccui.TextureResType.plistType)

	local addname = panelShuXing:getChildByName("Text")
	addname:setString(string.format(GUITips.RSI_JINGJIE_TIPS1, tostring(curinfo.name)))

	local m_attrList = panelShuXing:getChildByName("Attr_List")
	local attrcell = m_attrList:getChildByName("Attribute1")
	attrcell:retain()
	m_attrList:removeAllItems()
	for k,v in pairs(curinfo.attr) do
		local cell = attrcell:clone()  
		local value = cell:getChildByName("Value") 
		value:setPositionX(cell:getContentSize().width+40) 
		Utils:ShowAttrLabelSec(cell, v[1], value,v[2])
		m_attrList:pushBackCustomItem(cell)
	end
end

function JingJieUI:InitTupo(isend)
	local bglimit = self.panelTupo:getChildByName("bg_limit")
	local bgcost = self.panelTupo:getChildByName("bg_cost")
	local panelend = self.panelTupo:getChildByName("Panel_end")
	local button = self.panelTupo:getChildByName("Button")
	if isend == true then
		panelend:setVisible(true)
		bglimit:setVisible(false)
		bgcost:setVisible(false)
		button:setVisible(false)
		self.jiantou:setVisible(false)
		return
	end
	local curinfo = JsonConfig.m_jingjieConfig.getDefByID(self.m_otherInfo.curId + 1)
	local level = bglimit:getChildByName("Panel_level"):getChildByName("Text"):getChildByName("value")
	level:setString(curinfo.level_limit)
	local AddPower = 0
	for k,v in pairs(curinfo.attr) do
		--AddPower=AddPower+LDataConstMgr:GetSingleAttrPower(v[1],v[2])
	end
	local zhanliLabel = bglimit:getChildByName("Panel_zhanli"):getChildByName("Text"):getChildByName("value")
	zhanliLabel:setString(curinfo.zhanli_limit)
	local zhanli = LRoleDataMgr.MyHeroInfo.zhanDouLiInAll
	if zhanli < curinfo.zhanli_limit then
		zhanliLabel:setColor(AppDef.UIColor.RED)
	end
	local icon = bgcost:getChildByName("btn_Material")
	local numLabel = icon:getChildByName("Value")
	local data = curinfo.tupo_cost
	local item = Utils:GetItemCellValue(icon,0,data[1][1],true, false,0,nil,true, true)
	local mynum = LRoleDataMgr.Equip:CountItemNumById(data[1][1])
	numLabel:setString(mynum .."/" ..data[1][3])
	numLabel:setLocalZOrder(1000)
	self.isMaterial = true
	if mynum < data[1][3] then
		self.isMaterial = false
		numLabel:setColor(AppDef.UIColor.RED)
	end
	local coinLabel = bgcost:getChildByName("xiaohao"):getChildByName("Num")
	coinLabel:setString(data[2][2])
	local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
	if money < data[2][2] then
		numLabel:setColor(AppDef.UIColor.RED)
	end
end

function JingJieUI:TupoClicked(sender)
	local curinfo = JsonConfig.m_jingjieConfig.getDefByID(self.m_otherInfo.curId + 1)
	local level = LRoleDataMgr.MyHeroInfo.level
	local zhanli = LRoleDataMgr.MyHeroInfo.zhanDouLiInAll
	if curinfo.level_limit > level then
		Utils:ShowScrollTips(GUITips.RSI_MDSI_MSGI31)
		return
	end
	if curinfo.zhanli_limit > zhanli then
		Utils:ShowScrollTips(GUITips.RSI_ZHANLI_Tips)
		return
	end
	if self.isMaterial == false then
		Utils:ShowScrollTips(GUITips.RSI_UPGRADE_BUYITEM_TITLE)
		return
	end

	local money = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
	if money < curinfo.tupo_cost[2][2] then
		Utils:ShowScrollTips(GUITips.RSI_BP_SKILL_UPTIPS3)
		return
	end
	LuaNetSendMsg:QueryJingJieInfo(4)
end

--帮助按钮
function JingJieUI:ShowHelp()
  --local function closeMsgBox()
  --end
  --local userData =
  --{
  --  loseCallback = closeMsgBox,
  --  okCallback = closeMsgBox,
  --  title = GUITips.RSI_WELFARE_MSG38,
  --  desc = GUITips.RSI_Help_Str12
  --}
  --LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.PopWindow, userData)
  --LUIManager:SendMsg(LGameMsg.m_initUIMsg)
	LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "JingJie.JingJiePreViewUI", AppDef.UIType.PopWindow)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function JingJieUI:PlayEffect()
	local m_pBgAni = self.effectNode:getChildByTag(111)
	if m_pBgAni == nil then
		local bgAnim = "res2/animation/effect_jingjietupo_1"
		m_pBgAni = ImodAnim:create()
		m_pBgAni:setTag(111)
		self.effectNode:addChild(m_pBgAni)
		m_pBgAni:initAnimWithNameSync(bgAnim)
	end
	m_pBgAni:setVisible(true)
	m_pBgAni:PlayAction(0)
	performWithDelay(self.m_pUILayer, function()
			m_pBgAni:setVisible(false)
		end,3)
end

function JingJieUI:onExit()
  self:Destory()
	self.m_pUILayer = nil
end
return JingJieUI