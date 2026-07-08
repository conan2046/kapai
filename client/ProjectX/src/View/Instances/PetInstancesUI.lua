local PetInstancesUI = LUIBase:New()
PetInstancesUI.__index = PetInstancesUI

function PetInstancesUI:New(ind)
    local o = LUIBase:New()
    setmetatable(o,PetInstancesUI)  
    o:Init(ind)
    return o
end

--[[
æ³¨å†ŒUIæ¶ˆæ¯
]]
function PetInstancesUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.RefreshInstances,
        LUIActivityEvent.RefreshInstancesCount,
        LUIRoleTeamEvent.TeamMemberChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

function PetInstancesUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.RefreshInstances then
        self:InitListView(self.list)
        self:ShowCopyInfo(self.m_curCopyBtn)
    elseif msg.msgId == LUIActivityEvent.RefreshInstancesCount then
        local _ = self.m_pRightTableView and self.m_pRightTableView:reloadData()
    elseif msg.msgId == LUIRoleTeamEvent.TeamMemberChanged then
        self:EnterCallback()
    end
end

function PetInstancesUI:Init(ind)
    self:RegistMsgs()
    self.m_beginInd = ind
    self.m_pUILayer = cc.CSLoader:createNode("csd/PetInstancesLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData()
    self:AddTouchEvt()
    LuaNetSendMsg:QueryPetCopyList()

    -- if #LDataConstMgr.m_CopyData._PetCopyList ~= 0 then
    --     self:InitListView(self.list)
    --     self:ShowCopyInfo(self.m_curCopyBtn)
    -- end
end

function PetInstancesUI:GetInd()
    return self.m_beginInd
end

function PetInstancesUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pSweepBtn = nil
    self.m_panelUI = nil
    self.m_pPetInstancesBg = nil
    self.m_pRightTableView = nil
    self.list = nil
    self.m_pLine = nil
    self.m_curCopyBtn = nil
    
    self.m_pContent = nil
    self.m_pInfo1 = nil
    self.m_pInfo2 = nil
    self.m_pInfo3 = nil
    self.m_pInfo4 = nil

    self.m_pGoldNum = nil
    self.m_pCoinNum = nil
    
    self.m_pSweepBtn = nil
    self.m_pEnterBtn = nil
end

function PetInstancesUI:AddTouchEvt()
    self.idx = 1
    local function SweepCallback(sender)
        local petCoye = LDataConstMgr.m_CopyData._PetCopyList
        local ind = self.m_curCopyBtn:getTag()
        local copy = petCoye[ind]

        LuaNetSendMsg:QueryPetCopySweep(4, copy.Id)
    end
    self.m_pSweepBtn:addClickEventListener(SweepCallback)
	self:MarkIntaractCObj(self.m_pSweepBtn)
    local function EnterCallback(sender)
        self:EnterCallback(sender)
    end
    self.m_pEnterBtn:addClickEventListener(EnterCallback)
	self:MarkIntaractCObj(self.m_pEnterBtn)
end

function PetInstancesUI:EnterCallback( sender )
    -- body
    if self.m_curCopyBtn == nil then
        return
    end

    --昆仑寻宝状态下,不能参见副本
    if LRoleDataMgr.MonopolyData.isMonopolyState then
        Utils:ShowScrollTips(GUITips.RSI_GS_TIP_MONOPOLY)
        return
    end

    Utils:SendMsg(LUIActivityEvent.EnterFubBen)

    local petCoye = LDataConstMgr.m_CopyData._PetCopyList
    local ind = self.m_curCopyBtn:getTag()
    local copy = petCoye[ind]

    if ind == 4 then -- 通天塔
        if Utils:CheckModelNotOpened(AppDef.EActivityID.EAID_TOWER) then
            return
        end
        EnterBtnTouched(AppDef.EActivityID.EAID_TOWER)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Instances.InstancesMainUI")
        self:SendMsg(LGameMsg.m_initUIMsg)
    else
        if copy.costtype > 1 then
            local num =  LRoleDataMgr.Equip:CountItemNumById(copy.UseMoney)
            if num == 0 then
                Utils:ItemNotEnoughTips(copy.UseMoney)
                return
            end
        else
            if copy.canEnterTimes <= 0 then
                Utils:ShowScrollTips(string.format(GUITips.Copy_Tips_Error1, copy.Name))
                return
            end
        end

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
        LuaNetSendMsg:QueryEnterPetCopy(copy.Id)
    end
end

function PetInstancesUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("Panel")
    self.m_pPetInstancesBg = self.m_panelUI:getChildByName("PetInstancesBg")

    -- å‰¯æœ¬åŒºåŸŸ
    self.list = self.m_pPetInstancesBg:getChildByName("List")
    self.m_pLine = self.m_pPetInstancesBg:getChildByName("List"):getChildByName("Line")
    self.m_pLine:getChildByName("Button1"):setVisible(false)
    self.m_pLine:getChildByName("Button2"):setVisible(false)
    self.m_pLine:getChildByName("Button3"):setVisible(false)
    self.m_pLine:getChildByName("Button4"):setVisible(false)
    self.m_curCopyBtn = nil
    
    -- å³ä¾§æ˜¾ç¤ºæ ?
    self.m_pContent = self.m_pPetInstancesBg:getChildByName("Content")
    self.m_pInfo1 = self.m_pContent:getChildByName("ContentText1")  -- å¼€å¯æ¡ä»?
    self.m_pInfo2 = self.m_pContent:getChildByName("ContentText2")  -- äº§å‡º
    self.m_pInfo3 = self.m_pContent:getChildByName("ContentText3")  -- æŽ‰è½
    self.m_pInfo4 = self.m_pContent:getChildByName("ContentText4")  -- å‡ çŽ‡
    self.m_pInfo3:setVisible(false)
    self.m_pInfo4:setVisible(false)

    self.m_pGoldNum = self.m_pContent:getChildByName("GoldBg"):getChildByName("GoldNum")
    self.m_pCoinNum = self.m_pContent:getChildByName("CoinBg"):getChildByName("CoinNum")
    
    self.m_pSweepBtn = self.m_pContent:getChildByName("SweepBtn")
    self.m_pSweepBtn:setVisible(false)
    self.m_pEnterBtn = self.m_pContent:getChildByName("EnterBtn")
    self.m_pGoldNum:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().TongBao)
    self.m_pCoinNum:setString(LRoleDataMgr.MyHeroInfo:GetDetailData().Money)
    
end

function PetInstancesUI:InitListView(view)
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
        local petCoye = LDataConstMgr.m_CopyData._PetCopyList
        local num = math.ceil(#petCoye / 4)
        return num
    end

    --tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)   --TableViewè¢«è§¦æ‘¸çš„æ—¶å€™çš„å›žè°ƒï¼Œä¸»è¦ç”¨äºŽé€‰æ‹©TableViewä¸­çš„Cell
    tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)   --æ­¤å›žè°ƒéœ€è¦è¿”å›žTableViewä¸­Cellçš„å°ºå¯¸å¤§å°?
    tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)   --æ­¤å›žè°ƒéœ€è¦ä¸ºTableViewåˆ›å»ºåœ¨æŸä¸ªä½ç½®çš„Cell
    tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  --æ­¤å›žè°ƒéœ€è¦è¿”å›žTableViewä¸­Cellçš„æ•°é‡?
    tableView:reloadData()
    self.m_pRightTableView = tableView
end

function PetInstancesUI:TableLineTouched(cell)

end

function PetInstancesUI:TableLineAtIndex(sender, idx)
    local function ButtonTouched(sender)    --å‰¯æœ¬ç‚¹å‡»
        self.m_beginInd = sender:getTag()
        self:ShowCopyInfo(sender)
    end

    local line = sender:dequeueCell()
    local petCoye = LDataConstMgr.m_CopyData._PetCopyList
    local lineChild
    if line == nil then
        line = cc.TableViewCell:new()
        lineChild = self.m_pLine:clone()
        
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
        local ind = i + addIdx
        local button = lineChild:getChildByName("Button"..i)
        if self.m_beginInd == nil or self.m_beginInd == ind or self.m_beginInd > #petCoye then
            self.m_curCopyBtn = button -- -- 默认第一个被选中
            self.m_beginInd = ind
        end
        if ind <= #petCoye then
            self:ShowCopyButton(button, petCoye[ind])
            button:setTag(ind)
            button:addClickEventListener(ButtonTouched)
			self:MarkIntaractCObj(button)
        else
            button:setVisible(false)
        end
    end
    return line
end

function PetInstancesUI:ShowCopyButton(button, info)
    button:setVisible(true)
    button:setTouchEnabled(true)
    local redDot = button:getChildByName("RedDot")
	
    if info ~= nil then
        if info.IsLock then
            button:getChildByName("Unlock"):setVisible(true)
            button:getChildByName("UnlockBg"):setVisible(true)
            button:getChildByName("ConsumIcon"):setVisible(false)
            button:getChildByName("ConsumName"):setVisible(false)
            button:getChildByName("ConsumNum"):setVisible(false)
            redDot:setVisible(false) 
        else
            button:getChildByName("Unlock"):setVisible(false)
            button:getChildByName("UnlockBg"):setVisible(false)
            redDot:setVisible(true)
            if info.canEnterTimes ~= 255 then
                redDot:getChildByName("Text"):setString(info.canEnterTimes)
            else
                redDot:getChildByName("Text"):setString("")
            end
            if info.costtype == 0 or info.costtype == 1 then
                if info.UseMoney ~= 0 then
                    button:getChildByName("ConsumName"):setString(GUITips.Copy_Cost_Type)
                    button:getChildByName("ConsumNum"):setString(info.UseMoney..GUITips["Copy_Cost_Type"..info.costtype])
                else
                    button:getChildByName("ConsumName"):setVisible(false)
                    button:getChildByName("ConsumNum"):setVisible(false)
                end
                button:getChildByName("ConsumIcon"):setVisible(false)
            else
                button:getChildByName("ConsumNum"):setVisible(false)
                button:getChildByName("ConsumIcon"):setVisible(true)
                local icon = button:getChildByName("ConsumIcon")
                button:getChildByName("ConsumName"):setString(GUITips.Copy_Cost_Type)
                icon:loadTexture("item/equip"..LRoleDataMgr.GetItemPicId(info.UseMoney)..".png", ccui.TextureResType.localType)
                -- if LRoleDataMgr.Equip:FindPackageItemById1(info.UseMoney) == 0 then
                --     redDot:setVisible(false)
                -- end
            end
        end
        if info and info.Id == 4 then
            redDot:setVisible(false)
        end
        local lvBg = button:getChildByName("LabelBg1")
		local bg = button:getChildByName("PetBg")
		if info.Id == 0 then
			bg:loadTexture("res2/InstancesBg/map20_0.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_1"])
		elseif info.Id ==1 then
			bg:loadTexture("res2/InstancesBg/map20_1.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_2"])
		elseif info.Id ==2 then
			bg:loadTexture("res2/InstancesBg/map20_2.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_3"])
		elseif info.Id ==3 then
			bg:loadTexture("res2/InstancesBg/map15.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_5"])
		elseif info.Id ==4 then
			bg:loadTexture("res2/InstancesBg/ui_xunchong_map.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_4"])
		elseif info.Id ==5 then
			bg:loadTexture("res2/InstancesBg/ui_xunchong_map.png")
			lvBg:getChildByName("LableName"):setString(GUITips["UI_Text_Copy_Level_4"])
		end		
        button:getChildByName("InstancesName"):setString(info.Name)
        button:getChildByName("SelectBorder"):setVisible(false)
    end
end

function PetInstancesUI:ShowCopyInfo(button)
    if button == nil then 
        return 
    end
    local petCoye = LDataConstMgr.m_CopyData._PetCopyList
    local ind = button:getTag()
    local info = petCoye[ind]
    if info == nil then
        return
    end
    if self.m_curCopyBtn ~=  nil then
        self.m_curCopyBtn:setBrightStyle(0)
        self.m_curCopyBtn:getChildByName("SelectBorder"):setVisible(false)
    end
    self.m_curCopyBtn = button
    self.m_curCopyBtn:setBrightStyle(1)
    self.m_curCopyBtn:getChildByName("SelectBorder"):setVisible(true)

    self.m_pInfo1:setString(info.Notice) -- å¼€å¯æ¡ä»?
    self.m_pInfo2:setString(GUITips["Pet_Copy_Mine_Tip"..info.Id]) -- äº§å‡º

    -- self.m_pEnterBtn:setBright(not info.IsLock and info.canEnterTimes ~= 0)
    -- self.m_pEnterBtn:setTouchEnabled(not info.IsLock and info.canEnterTimes ~= 0)

    self:UpdateCanSweep(info)
end

function PetInstancesUI:IsCanSweep(info)
    -- return info and info.isCleared == 1
    return info.Id ~= 2 and info.Id ~= 4 --不显示扫荡
end

function PetInstancesUI:UpdateCanSweep(info)
    self.m_pSweepBtn:setVisible(self:IsCanSweep(info))
    -- dump(info)
    local isCanSweep = info.canEnterTimes > 0
    self.m_pSweepBtn:setBright(isCanSweep)
    -- self.m_pSweepBtn:setTouchEnabled(isCanSweep)
end

return PetInstancesUI