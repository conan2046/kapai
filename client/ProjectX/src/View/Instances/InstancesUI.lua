local InstancesUI = LUIBase:New()
InstancesUI.__index = InstancesUI

function InstancesUI:New(ind)
    local o = LUIBase:New()
    setmetatable(o,InstancesUI)  
    o:Init(ind)
    return o
end

--[[
注册UI消息
]]
function InstancesUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshInstances,
        LUIActivityEvent.RefreshInstancesCount,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

function InstancesUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshInstances then
        self:InitListView(self.list)
        self:ShowCopyInfo(self.m_curCopyBtn)
    elseif msg.msgId == LUIActivityEvent.RefreshInstancesCount then
        local _ = self.m_pRightTableView and self.m_pRightTableView:reloadData()
        self:ShowCopyInfo(self.m_curCopyBtn)
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:EnterCallback()
    end
end

function InstancesUI:Init(ind)
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/InstancesLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData(ind)
    self:AddTouchEvt()
    LuaNetSendMsg:QueryCopy(11)
    -- if #LDataConstMgr.m_CopyData._CopyList ~= 0 then
    --     self:InitListView(self.list)
    --     self:ShowCopyInfo(self.m_curCopyBtn)
    -- end
end

function InstancesUI:onExit()
    self:Destory()
    
    self.m_pUILayer = nil
    self.m_panelUI = nil
    self.m_pInstancesBg = nil
    self.m_pRightTableView = nil
    -- 副本区域
    self.list = nil
    self.m_pLine = nil
    self.m_beginInd = nil
    self.m_curCopyBtn = nil
    
    -- 右侧显示栏
    self.m_pContent = nil
    self.m_pInfo1 = nil
    self.m_pInfo2 = nil
    self.m_pInfo3 = nil
    self.m_pInfo4 = nil
    self.m_equipIcon = nil
    self.m_itemUIs = nil
    self.m_pSweepBtn = nil
    self.m_pSweepBane = nil
    self.m_pEnterBtn = nil
    self.m_pEnterName = nil
end

function InstancesUI:AddTouchEvt()
    local function SweepCallback(sender)
        local copy = LDataConstMgr.m_CopyData._CopyList
        local ind = self.m_curCopyBtn:getTag()
        local copy = copy[ind]

        LuaNetSendMsg:QueryCopyMsg(20, copy.Id)
    end
    self.m_pSweepBtn:addClickEventListener(SweepCallback)
	self:MarkIntaractCObj(self.m_pSweepBtn)
    local function EnterCallback(sender)
        self:EnterCallback()
    end
    self.m_pEnterBtn:addClickEventListener(EnterCallback)
	self:MarkIntaractCObj(self.m_pEnterBtn)
    -- local function DropAwardCallback(sender)
    -- end
    -- self.m_equipIcon[1]:addClickEventListener(DropAwardCallback)
    -- self.m_equipIcon[2]:addClickEventListener(DropAwardCallback)
end

function InstancesUI:EnterCallback( sender )
    -- body
    --昆仑寻宝状态下,不能参见副本
    if LRoleDataMgr.MonopolyData.isMonopolyState then
        Utils:ShowScrollTips(GUITips.RSI_GS_TIP_MONOPOLY)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
        return
    end

    Utils:SendMsg(LUIActivityEvent.EnterFubBen)
    
    local copy = LDataConstMgr.m_CopyData._CopyList
    local ind = 1
    if self.m_curCopyBtn ~= nil and self.m_curCopyBtn:getTag() > 0 then
        ind = self.m_curCopyBtn:getTag()
    end
    if copy == nil or copy[ind] == nil then return end
    local copy = copy[ind]
    if copy.CurTimes >= copy.MaxTimes then
        Utils:ShowScrollTips(string.format(GUITips.Copy_Tips_Error1, copy.CopyName))
    else

        if LRoleDataMgr.MyHeroInfo:IsTeam() then
            local function okFunc()
                LuaNetSendMsg:QueryLeaveTeam()
            end
            local function canelFunc()
                
            end
            Utils:ShowDialogOKCancel(GUITips.RSI_TARGET_RD_TIPS9, okFunc,canelFunc)
            return
        end

        LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.StopAutoPath)
        self:SendMsg(LGameMsg.m_cBaseMsg)
        LuaNetSendMsg:QueryCopyMsg(12, copy.Id)
    end
end

function InstancesUI:GetInd()
    return self.m_beginInd
end

function InstancesUI:InitData(ind)
    self.m_panelUI = self.m_pUILayer:getChildByName("Panel")
    self.m_pInstancesBg = self.m_panelUI:getChildByName("PetInstancesBg")

    -- 副本区域
    self.list = self.m_pInstancesBg:getChildByName("List")
    self.m_pLine = self.list:getChildByName("Line")
    self.m_pLine:getChildByName("Button1"):setVisible(false)
    self.m_pLine:getChildByName("Button2"):setVisible(false)
    self.m_pLine:getChildByName("Button3"):setVisible(false)
    self.m_pLine:getChildByName("Button4"):setVisible(false)
    self.m_beginInd = ind or 1
    self.m_curCopyBtn = nil
    
    -- 右侧显示栏
    self.m_pContent = self.m_pInstancesBg:getChildByName("Content")
    self.m_pInfo1 = self.m_pContent:getChildByName("ContentText1")  -- 开启条件
    self.m_pInfo2 = self.m_pContent:getChildByName("ContentText1")  -- 开启条件
    self.m_pInfo3 = self.m_pContent:getChildByName("ContentText3")  -- 掉落
    self.m_pInfo4 = self.m_pContent:getChildByName("ContentText4")  -- 几率
    self.m_equipIcon = {}
    self.m_itemUIs = {}
    for i=1,2 do
        self.m_equipIcon[i] = self.m_pContent:getChildByName("EquipIconBg"..i)
        self.m_equipIcon[i]:setTag(i)
        self.m_equipIcon[i]:setTouchEnabled(true)
    end
    
    self.m_pSweepBtn = self.m_pContent:getChildByName("SweepBtn")
    self.m_pSweepBtn:setVisible(false)
    self.m_pSweepBane = self.m_pSweepBtn:getChildByName("BtnName")
    self.m_pSweepBane:setString(GUITips.UI_Text_Copy_Sweep_Times)
    self.m_pEnterBtn = self.m_pContent:getChildByName("EnterBtn")
    self.m_pEnterName = self.m_pEnterBtn:getChildByName("BtnName")
end

function InstancesUI:InitListView(view)
    local tableView = cc.TableView:create(view:getContentSize())
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)   --cc.SCROLLVIEW_DIRECTION_HORIZONTAL
    tableView:setAnchorPoint(view:getAnchorPoint())
    tableView:setPosition(view:getPosition())
    tableView:setDelegate()
    tableView:setSwallowsTouches(false)
    tableView:setBounceable(false)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    view:getParent():addChild(tableView)
    
    local function tableCellTouched(sender,cell)
        print("tableCellTouched",sender,cell,cell:getIdx())
        self:TableLineTouched(cell)
    end
    local function cellSizeForTable(sender,idx)
        local width = self.m_pLine:getContentSize().width
        local height = self.m_pLine:getContentSize().height
        return width, height
    end
    local function tableCellAtIndex(sender, idx)
        return self:TableLineAtIndex(sender, idx)
    end

    local function numberOfCellsInTableView()
        local copy = LDataConstMgr.m_CopyData._CopyList
        local num = math.ceil(#copy / 4)
        return num
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableView被触摸的时候的回调，主要用于选择TableView中的Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --此回调需要返回TableView中Cell的尺寸大小
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --此回调需要为TableView创建在某个位置的Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --此回调需要返回TableView中Cell的数量
    tableView:reloadData()
    self.m_pRightTableView = tableView
end

function InstancesUI:TableLineTouched(cell)

end

function InstancesUI:TableLineAtIndex(sender, idx)
    local function ButtonTouched(sender)    --副本点击
        self.m_beginInd = sender:getTag()
        self:ShowCopyInfo(sender)
    end

    local line = sender:dequeueCell()
    local copy = LDataConstMgr.m_CopyData._CopyList
    local lineChild
    if line == nil then
        line = cc.TableViewCell:new()
        lineChild = self.m_pLine:clone()
        lineChild:setAnchorPoint(cc.p(0, 0))
        local width = self.m_pLine:getContentSize().width
        local height = self.m_pLine:getContentSize().height
        lineChild:setTag(123)
        lineChild:setPosition(cc.p(0,0))
        lineChild:setVisible(true)
        line:addChild(lineChild)
    else
        lineChild = line:getChildByTag(123)
    end
    local buttonStr = "Button"
    local addIdx = idx * 4
    for i=1, 4 do
        local button = lineChild:getChildByName("Button"..i)
        if self.m_beginInd ~= nil and self.m_beginInd == i then
            self.m_curCopyBtn = button
        else
            if self.m_curCopyBtn == nil then
                self.m_curCopyBtn = button -- 默认第一个被选中
            end
        end
        if i + addIdx <= #copy then
            self:ShowCopyButton(button, copy[i + addIdx])
            button:setTag(i + addIdx)
            button:addClickEventListener(ButtonTouched)
			self:MarkIntaractCObj(button)
        else
            button:setVisible(false)
        end
    end
    return line
end

function InstancesUI:ShowCopyButton(button, info)
    button:setVisible(true)
    button:setTouchEnabled(true)
    local redDot = button:getChildByName("RedDot")
    if info ~= nil then
        local level = LRoleDataMgr.MyHeroInfo:Getlevel()
        if info.EnterLevel > level then
            button:getChildByName("Unlock"):setVisible(true)
            button:getChildByName("UnlockBg"):setVisible(true)
            button:getChildByName("ConsumIcon"):setVisible(false)   -- 消耗图标
            button:getChildByName("ConsumName"):setVisible(false)   -- 消耗描述
            button:getChildByName("ConsumNum"):setVisible(false)   -- 消耗数量
            redDot:setVisible(false)       -- 小红点
        else
            button:getChildByName("Unlock"):setVisible(false)
            button:getChildByName("UnlockBg"):setVisible(false)
            redDot:setVisible(true)       -- 小红点
            redDot:getChildByName("Text"):setString(info.MaxTimes - info.CurTimes)

            if info.CopyType == 0 or info.CopyType == 1 then
                if info.CostMoney ~= 0 then
                    button:getChildByName("ConsumName"):setString(GUITips.Copy_Cost_Type)
                    -- button:getChildByName("ConsumName"):setString(GUITips["Copy_Cost_Type"..info.CopyType])   -- 消耗描述
                    button:getChildByName("ConsumNum"):setString(info.CostMoney..GUITips["Copy_Cost_Type"..info.CopyType])   -- 消耗数量
                else
                    button:getChildByName("ConsumName"):setVisible(false)
                    button:getChildByName("ConsumNum"):setVisible(false)
                end
                button:getChildByName("ConsumIcon"):setVisible(false)   -- 消耗图标
            else
                button:getChildByName("ConsumName"):setVisible(false)
                button:getChildByName("ConsumNum"):setVisible(false)
                button:getChildByName("ConsumIcon"):setVisible(true)   -- 消耗图标
                button:getChildByName("ConsumIcon"):loadTexture("item/equip"..LRoleDataMgr.GetItemPicId(info.CostMoney)..".png")
                if LRoleDataMgr.Equip:FindPackageItemById1(info.CostMoney) == 0 then
                    redDot:setVisible(false)       -- 小红点
                end
            end
        end
		local bg = button:getChildByName("PetBg")
		local lvBg = button:getChildByName("LabelBg1")
		if info.Id == 2 then
			bg:loadTexture("res2/InstancesBg/map24.png")  --强化副本
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_7"])
		elseif info.Id ==4 then
			bg:loadTexture("res2/InstancesBg/map29.png")  --升阶副本
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_6"])
		elseif info.Id ==101 then
			bg:loadTexture("res2/InstancesBg/map35.png")  --淬炼副本
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_9"])
		elseif info.Id ==102 then
			bg:loadTexture("res2/InstancesBg/map36.png")  --潜能副本
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_8"])
		end	
        button:getChildByName("InstancesName"):setString(info.CopyName)
        button:getChildByName("SelectBorder"):setVisible(false)
    end
end

function InstancesUI:ShowCopyInfo(button)
    if button == nil then
        return
    end
    local copy = LDataConstMgr.m_CopyData._CopyList
    local ind = button:getTag()
	local info = copy[ind]
    if self.m_curCopyBtn ~=  nil then
        self.m_curCopyBtn:setBrightStyle(0)
        self.m_curCopyBtn:getChildByName("SelectBorder"):setVisible(false)
    end
    self.m_curCopyBtn = button
    self.m_curCopyBtn:setBrightStyle(1)
    self.m_curCopyBtn:getChildByName("SelectBorder"):setVisible(true)
    self.m_pInfo1:setString(info.Description) -- 开启条件
    self.m_pInfo3:setString(info.JiLvSrc) -- 掉落
    self.m_pInfo4:setString(info.JiLv) -- 几率
    -- local str = string.format(GUITips.UI_Text_Copy_Enter_Times, info.MaxTimes - info.CurTimes)
    -- self.m_pEnterName:setString(str)
    --掉落物品
    self:ShowDropAward(info.ItemId)
    self:UpdateCanSweep(info)
end

function InstancesUI:IsCanSweep(info)
    --dump(info)
    return info and (info.CurTimes < info.MaxTimes)
end


function InstancesUI:UpdateCanSweep(info)
    self.m_pSweepBtn:setVisible(true)
    local isCanSweep = self:IsCanSweep(info)
    self.m_pSweepBtn:setBright(isCanSweep)
    -- self.m_pSweepBtn:setTouchEnabled(isCanSweep)
end

function InstancesUI:ShowDropAward(ItemIds)
    for key, value in pairs(ItemIds) do
        if key > 2 then break end
		self.m_equipIcon[key]:removeAllChildren()
        Utils:GetItemCellValue(self.m_equipIcon[key], 0, value, true, false, 0, nil, true)
    end
    for i=#ItemIds+1,2 do
        self.m_equipIcon[i]:removeAllChildren()
    end
end

return InstancesUI