local QiangHuaDaShiDaChengUI = LUIBase:New()
QiangHuaDaShiDaChengUI.__index = QiangHuaDaShiDaChengUI

QiangHuaDaShiDaChengUI.IsHideInBattle = true

function QiangHuaDaShiDaChengUI:New(data)
    local o = {}
    setmetatable(o, QiangHuaDaShiDaChengUI)
    o:Init(data)
    return o
end

function QiangHuaDaShiDaChengUI:Init(data)
	self.m_pUILayer = nil
	self.m_timeline = nil
	self.m_masterLayer = nil
	self:InitViewSize()
	self:InUIControl()
	self:setCloseCallback()
	self:LoadData(data)
end

function QiangHuaDaShiDaChengUI:InitViewSize()
	self.m_pUILayer = cc.CSLoader:createNode("csd/zhuangbeiyangcheng/qianghuadashidacheng.csb")
	self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

	self.m_timeline = cc.CSLoader:createTimeline("csd/zhuangbeiyangcheng/qianghuadashidacheng.csb")
    self.m_pUILayer:runAction(self.m_timeline)
	self.m_timeline:gotoFrameAndPlay(0, false)
	local function onCloseFrame(frame)
		if frame:getEvent() == "close" then
			self:CloseMasterDaChengUI()
		end
	end
	self.m_timeline:setFrameEventCallFunc(onCloseFrame)
end

function QiangHuaDaShiDaChengUI:InUIControl()
	self.m_masterLayer = self.m_pUILayer:getChildByName("dashidacheng")
	local touchListener = cc.EventListenerTouchOneByOne:create()
	local function onTouchBegan(touch, event)
		--self:CloseMasterDaChengUI()
	end

	touchListener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	touchListener:setSwallowTouches(true)
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener,self.m_masterLayer)
	self.m_masterLayer:setTouchEnabled(true)

	self.tabNames = {GUITips.RSI_QHDS_Equip_QiangHua, GUITips.RSI_QHDS_Equip_JingLian,GUITips.RSI_QHDS_Equip_JueXing,GUITips.RSI_QHDS_Equip_ShenZhou,GUITips.RSI_QHDS_FaBao_QiangHua,GUITips.RSI_QHDS_FaBao_JingLian}
	self.attrNames = {GUITips.Item_Hp,GUITips.Item_Attack,GUITips.Item_WuFang,GUITips.Item_FaFang}
end

function QiangHuaDaShiDaChengUI:LoadData(data)
	local type = data.type
	local level = data.level
	local jichushuxing = self.m_masterLayer:getChildByName("jichushuxing")
	local leftname = jichushuxing:getChildByName("name_1")
	leftname:setString(string.format(self.tabNames[type]..GUITips.UI_Text_Level_Index, (level -1)))
	local leftlevel = leftname:getChildByName("Level")
	leftlevel:setVisible(false)
	--leftlevel:setString(string.format(self.tabNames[type]..GUITips.UI_Text_Level_Index, (level -1)))

	local rightname = jichushuxing:getChildByName("name_2")
	rightname:setString(string.format(self.tabNames[type]..GUITips.UI_Text_Level_Index, level))
	local rightlevel = rightname:getChildByName("Level")
	rightlevel:setVisible(false)
	--rightlevel:setString(string.format(self.tabNames[type]..GUITips.UI_Text_Level_Index, level))

	--local attrValues = {0,0,0,0}
	--for i = 1, level do
	--	local masterData = LDataConstMgr:GetMasterData(type, i)
	--	for j = 1, #masterData.attr do
	--		attrValues[j] = attrValues[j] + masterData.attr[j][2]
	--	end
	--end
	local curData = LDataConstMgr:GetMasterData(type, level)
	if curData == nil then
		return
	end
	local preData = LDataConstMgr:GetMasterData(type, level - 1)  
	if preData == nil then
		preData = {}
		preData.attr = {}
		for i = 1,#curData.attr do
			local data = curData.attr[i]
			preData.attr[i] = {}
			preData.attr[i][1] = data[1]
			preData.attr[i][2] = 0
		end
	else

	end

	for i = 1, 4 do
		local attrName = jichushuxing:getChildByName("Atrribute_"..i)
		if i > #curData.attr then
			attrName:setVisible(false)
		else
			attrName:setVisible(true)
			local attrcfg = JsonConfig.m_AttrType.getDefByID(curData.attr[i][1])
			attrName:setString(attrcfg.attrName)
			local leftvalue = attrName:getChildByName("Value_1")
			--leftvalue:setString("+"..(attrValues[i] - curData.attr[i][2]))
			leftvalue:setString("+"..preData.attr[i][2])
			local rightvalue = attrName:getChildByName("Value_2")
			--rightvalue:setString("+"..attrValues[i])
			rightvalue:setString("+"..curData.attr[i][2])

			local addvalue = attrName:getChildByName("Value_3")
			addvalue:setString(curData.attr[i][2] - preData.attr[i][2])
		end
	end
end

function QiangHuaDaShiDaChengUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function QiangHuaDaShiDaChengUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

function QiangHuaDaShiDaChengUI:CloseMasterDaChengUI()
    Utils:DeleteUI("Activity.QiangHuaDaShiDaChengUI")
end

return QiangHuaDaShiDaChengUI