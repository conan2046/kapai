
local WanFaEntranceUI = LUIBase:New()
WanFaEntranceUI.__index = WanFaEntranceUI
--local this = LTcpSocket
function WanFaEntranceUI:New()
	local o = LUIBase:New()
	setmetatable(o,WanFaEntranceUI)	
    o:Init()
	return o
end

local ICONPATH = "res2/Icon/ui_main_icon/"

--注册事件
-- -----------------------------------
function WanFaEntranceUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function WanFaEntranceUI:ProcessEvent(msg)
end

function WanFaEntranceUI:Init()

    self.m_pUILayer = cc.CSLoader:createNode("csd/common/ActivityLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self.m_pRedDotVec = {}

    local function closeCallback()
        self:CloseUI()
    end
    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetCloseCallback, closeCallback)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    LGameMsg.m_baseMsgWithOne:Change(LUIPopFClassBgEvent.SetTitle, GUITips.UI_Title_Activity)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

    self:initData()
	self:UpdateRedDot()

    self:initControlUI()
    self:RegisterGuide()
end

function WanFaEntranceUI:initControlUI( ... )
    -- body
    local Panel = self.m_pUILayer:getChildByName("Panel")
    self._tableView = Panel:getChildByName("ActivityBg")
    local cell = self._tableView:getChildByName("ActivityList")
    cell:removeFromParent()
    cell:retain()

    local listView = ccui.ListView:create()
    listView:setDirection(LISTVIEW_DIR_VERTICAL)
    listView:setPosition(cc.p(0, 0))
    listView:setAnchorPoint(cc.p(0, 0))
    listView:setContentSize(self._tableView:getContentSize())
    -- 关闭惯性滑动
    listView:setBounceEnabled(true)
    listView:setSwallowTouches(false)
    -- 设置间距
    listView:setItemsMargin(2)
    -- 隐藏滚动条
    listView:setScrollBarEnabled(false)
    
    self._tableView:addChild(listView)
    local size
    if #self._datas % 2 == 0 then
        size = #self._datas / 2 
    else
        size = #self._datas / 2 + 1
    end
    print("initControlUI == size =", size)
    for i=1, size do
        local item = cell:clone()
        listView:pushBackCustomItem(item)
        for j=1, 2 do
            local index = (i - 1) * 2 + j
            local taskBtn = item:getChildByName("TaskBtn"..j)
            self:updateItem(taskBtn, index)
        end
    end
end

function WanFaEntranceUI:updateItem( singleItem, index )
    -- body
    print("index ====>", index)
    if index > #self._datas then
        singleItem:setVisible(false)
        return
    end
    local data = self._datas[index]
    singleItem:setVisible(true)
    singleItem:setTag(data.function_id)
    singleItem:addClickEventListener(handler(self, WanFaEntranceUI.showFunctionInfo))

    local Choose = singleItem:getChildByName("Choose")
    local Icon = singleItem:getChildByName("Icon")
    local TaskName = singleItem:getChildByName("TaskName")
    -- dump(data, "WanFaEntranceUI:updateItem ===>")
    TaskName:setString(data.name)
    local iconPath = ICONPATH .. data.icon .. ".png"
    print("iconPath ==", iconPath)
    Icon:loadTexture( iconPath, ccui.TextureResType.localType)
    local OpenLevel = singleItem:getChildByName("OpenLevel")
    local EnterBtn = singleItem:getChildByName("EnterBtn")
    EnterBtn:addClickEventListener(handler(self, WanFaEntranceUI.enterFunction))
    if data.function_id == AppDef.EModuleID.EMID_KAPAI_WF_ARENA then
        self.m_guideBtn1 = EnterBtn
    elseif data.function_id == AppDef.EModuleID.EMID_KAPAI_XUNBAO then
        self.m_guideBtn2 = EnterBtn
    end

    local State = singleItem:getChildByName("State")
    State:setVisible(false)

    local win = singleItem:getChildByName("win")
    win:setVisible(false)

    local isFuncionNotOPen = Utils:CheckModelNotOpened(data.function_id, true)
    if isFuncionNotOPen then
        EnterBtn:setVisible(false)
        local level = Utils:getFucnOpenLevel( data.function_id )
        OpenLevel:setString(tostring(level) .. GUITips.UI_JiKaiqi)
    else
        OpenLevel:setVisible(false)
        EnterBtn:setVisible(true)
    end

    EnterBtn:setTag(data.function_id)
	singleItem:getChildByName("Prompt"):setVisible(self.m_pRedDotVec[data.function_id])
end

function WanFaEntranceUI:enterFunction( sender )
    -- body
    local functionId = sender:getTag()
    print("enterFunction", functionId)
    -- function_id=18 collides with the main HUD activity enum. The gameplay
    -- entry owns the stamina-claim destination and must bypass the activity
    -- list empty check in Utils:OpenFunction(18).
    if functionId == AppDef.EModuleID.EMID_ACTIVITY_Tili_REVERT then
        Utils:InitUI("WelfareActivity.WelfareActivityUI", AppDef.UIType.SpecialLayer, 1)
    else
        Utils:OpenFunction(functionId)
    end
    self:CloseUI()
end

function WanFaEntranceUI:showFunctionInfo(sender)
    -- body
    local functionId = sender:getTag()
    if self._lastSelect ~= nil then
        self._lastSelect:getChildByName("Choose"):setVisible(false)
    end
    sender:getChildByName("Choose"):setVisible(true)
    self._lastSelect = sender

    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Main.WanFaInfoUI",AppDef.UIType.PopWindow, functionId)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function WanFaEntranceUI:initData( ... )
    -- body
    local mapArr = LDataConstMgr:GetFunctionLevelMap()
    self._datas = {}
    for k,v in pairs(mapArr) do
        -- 1 -- 999 是活动
        if k < 999 then
            if Utils:ToBool(v.page)  then
                table.insert(self._datas, v)
				self.m_pRedDotVec[k] = false
            end
        end
    end
end

function WanFaEntranceUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("Main.WanFaEntranceUI")
end

function WanFaEntranceUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Arena_3)
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_XunBao_3)
    self.m_pUILayer = nil
    self:Destory()
end

function WanFaEntranceUI:RegisterGuide()
    if self.m_guideBtn1 ~= nil then
       Utils:RegisterGuide(GuideDef.StepId.Guide_Arena_3, self.m_guideBtn1 ,function()
            self:enterFunction(self.m_guideBtn1)
        end, nil, true)
    end
    if self.m_guideBtn2 ~= nil then
       Utils:RegisterGuide(GuideDef.StepId.Guide_XunBao_3, self.m_guideBtn2 ,function()
            self:enterFunction(self.m_guideBtn2)
        end, nil, true)
    end
end

function WanFaEntranceUI:UpdateRedDot()
    local functionIds = {AppDef.EModuleID.EMID_KAPAI_JUEZHANKUNLUN,AppDef.EModuleID.EMID_KAPAI_WF_ARENA
        ,AppDef.EModuleID.EMID_KAPAI_WF_XZ,AppDef.EModuleID.EMID_KAPAI_XUNBAO}
    local redIds = {RedDotDef.ID.KunLunJueZhan,RedDotDef.ID.ArenaTask,RedDotDef.ID.XueZhanDraw
        ,RedDotDef.ID.XunBao}
    for i=1,#functionIds do
	   self.m_pRedDotVec[functionIds[i]] = Utils:GetRedDotState(redIds[i])
    end
end

return WanFaEntranceUI
