local KunLunJueZhanUI = LUIBase:New()
KunLunJueZhanUI.__index = KunLunJueZhanUI

KunLunJueZhanUI.IsHideInBattle = true
function KunLunJueZhanUI:New(initTab)
    local o = {}
    setmetatable(o, KunLunJueZhanUI)
    o:Init(initTab)
    return o
end

function KunLunJueZhanUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKunLunEvent.LoadDataEvent,
		LUIKunLunEvent.UpdateDataEvent,
		LUIKunLunEvent.UpdateFightEvent,
		LUIKunLunEvent.FightFailedEvent,
		LUIKunLunEvent.GetRobotZhenFaInfo,
		LUIKunLunEvent.FightRewardShow,
		LUIFClassBgEvent.ResumeResourceData,
		LUIKunLunEvent.UpdateBuyFightNum,
		LUIRoleDataChangeEvent.KunlunMoneyChanged,
    }
    self:RegistSelf(self, self.msgIds)
end

function KunLunJueZhanUI:ProcessEvent(msg)
    if msg.msgId == LUIKunLunEvent.LoadDataEvent then
        self:LoadData(msg.value)
	elseif msg.msgId == LUIKunLunEvent.UpdateDataEvent then
		self:setDefaultBg()
		local ceng = math.floor((msg.value.pos-1) / 3) + 1
		if ceng == 3 and self.curCeng < 4 then --当前层已经通关无需更新UI 由op = 25 直接更新下一层
			Utils:ShowScrollTips(GUITips.UI_KunLun_LianChuang_Success)
			return
		end
		self:UpdateEnemyData(msg.value)
		self:UpdateUI(msg.value)
	elseif msg.msgId == LUIKunLunEvent.UpdateFightEvent then
		self:UpdateEnemyData(msg.value)
	elseif msg.msgId == LUIKunLunEvent.FightFailedEvent then
		self:UpdateFailedData(msg.value)
	elseif msg.msgId == LUIKunLunEvent.GetRobotZhenFaInfo then
		self:OpenFormationUI(msg.value)
	elseif msg.msgId == LUIFClassBgEvent.ResumeResourceData then
		self:setDefaultBg()
	elseif msg.msgId == LUIKunLunEvent.FightRewardShow then
		self:OpenRewardView(true)
	elseif msg.msgId == LUIKunLunEvent.UpdateBuyFightNum then
		self:UpdateBuyNum(msg.value)
	elseif msg.msgId == LUIRoleDataChangeEvent.KunlunMoneyChanged then
		self:UpdateKunLunMoney()
    end
end

function KunLunJueZhanUI:Init(initTab)
	self.Script = "JueZhanKunLun.KunLunJueZhanUI"
	self.m_pUILayer = nil
    self.m_timeline = nil
	self.m_fightNum = nil
	self.m_cengLabel = nil
	self.m_pRoleNode = nil
	self.m_pLianChuangLayer = nil
	self.m_enemyNodeVec = {}
	self.curCeng = 0
	self.curPos = 0
	self.fightnum = 0
	self.isOver = false
	self.m_pEnemyDatas = {}
	self.roleStartPosition = nil
	self.buy_num = nil
	self.curSelectEnemyId = 0

	self.fightStop = 1
	self.fightnumStop = 1
	self.lianchuangId = 0

    self:RegistMsgs()
	self:InitViewSize()
	self:InitUIControl()
	self:setCloseCallback()
	self:initLianChuangView()
	--self:LoadData(LRoleDataMgr.m_kunlunjuezhanData)
	LuaNetSendMsg:QuertKunLunData()
end

function KunLunJueZhanUI:InitViewSize()
	self.m_pUILayer = cc.CSLoader:createNode("csd/kunlun/juezhankunlun.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

	self.road_layer = self.m_pUILayer:getChildByName("road_layer")

	self.m_pLianChuangLayer = cc.CSLoader:createNode("csd/kunlun/lianchuangtishi.csb")
	ccui.Helper:doLayout(self.m_pUILayer)
	self.m_pUILayer:addChild(self.m_pLianChuangLayer)
	self.m_pLianChuangLayer:setVisible(false)

	self.m_timeline = cc.CSLoader:createTimeline("csd/kunlun/juezhankunlun.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)
	Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)

	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_KunLunJueZhan)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.BGChange, "res/UI/ui_bg/bg_juezhankunlun.png")
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

	local function closeCallback()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, self.Script)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.KunLun)
end

function KunLunJueZhanUI:InitUIControl()
	local enemy_layer = self.m_pUILayer:getChildByName("Enemy_layer")
	for i = 1, 3 do
		for j = 1, 3 do
			local enemynode = enemy_layer:getChildByName("Button_"..i.."_"..j)
			enemynode:addClickEventListener(handler(self, KunLunJueZhanUI.TiaozhanClicked))
			self:MarkIntaractCObj(enemynode)
			table.insert(self.m_enemyNodeVec, enemynode)

			local lianchuangBtn = enemynode:getChildByName("Button_lianchuang")
			lianchuangBtn:addClickEventListener(handler(self, KunLunJueZhanUI.LianChuangClicked))
			self:MarkIntaractCObj(lianchuangBtn)
		end
	end

	self.m_pRoleNode = self.m_pUILayer:getChildByName("Node_role")
	self.roleStartPosition = cc.p(self.m_pRoleNode:getPosition())
	local cengshulayer = self.m_pUILayer:getChildByName("cengshulayer")
	self.m_cengLabel = cengshulayer:getChildByName("cengshuBg"):getChildByName("text2")

	local tiaozhancishulayer =  self.m_pUILayer:getChildByName("tiaozhancishulayer")
	self.m_fightNum = tiaozhancishulayer:getChildByName("tiaozhancishuBg"):getChildByName("num")
	local addbtn = tiaozhancishulayer:getChildByName("AddBtn")
	addbtn:addClickEventListener(handler(self, KunLunJueZhanUI.AddFightNumClicked))
	self:MarkIntaractCObj(addbtn)
	local shangdianbtn = self.m_pUILayer:getChildByName("btn_shangdian")
	shangdianbtn:addClickEventListener(handler(self, KunLunJueZhanUI.OpenShangDianClicked))
	self:MarkIntaractCObj(shangdianbtn)
	self.kunlunLabel = shangdianbtn:getChildByName("Icon"):getChildByName("Text")
	self:UpdateKunLunMoney()
	self.btn = self.m_pUILayer:getChildByName("Box"):getChildByName("Button")
	self.btn:setVisible(false)
	self.boxBtn = self.m_pUILayer:getChildByName("Box"):getChildByName("Button1")
	self.boxBtn:addClickEventListener(handler(self, KunLunJueZhanUI.OpenRewardClicked))
	self:MarkIntaractCObj(self.boxBtn)
	
	local roadchildren = self.road_layer:getChildren()
	for i=1,#roadchildren do
        roadchildren[i]:setVisible(false)
    end
end

function KunLunJueZhanUI:UpdateKunLunMoney()
	local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetKunLunMoney()
	self.kunlunLabel:setString(myMoney)
end

function KunLunJueZhanUI:setDefaultBg()
	Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.BGChange, "res/UI/ui_bg/bg_juezhankunlun.png")
	self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function KunLunJueZhanUI:OpenRewardView(iscan)
	local data = JsonConfig.m_KunlunConfig.getDefByID(self.curCeng)
	if iscan == true then
		Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,data.reward,false,GUITips.RSI_FUND_TIPS4,nil,nil)
	else
		Utils:OpenRewardBox(GUITips.RSI_BOX_TIP2,data.reward,false,GUITips.RSI_BOX_TIP1,nil,nil)
	end
end

function KunLunJueZhanUI:LoadData(kunlundata)
	--dump(kunlundata, "========kunlundata============>>>>>>>>>>>>>>>>>>")
	self.curCeng = kunlundata.ceng
	self.curPos = kunlundata.pos
	self.fightnum = kunlundata.zhandou_num
	self.buy_num = kunlundata.buy_num
	self.m_cengLabel:setString(string.format(GUITips.RSI_KUNLUN_CENG_TIPS, kunlundata.ceng))
	self.m_fightNum:setString(kunlundata.zhandou_num)
	local data = LRoleDataMgr.MyHeroInfo
	self.m_pModelAni = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, data.model)
	self.m_pRoleNode:addChild(self.m_pModelAni)
	self.m_pModelAni:PlayStand(4)
	self.m_pEnemyDatas = {}
	self.m_pEnemyDatas = kunlundata.enemyinfos
	for i = 1, #self.m_pEnemyDatas do
		self:UpdateItem(self.m_enemyNodeVec[i], self.m_pEnemyDatas[i])
	end
	if kunlundata.pos > 0 then
		self:InitRolePos(kunlundata.pos)
	else
		self.m_pRoleNode:setPosition(self.roleStartPosition)
	end
	local ceng = math.floor((kunlundata.pos-1) / 3) + 1
	if ceng == 3 and self.curCeng == 4 then
		self.isOver = true
		self.btn:setVisible(true)
		self.boxBtn:setVisible(false)
	end
	local children = self.road_layer:getChildren()
	for i = 1,#children do
		children[i]:setVisible(false)
	end
	self:UpdateRoad()
end

function KunLunJueZhanUI:UpdateEnemyData(data)
	local pos = data.pos
	local path = data.path
	if path == nil then
		if self.m_pEnemyDatas[pos] == nil then
			return
		end
		self.m_pEnemyDatas[pos].state = 3
	else
		for i = 1, #path do
			if path[i] <= pos then 
				self.m_pEnemyDatas[path[i]].state = 3
			end
		end
	end
end

function KunLunJueZhanUI:UpdateItem(pItem, pData)
	pItem:setTag(pData.id)
	pItem:setVisible(true)
	local roleNode = pItem:getChildByName("BaseImage"):getChildByName("Node")
	roleNode:setVisible(true)
	if roleNode:getChildByTag(222) ~= nil then
		roleNode:removeChildByTag(222)
	end
	local infolayer = pItem:getChildByName("info_layer")
	infolayer:setVisible(true)
	infolayer:setTouchEnabled(false)
	local bloodbar = pItem:getChildByName("bloodBar")
	bloodbar:setVisible(true)
	local lianchuangBtn = pItem:getChildByName("Button_lianchuang")
	--lianchuangBtn:setVisible(true)
	if pData.state == 3 then
		infolayer:setVisible(false)
		lianchuangBtn:setVisible(false)
		bloodbar:setVisible(false)
		roleNode:setVisible(false)
		return
	end
	local modelAni = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, pData.professional)
	modelAni:setTag(222)
	roleNode:addChild(modelAni)
	modelAni:PlayStand(0)
	infolayer:setVisible(true)
	local level = infolayer:getChildByName("Level")
	level:setString(pData.level)
	local name = infolayer:getChildByName("Name")
	name:setString(pData.name)
	local zhanli = infolayer:getChildByName("Zhanli"):getChildByName("Zhanli_num")
	zhanli:setString(pData.fight)
	bloodbar:setVisible(true)
	if pData.state == 0 then
		bloodbar:setPercent(100)
	elseif pData.state == 2 then
		local curblood = 0
		local maxblood = 0
		for i = 1, #pData.pets do 
			local data = pData.pets[i]
			curblood = curblood + data.blood
			maxblood = maxblood + data.maxblood
		end
		bloodbar:setPercent( math.ceil( (curblood / maxblood) * 100 ) )
	end
end

function KunLunJueZhanUI:UpdateUI(data)
	self.curPos = data.pos
	self.fightnum = data.num
	self.m_fightNum:setString(data.num)
	local fight_pos = data.pos
	local path = data.path
	if path ~= nil then
		for i = 1, #path do
			self:UpdateEnemyNode(path[i])
		end
		Utils:ShowScrollTips(GUITips.UI_KunLun_LianChuang_Fail)
	else
		self:UpdateEnemyNode(fight_pos)
	end
	if fight_pos > 0 then
		self:InitRolePos(fight_pos)
	end
	local ceng = math.floor((data.pos-1) / 3) + 1
	if ceng == 3 and self.curCeng == 4 and self.isOver == false then
		Utils:ShowScrollTips(GUITips.RSI_JIESUAN_TITLE2)
		self.isOver = true
		self.btn:setVisible(true)
		self.boxBtn:setVisible(false)
		LRedDotCheckMgr:WanFaRedDotCheck()
	end
	self:UpdateRoad()
end

function KunLunJueZhanUI:UpdateBuyNum(data)
	self.fightnum = data[1]
	self.m_fightNum:setString(data[1])
	self.buy_num = data[2]
end

function KunLunJueZhanUI:UpdateEnemyNode(pos)
	local data = self.m_pEnemyDatas[pos]
	if data.state == 3 then
		local node = self.m_enemyNodeVec[pos]
		node:getChildByName("info_layer"):setVisible(false)
		node:getChildByName("Button_lianchuang"):setVisible(false)
		node:getChildByName("bloodBar"):setVisible(false)
		local modelNode = node:getChildByName("BaseImage"):getChildByName("Node")
		modelNode:setVisible(false)
		modelNode:removeChildByTag(222)
	end
end

function KunLunJueZhanUI:UpdateRoad()
	for i = 1, #self.m_pEnemyDatas do
		local pItem = self.m_enemyNodeVec[i]
		local pData = self.m_pEnemyDatas[i]
		local lianchuangBtn = pItem:getChildByName("Button_lianchuang")
		--lianchuangBtn:setVisible(true)
		local _canFight = self:CheckCanTiaoZhan(pData.id)
		if _canFight == false then
			pItem:getChildByName("Button_lianchuang"):setVisible(false)
		end
		local isShow = _canFight == true or pData.state == 3
		local ind = math.ceil(pData.id / 3) - 1
		local yu = pData.id - (ind * 3)
		if ind > 0 then
			if isShow == true then
				local path = "road_"..ind.."_"..yu
				if yu == 2 then
					if self:CheckCanTiaoZhan(pData.id - 1) == true or self.m_pEnemyDatas[pData.id - 1].state == 3 then
						self.road_layer:getChildByName(path.."_shang"):setVisible(true)
					end
					if self:CheckCanTiaoZhan(pData.id + 1) == true or self.m_pEnemyDatas[pData.id + 1].state == 3 then
						self.road_layer:getChildByName(path.."_xia"):setVisible(true)
					end
				end
				self.road_layer:getChildByName(path):setVisible(true)
			end
		end
	end
end

function KunLunJueZhanUI:UpdateFailedData(data)
	self.fightnum = data.fightnum
	self.m_fightNum:setString(data.fightnum)
	local pos = data.pos
	local pData = self.m_pEnemyDatas[pos]
	local enemyNode = self.m_enemyNodeVec[pos]
	local bloodBar = enemyNode:getChildByName("bloodBar")
	pData.state  = data.state
	pData.pets = data.pets
	if pData.state == 2 then
		local curblood = 0
		local maxblood = 0
		for i = 1, #pData.pets do 
			local data = pData.pets[i]
			curblood = curblood + data.blood
			maxblood = maxblood + data.maxblood
		end
		bloodBar:setPercent( math.ceil( (curblood / maxblood) * 100 ))
	end
end

function KunLunJueZhanUI:InitRolePos(pos)
	local node = self.m_enemyNodeVec[pos]
	local position = cc.p(node:getPosition())
	if position ~= nil then
		self.m_pRoleNode:setPosition(cc.p(position.x, position.y -80))
	end
end

function KunLunJueZhanUI:TiaozhanClicked(sender)
	if self.isOver == true then
		--return
	end
	if self.fightnum <= 0 then
		Utils:ShowScrollTips(GUITips.RIS_LEFTUI_MSG173)
		return
	end
	local enemydata = self.m_pEnemyDatas[sender:getTag()]
	if enemydata.state == 3 then
		return
	end
	if self:CheckCanTiaoZhan(sender:getTag()) then
		local data = self.m_pEnemyDatas[sender:getTag()]
		self.curSelectEnemyId = data.id
		if data.robot == 0 then
			LuaNetSendMsg:QueryOtherPlayerInfo(data.roleid,1)
		else
			LuaNetSendMsg:QueryRobotInfo(data.roleid)
		end
		--self:OpenFormationUI(sender:getTag())
	else
		Utils:ShowScrollTips(GUITips.RSI_KUNLUN_FIGHT_NONE)
	end
end

function KunLunJueZhanUI:LianChuangClicked(sender)
	--local id = sender.parent:getTag()
	if self.isOver == true then
		return
	end
	self.lianchuangId = sender:getParent():getTag()
	self.m_pLianChuangLayer:setVisible(true)
end

function KunLunJueZhanUI:OpenFormationUI(zhenfaData)
	local value = {}
    value.enemyZhenfaId = zhenfaData.zhengfaId
    value.enemyInfos = zhenfaData.zhengfaData
    --local max = AppDef.Formation.MaxFightNum
    --for i = 1,max do
    --    value.enemyInfos[i] = {}
    --end
	--dump(value, "=OpenFormationUI===============>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    local fun = function()
        LuaNetSendMsg:QuertKunLunById(self.curSelectEnemyId)
    end
    value.callback = fun
	value.isrole = zhenfaData.isRole
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function KunLunJueZhanUI:initLianChuangView()
	local popup = self.m_pLianChuangLayer:getChildByName("Popup")
	local checkbox1 = popup:getChildByName("CheckBox1")
	local function fightCallback(pSender, inputType)
		self.fightStop = math.abs(inputType - 1)
    end
    checkbox1:addEventListener(fightCallback)

	local checkbox2 = popup:getChildByName("CheckBox2")
	local function numCallback(pSender, inputType)
        self.fightnumStop = math.abs(inputType - 1)
    end
    checkbox2:addEventListener(numCallback)

	local function closeCallBack()
		self.m_pLianChuangLayer:setVisible(false)
    end
	local closebtn = popup:getChildByName("Btn_close")
	closebtn:addClickEventListener(handler(self, closeCallBack))
	self:MarkIntaractCObj(closebtn)
	

	local function startCallBack()
		LuaNetSendMsg:QuertKunLunLianChuang(self.lianchuangId, self.fightStop, self.fightnumStop)
		self.m_pLianChuangLayer:setVisible(false)
    end
	local startBtn = popup:getChildByName("Btn_start")
	startBtn:addClickEventListener(handler(self, startCallBack))
	self:MarkIntaractCObj(startBtn)
end

function KunLunJueZhanUI:CheckCanTiaoZhan(id)
	if self.m_pEnemyDatas[id].state == 3 then
		return false
	end
	local ceng = math.floor((id-1) / 3) + 1
	if ceng == 1 then
		return true
	else
		local lastid = id - 3
		local data = self.m_pEnemyDatas[lastid]
		if data.state == 3 then
			return true
		else
			local leftid = id - 1
			local rightid = id + 1
			if id % 3 == 2 then
				if self.m_pEnemyDatas[lastid].state == 3 or self.m_pEnemyDatas[rightid].state == 3 then
					return true
				end
			elseif id % 3 == 1 then
				if self.m_pEnemyDatas[rightid].state == 3 then
					return true
				end
			elseif id % 3 == 0 then
				if self.m_pEnemyDatas[leftid].state == 3 then
					return true
				end
			end
		end
	end
	return false
end

function KunLunJueZhanUI:AddFightNumClicked(sender)
	if self.buy_num == 0 then
		Utils:ShowScrollTips(GUITips.RSI_PET_MSG40)
		return
	end
	Utils:InitUI("JueZhanKunLun.BuyJueZhanUI", AppDef.UIType.PopWindow, {self.fightnum, self.buy_num})
end

function KunLunJueZhanUI:OpenShangDianClicked(sender)
	-- Utils:InitUI("Shop.WanFaShopMainUI", AppDef.UIType.PopFirstClassLayer, 1)
	Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_KUNLUN)
end

function KunLunJueZhanUI:OpenRewardClicked(sender)
	if self.m_pEnemyDatas[7].state == 3 or self.m_pEnemyDatas[8].state == 3 or self.m_pEnemyDatas[9].state == 3 then
		self:OpenRewardView(true)
	else
		self:OpenRewardView(false)
	end
end

function KunLunJueZhanUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function KunLunJueZhanUI:onExit()
    self:Destory()
    self.Script = nil
    self.m_pUILayer = nil
    self.m_timeline = nil
	self.m_fightNum = nil
	self.m_cengLabel = nil
	self.m_pRoleNode = nil
	self.m_pLianChuangLayer = nil
	self.m_enemyNodeVec = {}
	self.m_pEnemyDatas = {}
	LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.BGChange, "res/UI/ui_common_new/ui_bg_new.jpg")
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
return KunLunJueZhanUI