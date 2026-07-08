local WelfareActivityDef = require("View.WelfareActivity.WelfareActivityDef")

local ActivityRankUI = LUIBase:New()
ActivityRankUI.__index = ActivityRankUI

local g_cellTag = 0
local m_pTableView = nil
local m_tableCount = 0
local m_isDragging = false
local m_datas = nil
local m_pItems = {}
local m_tag = 0
----------------------------------------------------------------------
function ActivityRankUI:setTag(tag)
    m_tag = tag
end
----------------------------------------------------------------------
function ActivityRankUI:New(uiLayer)
    local o = {}
    setmetatable(o, ActivityRankUI)
    o:Init(uiLayer)
    return o
end

----------------------------------------------------------------------
function ActivityRankUI:Init(uiLayer)
    self.Script = "WelfareActivity.ActivityRankUI"
    ----------------------------------------------------------------------
    self.m_pUILayer = uiLayer
    self.m_pTimeBg = nil
    self.m_vecHeroInfo = nil
    ----------------------------------------------------------------------
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    ----------------------------------------------------------------------
    self:InitUIControl()
    self:setCloseCallback()
end

----------------------------------------------------------------------
function ActivityRankUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    for k,v in pairs(m_pItems) do
        local _ = v and v:onExit(true)
        v = nil
    end
    m_pTableView = nil
    m_tableCount = 0
    m_isDragging = false
    m_datas = nil
    m_pItems = {}
    g_cellTag = 0
    self.m_pTimeBg = nil
    self.m_vecHeroInfo = nil
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
end

----------------------------------------------------------------------
function ActivityRankUI:InitUIControl()
    local pPanel = self.m_pUILayer
    ----------------------------------------------------------------------
    local pPowerBg = pPanel:getChildByName("PowerBg")
    pPowerBg:setVisible(true)
    ----------------------------------------------------------------------
    local pRechargeBtn = pPowerBg:getChildByName("RechargeBtn")
    pRechargeBtn:addClickEventListener(handler(self, ActivityRankUI.RechargeClick))
	self:MarkIntaractCObj(pRechargeBtn)
    ----------------------------------------------------------------------
    local pButton = pPowerBg:getChildByName("Button")
    pButton:addClickEventListener(handler(self, ActivityRankUI.ButtonClick))
	self:MarkIntaractCObj(pButton)
    ----------------------------------------------------------------------
    self.m_pTablePanel = pPanel:getChildByName("List")
    self.m_pTablePanel:setVisible(true)
    self.m_pTablePanel:setTouchEnabled(false)
    ----------------------------------------------------------------------
    self.m_pGridCell = pPanel:getChildByName("Ranking")
    self.m_pGridCell:setAnchorPoint(cc.p(0,0))
    self.m_pGridCell:setTouchEnabled(false)
    self.m_pGridCell:setVisible(false)
    ----------------------------------------------------------------------
    if m_pTableView == nil then
        m_pTableView = self:InitTableView(self.m_pTablePanel)
    end
    ----------------------------------------------------------------------
    self.m_pTimeBg = pPowerBg:getChildByName("Time")
    ---------------------------------------------------------------------
    local Recharge = pPanel:getChildByName("Recharge")
    self._petCell = Recharge:getChildByName("IconColor")
end
----------------------------------------------------------------------
function ActivityRankUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
----------------------------------------------------------------------
function ActivityRankUI:InitTableView(tbPanel)
    local cfg = {}
    cfg.tbPanel = tbPanel
    cfg.cellSizeForTable = function(sender,idx)
        local width = self.m_pGridCell:getContentSize().width
        local height = self.m_pGridCell:getContentSize().height
        return width, height
    end
    cfg.tableCellAtIndex = function(sender, idx)
        return self:TableCellAtIndex(sender, idx)
    end

    cfg.numberOfCellsInTableView = function()
        return m_tableCount
    end

    cfg.scrollViewDidScroll = function(view)
        m_isDragging = view:isDragging()
    end

    return Utils:createTableView(cfg)
end
----------------------------------------------------------------------
function ActivityRankUI:TableCellAtIndex(sender, idx)
    idx = idx + 1
    local cell = sender:dequeueCell()
    local cellChild = nil
    
    if cell == nil then
        g_cellTag = g_cellTag + 1
        cell = cc.TableViewCell:new()
        cell:setTag(g_cellTag)

        cellChild = self.m_pGridCell:clone()
        cellChild:setTag(123)
        cellChild:setPosition(cc.p(0, 0))
        cellChild:setVisible(true)
        cellChild:setEnabled(true)
        cell:addChild(cellChild)

        local pIconBg_1 = cellChild:getChildByName("IconBg_1")
        pIconBg_1:setTouchEnabled(true)
        pIconBg_1:setSwallowTouches(false)
        local pIconBg_2 = cellChild:getChildByName("IconBg_2")
        pIconBg_2:setTouchEnabled(true)
        pIconBg_2:setSwallowTouches(false)
    else
        cellChild = cell:getChildByTag(123)
    end
    if cellChild ~= nil then
        self:updateItem(cellChild, m_datas[idx], idx, cell:getTag())
    end
    return cell
end
----------------------------------------------------------------------
function ActivityRankUI:updateItem(cell, info, idx, cellTag)
    self:updateRank(cell, info, idx)
    -----------------------------------------------------------------------------------
    self:updateRankUserName(cell, info, idx)
    -----------------------------------------------------------------------------------
    local pPowerBg = cell:getChildByName("PowerBg")
    pPowerBg:setVisible(false)
    local pLevelBg = cell:getChildByName("LevelBg")
    pLevelBg:setVisible(false)
    local pQianghuaBg = cell:getChildByName("QianghuaBg")
    pQianghuaBg:setVisible(false)
    local pRechargeBg = cell:getChildByName("RechargeBg")
    pRechargeBg:setVisible(false)
    local MeiliBg = cell:getChildByName("MeiliBg")
    MeiliBg:setVisible(false)
    -----------------------------------------------------------------------------------
    if m_tag == WelfareActivityDef.Type.DengJiChongCiBang then
        self:updateRankLevel(pLevelBg, info)
    elseif m_tag == WelfareActivityDef.Type.ZuiQiangShenChongBang then
        self:updateRankPet(pPowerBg, info)
    elseif m_tag == WelfareActivityDef.Type.XianJiaQiangHuaBang then
        self:updateRankQianghua(pQianghuaBg, info)
    elseif m_tag == WelfareActivityDef.Type.QunXianZhanLiBang then
        self:updateRankPower(pPowerBg, info)
    elseif m_tag == WelfareActivityDef.Type.ShenJiYuYiBang then
        self:updateRankWing(pPowerBg, info)
    elseif m_tag == WelfareActivityDef.Type.XinFuChongZhiBang then
        self:updateRankRecharge(pRechargeBg, info)
    elseif m_tag == WelfareActivityDef.Type.XianHuaBang then
        self:updateRankRecharge(MeiliBg, info)
    end
    -----------------------------------------------------------------------------------
    self:updateRankButton(cell, info, idx, cellTag)
end
----------------------------------------------------------------------
function ActivityRankUI:updateRank(cell, info, rank)
    if cell == nil or info == nil then
        return
    end
    local pNum_1 = cell:getChildByName("Num_1")
    local pNum_2 = cell:getChildByName("Num_2")
    if rank < 4 then
        pNum_1:setVisible(true)
        pNum_2:setVisible(false)
        pNum_1:loadTexture(string.format("res/UI/ui_paihangbang/ui_paihangbang_nm_0%d.png", rank), UI_TEX_TYPE_PLIST)
    else
        pNum_1:setVisible(false)
        pNum_2:setVisible(true)
        pNum_2:setString(tostring(rank))
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankUserName(parent, info, rank)
    if parent == nil or info == nil then
        return
    end
    local pText = parent:getChildByName("Name")
    if pText ~= nil then
        pText:setString(info.heroName)
        if rank == 1 then
            pText:setTextColor(cc.c4b(255,0,0,255))
        elseif rank == 2 then
            pText:setTextColor(cc.c4b(0,0,255,255))
        elseif rank == 3 then
            pText:setTextColor(cc.c4b(0,255,0,255))
        else
            pText:setTextColor(cc.c4b(110,56,48,255))
        end
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankLevel(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    local pValue = pNode:getChildByName("Value")
    pValue:setString('Lv.'..info.heroValue)
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankPower(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    pNode:setPositionY(50)
    local pValue = pNode:getChildByName("Value")
    pValue:setString(tostring(info.heroValue))
    local pPetText = pNode:getChildByName("PetText")
    pPetText:setVisible(false)
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankWing(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    pNode:setPositionY(60)
    
    local pValue = pNode:getChildByName("Value")
    pValue:setString(tostring(info.heroValue))

    local pPetText = pNode:getChildByName("PetText")
    pPetText:setVisible(true)
    local wingId = tonumber(info.heroName2)
    if wingId and wingId > 0 then
        local data = LDataConstMgr:GetWingConfigData(wingId)
        pPetText:setString(string.format(GUITips.RSI_WACT_TIP7, data and data.name or ""))
    else
        pPetText:setString(string.format(GUITips.RSI_WACT_TIP7, ""))
        --dump(info)
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankRecharge(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    local pValue = pNode:getChildByName("Value")
    pValue:setString(tostring(info.heroValue or 0))
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankPet(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    pNode:setPositionY(60)

    local pValue = pNode:getChildByName("Value")
    pValue:setString(tostring(info.heroValue))

    local pPetText = pNode:getChildByName("PetText")
    pPetText:setVisible(true)
    pPetText:setString(string.format(GUITips.RSI_WACT_TIP1, info.heroName2))
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankQianghua(pNode, info)
    if pNode == nil or info == nil then
        return
    end
    pNode:setVisible(true)
    local pValue = pNode:getChildByName("Value")
    pValue:setString('+'..info.heroValue)
end
----------------------------------------------------------------------
function ActivityRankUI:updateRankButton(pNode, info, rank, cellTag)
    if pNode == nil or info == nil then
        return
    end

    for i=1,#info.awarddatas do
        local index = rank * 2 + i
        local pIconBg = pNode:getChildByName("IconBg_"..i)
        pIconBg:setVisible(true)

        local item = info.awarddatas[i]

        -- local pIcon = pIconBg:getChildByName("Icon")
        -- local isMoney = item.id >= AppDef.AwrdItem.AWRD_ITEM_COIN and false
        -- if pIcon ~= nil then
        --     pIcon:setVisible(isMoney)
        -- end
        
        -- local pNum = pIconBg:getChildByName("Text_5")
        -- if pNum ~= nil then
        --     pNum:setVisible(isMoney)
        -- end

        pIconBg:removeAllChildren()
        if item.id == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then
            --称号
            Utils:GetItemCellValue(pIconBg, 0, item.id, false, true, item.medalID, nil, true)
        elseif item.petData ~= nil then
            --宠物显示
            local showItem = self._petCell:clone()
            pIconBg:addChild(showItem)
            Utils:ShowPetByData(item.petData, pIconBg, showItem, false)
        else
            -- print("honorButtonClick item.id =", item.id)
            Utils:GetItemCellValue(pIconBg, 0, item.id, false, true, item.num or item.itemNum, nil, true)
        end
    end

    local pIconBg_2 = pNode:getChildByName("IconBg_2")
    if #info.awarddatas < 2 then
        pIconBg_2:setVisible(false)
    end

end
----------------------------------------------------------------------
function ActivityRankUI:honorButtonClick(sender)
     local tag = sender:getTag()
     local info = m_datas[tag]
     local id = nil
     for i=1,#info.awarddatas do
         local item = info.awarddatas[i]
         if item.id == AppDef.AwrdItem.AWRD_ITEM_CHENGHAO then
             id = item.medalID
             break
         end
     end
     if id ~= nil and id > 0 then
         Utils:OpenWearTips("Title",id)
     end
end
----------------------------------------------------------------------
function ActivityRankUI:initData()
    self:Reset()
    if m_tag == WelfareActivityDef.Type.DengJiChongCiBang then
        LuaNetSendMsg:QueryWelFareInfo(28)
    elseif m_tag == WelfareActivityDef.Type.ZuiQiangShenChongBang then
        LuaNetSendMsg:QueryWelFareInfo(26)
    elseif m_tag == WelfareActivityDef.Type.XianJiaQiangHuaBang then
        LuaNetSendMsg:QueryWelFareInfo(27)
    elseif m_tag == WelfareActivityDef.Type.QunXianZhanLiBang then
        LuaNetSendMsg:QueryWelFareInfo(29)
    elseif m_tag == WelfareActivityDef.Type.XinFuChongZhiBang then
        LuaNetSendMsg:QueryWelFareInfo(30)
    elseif m_tag == WelfareActivityDef.Type.XianHuaBang then
        LuaNetSendMsg:QueryWelFareInfo(85)
    elseif m_tag == WelfareActivityDef.Type.ShenJiYuYiBang then
        LuaNetSendMsg:QueryWelFareInfo(45)
    end
end

function ActivityRankUI:updateData(data)
    Utils:FreeTable(self.m_vecHeroInfo)
    self.m_vecHeroInfo = nil
    self.m_vecHeroInfo = {}
    local loop = #data.roledatas
    for k = 1,loop do
        local tmpHeroInfo = {}
        tmpHeroInfo.heroID = data["roledatas"][k]["role_id"]
        tmpHeroInfo.heroValue = data["roledatas"][k]["value"]
        tmpHeroInfo.heroName = data["roledatas"][k]["role_name"]
        tmpHeroInfo.heroName2 = data["roledatas"][k]["pet_name"]
        tmpHeroInfo.awarddatas = data["roledatas"][k]["awarddatas"]
        table.insert(self.m_vecHeroInfo, tmpHeroInfo)
    end
    Utils:FreeTable(self.m_result)
    self.m_result = nil
    self.m_result = data
    Utils:FreeTable(m_datas)
    m_datas = nil
    m_datas = self.m_vecHeroInfo or {}
    m_tableCount = #m_datas
    self.m_pTablePanel:setVisible(true)
    m_pTableView:setVisible(true)
    m_pTableView:reloadData()
    self:updateTop()
    self.m_pUILayer:setVisible(true)
end
----------------------------------------------------------------------
function ActivityRankUI:Reset()
    if self.m_pUILayer == nil then
        return
    end
    local pPowerBg = self.m_pUILayer:getChildByName("PowerBg")
    ------------------------------------------------------------------
    local pChildren = pPowerBg:getChildren()
    for i=1,#pChildren do
        pChildren[i]:setVisible(false)
    end
    local pButton = pPowerBg:getChildByName("Button")
    for i=1,5 do
        local pText = pButton:getChildByName("Text_"..i)
        local _ = pText and pText:setVisible(false)
    end
    self.m_pTablePanel:setVisible(false)
    m_pTableView:setVisible(false)
end
----------------------------------------------------------------------
function ActivityRankUI:updateTop()
    local pPowerBg = self.m_pUILayer:getChildByName("PowerBg")
    pPowerBg:setVisible(true)
    ------------------------------------------------------------------
    local pButton = pPowerBg:getChildByName("Button")
    ------------------------------------------------------------------
    if m_tag == WelfareActivityDef.Type.DengJiChongCiBang then
        local pNode = pPowerBg:getChildByName("MyLevel")
        local _ = self:checkNode(pNode) and self:updateLevel(pNode)
        pButton:setTag(m_tag)
        pButton:setVisible(true)
        pButton:getChildByName("Text_2"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.ZuiQiangShenChongBang then
        local pNode = pPowerBg:getChildByName("MyPet")
        local _ = self:checkNode(pNode) and self:updatePet(pNode)
        pButton:setTag(m_tag)
        pButton:setVisible(true)
        pButton:getChildByName("Text_4"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.XianJiaQiangHuaBang then
        local pNode = pPowerBg:getChildByName("MyQianghua")
        local _ = self:checkNode(pNode) and self:updateQiangHua(pNode)
        pButton:setTag(m_tag)
        pButton:setVisible(true)
        pButton:getChildByName("Text_3"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.QunXianZhanLiBang then
        local pNode = pPowerBg:getChildByName("MyPower")
        local _ = self:checkNode(pNode) and self:updatePower(pNode)
        pButton:setTag(m_tag)
        pButton:setVisible(true)
        pButton:getChildByName("Text_1"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.XinFuChongZhiBang then
        local pNode = pPowerBg:getChildByName("MyRecharge")
        local _ = self:checkNode(pNode) and self:updateRecharge(pNode)
        pPowerBg:getChildByName("RechargeBtn"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.ShenJiYuYiBang then
        local pNode = pPowerBg:getChildByName("MyPet")
        local _ = self:checkNode(pNode) and self:updateWing(pNode)
        pButton:setTag(m_tag)
        pButton:setVisible(true)
        pButton:getChildByName("Text_5"):setVisible(true)
    elseif m_tag == WelfareActivityDef.Type.XianHuaBang then
        local pNode = pPowerBg:getChildByName("MyMeili")
        local _ = self:checkNode(pNode) and self:updateXianhua(pNode)
    end
    do
        local _ = self:checkNode(self.m_pTimeBg)
        self:updateTime(self.m_pTimeBg, self.m_result.desc, self.m_result.state)
        local pNode = pPowerBg:getChildByName("MyRanking")
        local _ = self:checkNode(pNode) and self:updateMyRank(pNode, self.m_result.my_paihang or 0)
    end

    local tips = self.m_pUILayer:getChildByName("Tips")
    tips:setVisible(true)
end
----------------------------------------------------------------------
function ActivityRankUI:checkNode(pNode)
    if pNode == nil then
        return false
    end
    pNode:setVisible(true)
    return true
end
----------------------------------------------------------------------
function ActivityRankUI:updatePower(pNode)
    pNode:getChildByName("Value"):setString(self.m_result.my_data or 0)
end
----------------------------------------------------------------------
function ActivityRankUI:updateLevel(pNode)
    pNode:getChildByName("Text"):setString(self.m_result.my_data or 0)
end
----------------------------------------------------------------------
function ActivityRankUI:updatePet(pNode)
    pNode:setString(GUITips.RSI_WACT_TIP5)
    local pName = pNode:getChildByName("Text")
    local id = tonumber(self.m_result.my_data)
    if id then
        local zhandouli = nil
        local name = nil
        for i=1,#LRoleDataMgr.Pet.petlist do
            local info = LRoleDataMgr.Pet.petlist[i]
            if info and info.id and info.id == id then
                zhandouli = info.zhandouli
                name = info.name
                break
            end
        end
        if zhandouli and name then
            pName:setString(name .. "(" ..GUITips.RSI_WACT_TIP12 .. Utils:getPowerStr(zhandouli) .. ")")
        else
            pName:setString("")
        end
    else
        pName:setString("")
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateWing(pNode)
    pNode:setString(GUITips.RSI_WACT_TIP4)
    local wingId = tonumber(self.m_result.my_data)
    if wingId > 0 then
        local data = LDataConstMgr:GetWingConfigData(wingId)
        local str = data and data.name or ""
        if #str > 0 then
            local OtInfo = LRoleDataMgr.MyHeroInfo:GetChiBangOtherInfo()
            if OtInfo and OtInfo.fightPower then
                str = str .. GUITips.RSI_WACT_TIP12 .. Utils:getPowerStr(OtInfo.fightPower)
            end
            pNode:getChildByName("Text"):setString(str)
        end
    else
        pNode:getChildByName("Text"):setString(GUITips.RSI_WACT_TIP6)
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateQiangHua(pNode)
    pNode:getChildByName("Text"):setString("+" .. (self.m_result.my_data or ""))
end
----------------------------------------------------------------------
function ActivityRankUI:updateRecharge(pNode)
    local pGoldIcon = pNode:getChildByName("GoldIcon")
    pGoldIcon:getChildByName("Text"):setString(self.m_result.my_data or "")
end
----------------------------------------------------------------------
function ActivityRankUI:updateXianhua(pNode)
    local FlowerIcon = pNode:getChildByName("FlowerIcon")
    FlowerIcon:getChildByName("Text"):setString(self.m_result.my_data or "")
end
----------------------------------------------------------------------
function ActivityRankUI:updateTime(pNode, str, state)
    local pTime = pNode:getChildByName("Text_1")
    local pFinish = pTime:getChildByName("Text_2")
    pTime:setString(str or "")
    pFinish:setVisible(true)
    if state == 0 then
        pFinish:setString(GUITips.RSI_WACT_TIP8)
        pFinish:setPositionX(pTime:getContentSize().width + 6)
        pFinish:setTextColor(cc.c4b(0xFF,0xA5,0,0xff))
    elseif state == 1 then
        pFinish:setString(GUITips.RSI_WACT_TIP9)
        pFinish:setPositionX(pTime:getContentSize().width + 6)
        pFinish:setTextColor(cc.c4b(0,0x80,0,0xff))
    elseif state == 2 then
        pFinish:setString(GUITips.RSI_WACT_TIP10)
        pFinish:setPositionX(pTime:getContentSize().width + 6)
        pFinish:setTextColor(cc.c4b(0xff,0,0,0xff))
    else
        pFinish:setVisible(false)
    end
end
----------------------------------------------------------------------
function ActivityRankUI:updateMyRank(pNode, myRank)
    if myRank > 0 then
        pNode:getChildByName("Text"):setString(tostring(myRank))
    else
        pNode:getChildByName("Text"):setString(GUITips.RSI_WACT_TIP2)
    end
end
----------------------------------------------------------------------
function ActivityRankUI:RechargeClick(sender)
    Utils:DeleteUI("WelfareActivity.WelfareActivityUI")
    LuaNetSendMsg:QueryPayPriceList()
end

function ActivityRankUI:ButtonClick(sender)
    local tag = sender:getTag()
    if tag ~= m_tag then
        return
    end
    
    if m_tag == WelfareActivityDef.Type.DengJiChongCiBang then
        Utils:SendMsg(LUIWelfareActivityEvent.ClosePopup)
        Utils:OpenFunction(AppDef.EModuleID.EMID_WANFA)
    elseif m_tag == WelfareActivityDef.Type.ZuiQiangShenChongBang then
        Utils:SendMsg(LUIWelfareActivityEvent.ClosePopup)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHENJIANG)
    elseif m_tag == WelfareActivityDef.Type.XianJiaQiangHuaBang then
        Utils:SendMsg(LUIWelfareActivityEvent.ClosePopup)
        Utils:OpenFunction(AppDef.EModuleID.EMID_DZQIANGHUA)
    elseif m_tag == WelfareActivityDef.Type.QunXianZhanLiBang then
        Utils:SendMsg(LUILogicEvent.ShowBestStrong)
    elseif m_tag == WelfareActivityDef.Type.ShenJiYuYiBang then
        Utils:SendMsg(LUIWelfareActivityEvent.ClosePopup)
        Utils:OpenFunction(AppDef.EModuleID.EMID_YYJINJIE)
    end
end 


return ActivityRankUI